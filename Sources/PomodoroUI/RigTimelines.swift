import PomodoroCore
import SwiftUI

/// Each character's performances, reachable as an evaluatable timeline rather than
/// only as something a `KeyframeAnimator` can play.
///
/// `CharacterStage` drives the real performances through `KeyframeAnimator`, which
/// only ever runs forward in real time. That is the right thing on screen and the
/// wrong thing for authoring: it makes a pose at t=1.37s something you can only
/// reach by waiting 1.37 seconds. `KeyframeTimeline` wraps the same keyframe
/// content and exposes `value(time:)`, so RigStudio can scrub and the tests can
/// assert on a specific instant.
///
/// The timelines are rebuilt per call. They are cheap — a keyframe track is a
/// description, not a running animation — and caching them would mean holding one
/// opaque `Keyframes` existential per character per cue for no measurable gain.

public extension SamuraiPerformance {
    static func timeline(for cue: CharacterCue) -> KeyframeTimeline<SamuraiPose> {
        switch cue {
        case .focusStart: KeyframeTimeline(initialValue: SamuraiPose()) { snapToGuard }
        case .breakStart: KeyframeTimeline(initialValue: SamuraiPose()) { exhale }
        case .longBreak: KeyframeTimeline(initialValue: SamuraiPose()) { triumph }
        }
    }
}

public extension NinjaPerformance {
    static func timeline(for cue: CharacterCue) -> KeyframeTimeline<NinjaPose> {
        switch cue {
        case .focusStart: KeyframeTimeline(initialValue: NinjaPose()) { shurikenThrow }
        case .breakStart: KeyframeTimeline(initialValue: NinjaPose()) { perch }
        case .longBreak: KeyframeTimeline(initialValue: NinjaPose()) { backflip }
        }
    }
}

public extension GeneralPerformance {
    static func timeline(for cue: CharacterCue) -> KeyframeTimeline<GeneralPose> {
        switch cue {
        case .focusStart: KeyframeTimeline(initialValue: GeneralPose()) { backToTheFront }
        case .breakStart: KeyframeTimeline(initialValue: GeneralPose()) { atEase }
        case .longBreak: KeyframeTimeline(initialValue: GeneralPose()) { paradeOfOne }
        }
    }
}

public extension RabbitPerformance {
    static func timeline(for cue: CharacterCue) -> KeyframeTimeline<RabbitPose> {
        switch cue {
        case .focusStart: KeyframeTimeline(initialValue: RabbitPose()) { reluctantSalute }
        case .breakStart: KeyframeTimeline(initialValue: RabbitPose()) { twoHops }
        case .longBreak: KeyframeTimeline(initialValue: RabbitPose()) { fullMascotMode }
        }
    }
}

public extension AnimeGirlPerformance {
    static func timeline(for cue: CharacterCue) -> KeyframeTimeline<AnimeGirlPose> {
        switch cue {
        case .focusStart: KeyframeTimeline(initialValue: AnimeGirlPose()) { fistPump }
        case .breakStart: KeyframeTimeline(initialValue: AnimeGirlPose()) { perchWave }
        case .longBreak: KeyframeTimeline(initialValue: AnimeGirlPose()) { twirl }
        }
    }
}

/// The declared duration and the longest authored track, for every performance.
///
/// `duration(for:)` is what the stage uses to decide how long to keep the window
/// open; the timeline's own duration is the sum of the longest track's keyframes.
/// Nothing keeps the two in step, so a track that runs past the declared duration
/// gets cut off mid-motion on screen. Exposed here so a test can compare them.
public enum PerformanceAudit {

    public struct Entry: Sendable {
        public let character: PomodoroCharacter
        public let cue: CharacterCue
        /// What `CharacterStage` believes the performance lasts.
        public let declared: Double
        /// What the longest authored keyframe track actually adds up to.
        public let authored: Double

        public var drift: Double { authored - declared }
    }

    public static var all: [Entry] {
        var entries: [Entry] = []
        for cue in CharacterCue.allCases {
            entries.append(.init(character: .samurai, cue: cue,
                                 declared: SamuraiPerformance.duration(for: cue),
                                 authored: SamuraiPerformance.timeline(for: cue).duration))
            entries.append(.init(character: .ninja, cue: cue,
                                 declared: NinjaPerformance.duration(for: cue),
                                 authored: NinjaPerformance.timeline(for: cue).duration))
            entries.append(.init(character: .general, cue: cue,
                                 declared: GeneralPerformance.duration(for: cue),
                                 authored: GeneralPerformance.timeline(for: cue).duration))
            entries.append(.init(character: .rabbit, cue: cue,
                                 declared: RabbitPerformance.duration(for: cue),
                                 authored: RabbitPerformance.timeline(for: cue).duration))
            entries.append(.init(character: .animeGirl, cue: cue,
                                 declared: AnimeGirlPerformance.duration(for: cue),
                                 authored: AnimeGirlPerformance.timeline(for: cue).duration))
        }
        return entries
    }
}
