import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var timerManager: TimerManager
    @AppStorage(PaperTheme.accentKey) private var accent: PaperAccent = .clay
    @AppStorage(PaperTheme.fontKey) private var displayFont: PaperFont = .serif
    @Environment(\.paperTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            section("Appearance") {
                SettingsRow(title: "Accent color", detail: "Focus sessions, charts and switches") {
                    AccentSwatches(selection: $accent)
                }
                Hairline()
                SettingsRow(title: "Display font", detail: "Timer and headings") {
                    PaperSegmented(selection: $displayFont, options: PaperFont.allCases, segmentPadding: 11) { font in
                        Text(font.title)
                            .font(.system(size: 13, weight: .medium, design: font.design))
                    }
                }
            }

            section("Durations") {
                SettingsRow(title: "Focus session", detail: "How long each block of work runs") {
                    PaperStepper(value: $timerManager.focusDurationMinutes, range: 5...120, step: 5, name: "Focus session")
                }
                Hairline()
                SettingsRow(title: "Short break", detail: "Between focus sessions") {
                    PaperStepper(value: $timerManager.shortBreakDurationMinutes, range: 1...30, step: 1, name: "Short break")
                }
                Hairline()
                SettingsRow(title: "Long break", detail: "After every fourth session") {
                    PaperStepper(value: $timerManager.longBreakDurationMinutes, range: 5...60, step: 5, name: "Long break")
                }
            }

            section("Behavior") {
                SettingsRow(title: "Auto-start breaks", detail: "Begin the break as soon as focus ends") {
                    paperSwitch("Auto-start breaks", isOn: $timerManager.autoStartBreaks)
                }
                Hairline()
                SettingsRow(title: "Streak minimum", detail: "Focus a day needs to keep your streak") {
                    PaperStepper(value: $timerManager.streakMinMinutes, range: 1...120, step: 5, name: "Streak minimum")
                }
                Hairline()
                SettingsRow(title: "Completion sound") {
                    HStack(spacing: 6) {
                        Picker("Completion sound", selection: $timerManager.completionSound) {
                            ForEach(TimerManager.availableSounds, id: \.self) { sound in
                                Text(sound).tag(sound)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .fixedSize()

                        Button {
                            NSSound(named: NSSound.Name(timerManager.completionSound))?.play()
                        } label: {
                            Image(systemName: "speaker.wave.2")
                                .font(.system(size: 12, weight: .medium))
                                .frame(width: 32, height: 32)
                                .foregroundStyle(Paper.textSecondary)
                                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Paper.surface))
                                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Paper.border))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help("Preview sound")
                        .accessibilityLabel("Preview sound")
                    }
                }
            }

            section("Remote control") {
                SettingsRow(title: "Control from your phone", detail: "Start, pause and skip through Supabase") {
                    paperSwitch("Control from your phone", isOn: $timerManager.remoteControlEnabled)
                }
                Hairline()
                VStack(alignment: .leading, spacing: 12) {
                    field("Project URL") {
                        TextField("Project URL", text: $timerManager.supabaseUrl, prompt: Text(verbatim: "https://your-project.supabase.co"))
                    }
                    field("Anon key") {
                        SecureField("Anon key", text: $timerManager.supabaseKey, prompt: Text("Paste the anon public key"))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .disabled(!timerManager.remoteControlEnabled)
                .opacity(timerManager.remoteControlEnabled ? 1 : 0.5)

                if timerManager.remoteControlEnabled {
                    Hairline()
                    HStack(spacing: 8) {
                        Circle()
                            .fill(SupabaseSync.shared.isActive ? Paper.olive : Paper.clay)
                            .frame(width: 7, height: 7)
                        Text(SupabaseSync.shared.isActive ? "Connected" : "Not connected — save a valid URL and key")
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(Paper.textMuted)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 8)
        .padding(.bottom, 28)
        .frame(width: 520)
        .foregroundStyle(Paper.text)
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .containerBackground(Paper.background, for: .window)
        .onChange(of: timerManager.focusDurationMinutes) { _, _ in
            timerManager.updateTimeForCurrentSettings()
        }
        .onChange(of: timerManager.shortBreakDurationMinutes) { _, _ in
            timerManager.updateTimeForCurrentSettings()
        }
        .onChange(of: timerManager.longBreakDurationMinutes) { _, _ in
            timerManager.updateTimeForCurrentSettings()
        }
    }

    // MARK: - Building Blocks

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(theme.display(21))
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Paper.surface))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Paper.hairline))
        }
    }

    private func paperSwitch(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .toggleStyle(.switch)
            .labelsHidden()
            .controlSize(.small)
    }

    private func field<Field: View>(_ label: String, @ViewBuilder input: () -> Field) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Paper.textSecondary)
            input()
                .labelsHidden()
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .padding(.horizontal, 10)
                .frame(height: 32)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Paper.background))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Paper.border))
        }
    }
}

// MARK: - Row

private struct SettingsRow<Control: View>: View {
    let title: String
    var detail: String? = nil
    @ViewBuilder var control: Control

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 14))
                if let detail {
                    Text(detail)
                        .font(.system(size: 12))
                        .foregroundStyle(Paper.textMuted)
                }
            }
            Spacer(minLength: 0)
            control
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minHeight: 52)
    }
}

// MARK: - Accent Swatches

private struct AccentSwatches: View {
    @Binding var selection: PaperAccent

    var body: some View {
        HStack(spacing: 6) {
            ForEach(PaperAccent.allCases) { accent in
                let isSelected = selection == accent
                Button {
                    selection = accent
                } label: {
                    Circle()
                        .fill(accent.color)
                        .frame(width: 18, height: 18)
                        .padding(3)
                        .overlay(Circle().strokeBorder(isSelected ? Paper.text : Color.clear, lineWidth: 1.5))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help(accent.title)
                .accessibilityLabel(accent.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

// MARK: - Stepper

/// "−  25 min  +" stepper.
private struct PaperStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let name: String

    var body: some View {
        HStack(spacing: 0) {
            stepButton("minus", enabled: value > range.lowerBound) { decrement() }
            Text("\(value) min")
                .font(.system(size: 13, weight: .medium))
                .monospacedDigit()
                .frame(minWidth: 60)
            stepButton("plus", enabled: value < range.upperBound) { increment() }
        }
        .frame(height: 32)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Paper.background))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Paper.border))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
        .accessibilityValue("\(value) minutes")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: increment()
            case .decrement: decrement()
            @unknown default: break
            }
        }
    }

    private func increment() { value = min(range.upperBound, value + step) }
    private func decrement() { value = max(range.lowerBound, value - step) }

    private func stepButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Paper.textSecondary)
                .frame(width: 32, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.35)
    }
}
