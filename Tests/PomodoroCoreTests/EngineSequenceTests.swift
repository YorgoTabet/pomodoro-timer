import Foundation
import Testing
@testable import PomodoroCore

/// Drives `PomodoroEngine.next` through whole cycles the way `TimerController`
/// does, instead of probing single transitions: the bug this guards against is a
/// sequence that drifts after the first long break, which no single-step test
/// can see.
@Suite("PomodoroEngine sequences")
struct EngineSequenceTests {

    /// Walk `count` phases starting from a fresh focus session, using the same
    /// bookkeeping as the controller: the completed count passed to `next` is the
    /// count *before* the current phase finishes.
    private func walk(phases count: Int, interval: Int) -> String {
        var phase = Phase.focus
        var completed = 0
        var trace = ""
        for _ in 0..<count {
            switch phase {
            case .focus: trace += "F"
            case .shortBreak: trace += "S"
            case .longBreak: trace += "L"
            }
            let next = PomodoroEngine.next(
                after: phase,
                completedFocusSessions: completed,
                pomodorosUntilLongBreak: interval
            )
            if phase == .focus { completed += 1 }
            phase = next
        }
        return trace
    }

    @Test("Full cycles repeat exactly, including the wrap after the long break", arguments: [
        // Two complete interval-4 cycles: the second must mirror the first, i.e.
        // the modular count wraps rather than treating session 5 as another Nth.
        (interval: 4, expected: "FSFSFSFLFSFSFSFL"),
        (interval: 2, expected: "FSFLFSFL"),
        (interval: 1, expected: "FLFLFL"),
    ])
    func fullCycleSequence(interval: Int, expected: String) {
        #expect(walk(phases: expected.count, interval: interval) == expected)
    }

    @Test("Changing the interval mid-cycle re-evaluates against the new modulus")
    func midCycleIntervalChange() {
        // 5 sessions done under interval 4 (one long break behind us); the user
        // shrinks the interval to 3. The 6th session makes 6, and 6 % 3 == 0, so
        // the long break comes immediately.
        #expect(PomodoroEngine.next(after: .focus, completedFocusSessions: 5, pomodorosUntilLongBreak: 3) == .longBreak)

        // 3 sessions done under interval 4 — the long break was due next — but the
        // user grows the interval to 8. The 4th session makes 4, and 4 % 8 != 0, so
        // the long break is postponed to session 8.
        #expect(PomodoroEngine.next(after: .focus, completedFocusSessions: 3, pomodorosUntilLongBreak: 8) == .shortBreak)
        #expect(PomodoroEngine.next(after: .focus, completedFocusSessions: 7, pomodorosUntilLongBreak: 8) == .longBreak)
    }
}
