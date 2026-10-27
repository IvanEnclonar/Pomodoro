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

struct TimerStatus: Codable, Sendable {
    let timerState: String
    let sessionState: String
    let timeRemaining: Int
    let sessionCount: Int
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case timerState = "timer_state"
        case sessionState = "session_state"
        case timeRemaining = "time_remaining"
        case sessionCount = "session_count"
        case updatedAt = "updated_at"
    }
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
    
    // Completion sound
    @AppStorage("completionSound") var completionSound: String = "Ping"
    @AppStorage("autoStartBreaks") var autoStartBreaks: Bool = false
    @AppStorage("streakMinMinutes") var streakMinMinutes: Int = 25

    // Remote control
    @AppStorage("supabaseUrl") var supabaseUrl: String = ""
    @AppStorage("supabaseKey") var supabaseKey: String = ""
    @AppStorage("remoteControlEnabled") var remoteControlEnabled: Bool = false
    static let availableSounds = ["Ping", "Glass", "Basso", "Blow", "Bottle", "Frog", "Funk", "Hero", "Morse", "Pop", "Purr", "Sosumi", "Submarine", "Tink"]
    
    // Data Persistence using UserDefaults
    @AppStorage("focusTimeToday") var focusTimeToday: Int = 0
    @AppStorage("sessionsCompletedToday") var sessionsCompletedToday: Int = 0
    @AppStorage("lastActiveDate") var lastActiveDate: Double = Date().timeIntervalSince1970
    
    // Focus History: [DateString (yyyy-MM-dd): TotalSeconds]
    @AppStorage("weeklyFocusHistoryData") private var weeklyFocusHistoryData: Data = Data()
    
    @Published var weeklyHistory: [String: Int] = [:]

    // Open session: counts up with no target while the timer is set aside
    @Published private(set) var isOpenSession = false
    @Published private(set) var openSessionRunning = false
    @Published private(set) var openElapsed: Int = 0
    @Published private(set) var openSessionStart: Date?
    @Published var openSessionToast: OpenSessionToast?
    private var openTimer: AnyCancellable?
    private var setAside: (state: TimerState, session: SessionState, remaining: Int)?
    
    // Streak: consecutive days meeting the minimum focus threshold
    var currentStreak: Int {
        let calendar = Calendar.current
        let fmt = dateFormatter()
        let threshold = streakMinMinutes * 60
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
    func currentStatus() -> TimerStatus {
        let timerStateStr: String
        switch timerState {
        case .running: timerStateStr = "running"
        case .paused:  timerStateStr = "paused"
        case .stopped: timerStateStr = "stopped"
        }
        let sessionStateStr: String
        switch sessionState {
        case .focus:       sessionStateStr = "focus"
        case .shortBreak:  sessionStateStr = "shortBreak"
        case .longBreak:   sessionStateStr = "longBreak"
        }
        let iso = ISO8601DateFormatter()
        return TimerStatus(
            timerState: timerStateStr,
            sessionState: sessionStateStr,
            timeRemaining: timeRemaining,
            sessionCount: sessionCount,
            updatedAt: iso.string(from: Date())
        )
    }

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
        case .focus: return focusDurationMinutes * 60
        case .shortBreak: return shortBreakDurationMinutes * 60
        case .longBreak: return longBreakDurationMinutes * 60
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

// MARK: - Open Session

struct OpenSessionToast: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let seconds: Int
    let logged: Bool
}

extension TimerManager {
    /// "45 sec", "12 min", "1h 5m"
    static func describe(seconds: Int) -> String {
        if seconds < 60 { return "\(seconds) sec" }
        let minutes = Int((Double(seconds) / 60).rounded())
        return minutes < 60 ? "\(minutes) min" : "\(minutes / 60)h \(minutes % 60)m"
    }

    /// Starts counting up with no target. The timer is paused if it was running and
    /// put back exactly as it was when the open session is logged or discarded.
    func startOpenSession() {
        guard !isOpenSession else { return }
        setTimerAside()
        openSessionToast = nil
        openElapsed = 0
        openSessionStart = Date()
        isOpenSession = true
        resumeOpenSession()
    }

    func toggleOpenSession() {
        openSessionRunning ? pauseOpenSession() : resumeOpenSession()
    }

    /// Adds the open session to today's focus time, then restores the timer.
    func logOpenSession() {
        let seconds = openElapsed
        endOpenSession()
        addFocusTime(seconds)
        openSessionToast = OpenSessionToast(message: "Added \(Self.describe(seconds: seconds)) to today", seconds: seconds, logged: true)
    }

    func discardOpenSession() {
        let seconds = openElapsed
        endOpenSession()
        openSessionToast = OpenSessionToast(message: "Discarded \(Self.describe(seconds: seconds))", seconds: seconds, logged: false)
    }

    /// Reopens the session the toast refers to, paused, taking back any time it logged.
    func undoOpenSessionEnd() {
        guard let toast = openSessionToast, !isOpenSession else { return }
        openSessionToast = nil
        if toast.logged { addFocusTime(-toast.seconds) }
        setTimerAside()
        openElapsed = toast.seconds
        isOpenSession = true
    }

    private func setTimerAside() {
        setAside = (timerState, sessionState, timeRemaining)
        if timerState == .running { pause() }
    }

    private func resumeOpenSession() {
        openSessionRunning = true
        openTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.openElapsed += 1 }
    }

    private func pauseOpenSession() {
        openSessionRunning = false
        openTimer?.cancel()
    }

    private func endOpenSession() {
        pauseOpenSession()
        isOpenSession = false
        guard let saved = setAside else { return }
        setAside = nil
        sessionState = saved.session
        timeRemaining = saved.remaining
        if saved.state == .running {
            start()
        } else {
            timerState = saved.state
        }
    }

    private func addFocusTime(_ seconds: Int) {
        checkAndUpdateDailyReset()
        focusTimeToday = max(0, focusTimeToday + seconds)
        weeklyHistory[dateFormatter().string(from: Date())] = focusTimeToday
        saveWeeklyHistory()
    }
}
