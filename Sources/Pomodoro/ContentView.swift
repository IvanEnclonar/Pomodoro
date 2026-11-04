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

    private let ringSize: CGFloat = 300
    private let ringLine: CGFloat = 4

    var body: some View {
        Group {
            if timerManager.isOpenSession {
                openSession
            } else {
                pomodoro
            }
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            if let toast = timerManager.openSessionToast {
                OpenSessionToastView(toast: toast, undo: timerManager.undoOpenSessionEnd)
                    .padding(.bottom, 20)
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

    private func clock(_ text: String) -> some View {
        Text(text)
            .font(theme.display(84, weight: .light))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: ringSize - 70)
    }

    // MARK: Pomodoro

    private var pomodoro: some View {
        VStack(spacing: 32) {
            ZStack {
                CycleArcs(
                    completed: timerManager.sessionsDoneInCycle,
                    inFocus: timerManager.sessionState == .focus,
                    progress: timerManager.progress,
                    lineWidth: ringLine,
                    gap: 5.0 / 360,
                    track: Paper.track,
                    fill: theme.accent.color
                )
                .padding(ringLine / 2)
                .animation(.easeOut(duration: 0.3), value: timerManager.progress)
                // The arcs already show where you are in the round, so the session is
                // only spelled out for VoiceOver.
                .accessibilityElement()
                .accessibilityLabel("\(timerManager.sessionTitle), \(timerManager.sessionDetail)")

                clock(timerManager.timeString)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.snappy, value: timerManager.timeRemaining)

                // A break looks the same as focus on the ring, so it keeps its name. It is
                // offset from the centre rather than stacked, so the clock never moves.
                if timerManager.sessionState != .focus {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(theme.accent(for: timerManager.sessionState))
                            .frame(width: 8, height: 8)
                        Text(timerManager.sessionTitle)
                            .fontWeight(.medium)
                            .foregroundStyle(Paper.textSecondary)
                    }
                    .font(.system(size: 13))
                    .offset(y: -60)
                    .transition(.opacity)
                }
            }
            .frame(width: ringSize, height: ringSize)

            HStack(spacing: 16) {
                iconButton("stopwatch", "Track without a timer", action: timerManager.startOpenSession)

                Button(action: timerManager.toggle) {
                    Image(systemName: timerManager.primaryActionIcon)
                        // The play triangle looks off-centre in a circle without a nudge.
                        .offset(x: timerManager.timerState == .running ? 0 : 1.5)
                }
                .buttonStyle(.icon(.primary, size: 56, iconSize: 20))
                .keyboardShortcut(.space, modifiers: [])
                .help(timerManager.primaryActionTitle)
                .accessibilityLabel(timerManager.primaryActionTitle)

                iconButton("forward.end.fill", "Skip", action: timerManager.skip)
            }
        }
    }

    private func iconButton(_ systemName: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
        }
        .buttonStyle(.icon(.secondary, size: 44, iconSize: 15))
        .help(label)
        .accessibilityLabel(label)
    }

    // MARK: Open Session

    private var openSession: some View {
        let logLabel = "Log \(TimerManager.describe(seconds: timerManager.openElapsed))"
        let toggleLabel = timerManager.openSessionRunning ? "Pause" : "Resume"

        return VStack(spacing: 32) {
            ZStack {
                // One unbroken ring: an open session has no place in the cycle.
                Circle()
                    .stroke(Paper.track, lineWidth: ringLine)
                    .padding(ringLine / 2)
                    .accessibilityElement()
                    .accessibilityLabel("Open session, \(timerManager.openSessionStatus)")

                clock(timerManager.openClockString)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: timerManager.openElapsed)
            }
            .frame(width: ringSize, height: ringSize)

            HStack(spacing: 16) {
                Button(action: timerManager.toggleOpenSession) {
                    Image(systemName: timerManager.openSessionRunning ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.icon(.secondary, size: 44, iconSize: 15))
                .keyboardShortcut(.space, modifiers: [])
                .help(toggleLabel)
                .accessibilityLabel(toggleLabel)

                Button(action: timerManager.logOpenSession) {
                    Image(systemName: "checkmark")
                }
                .buttonStyle(.icon(.primary, size: 56, iconSize: 20))
                .keyboardShortcut(.return, modifiers: [])
                .disabled(timerManager.openElapsed == 0)
                .help(logLabel)
                .accessibilityLabel(logLabel)

                iconButton("xmark", "Discard", action: timerManager.discardOpenSession)
            }
        }
    }
}
