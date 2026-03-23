import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var timerManager: TimerManager

    var body: some View {
        Form {
            Section("Durations") {
                Stepper(value: $timerManager.focusDurationMinutes, in: 5...120, step: 5) {
                    durationLabel("Focus Session", value: timerManager.focusDurationMinutes)
                }
                .onChange(of: timerManager.focusDurationMinutes) { _, _ in
                    timerManager.updateTimeForCurrentSettings()
                }

                Stepper(value: $timerManager.shortBreakDurationMinutes, in: 1...30, step: 1) {
                    durationLabel("Short Break", value: timerManager.shortBreakDurationMinutes)
                }
                .onChange(of: timerManager.shortBreakDurationMinutes) { _, _ in
                    timerManager.updateTimeForCurrentSettings()
                }

                Stepper(value: $timerManager.longBreakDurationMinutes, in: 5...60, step: 5) {
                    durationLabel("Long Break", value: timerManager.longBreakDurationMinutes)
                }
                .onChange(of: timerManager.longBreakDurationMinutes) { _, _ in
                    timerManager.updateTimeForCurrentSettings()
                }
            }

            Section("Behavior") {
                Toggle("Auto-start Breaks", isOn: $timerManager.autoStartBreaks)

                Stepper(value: $timerManager.streakMinMinutes, in: 1...120, step: 5) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Streak Minimum")
                        Text("\(timerManager.streakMinMinutes) min/day to count")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Picker("Completion Sound", selection: $timerManager.completionSound) {
                        ForEach(TimerManager.availableSounds, id: \.self) { sound in
                            Text(sound).tag(sound)
                        }
                    }

                    Button {
                        NSSound(named: NSSound.Name(timerManager.completionSound))?.play()
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                    }
                    .buttonStyle(.borderless)
                    .help("Preview sound")
                }
            }
        }
        .formStyle(.grouped)
        .fontDesign(.rounded)
        .frame(minWidth: 380)
    }

    private func durationLabel(_ title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
            Text("\(value) minutes")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
