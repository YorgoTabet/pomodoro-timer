import PomodoroCore
import PomodoroUI
import SwiftUI

/// The control panel at the top of the menu bar menu.
///
/// A menu of verbs ("Start", "Skip", "Reset") tells you what you can do but nothing
/// about where you are. This puts the dial, the cycle, and today's count above the
/// verbs, so one click answers the question you actually opened the menu to ask.
struct MenuHeaderView: View {

    @Bindable var controller: TimerController
    let settings: PomodoroSettings
    let completedToday: Int

    private var tint: Color { Theme.tint(for: controller.phase) }

    var body: some View {
        HStack(spacing: 14) {
            TimerDial(
                phase: controller.phase,
                progress: controller.progress,
                lineWidth: 6,
                isRunning: controller.isRunning
            ) {
                Text(controller.displayTime)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
            }
            .frame(width: 66, height: 66)
            .animation(.smooth(duration: 0.3), value: controller.remainingSeconds)

            VStack(alignment: .leading, spacing: 7) {
                Text(controller.isRunning ? controller.phase.title : "\(controller.phase.title) · paused")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(controller.isRunning ? Color.primary : .secondary)

                CyclePips(
                    position: controller.completedFocusSessions % max(settings.pomodorosUntilLongBreak, 1),
                    length: settings.pomodorosUntilLongBreak,
                    phase: controller.phase,
                    size: 6
                )

                Text("\(completedToday) completed today")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(width: 258)
        .background {
            Theme.backdrop(for: controller.phase)
                .opacity(0.55)
                .animation(.smooth(duration: 0.4), value: controller.phase)
        }
    }
}
