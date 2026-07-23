import AppIntents
import PomodoroCore
import PomodoroUI
import SwiftUI
import WidgetKit

/// The widget's tinted backdrop, extended behind the rounded corners by the system.
struct WidgetBackground: View {
    let phase: Phase

    var body: some View {
        ZStack {
            Theme.backdrop(for: phase)
            // An off-centre bloom so the surface has a light source. Without one,
            // glass on top has nothing to refract and reads as flat grey.
            RadialGradient(
                colors: [Theme.highlight(for: phase).opacity(0.30), .clear],
                center: UnitPoint(x: 0.18, y: 0.12),
                startRadius: 2,
                endRadius: 150
            )
        }
        .animation(.smooth(duration: 0.5), value: phase)
    }
}

struct PomodoroWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let snapshot: TimerSnapshot
    /// The moment this entry represents — not "now". See `TimerSnapshot.progress(at:)`.
    let date: Date

    var body: some View {
        switch family {
        case .systemMedium: medium
        default: small
        }
    }

    // MARK: - Small

    private var small: some View {
        VStack(spacing: 7) {
            TimerDial(
                phase: snapshot.phase,
                progress: snapshot.progress(at: date),
                lineWidth: 7,
                isRunning: snapshot.isRunning
            ) {
                countdown(size: 18)
            }
            .frame(height: 76)

            CyclePips(
                position: snapshot.cyclePosition,
                length: snapshot.cycleLength,
                phase: snapshot.phase,
                size: 5
            )

            HStack(spacing: 7) {
                toggleButton
                skipButton
            }
            .glassGroup(spacing: 7)
        }
    }

    // MARK: - Medium

    private var medium: some View {
        HStack(spacing: 18) {
            TimerDial(
                phase: snapshot.phase,
                progress: snapshot.progress(at: date),
                lineWidth: 9,
                isRunning: snapshot.isRunning
            ) {
                countdown(size: 25)
            }
            .frame(width: 108, height: 108)

            VStack(alignment: .leading, spacing: 11) {
                header
                CyclePips(
                    position: snapshot.cyclePosition,
                    length: snapshot.cycleLength,
                    phase: snapshot.phase,
                    size: 7
                )
                HStack(spacing: 8) {
                    toggleButton
                    skipButton
                    resetButton
                }
                .glassGroup(spacing: 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Image(systemName: Theme.symbol(for: snapshot.phase))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.tint(for: snapshot.phase))
                    .contentTransition(.symbolEffect(.replace))
                Text(snapshot.phase.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }

            // The running/paused state has to be legible without comparing two
            // consecutive glances at the number.
            Text(statusLine)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
        }
        .animation(.smooth(duration: 0.4), value: snapshot.phase)
        .animation(.smooth(duration: 0.3), value: snapshot.isRunning)
    }

    private var statusLine: String {
        let done = snapshot.completedToday
        let suffix = done == 1 ? "1 done today" : "\(done) done today"
        return snapshot.isRunning ? suffix : "Paused · \(suffix)"
    }

    // MARK: - Countdown

    /// While running, hand SwiftUI the deadline and let it drive the seconds itself —
    /// the extension is never woken once per second to redraw a number.
    @ViewBuilder
    private func countdown(size: CGFloat) -> some View {
        Group {
            if snapshot.isRunning, let deadline = snapshot.deadline, deadline > date {
                Text(timerInterval: date...deadline, countsDown: true)
                    .multilineTextAlignment(.center)
            } else {
                Text(snapshot.displayTime(at: date))
                    .contentTransition(.numericText(countsDown: true))
            }
        }
        .font(.system(size: size, weight: .medium, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(.primary)
        .minimumScaleFactor(0.55)
        .lineLimit(1)
    }

    // MARK: - Controls

    private var toggleButton: some View {
        Button(intent: ToggleTimerIntent()) {
            Image(systemName: snapshot.isRunning ? "pause.fill" : "play.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.tint(for: snapshot.phase))
                .contentTransition(.symbolEffect(.replace))
                .glassControl(size: 32)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(snapshot.isRunning ? "Pause" : "Start")
    }

    private var skipButton: some View {
        Button(intent: SkipPhaseIntent()) {
            Image(systemName: "forward.end.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
                .glassControl(size: 32)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Skip to next phase")
    }

    private var resetButton: some View {
        Button(intent: ResetTimerIntent()) {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
                .glassControl(size: 32)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Reset timer")
    }
}
