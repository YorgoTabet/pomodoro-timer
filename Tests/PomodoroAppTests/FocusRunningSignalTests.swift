import Foundation
import Testing
@testable import Pomodoro
@testable import PomodoroCore

/// The signal the music control hangs off: focus is running, or it is not.
///
/// Worth its own suite because the failure it guards against is silent. If a path
/// out of focus forgets to announce itself, nothing crashes and no test goes red —
/// the user's music simply keeps playing through their break.
@Suite("Focus running signal")
@MainActor
struct FocusRunningSignalTests {

    /// Records every announcement so the *sequence* can be asserted, not just the
    /// final state — a stop followed by a spurious start reads the same otherwise.
    private final class Recorder {
        var events: [Bool] = []
    }

    private func makeController(
        configure: (PomodoroSettings) -> Void = { _ in }
    ) -> (TimerController, Recorder) {
        let settings = PomodoroSettings(defaults: makeAppTestDefaults())
        configure(settings)
        let stats = StatsStore(fileURL: makeScratchStatsURL())
        let controller = TimerController(settings: settings, stats: stats)

        let recorder = Recorder()
        controller.onFocusRunningChanged = { recorder.events.append($0) }
        return (controller, recorder)
    }

    @Test("Starting and pausing focus announces both edges, once each")
    func startAndPause() {
        let (controller, recorder) = makeController()

        controller.start()
        #expect(recorder.events == [true])

        // A second start is a no-op and must not re-announce.
        controller.start()
        #expect(recorder.events == [true])

        controller.pause()
        #expect(recorder.events == [true, false])

        controller.pause()
        #expect(recorder.events == [true, false])
    }

    @Test("Skipping out of a running focus session stops the music")
    func skipStops() {
        let (controller, recorder) = makeController()

        controller.start()
        controller.skip()

        #expect(recorder.events == [true, false])
        #expect(controller.phase != .focus)
    }

    @Test("Resetting from a running focus session stops the music")
    func resetStops() {
        let (controller, recorder) = makeController()

        controller.start()
        controller.reset()

        #expect(recorder.events == [true, false])
    }

    @Test("A break running is not focus running, and stays silent")
    func breakDoesNotStart() {
        let (controller, recorder) = makeController()

        controller.skip()          // focus -> break, never started
        controller.start()         // the break is now running
        #expect(recorder.events.isEmpty)

        controller.pause()
        #expect(recorder.events.isEmpty)
    }

    @Test("Auto-starting focus after a break announces the start")
    func autoStartFocusAnnounces() {
        let (controller, recorder) = makeController { $0.autoStartFocus = true }

        controller.skip()          // into the break
        controller.start()
        #expect(recorder.events.isEmpty)

        // Elapse the break: the controller auto-starts focus, which must announce.
        controller.elapse()
        #expect(controller.phase == .focus)
        #expect(controller.isRunning)
        #expect(recorder.events == [true])
    }

    @Test("Focus elapsing announces the stop before the phase-elapsed callback")
    func focusElapseStopsBeforeChime() {
        let (controller, recorder) = makeController { $0.autoStartBreaks = false }

        var orderedNotes: [String] = []
        controller.onFocusRunningChanged = { running in
            recorder.events.append(running)
            orderedNotes.append("music:\(running)")
        }
        controller.onPhaseElapsed = { _, _ in orderedNotes.append("chime") }

        controller.start()
        controller.elapse()

        #expect(recorder.events == [true, false])
        #expect(orderedNotes == ["music:true", "music:false", "chime"])
    }

    @Test("Editing settings while stopped does not announce anything")
    func settingsChangeIsSilent() {
        let (controller, recorder) = makeController()

        controller.settingsChanged()
        #expect(recorder.events.isEmpty)
    }
}

// MARK: - Fixtures

/// A private defaults domain per test, so one test's writes can't colour another's.
func makeAppTestDefaults(function: String = #function) -> UserDefaults {
    let suite = "pomodoro.apptests.\(function).\(UUID().uuidString)"
    UserDefaults().removePersistentDomain(forName: suite)
    return UserDefaults(suiteName: suite)!
}

/// Stats are written to disk, so tests get a throwaway file rather than the real one.
func makeScratchStatsURL() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("pomodoro-apptests-\(UUID().uuidString).json")
}
