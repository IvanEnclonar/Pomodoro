import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var timerManager: TimerManager
    
    var body: some View {
        VStack(spacing: 24) {
            
            Text("Timer Preferences")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .padding(.bottom, 8)
            
            // Config Sliders / Steppers
            VStack(spacing: 20) {
                
                // Focus Duration
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Focus Session")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                        Text("\(timerManager.focusDurationMinutes) minutes")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Stepper("", value: $timerManager.focusDurationMinutes, in: 5...120, step: 5)
                        .labelsHidden()
                }
                .onChange(of: timerManager.focusDurationMinutes) { _ in
                    timerManager.updateTimeForCurrentSettings()
                }
                
                Divider()
                
                // Short Break Duration
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Short Break")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                        Text("\(timerManager.shortBreakDurationMinutes) minutes")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Stepper("", value: $timerManager.shortBreakDurationMinutes, in: 1...30, step: 1)
                        .labelsHidden()
                }
                .onChange(of: timerManager.shortBreakDurationMinutes) { _ in
                    timerManager.updateTimeForCurrentSettings()
                }
                
                Divider()
                
                // Long Break Duration
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Long Break")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                        Text("\(timerManager.longBreakDurationMinutes) minutes")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Stepper("", value: $timerManager.longBreakDurationMinutes, in: 5...60, step: 5)
                        .labelsHidden()
                }
                .onChange(of: timerManager.longBreakDurationMinutes) { _ in
                    timerManager.updateTimeForCurrentSettings()
                }
            }
            .padding(16)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(12)
            
            // Auto-start Breaks Toggle
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Auto-start Breaks")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                        Text("Automatically start break sessions")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $timerManager.autoStartBreaks)
                        .labelsHidden()
                }
                
                Divider()
                
                // Streak Minimum
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Streak Minimum")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                        Text("\(timerManager.streakMinMinutes) min/day to count")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Stepper("", value: $timerManager.streakMinMinutes, in: 1...120, step: 5)
                        .labelsHidden()
                }
                
                Divider()
                
                // Completion Sound
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Completion Sound")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                    }
                    
                    Spacer()
                    
                    // Preview button
                    Button(action: {
                        // Security: Validate sound against allowlist to prevent resource misuse
                        let soundName = timerManager.completionSound
                        let safeSound = TimerManager.availableSounds.contains(soundName) ? soundName : "Ping"
                        NSSound(named: NSSound.Name(safeSound))?.play()
                    }) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Preview sound")
                    
                    Picker("", selection: $timerManager.completionSound) {
                        ForEach(TimerManager.availableSounds, id: \.self) { sound in
                            Text(sound).tag(sound)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 120)
                }
            }
            .padding(16)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(12)
            
        }
        .padding(30)
        .frame(width: 340)
    }
}
