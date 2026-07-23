import PomodoroCore
import SwiftUI

/// The samurai's three performances, transcribed from the art-direction spec.
///
/// Each is a `KeyframeTrack` set over `SamuraiPose`. Timeline rows in the spec map
/// one-to-one onto keyframes here, so the two can be diffed by eye.
public enum SamuraiPerformance {

    /// Preferred emergence edge per cue. The stage flips these when the pill is too
    /// close to a screen edge.
    public static func preferredEdge(for cue: CharacterCue) -> StageEdge {
        switch cue {
        case .focusStart: .trailing   // strides in from the right, blade first
        case .breakStart: .top        // rises to bow over the pill
        case .longBreak: .leading     // sweeps in from the left for the victory pose
        }
    }

    public static func duration(for cue: CharacterCue) -> Double {
        switch cue {
        case .focusStart: 1.80
        case .breakStart: 2.00
        case .longBreak: 2.60
        }
    }

    // MARK: - focusStart · "Iai draw" (1.8s)

    /// A single decisive slash: work has begun. The stillness after the cut is the
    /// point — that's the whole idea of iaijutsu.
    @KeyframesBuilder<SamuraiPose>
    public static var iaiDraw: some Keyframes<SamuraiPose> {
        KeyframeTrack(\.emergence) {
            SpringKeyframe(0, duration: 0.32, spring: .init(response: 0.32, dampingRatio: 0.75))
            LinearKeyframe(0, duration: 1.18)
            CubicKeyframe(-2, duration: 0.08)
            CubicKeyframe(48, duration: 0.22)
        }
        KeyframeTrack(\.crest) {
            LinearKeyframe(0, duration: 0.10)
            SpringKeyframe(-10, duration: 0.11, spring: .init(response: 0.4, dampingRatio: 0.55))
            SpringKeyframe(0, duration: 0.11, spring: .init(response: 0.4, dampingRatio: 0.55))
            LinearKeyframe(0, duration: 1.48)
        }
        KeyframeTrack(\.swordArm) {
            LinearKeyframe(-15, duration: 0.32)
            CubicKeyframe(-110, duration: 0.12)   // anticipation: cocked back across the body
            CubicKeyframe(42, duration: 0.12)     // THE SLASH
            SpringKeyframe(30, duration: 0.22, spring: .init(response: 0.3, dampingRatio: 0.6))
            LinearKeyframe(30, duration: 0.57)    // hold the extended pose
            CubicKeyframe(-15, duration: 0.15)    // re-sheath
            LinearKeyframe(-15, duration: 0.30)
        }
        KeyframeTrack(\.rootRotation) {
            LinearKeyframe(0, duration: 0.32)
            CubicKeyframe(-4, duration: 0.12)     // leans into the wind-up
            SpringKeyframe(3, duration: 0.06, spring: .init(response: 0.3, dampingRatio: 0.7))
            SpringKeyframe(0, duration: 0.06, spring: .init(response: 0.3, dampingRatio: 0.7))
            LinearKeyframe(0, duration: 1.24)
        }
        KeyframeTrack(\.bladeOpacity) {
            LinearKeyframe(1, duration: 0.60)
            CubicKeyframe(0.7, duration: 0.075)   // one glint flicker
            CubicKeyframe(1, duration: 0.075)
            LinearKeyframe(1, duration: 1.05)
        }
    }

    // MARK: - breakStart · "Sheath and exhale" (2.0s)

