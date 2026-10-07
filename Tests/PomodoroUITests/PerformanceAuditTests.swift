import PomodoroCore
import Testing
@testable import PomodoroUI

/// Guards the seam between "how long the stage keeps the window open" and "how long
/// the keyframes actually run".
///
/// `duration(for:)` is hand-written per character; the authored length is whatever
/// the longest track's keyframes sum to. Nothing in the type system ties them
/// together, so a track edited to add a beat silently runs past the end of its own
/// performance and gets cut off mid-motion.
@Suite("Performance duration audit")
struct PerformanceAuditTests {

    @Test("Every performance's declared duration matches its longest authored track")
    func declaredMatchesAuthored() {
        for entry in PerformanceAudit.all {
            #expect(
                abs(entry.drift) < 0.02,
                """
                \(entry.character.displayName) · \(entry.cue.displayName): \
                declared \(entry.declared)s but tracks run \(entry.authored)s \
                (drift \(entry.drift)s)
                """
            )
        }
    }

    @Test("No performance ends on a pose that is still visible")
    func everyPerformanceEndsHidden() {
        // The stage tears the window down when the declared duration elapses. If the
        // character has not travelled back behind the pill by then it vanishes in
        // mid-air rather than withdrawing.
        for cue in CharacterCue.allCases {
            let samurai = SamuraiPerformance.timeline(for: cue)
            #expect(samurai.value(time: samurai.duration).emergence > 150,
                    "Samurai · \(cue.displayName) ends still on screen")

            let ninja = NinjaPerformance.timeline(for: cue)
            #expect(ninja.value(time: ninja.duration).emergence > 150,
                    "Ninja · \(cue.displayName) ends still on screen")

            let general = GeneralPerformance.timeline(for: cue)
            #expect(general.value(time: general.duration).emergence > 150,
                    "General · \(cue.displayName) ends still on screen")

            let rabbit = RabbitPerformance.timeline(for: cue)
            #expect(rabbit.value(time: rabbit.duration).emergence > 150,
                    "Rabbit · \(cue.displayName) ends still on screen")

            let girl = AnimeGirlPerformance.timeline(for: cue)
            #expect(girl.value(time: girl.duration).emergence > 150,
                    "Anime girl · \(cue.displayName) ends still on screen")

            let hancock = HancockPerformance.timeline(for: cue)
            #expect(hancock.value(time: hancock.duration).emergence > 150,
                    "Hancock · \(cue.displayName) ends still on screen")
        }
    }
}
