import SwiftUI

struct DailyFocusData: Identifiable {
    let id = UUID()
    let date: Date
    let seconds: Int
    let isToday: Bool
}

struct HeatmapDay: Identifiable {
    let id = UUID()
    let date: Date
    let dateString: String
    let seconds: Int
    let isToday: Bool
}

struct StatsView: View {
    @ObservedObject var timerManager: TimerManager
    @Environment(\.paperTheme) private var theme

    private let cellSize: CGFloat = 44
    private var columns: [GridItem] {
        Array(repeating: GridItem(.fixed(cellSize), spacing: 6), count: 7)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                todaySection
                weekSection
                monthSection
            }
            .padding(.horizontal, 28)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.never)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Today

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.system(size: 13))
                    .foregroundStyle(Paper.textMuted)
                Text("Today")
                    .font(theme.display(32))
            }

            HStack(spacing: 0) {
                statColumn(value: Paper.duration(seconds: timerManager.focusTimeToday), label: "Focused")
                statColumn(value: "\(timerManager.sessionsCompletedToday)", label: "Sessions", divided: true)
                statColumn(value: timerManager.streakText, label: "Streak", divided: true)
            }
            .padding(.vertical, 16)
            .overlay(alignment: .top) { Hairline() }
            .overlay(alignment: .bottom) { Hairline() }
        }
    }

    private func statColumn(value: String, label: String, divided: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(theme.display(30))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Paper.textMuted)
        }
        .padding(.leading, divided ? 20 : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .leading) {
            if divided {
                Rectangle().fill(Paper.hairline).frame(width: 1)
            }
        }
    }

    // MARK: - Last 7 Days

    private var weekSection: some View {
        let days = last7DaysData
        let peak = max(days.map(\.seconds).max() ?? 0, 1)
        let total = days.reduce(0) { $0 + $1.seconds }

        return VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Last 7 days") {
                Text("\(Paper.duration(seconds: total)) total")
                    .font(.system(size: 13))
                    .foregroundStyle(Paper.textMuted)
            }

            VStack(spacing: 8) {
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(days) { day in
                        VStack(spacing: 6) {
                            if day.isToday && day.seconds >= 60 {
                                Text(Paper.duration(seconds: day.seconds))
                                    .font(.system(size: 12, weight: .medium))
                                    .fixedSize()
                            }
                            UnevenRoundedRectangle(topLeadingRadius: 5, topTrailingRadius: 5, style: .continuous)
                                .fill(day.isToday ? theme.accent.color : theme.barMuted)
                                .frame(maxWidth: 34)
                                .frame(height: barHeight(day.seconds, peak: peak))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .contentShape(Rectangle())
                        .help("\(day.date.formatted(.dateTime.weekday(.abbreviated))) · \(focusLabel(day.seconds))")
                    }
                }
                .frame(height: 140)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Paper.border).frame(height: 1)
                }

                HStack(spacing: 12) {
                    ForEach(days) { day in
                        Text(day.date.formatted(.dateTime.weekday(.narrow)))
                            .font(.system(size: 12, weight: day.isToday ? .semibold : .regular))
                            .foregroundStyle(day.isToday ? Paper.text : Paper.textMuted)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func barHeight(_ seconds: Int, peak: Int) -> CGFloat {
        guard seconds > 0 else { return 0 }
        return max(CGFloat(seconds) / CGFloat(peak) * 112, 3)
    }

    // MARK: - Last 30 Days

    private var monthSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Last 30 days") {
                HStack(spacing: 4) {
                    Text("Less").padding(.trailing, 2)
                    ForEach(theme.heat.indices, id: \.self) { level in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(theme.heat[level])
                            .frame(width: 10, height: 10)
                    }
                    Text("More").padding(.leading, 2)
                }
                .font(.system(size: 11))
                .foregroundStyle(Paper.textMuted)
            }

            VStack(spacing: 8) {
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { _, day in
                        Text(day)
                            .font(.system(size: 11))
                            .foregroundStyle(Paper.textMuted)
                            .frame(width: cellSize)
                    }
                }

                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(0..<leadingEmptyCells, id: \.self) { _ in
                        Color.clear.frame(height: cellSize)
                    }
                    ForEach(heatmapData) { day in
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(theme.heat[heatLevel(day.seconds)])
                            .frame(height: cellSize)
                            .overlay {
                                if day.isToday {
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .strokeBorder(Paper.text, lineWidth: 1.5)
                                }
                            }
                            .help(tooltipText(for: day))
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func sectionHeader<Trailing: View>(_ title: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(theme.display(21))
            Spacer()
            trailing()
        }
    }

    // MARK: - Data Helpers

    private var last7DaysData: [DailyFocusData] {
        let calendar = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let today = Date()

        return (0..<7).reversed().compactMap { i -> DailyFocusData? in
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { return nil }
            let seconds = timerManager.weeklyHistory[fmt.string(from: date)] ?? 0
            return DailyFocusData(date: date, seconds: seconds, isToday: i == 0)
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
            let seconds = timerManager.weeklyHistory[dateStr] ?? 0
            return HeatmapDay(date: date, dateString: dateStr, seconds: seconds, isToday: calendar.isDateInToday(date))
        }
    }

    private var leadingEmptyCells: Int {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -29, to: Date()) else { return 0 }
        return calendar.component(.weekday, from: startDate) - 1
    }

    /// 0 = none, then under 45m, under 1h 30m, under 2h, and 2h or more.
    private func heatLevel(_ seconds: Int) -> Int {
        let minutes = seconds / 60
        if seconds <= 0     { return 0 }
        else if minutes < 45  { return 1 }
        else if minutes < 90  { return 2 }
        else if minutes < 120 { return 3 }
        else                  { return 4 }
    }

    private func focusLabel(_ seconds: Int) -> String {
        seconds > 0 ? Paper.duration(seconds: seconds) : "No focus"
    }

    private func tooltipText(for day: HeatmapDay) -> String {
        "\(day.date.formatted(.dateTime.month(.abbreviated).day())): \(focusLabel(day.seconds))"
    }
}
