import SwiftUI
import Combine
import AppKit

enum SessionState: Equatable {
    case focus
    case shortBreak
    case longBreak
}

enum TimerState {
    case stopped
    case running
    case paused
}

class TimerManager: ObservableObject {
    @Published var timeRemaining: Int
    @Published var sessionState: SessionState = .focus
    @Published var timerState: TimerState = .stopped
    @Published var sessionCount: Int = 0
    
    // Configurable duration in minutes (not seconds) to make UI bindings easier
    @AppStorage("focusDurationMinutes") var focusDurationMinutes: Int = 25
    @AppStorage("shortBreakDurationMinutes") var shortBreakDurationMinutes: Int = 5
    @AppStorage("longBreakDurationMinutes") var longBreakDurationMinutes: Int = 15
    
    // Safe duration wrappers to prevent integer overflow DOS from UserDefaults corruption
    private var safeFocusDurationMinutes: Int { max(1, min(focusDurationMinutes, 1440)) }
    private var safeShortBreakDurationMinutes: Int { max(1, min(shortBreakDurationMinutes, 1440)) }
    private var safeLongBreakDurationMinutes: Int { max(1, min(longBreakDurationMinutes, 1440)) }

    // Completion sound
    @AppStorage("completionSound") var completionSound: String = "Ping"
    @AppStorage("autoStartBreaks") var autoStartBreaks: Bool = false
    @AppStorage("streakMinMinutes") var streakMinMinutes: Int = 25
    private var safeStreakMinMinutes: Int { max(1, min(streakMinMinutes, 1440)) }
    static let availableSounds = ["Ping", "Glass", "Basso", "Blow", "Bottle", "Frog", "Funk", "Hero", "Morse", "Pop", "Purr", "Sosumi", "Submarine", "Tink"]
    
    // Data Persistence using UserDefaults
    @AppStorage("focusTimeToday") var focusTimeToday: Int = 0
    @AppStorage("sessionsCompletedToday") var sessionsCompletedToday: Int = 0
    @AppStorage("lastActiveDate") var lastActiveDate: Double = Date().timeIntervalSince1970
    
    // Focus History: [DateString (yyyy-MM-dd): TotalSeconds]
    @AppStorage("weeklyFocusHistoryData") private var weeklyFocusHistoryData: Data = Data()
    
    @Published var weeklyHistory: [String: Int] = [:]
    
