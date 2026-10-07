import PomodoroCore
import PomodoroUI

/// Measures how much every joint actually moves.
///
/// `swift run RigStudio --audit`
///
/// Two defects hide well in source and are obvious in this table:
///
/// - a joint that **never moves** in a performance. The rig has the joint, the
///   drawing has the segment, and the timeline simply never mentions it — so a
///   two-bone arm swings from the shoulder as one rigid stick.
/// - a joint that **freezes** for a long stretch mid-performance. A held pose is
///   normal; a mathematically motionless one for over a second reads as a paused
///   video.
enum MotionAudit {

    /// Longer than this without moving reads as frozen rather than held.
    static let freezeThreshold = 0.9
    /// Below this, a joint has not meaningfully moved. Degrees, or design units for
    /// the offset tracks.
    static let stillEpsilon = 0.05

    struct Finding {
        let part: String
        let range: Double
        let longestFreeze: Double
    }

    static func run() {
        for cue in CharacterCue.allCases {
            print("\n══ \(cue.displayName)")
            report(SamuraiSubject.self, cue)
            report(NinjaSubject.self, cue)
            report(GeneralSubject.self, cue)
            report(RabbitSubject.self, cue)
            report(AnimeGirlSubject.self, cue)
            report(HancockSubject.self, cue)
        }
    }

    static func report<S: RigSubject>(_ subject: S.Type, _ cue: CharacterCue) {
        let findings = analyse(subject, cue)
        let dead = findings.filter { $0.range < stillEpsilon }
        let frozen = findings.filter { $0.range >= stillEpsilon && $0.longestFreeze > freezeThreshold }

        print("  \(S.character.displayName):")
        if dead.isEmpty, frozen.isEmpty {
            print("    every joint moves, nothing freezes")
            return
        }
        if !dead.isEmpty {
            print("    never moves: \(dead.map(\.part).joined(separator: ", "))")
        }
        for finding in frozen.sorted(by: { $0.longestFreeze > $1.longestFreeze }) {
            print(String(format: "    frozen %.2fs  %@ (range %.1f)",
                         finding.longestFreeze, finding.part, finding.range))
        }
    }

    /// Samples the whole performance at 60fps and, per joint, records its total
    /// range and the longest run of frames during which it did not change.
    static func analyse<S: RigSubject>(_ subject: S.Type, _ cue: CharacterCue) -> [Finding] {
        let duration = S.duration(for: cue)
        let steps = max(2, Int((duration * 60).rounded()))
        let poses = S.poses(for: cue, count: steps)
        let step = duration / Double(steps - 1)

        return S.parts.map { part in
            let series = poses.map { S.angle($0, part) }
            let range = (series.max() ?? 0) - (series.min() ?? 0)

            var longest = 0.0, run = 0
            for index in 1..<series.count {
                if abs(series[index] - series[index - 1]) < 0.002 {
                    run += 1
                    longest = max(longest, Double(run) * step)
                } else {
                    run = 0
                }
            }
            return Finding(part: String(describing: part), range: range, longestFreeze: longest)
        }
    }
}
