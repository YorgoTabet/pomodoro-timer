import PomodoroCore
import SwiftUI

/// Preferences. Every control writes straight through to `UserDefaults` via
/// `Settings`, so there is no apply/cancel state to keep in sync.
struct SettingsView: View {

    @Bindable var settings: PomodoroSettings
    let onChange: () -> Void

    @State private var launchAtLogin = LoginItem.isEnabled

    var body: some View {
        Form {
            Section("Intervals") {
                stepper("Focus", value: $settings.focusMinutes, range: 1...240, unit: "min")
                stepper("Short break", value: $settings.shortBreakMinutes, range: 1...240, unit: "min")
                stepper("Long break", value: $settings.longBreakMinutes, range: 1...240, unit: "min")
                stepper("Long break every", value: $settings.pomodorosUntilLongBreak, range: 1...12, unit: "pomodoros")
            }

            Section("Automatic start") {
                Toggle("Start breaks automatically", isOn: $settings.autoStartBreaks)
                Toggle("Start next focus automatically", isOn: $settings.autoStartFocus)
            }

            Section("Music") {
                Toggle("Pause music when focus ends", isOn: $settings.controlMusic)
                Toggle("Resume music when focus starts", isOn: $settings.resumeMusicOnFocusStart)
                    .disabled(!settings.controlMusic)
                Text("Controls Music and Spotify directly when they're running, and falls back to the system play/pause key for anything else, including browser audio.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("Alerts") {
                Toggle("Show notification", isOn: $settings.notificationsEnabled)
                Toggle("Play a chime", isOn: $settings.chimeEnabled)
            }

            Section("General") {
                Toggle("Show floating bar", isOn: $settings.showFloatingBar)
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .disabled(!LoginItem.isAvailable)
                    .onChange(of: launchAtLogin) { _, newValue in
                        // Revert the switch if registration was refused, rather than
                        // showing a state the system doesn't actually have.
                        if !LoginItem.setEnabled(newValue) {
                            launchAtLogin = LoginItem.isEnabled
                        }
                    }
                if !LoginItem.isAvailable {
                    Text("Available once the app is installed in /Applications.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
        .onChange(of: settings.focusMinutes) { _, _ in onChange() }
        .onChange(of: settings.shortBreakMinutes) { _, _ in onChange() }
        .onChange(of: settings.longBreakMinutes) { _, _ in onChange() }
        .onChange(of: settings.showFloatingBar) { _, _ in onChange() }
    }

    private func stepper(_ title: String, value: Binding<Int>, range: ClosedRange<Int>, unit: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("", value: value, format: .number)
                .labelsHidden()
                .frame(width: 48)
                .multilineTextAlignment(.trailing)
            Stepper("", value: value, in: range)
                .labelsHidden()
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 74, alignment: .leading)
        }
    }
}