    /// Duty done; a slow bow. Nothing snaps — every motion here is a release.
    @KeyframesBuilder<SamuraiPose>
    public static var sheatheAndExhale: some Keyframes<SamuraiPose> {
        KeyframeTrack(\.emergence) {
            SpringKeyframe(0, duration: 0.32, spring: .init(response: 0.32, dampingRatio: 0.75))
            LinearKeyframe(0, duration: 1.38)
            CubicKeyframe(-2, duration: 0.08)
            CubicKeyframe(48, duration: 0.22)
        }
        KeyframeTrack(\.swordArm) {
            LinearKeyframe(-15, duration: 0.40)
            CubicKeyframe(8, duration: 0.15)      // lowers the blade fully
            LinearKeyframe(8, duration: 1.45)
        }
        KeyframeTrack(\.rootRotation) {
            LinearKeyframe(0, duration: 0.60)
            CubicKeyframe(9, duration: 0.40)      // the bow
            CubicKeyframe(0, duration: 0.40)
            LinearKeyframe(0, duration: 0.60)
        }
        KeyframeTrack(\.crest) {
            LinearKeyframe(0, duration: 0.60)
            SpringKeyframe(-8, duration: 0.40, spring: .init(response: 0.4, dampingRatio: 0.55))
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.4, dampingRatio: 0.55))
            LinearKeyframe(0, duration: 0.60)
        }
        KeyframeTrack(\.eyeScaleY) {
            LinearKeyframe(1, duration: 1.10)
            CubicKeyframe(0.25, duration: 0.30)   // content, closed
            LinearKeyframe(0.25, duration: 0.60)
        }
    }

    // MARK: - longBreak · "Blade to the sky" (2.6s)

    /// Victory stance with three proud bounces, each with a glint at its apex.
    @KeyframesBuilder<SamuraiPose>
    public static var bladeToTheSky: some Keyframes<SamuraiPose> {
        KeyframeTrack(\.emergence) {
            SpringKeyframe(0, duration: 0.32, spring: .init(response: 0.32, dampingRatio: 0.68))
            LinearKeyframe(0, duration: 0.48)
            // Three proud bounces, 0.37s apart.
            SpringKeyframe(-2, duration: 0.185, spring: .init(response: 0.35, dampingRatio: 0.6))
            SpringKeyframe(0, duration: 0.185, spring: .init(response: 0.35, dampingRatio: 0.6))
            SpringKeyframe(-2, duration: 0.185, spring: .init(response: 0.35, dampingRatio: 0.6))
            SpringKeyframe(0, duration: 0.185, spring: .init(response: 0.35, dampingRatio: 0.6))
            SpringKeyframe(-2, duration: 0.185, spring: .init(response: 0.35, dampingRatio: 0.6))
            SpringKeyframe(0, duration: 0.185, spring: .init(response: 0.35, dampingRatio: 0.6))
            LinearKeyframe(0, duration: 0.35)
            CubicKeyframe(-2, duration: 0.13)
            CubicKeyframe(48, duration: 0.22)
        }
        KeyframeTrack(\.swordArm) {
            LinearKeyframe(-15, duration: 0.40)
            CubicKeyframe(-95, duration: 0.12)    // wind-up down-across
            SpringKeyframe(5, duration: 0.10, spring: .init(response: 0.3, dampingRatio: 0.5))
            SpringKeyframe(-8, duration: 0.08, spring: .init(response: 0.3, dampingRatio: 0.5))
            LinearKeyframe(-8, duration: 1.20)    // held aloft through the bounces
            CubicKeyframe(-15, duration: 0.35)
            LinearKeyframe(-15, duration: 0.35)
        }
        KeyframeTrack(\.rootScale) {
            LinearKeyframe(1, duration: 0.52)
            SpringKeyframe(1.08, duration: 0.10, spring: .init(response: 0.3, dampingRatio: 0.5))
            SpringKeyframe(1.0, duration: 0.08, spring: .init(response: 0.3, dampingRatio: 0.5))
            LinearKeyframe(1, duration: 1.90)
        }
        KeyframeTrack(\.bladeOpacity) {
            LinearKeyframe(1, duration: 0.85)
            CubicKeyframe(0.55, duration: 0.06)   // glint 1
            CubicKeyframe(1, duration: 0.06)
            LinearKeyframe(1, duration: 0.23)
            CubicKeyframe(0.55, duration: 0.06)   // glint 2
            CubicKeyframe(1, duration: 0.06)
            LinearKeyframe(1, duration: 0.23)
            CubicKeyframe(0.55, duration: 0.06)   // glint 3
            CubicKeyframe(1, duration: 0.06)
            LinearKeyframe(1, duration: 0.93)
        }
        KeyframeTrack(\.crest) {
            LinearKeyframe(0, duration: 0.85)
            SpringKeyframe(7, duration: 0.18, spring: .init(response: 0.4, dampingRatio: 0.55))
            SpringKeyframe(0, duration: 0.18, spring: .init(response: 0.4, dampingRatio: 0.55))
            SpringKeyframe(7, duration: 0.18, spring: .init(response: 0.4, dampingRatio: 0.55))
            SpringKeyframe(0, duration: 0.18, spring: .init(response: 0.4, dampingRatio: 0.55))
            SpringKeyframe(7, duration: 0.18, spring: .init(response: 0.4, dampingRatio: 0.55))
            SpringKeyframe(0, duration: 0.18, spring: .init(response: 0.4, dampingRatio: 0.55))
            LinearKeyframe(0, duration: 0.67)
        }
    }
}
