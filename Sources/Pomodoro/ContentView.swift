import SwiftUI

struct ContentView: View {
    @ObservedObject var timerManager: TimerManager

    var body: some View {
        TabView {
            timerTab
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }

            StatsView(timerManager: timerManager)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
        }
        .frame(minWidth: 410, minHeight: 420)
    }

    // MARK: - Timer Tab

    private var timerTab: some View {
        VStack(spacing: 25) {
            // Session Type
            Text(sessionText)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(sessionAccentColor)
                .textCase(.uppercase)
                .tracking(1.5)

            // Timer Display
            Text(timerManager.timeString)
                .font(.system(size: 80, weight: .thin, design: .rounded))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .contentTransition(.numericText())

            // Session Progress Dots
            HStack(spacing: 10) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(completedInCycle > index
                              ? sessionAccentColor
                              : Color.primary.opacity(0.15))
                        .frame(width: 10, height: 10)
                }
            }

            // Controls
            controlsView
        }
        .padding(30)
        .animation(.easeInOut(duration: 0.4), value: timerManager.sessionState)
    }

    // MARK: - Controls

    @State private var hoveringPlay = false
    @State private var hoveringSkip = false

    @ViewBuilder
    private var controlsView: some View {
        if #available(macOS 26, *) {
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 12) {
                    Button(action: { timerManager.previousSession() }) {
                        Image(systemName: "backward.end.fill")
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.glass)
                    .disabled(timerManager.sessionCount == 0 && timerManager.sessionState == .focus)
                    
                    Button(action: togglePlayPause) {
                        Image(systemName: playPauseIcon)
                            .font(.system(size: 20, weight: .medium))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(sessionAccentColor)
                    .opacity(hoveringPlay ? 0.75 : 1.0)
                    .onHover { hovering in
                        hoveringPlay = hovering
                        hovering ? NSCursor.pointingHand.push() : NSCursor.pop()
                    }
                    .animation(.spring(duration: 0.2), value: hoveringPlay)
            
                    Button(action: { timerManager.skip() }) {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.glass)
                    .opacity(hoveringSkip ? 0.75 : 1.0)
                    .onHover { hovering in
                        hoveringSkip = hovering
                        hovering ? NSCursor.pointingHand.push() : NSCursor.pop()
                    }
                    .animation(.spring(duration: 0.2), value: hoveringSkip)
                }
            }
        } else {
            HStack(spacing: 16) {
                Button(action: togglePlayPause) {
                    Image(systemName: playPauseIcon)
                        .font(.system(size: 20, weight: .medium))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(sessionAccentColor)
                .opacity(hoveringPlay ? 0.75 : 1.0)
                .onHover { hovering in
                    hoveringPlay = hovering
                    hovering ? NSCursor.pointingHand.push() : NSCursor.pop()
                }
                .animation(.spring(duration: 0.2), value: hoveringPlay)

                Button(action: { timerManager.skip() }) {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .opacity(hoveringSkip ? 0.75 : 1.0)
                .onHover { hovering in
                    hoveringSkip = hovering
                    hovering ? NSCursor.pointingHand.push() : NSCursor.pop()
                }
                .animation(.spring(duration: 0.2), value: hoveringSkip)
            }
        }
    }

    // MARK: - Helpers

    private func togglePlayPause() {
        if timerManager.timerState == .running {
            timerManager.pause()
        } else {
            timerManager.start()
        }
    }

    private var playPauseIcon: String {
        timerManager.timerState == .running ? "pause.fill" : "play.fill"
    }

    private var sessionText: String {
        switch timerManager.sessionState {
        case .focus:      return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak:  return "Long Break"
        }
    }

    private var completedInCycle: Int {
        timerManager.sessionState == .longBreak ? 4 : timerManager.sessionCount % 4
    }

    private var sessionAccentColor: Color {
        switch timerManager.sessionState {
        case .focus:      return .accentColor
        case .shortBreak: return .green
        case .longBreak:  return .blue
        }
    }
}
