import PomodoroCore
import PomodoroUI
import SwiftUI

/// Preferences. Every control writes straight through to `UserDefaults`, so there
/// is no apply/cancel state to keep in sync — and no way to end up looking at
/// settings the app isn't actually using.
struct SettingsView: View {

    @Bindable var settings: PomodoroSettings
    let onChange: () -> Void

    @State private var section: Section = .timer

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

    /// Shows the shape of the cycle the current numbers produce. Four number
    /// fields don't communicate "50 minutes of work then a walk" — this does.
    private var cyclePreview: some View {
        VStack(spacing: 9) {
            GeometryReader { geometry in
                let segments = cycleSegments
                let gaps = CGFloat(max(segments.count - 1, 0)) * 2
                let usable = max(geometry.size.width - gaps, 1)
                let total = CGFloat(segments.reduce(0) { $0 + $1.minutes })

                HStack(spacing: 2) {
                    ForEach(segments) { segment in
                        let width = max(usable * CGFloat(segment.minutes) / total, 3)
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Theme.highlight(for: segment.phase),
                                        Theme.tint(for: segment.phase),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: width)
                            .overlay {
                                // Only label a block wide enough to hold the number
                                // without it spilling over the edges.
                                if width >= 24 {
                                    Text("\(segment.minutes)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.95))
                                }
                            }
                    }
                }
            }
            .frame(height: 26)
            .animation(.smooth(duration: 0.35), value: settings.pomodorosUntilLongBreak)
            .animation(.smooth(duration: 0.35), value: settings.focusMinutes)
            .animation(.smooth(duration: 0.35), value: settings.shortBreakMinutes)
            .animation(.smooth(duration: 0.35), value: settings.longBreakMinutes)

            Text("One full cycle · \(cycleTotalText)")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    private struct CycleSegment: Identifiable {
        let id: Int
        let phase: Phase
        let minutes: Int
    }

    /// focus, break, focus, break, … focus, long break.
    ///
    /// Widths are computed from these minute values rather than left to layout
    /// priority: priority decides who gets space *first*, not in what proportion,
    /// so a 25-vs-5 split gave the focus blocks everything and collapsed the breaks
    /// to nothing.
    private var cycleSegments: [CycleSegment] {
        var segments: [CycleSegment] = []
        let count = settings.pomodorosUntilLongBreak
        for index in 0..<count {
            segments.append(CycleSegment(id: segments.count, phase: .focus, minutes: settings.focusMinutes))
            if index < count - 1 {
                segments.append(CycleSegment(id: segments.count, phase: .shortBreak, minutes: settings.shortBreakMinutes))
            }
        }
        segments.append(CycleSegment(id: segments.count, phase: .longBreak, minutes: settings.longBreakMinutes))
        return segments
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

    /// The system segmented control, not a hand-rolled one.
    ///
    /// Two custom versions of this were wrong in the same way: anything that changes
    /// a `glassEffect`'s configuration per item changes those views' identity, so
    /// SwiftUI re-inserts them and the whole bar replays its entrance on every
    /// click. `Picker` already renders in the system's Liquid Glass style, animates
    /// its selection correctly, and comes with keyboard and VoiceOver support that
    /// a stack of `Button`s does not.
    private var picker: some View {
        Picker("", selection: $section) {
            ForEach(Section.allCases) { item in
                Label(item.rawValue, systemImage: item.symbol).tag(item)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .padding(.horizontal, 20)
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

            Toggle("Launch at login", isOn: $settings.launchAtLogin)
                .disabled(!LoginItem.isAvailable)
                .onChange(of: settings.launchAtLogin) { _, newValue in
                    // Revert the switch if registration was refused, rather than
                    // showing a state the system doesn't actually have.
                    if !LoginItem.setEnabled(newValue) {
                        settings.launchAtLogin = !newValue
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
            // the rest, rather than being the only way in. Plain system buttons —
            // see `picker` for why these aren't custom glass.
            HStack(spacing: 6) {
                ForEach(presets, id: \.self) { preset in
                    presetButton(preset, value: value, phase: phase)
                }
            }
        }
    }

    /// `.borderedProminent` when selected: a tinted `.bordered` button reads as
    /// "slightly different colour", which is not enough to say which preset is live.
    @ViewBuilder
    private func presetButton(_ preset: Int, value: Binding<Int>, phase: Phase) -> some View {
        let isSelected = value.wrappedValue == preset
        Button("\(preset)") { value.wrappedValue = preset }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.small)
            .tint(isSelected ? Theme.tint(for: phase) : Color.secondary.opacity(0.22))
            .foregroundStyle(isSelected ? Color.white : .secondary)
            .font(.system(size: 10, weight: .semibold))
            .monospacedDigit()
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
