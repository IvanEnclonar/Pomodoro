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

    private let columns = Array(repeating: GridItem(.fixed(28), spacing: 4), count: 7)
    @State private var hoveredDay: DailyFocusData? = nil
    @State private var tooltipPosition: CGPoint = .zero

    var body: some View {
        ScrollView {
            if #available(macOS 26, *) {
                GlassEffectContainer(spacing: 20) {
                    cards
                }
            } else {
                cards
            }
        }
        .scrollIndicators(.never)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var cards: some View {
        VStack(spacing: 16) {
            topStatsRow
            weeklyChartSection
            heatmapSection
        }
        .padding(20)
    }

    // MARK: - Top Stats Row

    private var topStatsRow: some View {
        HStack(spacing: 0) {
            statColumn(value: formattedFocusTime, label: "Today's Focus")
            Divider().frame(height: 50)
            statColumn(value: "\(timerManager.sessionsCompletedToday)", label: "Sessions")
            Divider().frame(height: 50)
            statColumn(value: "🔥 \(timerManager.currentStreak)", label: "Day Streak")
        }
        .padding(16)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(16)
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 36, weight: .thin, design: .rounded))
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Weekly Chart

    private var weeklyChartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last 7 Days")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Chart(last7DaysData) { dataPoint in
                BarMark(
                    x: .value("Day", dataPoint.dayName),
                    y: .value("Minutes", dataPoint.minutes)
                )
                .foregroundStyle(
                    hoveredDay?.id == dataPoint.id
                        ? Color.accentColor.opacity(1.0)
                        : Color.accentColor.opacity(0.7)
                )
                .cornerRadius(5)
            }
            .chartXAxis {
                AxisMarks(stroke: StrokeStyle(lineWidth: 0))
            }
            .chartYAxis {
                AxisMarks(stroke: StrokeStyle(lineWidth: 0))
            }
            .frame(height: 110)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    let data = last7DaysData
                    Color.clear
                        .onContinuousHover { phase in
                            switch phase {
                            case .active(let loc):
                                tooltipPosition = loc
                                if let anchor = proxy.plotFrame {
                                    let plotFrame = geo[anchor]
                                    let plotX = loc.x - plotFrame.minX
                                    let index = Int(plotX / plotFrame.width * CGFloat(data.count))
                                    let clamped = min(max(index, 0), data.count - 1)
                                    hoveredDay = plotFrame.contains(loc) ? data[clamped] : nil
                                }
                            case .ended:
                                hoveredDay = nil
                            }
                        }
                }
            }
            .overlay(alignment: .topLeading) {
                if let day = hoveredDay {
                    Text(day.minutes > 0 ? "\(Int(day.minutes))m" : "No data")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                        .offset(x: tooltipPosition.x + 10, y: tooltipPosition.y - 28)
                        .allowsHitTesting(false)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        .animation(.easeOut(duration: 0.1), value: hoveredDay?.id)
                }
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }

    // MARK: - Heatmap

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Last 30 Days")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 3) {
                    Text("Less")
                        .font(.system(size: 8, design: .rounded))
                        .foregroundStyle(.secondary)
                    ForEach(0..<4) { level in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(heatmapColor(for: Double(level)))
                            .frame(width: 10, height: 10)
                    }
                    Text("More")
                        .font(.system(size: 8, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            // Day-of-week headers
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { _, day in
                    Text(day)
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 12)
                }
            }

            // Heatmap Grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<leadingEmptyCells, id: \.self) { _ in
                    Color.clear.frame(width: 28, height: 28)
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
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }

    // MARK: - Data Helpers

    private var last7DaysData: [DailyFocusData] {
        let calendar = Calendar.current
        let fmtDate = DateFormatter()
        fmtDate.dateFormat = "yyyy-MM-dd"
        let fmtDay = DateFormatter()
        fmtDay.dateFormat = "EEE"
        let today = Date()

        return (0..<7).reversed().compactMap { i -> DailyFocusData? in
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { return nil }
            let seconds = timerManager.weeklyHistory[fmtDate.string(from: date)] ?? 0
            let minutes = round(Double(seconds) / 60.0 * 10) / 10
            return DailyFocusData(dayName: fmtDay.string(from: date), minutes: minutes)
        }
    }

    private var heatmapData: [HeatmapDay] {
        let calendar = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let today = Date()

        return (0..<30).reversed().compactMap { i -> HeatmapDay? in
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { return nil }
            let dateStr = fmt.string(from: date)
            let hours = Double(timerManager.weeklyHistory[dateStr] ?? 0) / 3600.0
            return HeatmapDay(date: date, dateString: dateStr, hours: hours, isToday: calendar.isDateInToday(date))
        }
    }

    private var leadingEmptyCells: Int {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -29, to: Date()) else { return 0 }
        return calendar.component(.weekday, from: startDate) - 1
    }

    private func heatmapColor(for hours: Double) -> Color {
        if hours <= 0        { return Color.primary.opacity(0.06) }
        else if hours < 0.5  { return Color.green.opacity(0.3) }
        else if hours < 1.5  { return Color.green.opacity(0.55) }
        else                  { return Color.green.opacity(0.85) }
    }

    private func tooltipText(for day: HeatmapDay) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        let label = fmt.string(from: day.date)
        guard day.hours > 0 else { return "\(label): No focus" }
        let h = Int(day.hours)
        let m = Int((day.hours - Double(h)) * 60)
        return h > 0 ? "\(label): \(h)h \(m)m" : "\(label): \(m)m"
    }

    private var formattedFocusTime: String {
        let total = timerManager.focusTimeToday
        let h = total / 3600
        let m = (total % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}
