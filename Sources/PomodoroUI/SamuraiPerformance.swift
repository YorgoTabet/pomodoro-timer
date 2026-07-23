import PomodoroCore
import SwiftUI

/// The samurai's three performances, transcribed from the art-direction spec.
///
/// Each is a `KeyframeTrack` set over `SamuraiPose`; a timeline row in the spec maps
/// to one keyframe here, so the two can be diffed by eye.
///
/// Convention: positive rotation is clockwise on screen, `emergence` counts design
/// units *behind* the pill edge (200 = hidden, 0 = risen, negative = overshoot).
public enum SamuraiPerformance {

    /// Preferred emergence edge per cue. The stage flips these when the pill is too
    /// close to a screen edge.
    public static func preferredEdge(for cue: CharacterCue) -> StageEdge {
        switch cue {
        case .focusStart: .trailing
        case .breakStart: .top
        case .longBreak: .leading
        }
    }

    public static func duration(for cue: CharacterCue) -> Double {
        switch cue {
        case .focusStart: 2.40
        case .breakStart: 2.80
        case .longBreak: 3.40
        }
    }

    // MARK: - focusStart · "Snap to guard" (2.4s)

    /// The break is over. A windup, then the blade snaps to a raised jōdan guard,
    /// and he holds it with one controlled breath.
    @KeyframesBuilder<SamuraiPose>
    public static var snapToGuard: some Keyframes<SamuraiPose> {
        KeyframeTrack(\.emergence) {
            CubicKeyframe(164, duration: 0.12)          // horns peek, a beat
            SpringKeyframe(0, duration: 0.43, spring: .init(response: 0.38, dampingRatio: 0.58))
            LinearKeyframe(0, duration: 1.47)
            CubicKeyframe(-6, duration: 0.12)           // anticipation lift
            CubicKeyframe(200, duration: 0.26)
        }
        KeyframeTrack(\.rootScaleY) {
            LinearKeyframe(0.94, duration: 0.12)
            SpringKeyframe(1.0, duration: 0.43, spring: .init(response: 0.38, dampingRatio: 0.58))
            LinearKeyframe(1.0, duration: 1.85)
        }
        KeyframeTrack(\.swordArmUpper) {
            LinearKeyframe(0, duration: 0.50)
            CubicKeyframe(10, duration: 0.12)           // windup: the sword dips
            // -48/-40, not the spec's -80/-72: the finished art rests with the
            // blade already angled up-right, so the spec's angles swung it across
            // his face. Found by rendering a sweep and looking.
            SpringKeyframe(-48, duration: 0.20, spring: .init(response: 0.32, dampingRatio: 0.55))
            SpringKeyframe(-40, duration: 0.13, spring: .init(response: 0.32, dampingRatio: 0.55))
            LinearKeyframe(-40, duration: 0.80)
            CubicKeyframe(-20, duration: 0.27)          // lower to ready
            LinearKeyframe(-20, duration: 0.38)
        }
        KeyframeTrack(\.swordFore) {
            LinearKeyframe(0, duration: 0.50)
            CubicKeyframe(8, duration: 0.12)
            SpringKeyframe(-12, duration: 0.33, spring: .init(response: 0.32, dampingRatio: 0.60))
            LinearKeyframe(-12, duration: 0.80)
            CubicKeyframe(0, duration: 0.27)
            LinearKeyframe(0, duration: 0.38)
        }
        // The blade drags 60ms behind the arm, which is what gives it weight.
        KeyframeTrack(\.katana) {
            LinearKeyframe(0, duration: 0.68)
            SpringKeyframe(14, duration: 0.32, spring: .init(response: 0.35, dampingRatio: 0.50))
            LinearKeyframe(14, duration: 0.75)
            CubicKeyframe(0, duration: 0.27)
            LinearKeyframe(0, duration: 0.38)
        }
        KeyframeTrack(\.head) {
            LinearKeyframe(0, duration: 0.88)
            CubicKeyframe(-6, duration: 0.17)           // chin-down glare
            LinearKeyframe(-6, duration: 0.70)
            CubicKeyframe(0, duration: 0.27)
            LinearKeyframe(0, duration: 0.38)
        }
        KeyframeTrack(\.maedate) {
            LinearKeyframe(9, duration: 0.26)
            SpringKeyframe(-4, duration: 0.16, spring: .init(response: 0.55, dampingRatio: 0.38))
            SpringKeyframe(0, duration: 0.20, spring: .init(response: 0.55, dampingRatio: 0.38))
            LinearKeyframe(0, duration: 1.52)
            CubicKeyframe(-10, duration: 0.26)          // streams upward on the drop
        }
        // The staggered skirt-plate cascade — never fire these together.
        KeyframeTrack(\.kusazuriL) {
            LinearKeyframe(-10, duration: 0.22)
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.50, dampingRatio: 0.42))
            LinearKeyframe(0, duration: 1.62)
            CubicKeyframe(-8, duration: 0.26)
        }
        KeyframeTrack(\.kusazuriFL) {
            LinearKeyframe(-6, duration: 0.28)
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.50, dampingRatio: 0.42))
            LinearKeyframe(0, duration: 1.82)
        }
        KeyframeTrack(\.kusazuriFR) {
            LinearKeyframe(6, duration: 0.34)
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.50, dampingRatio: 0.42))
            LinearKeyframe(0, duration: 1.76)
        }
        KeyframeTrack(\.kusazuriR) {
            LinearKeyframe(10, duration: 0.40)
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.50, dampingRatio: 0.42))
            LinearKeyframe(0, duration: 1.44)
            CubicKeyframe(8, duration: 0.26)
        }
        KeyframeTrack(\.sodeL) {
            LinearKeyframe(-14, duration: 0.24)
            SpringKeyframe(0, duration: 0.34, spring: .init(response: 0.50, dampingRatio: 0.50))
            LinearKeyframe(0, duration: 1.82)
        }
        KeyframeTrack(\.sodeR) {
            LinearKeyframe(14, duration: 0.24)
            SpringKeyframe(0, duration: 0.46, spring: .init(response: 0.50, dampingRatio: 0.50))
            SpringKeyframe(-18, duration: 0.16, spring: .init(response: 0.45, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.45, dampingRatio: 0.45))
            LinearKeyframe(0, duration: 1.24)
        }
        KeyframeTrack(\.sashTailL) {
            LinearKeyframe(-16, duration: 0.26)
            SpringKeyframe(0, duration: 0.36, spring: .init(response: 0.60, dampingRatio: 0.38))
            LinearKeyframe(0, duration: 1.78)
        }
        KeyframeTrack(\.sashTailR) {
            LinearKeyframe(16, duration: 0.26)
            SpringKeyframe(0, duration: 0.36, spring: .init(response: 0.60, dampingRatio: 0.38))
            LinearKeyframe(0, duration: 1.78)
        }
        KeyframeTrack(\.torsoScaleY) {
            LinearKeyframe(1.0, duration: 1.05)
            CubicKeyframe(1.015, duration: 0.35)        // one controlled breath
            CubicKeyframe(1.0, duration: 0.35)
            LinearKeyframe(1.0, duration: 0.65)
        }
        KeyframeTrack(\.pupilDrop) {
            LinearKeyframe(0, duration: 0.88)
            CubicKeyframe(-0.8, duration: 0.17)         // eyes lock forward
            LinearKeyframe(-0.8, duration: 1.35)
        }
    }

    // MARK: - breakStart · "Exhale" (2.8s)

    /// The session is done. Shoulders drop, the guard relaxes, and he sways.
    @KeyframesBuilder<SamuraiPose>
    public static var exhale: some Keyframes<SamuraiPose> {
        KeyframeTrack(\.emergence) {
            SpringKeyframe(0, duration: 0.35, spring: .init(response: 0.50, dampingRatio: 0.80))
            LinearKeyframe(0, duration: 2.15)
            CubicKeyframe(200, duration: 0.30)
        }
        KeyframeTrack(\.torsoScaleY) {
            LinearKeyframe(1.0, duration: 0.35)
            CubicKeyframe(0.96, duration: 0.30)         // the big exhale
            SpringKeyframe(0.985, duration: 0.35, spring: .init(response: 0.5, dampingRatio: 0.7))
            LinearKeyframe(0.985, duration: 1.80)
        }
        KeyframeTrack(\.head) {
            LinearKeyframe(0, duration: 0.30)
            CubicKeyframe(4, duration: 0.25)            // easy tilt
            LinearKeyframe(4, duration: 0.15)
            CubicKeyframe(-5, duration: 0.18)           // slow neck roll
            CubicKeyframe(5, duration: 0.17)
            CubicKeyframe(4, duration: 1.15)
            SpringKeyframe(10, duration: 0.15, spring: .init(response: 0.45, dampingRatio: 0.60))
            SpringKeyframe(4, duration: 0.15, spring: .init(response: 0.45, dampingRatio: 0.60))
            LinearKeyframe(4, duration: 0.30)
        }
        KeyframeTrack(\.kabuto) {
            LinearKeyframe(0, duration: 0.78)
            CubicKeyframe(-3, duration: 0.20)
            CubicKeyframe(3, duration: 0.20)
            CubicKeyframe(0, duration: 1.62)
        }
        KeyframeTrack(\.kabutoLift) {
            LinearKeyframe(0, duration: 2.28)
            SpringKeyframe(-2, duration: 0.12, spring: .init(response: 0.40, dampingRatio: 0.50))
            SpringKeyframe(0, duration: 0.15, spring: .init(response: 0.40, dampingRatio: 0.50))
            LinearKeyframe(0, duration: 0.25)
        }
        KeyframeTrack(\.sodeL) {
            LinearKeyframe(0, duration: 0.35)
            SpringKeyframe(6, duration: 0.30, spring: .init(response: 0.60, dampingRatio: 0.70))
            LinearKeyframe(6, duration: 2.15)
        }
        KeyframeTrack(\.sodeR) {
            LinearKeyframe(0, duration: 0.35)
            SpringKeyframe(-6, duration: 0.30, spring: .init(response: 0.60, dampingRatio: 0.70))
            LinearKeyframe(-6, duration: 2.15)
        }
        KeyframeTrack(\.swordArmUpper) {
            LinearKeyframe(0, duration: 0.35)
            CubicKeyframe(14, duration: 0.40)           // the katana relaxes down
            LinearKeyframe(14, duration: 2.05)
        }
        KeyframeTrack(\.swordFore) {
            LinearKeyframe(0, duration: 0.35)
            CubicKeyframe(6, duration: 0.40)
            LinearKeyframe(6, duration: 2.05)
        }
        KeyframeTrack(\.katana) {
            LinearKeyframe(0, duration: 0.35)
            CubicKeyframe(-10, duration: 0.40)
            LinearKeyframe(-10, duration: 2.05)
        }
        KeyframeTrack(\.rootLean) {
            LinearKeyframe(0, duration: 1.10)
            CubicKeyframe(-2, duration: 0.28)           // two lazy sway half-cycles
            CubicKeyframe(2, duration: 0.55)
            CubicKeyframe(-2, duration: 0.55)
            CubicKeyframe(0, duration: 0.32)
        }
        KeyframeTrack(\.kusazuriL) {
            LinearKeyframe(-6, duration: 0.10)
            SpringKeyframe(0, duration: 0.25, spring: .init(response: 0.55, dampingRatio: 0.50))
            LinearKeyframe(0, duration: 0.75)
            CubicKeyframe(3, duration: 0.55)            // counter-sway
            CubicKeyframe(-3, duration: 0.55)
            CubicKeyframe(0, duration: 0.60)
        }
        KeyframeTrack(\.kusazuriR) {
            LinearKeyframe(6, duration: 0.16)
            SpringKeyframe(0, duration: 0.25, spring: .init(response: 0.55, dampingRatio: 0.50))
            LinearKeyframe(0, duration: 0.69)
            CubicKeyframe(-3, duration: 0.55)
            CubicKeyframe(3, duration: 0.55)
            CubicKeyframe(0, duration: 0.60)
        }
        KeyframeTrack(\.sashTailL) {
            LinearKeyframe(0, duration: 1.10)
            CubicKeyframe(6, duration: 0.55)
            CubicKeyframe(-6, duration: 0.55)
            CubicKeyframe(0, duration: 0.60)
        }
        KeyframeTrack(\.sashTailR) {
            LinearKeyframe(0, duration: 1.10)
            CubicKeyframe(-6, duration: 0.55)
            CubicKeyframe(6, duration: 0.55)
            CubicKeyframe(0, duration: 0.60)
        }
        KeyframeTrack(\.scabbard) {
            LinearKeyframe(0, duration: 1.20)
            CubicKeyframe(4, duration: 0.55)
            CubicKeyframe(-4, duration: 0.55)
            CubicKeyframe(0, duration: 0.50)
        }
        // Fierce gives way to at-ease.
        KeyframeTrack(\.fierceOpacity) {
            LinearKeyframe(1, duration: 0.30)
            LinearKeyframe(0, duration: 0.25)
            LinearKeyframe(0, duration: 2.25)
        }
        KeyframeTrack(\.easeOpacity) {
            LinearKeyframe(0, duration: 0.30)
            LinearKeyframe(1, duration: 0.25)
            LinearKeyframe(1, duration: 2.25)
        }
        KeyframeTrack(\.pupilDrop) {
            LinearKeyframe(0, duration: 0.30)
            CubicKeyframe(1.2, duration: 0.25)          // lids lower, gaze softens
            LinearKeyframe(1.2, duration: 2.25)
        }
    }

    // MARK: - longBreak · "Triumph" (3.4s)

    /// Four sessions done. A real leap, blade to the sky, and a fist pump.
    @KeyframesBuilder<SamuraiPose>
    public static var triumph: some Keyframes<SamuraiPose> {
        KeyframeTrack(\.emergence) {
            CubicKeyframe(178, duration: 0.10)          // horns only — a comic beat
            LinearKeyframe(178, duration: 0.10)
            SpringKeyframe(-14, duration: 0.25, spring: .init(response: 0.34, dampingRatio: 0.50))
            SpringKeyframe(0, duration: 0.15, spring: .init(response: 0.34, dampingRatio: 0.50))
            LinearKeyframe(0, duration: 2.35)
            CubicKeyframe(-8, duration: 0.10)
            CubicKeyframe(200, duration: 0.35)
        }
        KeyframeTrack(\.rootScaleY) {
            LinearKeyframe(0.90, duration: 0.20)        // launch squash
            SpringKeyframe(1.06, duration: 0.25, spring: .init(response: 0.34, dampingRatio: 0.50))
            SpringKeyframe(1.0, duration: 0.15, spring: .init(response: 0.34, dampingRatio: 0.50))
            LinearKeyframe(1.0, duration: 2.35)
            CubicKeyframe(1.04, duration: 0.10)
            LinearKeyframe(1.04, duration: 0.35)
        }
        KeyframeTrack(\.swordArmUpper) {
            LinearKeyframe(0, duration: 0.30)
            // Same correction as focusStart, held higher for the victory pose.
            SpringKeyframe(-62, duration: 0.25, spring: .init(response: 0.30, dampingRatio: 0.50))
            SpringKeyframe(-55, duration: 0.15, spring: .init(response: 0.30, dampingRatio: 0.50))
            LinearKeyframe(-55, duration: 1.90)
            CubicKeyframe(-10, duration: 0.35)
            LinearKeyframe(-10, duration: 0.45)
        }
        KeyframeTrack(\.swordFore) {
            LinearKeyframe(0, duration: 0.30)
            SpringKeyframe(-14, duration: 0.40, spring: .init(response: 0.30, dampingRatio: 0.50))
            LinearKeyframe(-20, duration: 1.90)
            CubicKeyframe(0, duration: 0.35)
            LinearKeyframe(0, duration: 0.45)
        }
        KeyframeTrack(\.katana) {
            LinearKeyframe(0, duration: 0.36)
            SpringKeyframe(18, duration: 0.40, spring: .init(response: 0.35, dampingRatio: 0.45))
            LinearKeyframe(18, duration: 1.84)
            CubicKeyframe(0, duration: 0.35)
            LinearKeyframe(0, duration: 0.45)
        }
        KeyframeTrack(\.head) {
            LinearKeyframe(0, duration: 0.30)
            CubicKeyframe(-10, duration: 0.25)          // looks up at the blade
            LinearKeyframe(-10, duration: 2.05)
            CubicKeyframe(0, duration: 0.35)
            LinearKeyframe(0, duration: 0.45)
        }
        KeyframeTrack(\.kabutoLift) {
            LinearKeyframe(0, duration: 0.80)
            SpringKeyframe(-4, duration: 0.20, spring: .init(response: 0.35, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.25, spring: .init(response: 0.35, dampingRatio: 0.45))
            LinearKeyframe(0, duration: 1.80)
            CubicKeyframe(-3, duration: 0.35)
        }
        KeyframeTrack(\.kabuto) {
            LinearKeyframe(0, duration: 0.80)
            SpringKeyframe(-5, duration: 0.20, spring: .init(response: 0.35, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.25, spring: .init(response: 0.35, dampingRatio: 0.45))
            LinearKeyframe(0, duration: 2.15)
        }
        // The showpiece: an exaggerated crest whip, 90ms behind the helmet.
        KeyframeTrack(\.maedate) {
            LinearKeyframe(0, duration: 0.89)
            SpringKeyframe(14, duration: 0.16, spring: .init(response: 0.50, dampingRatio: 0.30))
            SpringKeyframe(-10, duration: 0.16, spring: .init(response: 0.50, dampingRatio: 0.30))
            SpringKeyframe(0, duration: 0.14, spring: .init(response: 0.50, dampingRatio: 0.30))
            LinearKeyframe(0, duration: 1.70)
            CubicKeyframe(-12, duration: 0.35)
        }
        KeyframeTrack(\.rootLean) {
            LinearKeyframe(0, duration: 1.00)
            CubicKeyframe(-3, duration: 0.22)           // two victory sways
            CubicKeyframe(3, duration: 0.45)
            CubicKeyframe(-3, duration: 0.23)
            CubicKeyframe(0, duration: 0.20)
            LinearKeyframe(0, duration: 1.30)
        }
        KeyframeTrack(\.offArmUpper) {
            LinearKeyframe(0, duration: 1.90)
            SpringKeyframe(-70, duration: 0.15, spring: .init(response: 0.35, dampingRatio: 0.55))
            SpringKeyframe(-60, duration: 0.10, spring: .init(response: 0.35, dampingRatio: 0.55))
            LinearKeyframe(-60, duration: 0.15)         // hold the pump
            CubicKeyframe(0, duration: 0.30)
            LinearKeyframe(0, duration: 0.80)
        }
        KeyframeTrack(\.offArmFore) {
            LinearKeyframe(0, duration: 1.90)
            SpringKeyframe(-85, duration: 0.25, spring: .init(response: 0.35, dampingRatio: 0.55))
            LinearKeyframe(-85, duration: 0.15)
            CubicKeyframe(0, duration: 0.30)
            LinearKeyframe(0, duration: 0.80)
        }
        KeyframeTrack(\.kusazuriL) {
            LinearKeyframe(-14, duration: 0.35)
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.50, dampingRatio: 0.40))
            LinearKeyframe(0, duration: 2.30)
            CubicKeyframe(-12, duration: 0.35)
        }
        KeyframeTrack(\.kusazuriFL) {
            LinearKeyframe(-10, duration: 0.41)
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.50, dampingRatio: 0.40))
            LinearKeyframe(0, duration: 2.59)
        }
        KeyframeTrack(\.kusazuriFR) {
            LinearKeyframe(10, duration: 0.47)
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.50, dampingRatio: 0.40))
            LinearKeyframe(0, duration: 2.53)
        }
        KeyframeTrack(\.kusazuriR) {
            LinearKeyframe(14, duration: 0.53)
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.50, dampingRatio: 0.40))
            LinearKeyframe(0, duration: 2.12)
            CubicKeyframe(12, duration: 0.35)
        }
        KeyframeTrack(\.sashTailL) {
            LinearKeyframe(-22, duration: 0.35)
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.60, dampingRatio: 0.35))
            LinearKeyframe(0, duration: 2.65)
        }
        KeyframeTrack(\.sashTailR) {
            LinearKeyframe(22, duration: 0.35)
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.60, dampingRatio: 0.35))
            LinearKeyframe(0, duration: 2.65)
        }
        KeyframeTrack(\.chestCord) {
            LinearKeyframe(10, duration: 0.35)
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.55, dampingRatio: 0.40))
            LinearKeyframe(0, duration: 2.65)
        }
        KeyframeTrack(\.scabbard) {
            LinearKeyframe(10, duration: 0.35)
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.55, dampingRatio: 0.40))
            LinearKeyframe(0, duration: 2.65)
        }
        // Triumphant eyes, held until he is fully hidden again.
        KeyframeTrack(\.fierceOpacity) {
            LinearKeyframe(1, duration: 0.65)
            LinearKeyframe(0, duration: 0.15)
            LinearKeyframe(0, duration: 2.60)
        }
        KeyframeTrack(\.triumphOpacity) {
            LinearKeyframe(0, duration: 0.65)
            LinearKeyframe(1, duration: 0.15)
            LinearKeyframe(1, duration: 2.60)
        }
    }
}
