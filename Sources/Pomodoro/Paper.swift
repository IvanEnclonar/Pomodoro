import SwiftUI
import AppKit

// MARK: - Palette

/// Warm "Paper" palette: ivory and slate in light mode, warm charcoal in dark mode.
enum Paper {
    static let background      = Color(light: 0xFAF9F5, dark: 0x1F1E1D)
    static let surface         = Color(light: 0xFFFFFF, dark: 0x262624)
    static let text            = Color(light: 0x141413, dark: 0xFAF9F5)
    static let textSecondary   = Color(light: 0x3D3D3A, dark: 0xD1CFC5)
    static let textMuted       = Color(light: 0x5E5D59, dark: 0x9C9A92)
    static let track           = Color(light: 0xE8E6DC, dark: 0x30302E)
    static let hairline        = Color(light: 0x1F1E1D, lightAlpha: 0.12, dark: 0xFAF9F5, darkAlpha: 0.10)
    static let border          = Color(light: 0x1F1E1D, lightAlpha: 0.15, dark: 0xFAF9F5, darkAlpha: 0.14)
    static let controlFill     = Color(light: 0x73726C, lightAlpha: 0.12, dark: 0x30302E)
    static let controlSelected = Color(light: 0xFFFFFF, dark: 0x4D4C48)
    static let primary         = Color(light: 0x141413, dark: 0xFAF9F5)
    static let onPrimary       = Color(light: 0xFAF9F5, dark: 0x141413)

    static let clay  = Color(light: 0xD97757, dark: 0xD97757)
    static let olive = Color(light: 0x788C5D, dark: 0x8FA672)
    static let sky   = Color(light: 0x6A9BCC, dark: 0x7FAAD6)

    // MARK: Formatting

    /// "1h 40m", or "25m" under an hour.
    static func duration(seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}

extension Color {
    /// A color that resolves differently in light and dark appearances.
    init(light: UInt32, lightAlpha: Double = 1, dark: UInt32, darkAlpha: Double = 1) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor(hex: isDark ? dark : light, alpha: isDark ? darkAlpha : lightAlpha)
        })
    }
}

private extension NSColor {
    convenience init(hex: UInt32, alpha: Double) {
        self.init(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }
}

// MARK: - Theme

/// Accent color for focus sessions, charts and switches. Breaks keep olive and sky.
enum PaperAccent: String, CaseIterable, Identifiable {
    case clay, fig, kraft, aqua, violet, graphite

    var id: Self { self }

    var title: String { rawValue.capitalized }

    private var hex: (light: UInt32, dark: UInt32) {
        switch self {
        case .clay:     return (0xD97757, 0xD97757)
        case .fig:      return (0xC46686, 0xD4839F)
        case .kraft:    return (0xC9A82D, 0xD6B84A)
        case .aqua:     return (0x2E9191, 0x4BB0AE)
        case .violet:   return (0x6B4D9E, 0x9A80CC)
        case .graphite: return (0x3D3D3A, 0xD1CFC5)
        }
    }

    var color: Color { Color(light: hex.light, dark: hex.dark) }

    /// The accent mixed into the window background: 0 is the background, 1 the accent.
    func tint(_ fraction: Double) -> Color {
        let hex = hex
        return Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            let base = NSColor(hex: isDark ? 0x1F1E1D : 0xFAF9F5, alpha: 1)
            let accent = NSColor(hex: isDark ? hex.dark : hex.light, alpha: 1)
            return base.blended(withFraction: fraction, of: accent) ?? accent
        })
    }

    /// Past full strength: darker in light mode, lighter in dark mode.
    var deep: Color {
        let hex = hex
        return Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            let accent = NSColor(hex: isDark ? hex.dark : hex.light, alpha: 1)
            return accent.blended(withFraction: isDark ? 0.2 : 0.18, of: isDark ? .white : .black) ?? accent
        })
    }
}

/// Typeface for the timer, headings and numbers. All are built into macOS.
enum PaperFont: String, CaseIterable, Identifiable {
    case serif, sans, rounded, mono

    var id: Self { self }

    var title: String { rawValue.capitalized }

    var design: Font.Design {
        switch self {
        case .serif:   return .serif
        case .sans:    return .default
        case .rounded: return .rounded
        case .mono:    return .monospaced
        }
    }
}

