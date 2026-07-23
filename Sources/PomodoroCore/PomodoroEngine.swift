import Foundation

/// The pure transition rules of the pomodoro cycle.
///
/// No timers, no I/O, no AppKit — given a phase and how many focus sessions have
/// been completed, it says what comes next. Everything about *when* a transition
/// happens lives in `TimerController`; everything about *what* it becomes lives here.
public enum PomodoroEngine {

    /// The phase that follows `phase`.
    ///
    /// - Parameter completedFocusSessions: focus sessions finished *before* this
    ///   phase. When `phase` is `.focus`, finishing it makes the count
    ///   `completedFocusSessions + 1`, and that new total is what decides whether
    ///   the upcoming break is long.
    public static func next(
        after phase: Phase,
        completedFocusSessions: Int,
        pomodorosUntilLongBreak: Int
    ) -> Phase {
        guard phase == .focus else { return .focus }

        let interval = max(1, pomodorosUntilLongBreak)
        let total = completedFocusSessions + 1
        return total % interval == 0 ? .longBreak : .shortBreak
    }

    /// Seconds a phase should run for, under the given settings.
    public static func duration(of phase: Phase, settings: PomodoroSettings) -> Int {
        switch phase {
        case .focus: settings.focusMinutes * 60
        case .shortBreak: settings.shortBreakMinutes * 60
        case .longBreak: settings.longBreakMinutes * 60
        }
    }

    /// Whether the phase that just ended should be auto-followed by the next one.
    public static func shouldAutoStart(after phase: Phase, settings: PomodoroSettings) -> Bool {
        // Finishing focus leads into a break; finishing a break leads into focus.
        phase == .focus ? settings.autoStartBreaks : settings.autoStartFocus
    }
}
