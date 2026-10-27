import SwiftUI
import AppKit

/// Menu bar item: the cycle mark and the countdown.
struct MenuBarLabel: View {
    @ObservedObject var timerManager: TimerManager

    var body: some View {
        HStack(spacing: 4) {
            Image(nsImage: Self.cycle(
                completed: timerManager.sessionState == .longBreak ? 4 : timerManager.sessionCount % 4,
                inFocus: timerManager.sessionState == .focus,
                progress: timerManager.progress
            ))
            Text(timerManager.menuBarTimeString)
                .monospacedDigit()
        }
    }

    /// The app's cycle logo, live: one arc per session in the round. Finished sessions are solid,
    /// the focus session in progress fills as it runs, and the rest stay faint.
    /// The menu bar only draws images and text, so it is rendered to a template image.
    @MainActor
    private static func cycle(completed: Int, inFocus: Bool, progress: Double) -> NSImage {
        let fraction = (min(max(progress, 0), 1) * 24).rounded() / 24
        let gap = 15.0 / 360
        let stroke = StrokeStyle(lineWidth: 2, lineCap: .round)
        let glyph = ZStack {
            ForEach(0..<4, id: \.self) { i in
                let start = Double(i) * 0.25 + gap
                let end = Double(i + 1) * 0.25 - gap
                let filled = i < completed ? end : (inFocus && i == completed ? start + (end - start) * fraction : start)
                Circle()
                    .trim(from: start, to: end)
                    .stroke(Color.black.opacity(0.35), style: stroke)
                if filled > start {
                    Circle()
                        .trim(from: start, to: filled)
                        .stroke(Color.black, style: stroke)
                }
            }
        }
        .rotationEffect(.degrees(-90))
        .frame(width: 12, height: 12)
        .padding(1.5)

        let renderer = ImageRenderer(content: glyph)
        renderer.scale = 2
        let image = renderer.nsImage ?? NSImage()
        image.isTemplate = true
        return image
    }
}

/// Popover shown from the menu bar item.
struct MenuBarPopover: View {
    @ObservedObject var timerManager: TimerManager
    @Environment(\.openSettings) private var openSettings
    @Environment(\.paperTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                if timerManager.isOpenSession {
                    openSession
                } else {
                    pomodoro
                }
            }
            .padding(16)

            Hairline()

            HStack {
                Text("Today")
                Spacer()
                Text("\(Text(Paper.duration(seconds: timerManager.focusTimeToday)).foregroundStyle(Paper.text).fontWeight(.medium)) · \(timerManager.todaySummary)")
            }
            .font(.system(size: 12))
            .foregroundStyle(Paper.textMuted)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Hairline()

            VStack(spacing: 0) {
                Button("Open Pomodoro") {
                    WindowDelegate.shared.showWindow()
                }
                .buttonStyle(MenuRowStyle(shortcut: "⌘O"))
                .keyboardShortcut("o")

                Button("Settings…") {
                    NSApp.activate(ignoringOtherApps: true)
                    openSettings()
                }
                .buttonStyle(MenuRowStyle(shortcut: "⌘,"))
                .keyboardShortcut(",")

                Button("Quit Pomodoro") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(MenuRowStyle(shortcut: "⌘Q"))
                .keyboardShortcut("q")
            }
            .padding(6)
        }
        .frame(width: 304)
        .foregroundStyle(Paper.text)
        .background(Paper.background)
    }
}

extension MenuBarPopover {
    private var pomodoro: some View {
        VStack(alignment: .leading, spacing: 0) {
            SessionLabel(timerManager: timerManager, size: 13)

            Text(timerManager.timeString)
                .font(theme.display(64, weight: .light))
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
                .animation(.snappy, value: timerManager.timeRemaining)
                .padding(.top, 12)
                .padding(.bottom, 14)

            ProgressLine(progress: timerManager.progress, color: theme.accent(for: timerManager.sessionState))

            HStack(spacing: 8) {
                Button(action: timerManager.toggle) {
                    HStack(spacing: 6) {
                        Image(systemName: timerManager.primaryActionIcon)
                            .font(.system(size: 10, weight: .semibold))
                        Text(timerManager.primaryActionTitle)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PaperButtonStyle(prominence: .primary, height: 34, fontSize: 13, cornerRadius: 8))
                .keyboardShortcut("s")

                Button(action: timerManager.skip) {
                    HStack(spacing: 6) {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Skip")
                    }
                }
                .buttonStyle(PaperButtonStyle(prominence: .secondary, height: 34, fontSize: 13, cornerRadius: 8))
                .keyboardShortcut("k")
            }
            .padding(.top, 16)

            Button(action: timerManager.startOpenSession) {
                HStack(spacing: 6) {
                    Image(systemName: "stopwatch")
                    Text("Track without a timer")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Paper.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 26)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
    }

    private var openSession: some View {
        VStack(alignment: .leading, spacing: 0) {
            OpenSessionLabel(size: 13)

            Text(timerManager.openClockString)
                .font(theme.display(64, weight: .light))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.snappy, value: timerManager.openElapsed)
                .padding(.top, 12)
                .padding(.bottom, 6)

            Text(timerManager.openSessionStatus)
                .font(.system(size: 12))
                .foregroundStyle(Paper.textMuted)

            HStack(spacing: 8) {
                Button(action: timerManager.logOpenSession) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Log \(TimerManager.describe(seconds: timerManager.openElapsed))")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PaperButtonStyle(prominence: .primary, height: 34, fontSize: 13, cornerRadius: 8))
                .disabled(timerManager.openElapsed == 0)

                Button(action: timerManager.toggleOpenSession) {
                    Image(systemName: timerManager.openSessionRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(PaperButtonStyle(prominence: .secondary, height: 34, fontSize: 13, cornerRadius: 8))
                .accessibilityLabel(timerManager.openSessionRunning ? "Pause" : "Resume")

                Button(action: timerManager.discardOpenSession) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(PaperButtonStyle(prominence: .secondary, height: 34, fontSize: 13, cornerRadius: 8))
                .help("Discard")
                .accessibilityLabel("Discard")
            }
            .padding(.top, 16)
        }
    }
}

/// Full-width menu row with a shortcut hint and a hover highlight.
private struct MenuRowStyle: ButtonStyle {
    let shortcut: String

    func makeBody(configuration: Configuration) -> some View {
        MenuRowBody(configuration: configuration, shortcut: shortcut)
    }
}

private struct MenuRowBody: View {
    let configuration: ButtonStyleConfiguration
    let shortcut: String
    @State private var hovering = false

    var body: some View {
        HStack {
            configuration.label
            Spacer()
            Text(shortcut)
                .font(.system(size: 12))
                .foregroundStyle(Paper.textMuted)
        }
        .font(.system(size: 13))
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(hovering || configuration.isPressed ? Paper.controlFill : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
    }
}
