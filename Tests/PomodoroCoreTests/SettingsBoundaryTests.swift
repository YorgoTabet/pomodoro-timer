import Foundation
import Testing
@testable import PomodoroCore

/// Exact edges of the clamping ranges — the existing tests prove wildly-out-of-
/// range values are pulled back, but an off-by-one at the boundary (a `<` for a
/// `<=`) would pass those and still corrupt a legitimate 240-minute session.
@Suite("Settings boundaries")
struct SettingsBoundaryTests {

    @Test("Values exactly at min and max pass through; one past does not")
    func exactClampEdges() {
        let settings = PomodoroSettings(defaults: makeDefaults())

        settings.focusMinutes = 1
        #expect(settings.focusMinutes == 1)
        settings.focusMinutes = 240
        #expect(settings.focusMinutes == 240)
        settings.focusMinutes = 241
        #expect(settings.focusMinutes == 240)

        settings.shortBreakMinutes = 1
        #expect(settings.shortBreakMinutes == 1)
        settings.longBreakMinutes = 240
        #expect(settings.longBreakMinutes == 240)

        settings.pomodorosUntilLongBreak = 1
        #expect(settings.pomodorosUntilLongBreak == 1)
        settings.pomodorosUntilLongBreak = 12
        #expect(settings.pomodorosUntilLongBreak == 12)
        settings.pomodorosUntilLongBreak = 13
        #expect(settings.pomodorosUntilLongBreak == 12)

        // Chime volume: 0…2 where 2 is deliberate over-amplification, so 2 itself
        // must survive; the default with nothing stored is unity gain.
        #expect(settings.chimeVolume == 1.0)
        settings.chimeVolume = 0
        #expect(settings.chimeVolume == 0)
        settings.chimeVolume = 2
        #expect(settings.chimeVolume == 2)
        settings.chimeVolume = 2.5
        #expect(settings.chimeVolume == 2)
        settings.chimeVolume = -0.5
        #expect(settings.chimeVolume == 0)
    }

    @Test("A garbage character string decodes to .none, and real ones round-trip")
    func characterDecodeRobustness() {
        let defaults = makeDefaults()

        // Simulates stored data from a build whose roster differed: the raw string
        // no longer matches any case, and the getter must degrade, not trap.
        defaults.set("dragon", forKey: PomodoroSettings.Key.character.rawValue)
        let settings = PomodoroSettings(defaults: defaults)
        #expect(settings.character == .none)

        // A chosen character survives a relaunch (a second instance on the same
        // domain), including one that exists in the roster but isn't drawn yet.
        settings.character = .samurai
        #expect(PomodoroSettings(defaults: defaults).character == .samurai)
        settings.character = .ninja
        #expect(PomodoroSettings(defaults: defaults).character == .ninja)
    }
}
