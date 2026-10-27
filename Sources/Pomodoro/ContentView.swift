import SwiftUI

enum MainTab: String, CaseIterable, Identifiable {
    case timer, dashboard

    var id: Self { self }

    var title: String {
        switch self {
        case .timer:     return "Timer"
        case .dashboard: return "Dashboard"
        }
    }
}

struct ContentView: View {
    @ObservedObject var timerManager: TimerManager
    @State private var tab: MainTab = .timer

    var body: some View {
        Group {
            switch tab {
            case .timer:     TimerView(timerManager: timerManager)
            case .dashboard: StatsView(timerManager: timerManager)
            }
        }
        .frame(minWidth: 440, idealWidth: 460, minHeight: 560, idealHeight: 600)
        .foregroundStyle(Paper.text)
        .modifier(MainToolbar(tab: $tab))
        .toolbar(removing: .title)
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .containerBackground(Paper.background, for: .window)
    }
}

// MARK: - Toolbar

private struct MainToolbar: ViewModifier {
    @Binding var tab: MainTab

    private var tabSwitcher: some View {
        PaperSegmented(selection: $tab, options: MainTab.allCases, commandShortcuts: true) { tab in
            Text(tab.title)
                .font(.system(size: 13, weight: .medium))
        }
    }

    func body(content: Content) -> some View {
        // macOS 26 puts toolbar items on glass; Paper keeps them flat.
        if #available(macOS 26, *) {
            content.toolbar {
                ToolbarItem(placement: .principal) { tabSwitcher }
                    .sharedBackgroundVisibility(.hidden)
                ToolbarItem(placement: .primaryAction) { SettingsButton() }
                    .sharedBackgroundVisibility(.hidden)
            }
        } else {
            content.toolbar {
                ToolbarItem(placement: .principal) { tabSwitcher }
                ToolbarItem(placement: .primaryAction) { SettingsButton() }
            }
        }
    }
}

private struct SettingsButton: View {
    var body: some View {
        SettingsLink {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Paper.textMuted)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Settings")
        .accessibilityLabel("Settings")
    }
}

// MARK: - Timer

struct TimerView: View {
    @ObservedObject var timerManager: TimerManager
    @Environment(\.paperTheme) private var theme

    private var accent: Color { theme.accent(for: timerManager.sessionState) }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 16)

            Group {
                if timerManager.isOpenSession {
                    openSession
                } else {
                    pomodoro
                }
            }
            .padding(.horizontal, 40)

            Spacer(minLength: 16)

            todayFooter
        }
        .overlay(alignment: .bottom) {
            if let toast = timerManager.openSessionToast {
                OpenSessionToastView(toast: toast, undo: timerManager.undoOpenSessionEnd)
                    .padding(.bottom, 62)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task(id: toast.id) {
                        try? await Task.sleep(for: .seconds(6))
                        if timerManager.openSessionToast?.id == toast.id {
                            timerManager.openSessionToast = nil
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: timerManager.sessionState)
        .animation(.easeInOut(duration: 0.25), value: timerManager.isOpenSession)
        .animation(.snappy, value: timerManager.openSessionToast)
    }

    // MARK: Pomodoro

    private var pomodoro: some View {
        VStack(spacing: 32) {
            SessionLabel(timerManager: timerManager)

            VStack(spacing: 22) {
                Text(timerManager.timeString)
                    .font(theme.display(124, weight: .light))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.snappy, value: timerManager.timeRemaining)

                ProgressLine(progress: timerManager.progress, color: accent)
                    .frame(width: 280)
            }

            VStack(spacing: 12) {
                controls

                Button(action: timerManager.startOpenSession) {
                    HStack(spacing: 7) {
                        Image(systemName: "stopwatch")
                            .font(.system(size: 13, weight: .medium))
                        Text("Track without a timer")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Paper.textSecondary)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .pointerStyle(.link)
                .help("Count up with no target, then log the time when you're done")
            }

            Text("Up next: \(timerManager.upNext)")
                .font(.system(size: 13))
                .foregroundStyle(Paper.textMuted)
        }
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Button(action: timerManager.toggle) {
                HStack(spacing: 8) {
                    Image(systemName: timerManager.primaryActionIcon)
                        .font(.system(size: 12, weight: .semibold))
                    Text(timerManager.primaryActionTitle)
                }
                .frame(minWidth: 92)
            }
            .buttonStyle(PaperButtonStyle(prominence: .primary))
            .keyboardShortcut(.space, modifiers: [])

            Button(action: timerManager.skip) {
                HStack(spacing: 8) {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Skip")
                }
            }
            .buttonStyle(PaperButtonStyle(prominence: .secondary))
        }
    }

    // MARK: Open Session

    private var openSession: some View {
        VStack(spacing: 32) {
            OpenSessionLabel()

            VStack(spacing: 18) {
                Text(timerManager.openClockString)
                    .font(theme.display(124, weight: .light))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: timerManager.openElapsed)

                Text(timerManager.openSessionStatus)
                    .font(.system(size: 13))
                    .foregroundStyle(Paper.textMuted)
            }

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Button(action: timerManager.logOpenSession) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Log \(TimerManager.describe(seconds: timerManager.openElapsed))")
                        }
                        .frame(minWidth: 112)
                    }
                    .buttonStyle(PaperButtonStyle(prominence: .primary))
                    .keyboardShortcut(.return, modifiers: [])
                    .disabled(timerManager.openElapsed == 0)

                    Button(action: timerManager.toggleOpenSession) {
                        HStack(spacing: 8) {
                            Image(systemName: timerManager.openSessionRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 12, weight: .semibold))
                            Text(timerManager.openSessionRunning ? "Pause" : "Resume")
                        }
                    }
                    .buttonStyle(PaperButtonStyle(prominence: .secondary))
                    .keyboardShortcut(.space, modifiers: [])
                }

                Button("Discard", action: timerManager.discardOpenSession)
                    .buttonStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundStyle(Paper.textMuted)
                    .frame(height: 32)
                    .pointerStyle(.link)
            }

            Text("Your timer picks up where it was when you're done")
                .font(.system(size: 13))
                .foregroundStyle(Paper.textMuted)
        }
    }

    private var todayFooter: some View {
        VStack(spacing: 0) {
            Hairline()
            HStack {
                Text("Today")
                Spacer()
                Text("\(Text(Paper.duration(seconds: timerManager.focusTimeToday)).foregroundStyle(Paper.text).fontWeight(.medium)) focused · \(timerManager.todaySummary)")
            }
            .font(.system(size: 13))
            .foregroundStyle(Paper.textMuted)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
    }
}
