import PomodoroCore
import SwiftUI

/// The progress ring with the countdown inside it.
///
/// `timeLabel` is injected rather than derived: the widget hands in a self-updating
/// `Text(timerInterval:)`, the app hands in a string it refreshes on its own tick.
/// Same dial, two very different tick sources.
public struct TimerDial<TimeLabel: View>: View {

    let phase: Phase
    let progress: Double
    let lineWidth: CGFloat
    let isRunning: Bool
    let timeLabel: TimeLabel

    @State private var breathing = false

    public init(
        phase: Phase,
        progress: Double,
        lineWidth: CGFloat = 8,
        isRunning: Bool = false,
        @ViewBuilder timeLabel: () -> TimeLabel
    ) {
        self.phase = phase
        self.progress = progress
        self.lineWidth = lineWidth
        self.isRunning = isRunning
        self.timeLabel = timeLabel()
    }

    public var body: some View {
        ZStack {
            // A soft phase-coloured bloom behind the ring. This is what makes the
            // glass above it actually refract something instead of sitting on flat
            // grey — glass needs content underneath to be worth using.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.tint(for: phase).opacity(0.30), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 70
                    )
                )
                .blur(radius: 8)
                .scaleEffect(breathing ? 1.06 : 0.94)
                .opacity(isRunning ? 1 : 0.45)

            Circle()
                .stroke(.primary.opacity(0.10), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: max(progress, 0.0001))
                .stroke(
                    AngularGradient(
                        colors: [
                            Theme.tint(for: phase).opacity(0.75),
                            Theme.tint(for: phase),
                            Theme.highlight(for: phase),
                        ],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                // Start at 12 o'clock and sweep clockwise, the way a kitchen timer does.
                .rotationEffect(.degrees(-90))
                .shadow(color: Theme.tint(for: phase).opacity(0.5), radius: 4)

            VStack(spacing: 0) {
                timeLabel
                Text(phase.title.uppercased())
                    .font(.system(size: 8, weight: .bold))
                    .tracking(0.9)
                    .foregroundStyle(Theme.tint(for: phase))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .transition(.blurReplace)
            }
        }
        .animation(.smooth(duration: 0.6), value: progress)
        .animation(.smooth(duration: 0.45), value: phase)
        .onAppear {
            guard isRunning else { return }
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                breathing = true
            }
        }
    }
}