/// The appearance choices from Settings, passed down the environment.
struct PaperTheme {
    static let accentKey = "accentColor"
    static let fontKey = "displayFont"

    var accent: PaperAccent = .clay
    var font: PaperFont = .serif

    func accent(for session: SessionState) -> Color {
        switch session {
        case .focus:      return accent.color
        case .shortBreak: return Paper.olive
        case .longBreak:  return Paper.sky
        }
    }

    func display(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: font.design)
    }

    /// Heatmap ramp, from no focus to the most focus.
    var heat: [Color] {
        [Color(light: 0xECEAE2, dark: 0x30302E), accent.tint(0.25), accent.tint(0.5), accent.tint(0.85), accent.deep]
    }

    /// Chart bars for days other than today.
    var barMuted: Color { accent.tint(0.42) }
}

private struct PaperThemeKey: EnvironmentKey {
    static let defaultValue = PaperTheme()
}

extension EnvironmentValues {
    var paperTheme: PaperTheme {
        get { self[PaperThemeKey.self] }
        set { self[PaperThemeKey.self] = newValue }
    }
}

/// Reads the appearance settings and hands them to the views below.
private struct PaperThemeReader: ViewModifier {
    @AppStorage(PaperTheme.accentKey) private var accent: PaperAccent = .clay
    @AppStorage(PaperTheme.fontKey) private var font: PaperFont = .serif

    func body(content: Content) -> some View {
        content
            .environment(\.paperTheme, PaperTheme(accent: accent, font: font))
            .tint(accent.color)
    }
}

extension View {
    /// Applies the accent and display font chosen in Settings.
    func paperTheme() -> some View {
        modifier(PaperThemeReader())
    }
}

// MARK: - Session copy

extension TimerManager {
    var sessionTitle: String {
        switch sessionState {
        case .focus:      return "Focus"
        case .shortBreak: return "Short break"
        case .longBreak:  return "Long break"
        }
    }

    var sessionDetail: String {
        let inCycle = sessionCount % 4
        switch sessionState {
        case .focus:      return "Session \(inCycle + 1) of 4"
        case .shortBreak: return "After session \(inCycle)"
        case .longBreak:  return "Cycle complete"
        }
    }

    var upNext: String {
        switch sessionState {
        case .focus:
            return (sessionCount + 1) % 4 == 0
                ? "Long break · \(longBreakDurationMinutes) min"
                : "Short break · \(shortBreakDurationMinutes) min"
        case .shortBreak, .longBreak:
            return "Focus · \(focusDurationMinutes) min"
        }
    }

    var primaryActionTitle: String {
        switch timerState {
        case .running: return "Pause"
        case .paused:  return "Resume"
        case .stopped: return "Start"
        }
    }

    var primaryActionIcon: String {
        timerState == .running ? "pause.fill" : "play.fill"
    }

    var streakText: String {
        currentStreak == 1 ? "1 day" : "\(currentStreak) days"
    }

    /// "4 sessions · 9-day streak", leaving out a streak of zero.
    var todaySummary: String {
        let sessions = sessionsCompletedToday == 1 ? "1 session" : "\(sessionsCompletedToday) sessions"
        return currentStreak > 0 ? "\(sessions) · \(currentStreak)-day streak" : sessions
    }

    func toggle() {
        timerState == .running ? pause() : start()
    }

    /// Count-up clock for an open session: "12:47", or "1:02:05" past an hour.
    var openClockString: String {
        let h = openElapsed / 3600
        let m = (openElapsed % 3600) / 60
        let s = openElapsed % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
    }

    var openSessionStatus: String {
        guard openSessionRunning else { return "Paused" }
        guard let start = openSessionStart else { return "Running" }
        return "Started at \(start.formatted(date: .omitted, time: .shortened))"
    }

    /// What the menu bar shows: the open session while one is going, else the timer.
    var menuBarTimeString: String {
        isOpenSession ? openClockString : timeString
    }
}

// MARK: - Components

