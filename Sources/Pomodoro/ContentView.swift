import SwiftUI

struct ContentView: View {
    @ObservedObject var timerManager: TimerManager
    @State private var showingStats = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main Timer View
            VStack(spacing: 20) {
                // Header: Session Type
                Text(sessionText)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(sessionAccentColor.opacity(0.8))
                
                // Timer Display
                Text(timerManager.timeString)
                    .font(.system(size: 80, weight: .thin, design: .rounded))
                    .foregroundColor(.primary)
                    .monospacedDigit()
                
                // Session Progress Indicators
                HStack(spacing: 12) {
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(completedInCycle > index ? Color.primary.opacity(0.8) : Color.primary.opacity(0.2))
                            .frame(width: 12, height: 12)
                    }
                }
                .padding(.bottom, 10)
                
                // Controls
                HStack(alignment: .center, spacing: 24) {
                    
                    // Dashboard Button (Now inline!)
                    Button(action: {
                        withAnimation {
                            showingStats = true
                        }
                    }) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.secondary.opacity(0.1)))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Play / Pause Button
                    Button(action: {
                        if timerManager.timerState == .running {
                            timerManager.pause()
                        } else {
                            timerManager.start()
                        }
                    }) {
                        Image(systemName: timerManager.timerState == .running ? "pause.fill" : "play.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.primary.opacity(0.1)))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Skip Button
                    Button(action: {
                        timerManager.skip()
                    }) {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.secondary.opacity(0.1)))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 10)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
            .padding(.top, 20)
            .frame(width: 320, height: 320)
            .animation(.easeInOut(duration: 0.5), value: timerManager.sessionState)
            
            // A minimal clean background
            .background(
                VisualEffectView(material: .windowBackground, blendingMode: .behindWindow)
                    .ignoresSafeArea()
            )
            
            // Stats Overlay
            if showingStats {
                StatsView(timerManager: timerManager) {
                    withAnimation {
                        showingStats = false
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .onAppear {
            // Initialization
        }
    }
    
    private var sessionText: String {
        switch timerManager.sessionState {
        case .focus:
            return "FOCUS"
        case .shortBreak:
            return "SHORT BREAK"
        case .longBreak:
            return "LONG BREAK"
        }
    }
    
    private var completedInCycle: Int {
        if timerManager.sessionState == .longBreak {
            return 4
        } else {
            return timerManager.sessionCount % 4
        }
    }
    
    private var sessionAccentColor: Color {
        switch timerManager.sessionState {
        case .focus:
            return .primary
        case .shortBreak:
            return .green
        case .longBreak:
            return .blue
        }
    }
}

// Helper to use NSVisualEffectView for that premium macOS translucent feel
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
