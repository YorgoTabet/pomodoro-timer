import CoreGraphics
import PomodoroCore
import SwiftUI

/// One character, viewed uniformly: its rig, its poses, and how to draw it.
///
/// The five characters are deliberately independent — separate `Part` enums, separate
/// `Pose` structs, no shared base class — because their skeletons genuinely differ and
/// a common supertype would be a lie. That independence is fine for playback but
/// hostile to tooling: RigStudio would need five copies of every panel.
///
/// This protocol is the seam. It says only what a tool needs (evaluate a pose, name
/// the joints, read a joint's angle, draw the result) and nothing about what any
/// character looks like. Conformances live here in `PomodoroUI` rather than in the
/// tool because `rotation(of:)` on each pose is internal.
public protocol RigSubject {
    associatedtype Part: RigPart & CaseIterable
    /// `Sendable` because a pose crosses from the tool's evaluation into
    /// `@MainActor` drawing; every character's pose struct already is one.
    associatedtype Pose: Sendable
    associatedtype Body: View

    static var character: PomodoroCharacter { get }
    static func timeline(for cue: CharacterCue) -> KeyframeTimeline<Pose>
    /// Degrees at this joint, for the same pose the drawing uses.
    static func angle(_ pose: Pose, _ part: Part) -> Double
    @ViewBuilder static func draw(_ pose: Pose) -> Body
}

public extension RigSubject {
    static var canvas: CGSize { Part.canvas }
    static var parts: [Part] { Array(Part.allCases) }

    /// How long the performance actually runs.
    static func duration(for cue: CharacterCue) -> Double {
        timeline(for: cue).duration
    }

    /// The pose at one instant.
    ///
    /// Callers want a pose, not a timeline. Keeping `KeyframeTimeline` inside these
    /// helpers matters under strict concurrency: it is not `Sendable`, so a hoisted
    /// `let timeline = …` captured by a `@MainActor` view builder is a compile error,
    /// while a `Pose` crosses freely.
    static func pose(for cue: CharacterCue, at time: Double) -> Pose {
        timeline(for: cue).value(time: time)
    }

    /// `count` poses spread evenly across the whole performance, endpoints included.
    static func poses(for cue: CharacterCue, count: Int) -> [Pose] {
        let timeline = timeline(for: cue)
        guard count > 1 else { return [timeline.value(time: 0)] }
        return (0..<count).map { step in
            timeline.value(time: timeline.duration * Double(step) / Double(count - 1))
        }
    }

    /// Where a joint's pivot ends up once every ancestor's rotation has been applied.
    ///
    /// `RigView` composes those rotations with SwiftUI modifiers, which are
    /// write-only — there is no way to ask a rendered view where a joint went. So
    /// this repeats the composition in plain CoreGraphics, mirroring the modifier
    /// order exactly: the leaf's rotation is innermost, the root's outermost, and
    /// each anchor is the joint's *unrotated* pivot because every layer is drawn in
    /// a full-canvas frame.
    ///
    /// Scales and offsets applied through `extras` are deliberately ignored. They
    /// affect a handful of parts (eyes, smoke, whole-figure squash) and folding them
    /// in would mean re-describing every character's extras in a second place; for
    /// judging an arc, rotation is what matters.
    static func worldPivot(of part: Part, in pose: Pose) -> CGPoint {
        var point = part.pivot
        for joint in part.chain.reversed() {          // leaf first, matching the modifier nesting
            point = point.rotated(about: joint.pivot, degrees: angle(pose, joint))
        }
        return point
    }

    /// The curve a joint traces across a whole performance.
    ///
    /// This is the arc. A limb driven only by rotation sweeps a circle around its
    /// parent; a limb that also inherits body translation and counter-rotation
    /// sweeps something subtler. Drawn over the character, a lifeless arc is
    /// immediately obvious in a way that no amount of reading keyframe numbers makes
    /// obvious.
    static func arc(of part: Part, cue: CharacterCue, samples: Int = 160) -> [CGPoint] {
        let timeline = timeline(for: cue)
        guard timeline.duration > 0, samples > 1 else { return [] }
        return (0..<samples).map { step in
            let t = timeline.duration * Double(step) / Double(samples - 1)
            return worldPivot(of: part, in: timeline.value(time: t))
        }
    }
}

extension CGPoint {
    /// Clockwise for positive degrees, matching `rotationEffect` in SwiftUI's
    /// y-down coordinate space.
    func rotated(about centre: CGPoint, degrees: Double) -> CGPoint {
        guard degrees != 0 else { return self }
        let radians = degrees * .pi / 180
        let cosine = cos(radians), sine = sin(radians)
        let dx = x - centre.x, dy = y - centre.y
        return CGPoint(x: centre.x + dx * cosine - dy * sine,
                       y: centre.y + dx * sine + dy * cosine)
    }
}

// MARK: - The five characters

public enum SamuraiSubject: RigSubject {
    public static var character: PomodoroCharacter { .samurai }
    public static func timeline(for cue: CharacterCue) -> KeyframeTimeline<SamuraiPose> {
        SamuraiPerformance.timeline(for: cue)
    }
    public static func angle(_ pose: SamuraiPose, _ part: SamuraiArt.Part) -> Double {
        pose.rotation(of: part)
    }
    public static func draw(_ pose: SamuraiPose) -> some View { SamuraiView(pose: pose) }
}

public enum NinjaSubject: RigSubject {
    public static var character: PomodoroCharacter { .ninja }
    public static func timeline(for cue: CharacterCue) -> KeyframeTimeline<NinjaPose> {
        NinjaPerformance.timeline(for: cue)
    }
    public static func angle(_ pose: NinjaPose, _ part: NinjaArt.Part) -> Double {
        pose.rotation(of: part)
    }
    public static func draw(_ pose: NinjaPose) -> some View { NinjaView(pose: pose) }
}

public enum GeneralSubject: RigSubject {
    public static var character: PomodoroCharacter { .general }
    public static func timeline(for cue: CharacterCue) -> KeyframeTimeline<GeneralPose> {
        GeneralPerformance.timeline(for: cue)
    }
    public static func angle(_ pose: GeneralPose, _ part: GeneralArt.Part) -> Double {
        pose.rotation(of: part)
    }
    public static func draw(_ pose: GeneralPose) -> some View { GeneralView(pose: pose) }
}

public enum RabbitSubject: RigSubject {
    public static var character: PomodoroCharacter { .rabbit }
    public static func timeline(for cue: CharacterCue) -> KeyframeTimeline<RabbitPose> {
        RabbitPerformance.timeline(for: cue)
    }
    public static func angle(_ pose: RabbitPose, _ part: RabbitArt.Part) -> Double {
        pose.rotation(of: part)
    }
    public static func draw(_ pose: RabbitPose) -> some View { RabbitView(pose: pose) }
}

public enum AnimeGirlSubject: RigSubject {
    public static var character: PomodoroCharacter { .animeGirl }
    public static func timeline(for cue: CharacterCue) -> KeyframeTimeline<AnimeGirlPose> {
        AnimeGirlPerformance.timeline(for: cue)
    }
    public static func angle(_ pose: AnimeGirlPose, _ part: AnimeGirlArt.Part) -> Double {
        pose.rotation(of: part)
    }
    public static func draw(_ pose: AnimeGirlPose) -> some View { AnimeGirlView(pose: pose) }
}