/// Accent dot, session name and position in the cycle.
struct SessionLabel: View {
    @ObservedObject var timerManager: TimerManager
    var size: CGFloat = 14
    @Environment(\.paperTheme) private var theme

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(theme.accent(for: timerManager.sessionState))
                .frame(width: 8, height: 8)
            Text(timerManager.sessionTitle)
                .fontWeight(.medium)
                .foregroundStyle(Paper.textSecondary)
            Text("·")
                .foregroundStyle(Paper.textMuted)
            Text(timerManager.sessionDetail)
                .foregroundStyle(Paper.textMuted)
        }
        .font(.system(size: size))
    }
}

/// Hollow accent dot, "Open session", "No time limit".
struct OpenSessionLabel: View {
    var size: CGFloat = 14
    @Environment(\.paperTheme) private var theme

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .strokeBorder(theme.accent.color, lineWidth: 1.5)
                .frame(width: 8, height: 8)
            Text("Open session")
                .fontWeight(.medium)
                .foregroundStyle(Paper.textSecondary)
            Text("·")
                .foregroundStyle(Paper.textMuted)
            Text("No time limit")
                .foregroundStyle(Paper.textMuted)
        }
        .font(.system(size: size))
    }
}

/// "Added 12 min to today · Undo"
struct OpenSessionToastView: View {
    let toast: OpenSessionToast
    let undo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(toast.message)
            Button("Undo", action: undo)
                .buttonStyle(.plain)
                .fontWeight(.medium)
                .padding(.horizontal, 10)
                .frame(height: 28)
                .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Paper.onPrimary.opacity(0.14)))
                .pointerStyle(.link)
        }
        .font(.system(size: 13))
        .foregroundStyle(Paper.onPrimary)
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Paper.primary))
        .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
        .accessibilityElement(children: .combine)
    }
}

/// Two-point progress rule.
struct ProgressLine: View {
    var progress: Double
    var color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Paper.track)
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 2)
        .animation(.easeOut(duration: 0.3), value: progress)
    }
}

/// Pill-shaped segmented control, as used for the Timer / Dashboard switcher.
struct PaperSegmented<Option: Hashable, Label: View>: View {
    @Binding var selection: Option
    let options: [Option]
    var segmentPadding: CGFloat = 14
    /// Bind ⌘1, ⌘2, … to the options in order.
    var commandShortcuts = false
    @ViewBuilder let label: (Option) -> Label
    @Namespace private var pill

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(options.enumerated()), id: \.element) { index, option in
                let isSelected = selection == option
                let button = Button {
                    withAnimation(.snappy(duration: 0.25)) { selection = option }
                } label: {
                    label(option)
                        .foregroundStyle(isSelected ? Paper.text : Paper.textMuted)
                        .padding(.horizontal, segmentPadding)
                        .frame(height: 26)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(Paper.controlSelected)
                                    .shadow(color: .black.opacity(0.10), radius: 1, y: 1)
                                    .matchedGeometryEffect(id: "pill", in: pill)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])

                if commandShortcuts && index < 9 {
                    button.keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                } else {
                    button
                }
            }
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Paper.controlFill))
    }
}

struct Hairline: View {
    var body: some View {
        Rectangle().fill(Paper.hairline).frame(height: 1)
    }
}

/// Slate (primary) or white-with-border (secondary) button.
struct PaperButtonStyle: ButtonStyle {
    enum Prominence { case primary, secondary }

    var prominence: Prominence = .primary
    var height: CGFloat = 44
    var fontSize: CGFloat = 15
    var cornerRadius: CGFloat = 10

    func makeBody(configuration: Configuration) -> some View {
        PaperButtonBody(configuration: configuration, style: self)
    }
}

private struct PaperButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let style: PaperButtonStyle
    @State private var hovering = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
        let isPrimary = style.prominence == .primary
        configuration.label
            .font(.system(size: style.fontSize, weight: .medium))
            .padding(.horizontal, 18)
            .frame(height: style.height)
            .foregroundStyle(isPrimary ? Paper.onPrimary : Paper.textSecondary)
            .background(shape.fill(isPrimary ? Paper.primary : Paper.surface))
            .overlay(shape.strokeBorder(isPrimary ? Color.clear : Paper.border, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.7 : (hovering ? 0.88 : 1))
            .contentShape(shape)
            .onHover { hovering = $0 }
            .pointerStyle(.link)
            .animation(.easeOut(duration: 0.15), value: hovering)
    }
}
