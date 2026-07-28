import SwiftUI

/// Keyframe primitives for the parts of a performance where "nothing happens".
///
/// A `LinearKeyframe(x, duration: 1.2)` is mathematically motionless: the joint sits
/// at exactly `x` for 1.2 seconds. On screen that reads as a paused video, and it is
/// the single most common defect in this app's timelines — the back half of most
/// performances was a frozen pose held for over a second.
///
/// Animators solve this with a *moving hold*: the pose keeps drifting by a degree or
/// two, too little to read as a new action, more than enough to read as alive. These
/// helpers make that the easy thing to write, so a hold is never accidentally dead.
public enum Hold {

    /// A hold that drifts away from its value and eases back.
    ///
    /// The asymmetric split — out slowly, back a little faster — is what keeps it
    /// from reading as a metronome. A symmetric drift at a fixed period is just a
    /// slow oscillation, which the eye picks up as mechanical almost as quickly as
    /// no motion at all.
    ///
    /// - Parameters:
    ///   - value: the pose being held.
    ///   - duration: total seconds, unchanged — this is a drop-in for `LinearKeyframe`.
    ///   - drift: how far to wander, in the track's own units. Degrees for a joint;
    ///     keep it to 1–3 or it stops being a hold and becomes an action.
    @KeyframeTrackContentBuilder<Double>
    public static func moving(_ value: Double, duration: Double, drift: Double = 1.6)
        -> some KeyframeTrackContent<Double> {
        CubicKeyframe(value + drift, duration: duration * 0.58)
        CubicKeyframe(value, duration: duration * 0.42)
    }

    /// A moving hold with a slow breath in the middle: out, back past, and settle.
    ///
    /// For the long holds — anything over about a second — where a single drift is
    /// still too plain. Used on torsos and heads, where a real body would be
    /// breathing rather than merely not-quite-still.
    @KeyframeTrackContentBuilder<Double>
    public static func breathing(_ value: Double, duration: Double, drift: Double = 2.0)
        -> some KeyframeTrackContent<Double> {
        CubicKeyframe(value + drift, duration: duration * 0.34)
        CubicKeyframe(value - drift * 0.55, duration: duration * 0.30)
        CubicKeyframe(value + drift * 0.35, duration: duration * 0.22)
        CubicKeyframe(value, duration: duration * 0.14)
    }

    /// A hold that genuinely should not move.
    ///
    /// Opacity tracks, and any value where drifting would be a bug rather than a
    /// flourish. Exists so that a plain `LinearKeyframe` hold left in a rotation
    /// track stands out as an oversight rather than a decision.
    @KeyframeTrackContentBuilder<Double>
    public static func still(_ value: Double, duration: Double)
        -> some KeyframeTrackContent<Double> {
        LinearKeyframe(value, duration: duration)
    }
}
