import Foundation
import Testing
@testable import PomodoroCore

@Suite("PomodoroEngine")
struct PomodoroEngineTests {

    @Test("Every break returns to focus")
    func breaksReturnToFocus() {
        for phase in [Phase.shortBreak, .longBreak] {
            #expect(PomodoroEngine.next(after: phase, completedFocusSessions: 3, pomodorosUntilLongBreak: 4) == .focus)
        }
    }

    @Test("Focus leads to a short break until the Nth session")
    func shortBreaksBeforeTheBoundary() {
        // completedFocusSessions is the count *before* this session finishes, so
        // 0, 1, 2 finish sessions 1, 2, 3 of a 4-session cycle.
        for completed in 0..<3 {
            #expect(PomodoroEngine.next(after: .focus, completedFocusSessions: completed, pomodorosUntilLongBreak: 4) == .shortBreak)
        }
    }

    @Test("The Nth focus session leads to a long break", arguments: [3, 7, 11, 15])
    func longBreakOnBoundary(completed: Int) {
        #expect(PomodoroEngine.next(after: .focus, completedFocusSessions: completed, pomodorosUntilLongBreak: 4) == .longBreak)
    }

    @Test("An interval of 1 means every break is long")
    func intervalOfOne() {
        for completed in 0..<5 {
            #expect(PomodoroEngine.next(after: .focus, completedFocusSessions: completed, pomodorosUntilLongBreak: 1) == .longBreak)
        }
    }

    @Test("A zero or negative interval is treated as 1 rather than dividing by zero")
    func nonPositiveInterval() {
        #expect(PomodoroEngine.next(after: .focus, completedFocusSessions: 0, pomodorosUntilLongBreak: 0) == .longBreak)
        #expect(PomodoroEngine.next(after: .focus, completedFocusSessions: 0, pomodorosUntilLongBreak: -3) == .longBreak)
    }

    @Test("Durations come from settings, in seconds")
    func durations() {
        let settings = PomodoroSettings(defaults: makeDefaults())
        settings.focusMinutes = 30
        settings.shortBreakMinutes = 7
        settings.longBreakMinutes = 20

        #expect(PomodoroEngine.duration(of: .focus, settings: settings) == 1800)
        #expect(PomodoroEngine.duration(of: .shortBreak, settings: settings) == 420)
        #expect(PomodoroEngine.duration(of: .longBreak, settings: settings) == 1200)
    }

    @Test("Auto-start reads the toggle matching the phase that just ended")
    func autoStart() {
        let settings = PomodoroSettings(defaults: makeDefaults())
        settings.autoStartBreaks = true
        settings.autoStartFocus = false

        #expect(PomodoroEngine.shouldAutoStart(after: .focus, settings: settings))
        #expect(!PomodoroEngine.shouldAutoStart(after: .shortBreak, settings: settings))
        #expect(!PomodoroEngine.shouldAutoStart(after: .longBreak, settings: settings))
    }
}

/// A throwaway defaults domain so tests never touch the real preferences.
func makeDefaults(function: String = #function) -> UserDefaults {
    let name = "pomodoro.tests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defaults.removePersistentDomain(forName: name)
    return defaults
}
