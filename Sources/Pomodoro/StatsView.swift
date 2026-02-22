import SwiftUI
import Charts

struct DailyFocusData: Identifiable {
    let id = UUID()
    let dayName: String
    let minutes: Double
}

struct HeatmapDay: Identifiable {
    let id = UUID()
    let date: Date
    let dateString: String
    let hours: Double
    let isToday: Bool
}

struct StatsView: View {
    @ObservedObject var timerManager: TimerManager
    var onDismiss: () -> Void
    
    private let columns = Array(repeating: GridItem(.fixed(28), spacing: 4), count: 7)
    
    var body: some View {
        VStack(spacing: 30) {
            
            // Header with Back Button
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Text("Dashboard")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            // Top Stats Row: Focus Time, Sessions, Streak
            HStack(spacing: 25) {
                VStack(spacing: 2) {
                    Text(formattedFocusTime)
                        .font(.system(size: 50, weight: .thin, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Today's Focus")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 2) {
                    Text("\(timerManager.sessionsCompletedToday)")
                        .font(.system(size: 50, weight: .thin, design: .rounded))
                    Text("Sessions")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        Text("🔥")
                            .font(.system(size: 50))
                        Text("\(timerManager.currentStreak)")
                            .font(.system(size: 50, weight: .thin, design: .rounded))
                    }
                    Text("Day Streak")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            
            // Weekly Bar Chart
            VStack(alignment: .leading, spacing: 4) {
                Text("Last 7 Days (Minutes)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                
                Chart(last7DaysData) { dataPoint in
                    BarMark(
                        x: .value("Day", dataPoint.dayName),
                        y: .value("Minutes", dataPoint.minutes)
                    )
                    .foregroundStyle(Color.primary.opacity(0.6))
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(stroke: StrokeStyle(lineWidth: 0))
                }
                .chartYAxis {
                    AxisMarks(stroke: StrokeStyle(lineWidth: 0))
                }
                .frame(height: 100)
            }
            
            // Heatmap Section
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Last 30 Days")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Legend
                    HStack(spacing: 2) {
                        Text("Less")
                            .font(.system(size: 8, design: .rounded))
                            .foregroundColor(.secondary)
                        ForEach(0..<4) { level in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(heatmapColor(for: Double(level)))
                                .frame(width: 10, height: 10)
                        }
                        Text("More")
                            .font(.system(size: 8, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Day-of-week headers — use same grid layout so they align perfectly
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { _, day in
                        Text(day)
                            .font(.system(size: 8, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .frame(width: 28, height: 12)
                    }
                }
                
                // Heatmap Grid
                LazyVGrid(columns: columns, spacing: 4) {
                    // Add empty cells for alignment to start of week
                    ForEach(0..<leadingEmptyCells, id: \.self) { _ in
                        Color.clear
                            .frame(width: 28, height: 28)
                    }
                    
                    ForEach(heatmapData) { day in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(heatmapColor(for: day.hours))
                            .frame(width: 28, height: 28)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(day.isToday ? Color.primary.opacity(0.5) : Color.clear, lineWidth: 1.5)
                            )
                            .help(tooltipText(for: day))
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 16)
        .frame(width: 420, height: 560)
        .background(
            VisualEffectView(material: .windowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()
        )
    }
    
    // MARK: - Weekly Chart Data
    
    private var last7DaysData: [DailyFocusData] {
        var data: [DailyFocusData] = []
        let calendar = Calendar.current
        
        let formatterDate = DateFormatter()
        formatterDate.dateFormat = "yyyy-MM-dd"
        
        let formatterDayName = DateFormatter()
        formatterDayName.dateFormat = "EEE"
        
        let today = Date()
        
        for i in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let dateString = formatterDate.string(from: date)
                let dayName = formatterDayName.string(from: date)
                
                let seconds = timerManager.weeklyHistory[dateString] ?? 0
                let minutes = Double(seconds) / 60.0
                let cleanMinutes = round(minutes * 10) / 10
                
                data.append(DailyFocusData(dayName: dayName, minutes: cleanMinutes))
            }
        }
        return data
    }
    
    // MARK: - Heatmap Helpers
    
    private var heatmapData: [HeatmapDay] {
        var data: [HeatmapDay] = []
        let calendar = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let today = Date()
        
        for i in (0..<30).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let dateStr = fmt.string(from: date)
                let seconds = timerManager.weeklyHistory[dateStr] ?? 0
                let hours = Double(seconds) / 3600.0
                let isToday = calendar.isDateInToday(date)
                data.append(HeatmapDay(date: date, dateString: dateStr, hours: hours, isToday: isToday))
            }
        }
        return data
    }
    
    private var leadingEmptyCells: Int {
        let calendar = Calendar.current
        let today = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -29, to: today) else { return 0 }
        let weekday = calendar.component(.weekday, from: startDate)
        return weekday - 1
    }
    
    private func heatmapColor(for hours: Double) -> Color {
        if hours <= 0 {
            return Color.primary.opacity(0.06)
        } else if hours < 0.5 {
            return Color.green.opacity(0.3)
        } else if hours < 1.5 {
            return Color.green.opacity(0.55)
        } else {
            return Color.green.opacity(0.85)
        }
    }
    
    private func tooltipText(for day: HeatmapDay) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        let dateLabel = fmt.string(from: day.date)
        if day.hours > 0 {
            let h = Int(day.hours)
            let m = Int((day.hours - Double(h)) * 60)
            if h > 0 {
                return "\(dateLabel): \(h)h \(m)m"
            } else {
                return "\(dateLabel): \(m)m"
            }
        }
        return "\(dateLabel): No focus"
    }
    
    // Formatting helper for Today's string
    private var formattedFocusTime: String {
        let totalSeconds = timerManager.focusTimeToday
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