    // Streak: consecutive days meeting the minimum focus threshold
    var currentStreak: Int {
        let calendar = Calendar.current
        let fmt = dateFormatter()
        let threshold = safeStreakMinMinutes * 60
        var streak = 0
        let today = Date()
        
        // Check today first
        let todayStr = fmt.string(from: today)
        if (weeklyHistory[todayStr] ?? 0) >= threshold {
            streak = 1
        } else {
            return 0
        }
        
        // Walk backwards from yesterday
        var dayOffset = 1
        while dayOffset < 365 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { break }
            let dateStr = fmt.string(from: date)
            if (weeklyHistory[dateStr] ?? 0) >= threshold {
                streak += 1
                dayOffset += 1
            } else {
                break
            }
        }
        return streak
    }
    
    private var timer: AnyCancellable?
    private var tickCounter: Int = 0
    
    var progress: Double {
        let total = totalDuration(for: sessionState)
        return Double(total - timeRemaining) / Double(total)
    }
    
    var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    init() {
        // Initialize timeRemaining with default 0, will be correctly set below
        self.timeRemaining = 0
        self.timeRemaining = totalDuration(for: .focus)
        
        loadWeeklyHistory()
        checkAndUpdateDailyReset()
    }
    
    // Update the display time immediately if settings change while stopped
    func updateTimeForCurrentSettings() {
        if timerState == .stopped {
            timeRemaining = totalDuration(for: sessionState)
        }
    }
    
    func start() {
        checkAndUpdateDailyReset()
        if timerState == .stopped {
            timeRemaining = totalDuration(for: sessionState)
        }
        timerState = .running
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    func pause() {
        timerState = .paused
        timer?.cancel()
    }
    
    func stop() {
        timerState = .stopped
        timer?.cancel()
        tickCounter = 0
        saveWeeklyHistory()
        timeRemaining = totalDuration(for: sessionState)
    }
    
    func skip() {
        nextSession()
    }
    
    private func tick() {
        checkAndUpdateDailyReset()
        
        if sessionState == .focus {
            focusTimeToday += 1
            // Also update today's live history so the chart is real-time
            updateTodayHistoryLive()
        }
        
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            if sessionState == .focus {
                sessionsCompletedToday += 1
            }
            // Play ding sound
            NSSound(named: NSSound.Name(completionSound))?.play()
            // Show the window
            Task { @MainActor in WindowDelegate.shared.showWindow() }
            nextSession()
        }
    }
    
    private func nextSession() {
        stop()
        
        switch sessionState {
        case .focus:
            sessionCount += 1
            if sessionCount % 4 == 0 {
                sessionState = .longBreak
            } else {
                sessionState = .shortBreak
            }
        case .shortBreak, .longBreak:
            sessionState = .focus
        }
        
        timeRemaining = totalDuration(for: sessionState)
        
        // Auto-start breaks if enabled
        if autoStartBreaks && (sessionState == .shortBreak || sessionState == .longBreak) {
            start()
        }
    }
    
    private func totalDuration(for state: SessionState) -> Int {
        switch state {
        case .focus: return safeFocusDurationMinutes * 60
        case .shortBreak: return safeShortBreakDurationMinutes * 60
        case .longBreak: return safeLongBreakDurationMinutes * 60
        }
    }
    
    private func checkAndUpdateDailyReset() {
        let lastDate = Date(timeIntervalSince1970: lastActiveDate)
        if !Calendar.current.isDateInToday(lastDate) {
            // It's a new day, ensure the *previous* day's final time was stored
            saveDailyRecord(date: lastDate, seconds: focusTimeToday)
            
            // Reset today's stats
            focusTimeToday = 0
            sessionsCompletedToday = 0
            
            // Re-initialize today's record in the dictionary so the live chart starts at 0
            updateTodayHistoryLive() 
        } else {
            // Already today, just ensure today is in the dictionary explicitly
            updateTodayHistoryLive()
        }
        lastActiveDate = Date().timeIntervalSince1970
    }
    
    // MARK: - Focus History Logic
    
    private func dateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
    
    private func loadWeeklyHistory() {
        if let decoded = try? JSONDecoder().decode([String: Int].self, from: weeklyFocusHistoryData) {
            weeklyHistory = decoded
        }
    }
    
    private func saveWeeklyHistory() {
        pruneOldHistory()
        if let encoded = try? JSONEncoder().encode(weeklyHistory) {
            weeklyFocusHistoryData = encoded
        }
    }
    
    private func pruneOldHistory() {
        let calendar = Calendar.current
        let fmt = dateFormatter()
        let cutoff = calendar.date(byAdding: .day, value: -365, to: Date()) ?? Date()
        weeklyHistory = weeklyHistory.filter { key, _ in
            if let date = fmt.date(from: key) {
                return date >= cutoff
            }
            return false
        }
    }
    
    private func saveDailyRecord(date: Date, seconds: Int) {
        let dateString = dateFormatter().string(from: date)
        weeklyHistory[dateString] = seconds
        saveWeeklyHistory()
    }
    
    private func updateTodayHistoryLive() {
        let dateString = dateFormatter().string(from: Date())
        weeklyHistory[dateString] = focusTimeToday
        // Only persist to disk every 60 seconds
        tickCounter += 1
        if tickCounter >= 60 {
            tickCounter = 0
            saveWeeklyHistory()
        }
    }
}
