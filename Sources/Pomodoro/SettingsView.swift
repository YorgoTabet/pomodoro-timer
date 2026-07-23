import PomodoroCore
import PomodoroUI
import SwiftUI

/// Preferences. Every control writes straight through to `UserDefaults`, so there
/// is no apply/cancel state to keep in sync — and no way to end up looking at
/// settings the app isn't actually using.
struct SettingsView: View {

    @Bindable var settings: PomodoroSettings
    let onChange: () -> Void

    @State private var launchAtLogin = LoginItem.isEnabled
    @State private var section: Section = .timer
    @Namespace private var pickerNamespace
    @Namespace private var presetNamespace

    private enum Section: String, CaseIterable, Identifiable {
        case timer = "Timer"
        case music = "Music"
        case alerts = "Alerts"

        var id: String { rawValue }

        var symbol: String {
            switch self {
            case .timer: "timer"
            case .music: "music.note"
            case .alerts: "bell.badge"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            cyclePreview
            picker
            Divider().opacity(0.4)

            Group {
                switch section {
                case .timer: timerSection
                case .music: musicSection
                case .alerts: alertsSection
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            // Sections cross-fade in place rather than sliding, so the window
            // never appears to jump when you switch tabs.
            .transition(.opacity.combined(with: .offset(y: 4)))
            .animation(.smooth(duration: 0.25), value: section)
        }
        .frame(width: 440)
        .fixedSize(horizontal: false, vertical: true)
        .background {
            Theme.backdrop(for: .focus).opacity(0.45).ignoresSafeArea()
        }
    }

    // MARK: - Cycle preview

    /// Shows the shape of the cycle the current numbers produce. Four number fields
    /// don't communicate "50 minutes of work then a walk" — this does.
    private var cyclePreview: some View {
        VStack(spacing: 9) {
            HStack(spacing: 3) {
                ForEach(0..<settings.pomodorosUntilLongBreak, id: \.self) { index in
                    segment(.focus, minutes: settings.focusMinutes)
                    if index < settings.pomodorosUntilLongBreak - 1 {
                        segment(.shortBreak, minutes: settings.shortBreakMinutes)
                    }
                }
                segment(.longBreak, minutes: settings.longBreakMinutes)
            }
            .frame(height: 26)
            .animation(.smooth(duration: 0.35), value: settings.pomodorosUntilLongBreak)
            .animation(.smooth(duration: 0.35), value: settings.focusMinutes)

            Text("One full cycle · \(cycleTotalText)")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    private func segment(_ phase: Phase, minutes: Int) -> some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Theme.highlight(for: phase), Theme.tint(for: phase)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            // Widths are proportional to real duration, so a 45/5 split looks like
            // one, instead of every phase getting an equal-sized block.
            .frame(maxWidth: .infinity)
            .layoutPriority(Double(minutes))
            .overlay {
                if minutes >= 10 {
                    Text("\(minutes)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.95))
                }
            }
    }

    private var cycleTotalText: String {
        let n = settings.pomodorosUntilLongBreak
        let total = n * settings.focusMinutes
            + max(n - 1, 0) * settings.shortBreakMinutes
            + settings.longBreakMinutes
        let hours = total / 60
        let minutes = total % 60
        let duration = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
        return "\(n) pomodoro\(n == 1 ? "" : "s"), \(duration)"
    }

    // MARK: - Picker

    /// One glass surface with a selection that slides between tabs.
    ///
    /// Deliberately *not* three independently-tinted glass capsules: changing a
    /// `glassEffect`'s tint changes the view's identity, so SwiftUI tears down and
    /// re-inserts every button on each selection — which is what made them all drop
    /// in from above whenever one was clicked. One shape moved with
    /// `matchedGeometryEffect` has a stable identity and animates the way a
    /// segmented control should.
    private var picker: some View {
        HStack(spacing: 4) {
            ForEach(Section.allCases) { item in
                Button {
                    section = item
                } label: {
                    Label(item.rawValue, systemImage: item.symbol)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(section == item ? Color.white : .secondary)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 6)
                        .background {
                            if section == item {
                                Capsule()
                                    .fill(Theme.tint(for: .focus))
                                    .matchedGeometryEffect(id: "selection", in: pickerNamespace)
                            }
                        }
                        // Without this the glass and padding are decoration, not
                        // target: only the glyph and label text take the click.
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .glassPanel(in: Capsule())
        .animation(.smooth(duration: 0.28), value: section)
        .padding(.bottom, 14)
    }

    // MARK: - Sections

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            duration("Focus", value: $settings.focusMinutes, phase: .focus, presets: [15, 25, 45, 50])
            duration("Short break", value: $settings.shortBreakMinutes, phase: .shortBreak, presets: [3, 5, 10])
            duration("Long break", value: $settings.longBreakMinutes, phase: .longBreak, presets: [15, 20, 30])

            Divider().opacity(0.4)

            HStack {
                Text("Long break every")
                    .font(.system(size: 12))
                Spacer()
                Stepper(value: $settings.pomodorosUntilLongBreak, in: 1...12) {
                    Text("\(settings.pomodorosUntilLongBreak) pomodoros")
                        .font(.system(size: 12, weight: .medium))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }

            Toggle("Start breaks automatically", isOn: $settings.autoStartBreaks)
            Toggle("Start next focus automatically", isOn: $settings.autoStartFocus)
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
                caption("Available once the app is installed in /Applications.")
            }
        }
        .toggleStyle(.switch)
        .font(.system(size: 12))
        .onChange(of: settings.focusMinutes) { _, _ in onChange() }
        .onChange(of: settings.shortBreakMinutes) { _, _ in onChange() }
        .onChange(of: settings.longBreakMinutes) { _, _ in onChange() }
        .onChange(of: settings.showFloatingBar) { _, _ in onChange() }
    }

    private var musicSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle("Pause music when focus ends", isOn: $settings.controlMusic)
            Toggle("Resume music when focus starts", isOn: $settings.resumeMusicOnFocusStart)
                .disabled(!settings.controlMusic)

            Divider().opacity(0.4)

            VStack(alignment: .leading, spacing: 8) {
                sourceRow("music.note", "Apple Music", "Scripted directly — knows what was playing")
                sourceRow("waveform", "Spotify", "Scripted directly — knows what was playing")
                sourceRow("globe", "Browsers, Podcasts, anything else", "System play/pause key")
            }

            caption("Only ever resumes what Pomodoro itself paused, so music you stopped by hand stays stopped. macOS will ask once for permission to control Music and Spotify.")
        }
        .toggleStyle(.switch)
        .font(.system(size: 12))
    }

    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle("Show a notification", isOn: $settings.notificationsEnabled)
            Toggle("Play a chime", isOn: $settings.chimeEnabled)
            caption("Focus and break endings use different chimes, so you can tell them apart without looking.")
        }
        .toggleStyle(.switch)
        .font(.system(size: 12))
    }

    // MARK: - Pieces

    private func duration(_ title: String, value: Binding<Int>, phase: Phase, presets: [Int]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(Theme.tint(for: phase))
                    .frame(width: 7, height: 7)
                Text(title)
                    .font(.system(size: 12))
                Spacer()
                Text("\(value.wrappedValue) min")
                    .font(.system(size: 12, weight: .medium))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Stepper("", value: value, in: 1...240).labelsHidden()
            }

            // Presets cover the choice almost every time; the stepper is there for
            // the rest, rather than being the only way in.
            HStack(spacing: 5) {
                ForEach(presets, id: \.self) { preset in
                    Button {
                        value.wrappedValue = preset
                    } label: {
                        Text("\(preset)")
                            .font(.system(size: 10, weight: .semibold))
                            .monospacedDigit()
                            .frame(width: 32, height: 21)
                            .foregroundStyle(value.wrappedValue == preset ? Color.white : .secondary)
                            .background {
                                if value.wrappedValue == preset {
                                    Capsule()
                                        .fill(Theme.tint(for: phase))
                                        .matchedGeometryEffect(id: title, in: presetNamespace)
                                }
                            }
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(2)
            .glassPanel(in: Capsule())
            .animation(.smooth(duration: 0.28), value: value.wrappedValue)
        }
    }

    private func sourceRow(_ symbol: String, _ name: String, _ detail: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: symbol)
                .font(.system(size: 11))
                .foregroundStyle(Theme.tint(for: .focus))
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 0) {
                Text(name).font(.system(size: 11, weight: .medium))
                Text(detail).font(.system(size: 9)).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .opacity(settings.controlMusic ? 1 : 0.4)
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
