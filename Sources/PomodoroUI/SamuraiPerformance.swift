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
    /// Everything reveals from the top. Emerging sideways read as a different
    /// character each time; rising from behind the pill is the one gesture that
    /// makes the pill feel like the thing he lives in.
    public static func preferredEdge(for cue: CharacterCue) -> StageEdge { .top }

    /// Whether he comes *in front of* the pill rather than staying behind it.
    /// Only the back-to-work cue does — stepping into the foreground and aiming at
    /// you is what makes it read as a demand rather than a wave.
    public static func comesForward(for cue: CharacterCue) -> Bool {
        cue == .focusStart
    }

    public static func duration(for cue: CharacterCue) -> Double {
        switch cue {
        case .focusStart: 2.40
        case .breakStart: 2.80
        case .longBreak: 3.20
        }
    }

    // MARK: - focusStart · "Get back to work" (2.4s)
    //
    // Beat sheet: 0-0.12 crest peeks, 0.18 launch, 0.48 apex (blade cocks back),
    // 0.68 plant (strike lands, overshoots), 1.80 sheathe, 2.04 dip, 2.14 drop.

    /// He vaults from behind the pill into the foreground, plants, and levels the
    /// blade at you. The scale-up is what sells "stepped toward the viewer".
    @KeyframesBuilder<SamuraiPose>
    public static var snapToGuard: some Keyframes<SamuraiPose> {
        KeyframeTrack(\.emergence) {
            CubicKeyframe(140, duration: 0.12)            // crest peeks first
            LinearKeyframe(140, duration: 0.06)           // a beat of anticipation
            SpringKeyframe(-18, duration: 0.30, spring: .init(response: 0.30, dampingRatio: 0.55))
            SpringKeyframe(0, duration: 0.20, spring: .init(response: 0.30, dampingRatio: 0.62))
            Hold.moving(0, duration: 1.36, drift: 0.8)
            CubicKeyframe(-6, duration: 0.10)             // small rise before the drop
            CubicKeyframe(200, duration: 0.26, endVelocity: 900)   // ease-in
        }
        KeyframeTrack(\.rootScale) {
            LinearKeyframe(0.86, duration: 0.18)
            SpringKeyframe(1.12, duration: 0.30, spring: .init(response: 0.30, dampingRatio: 0.55))
            SpringKeyframe(1.06, duration: 0.20, spring: .init(response: 0.30, dampingRatio: 0.62))
            Hold.moving(1.06, duration: 1.46, drift: 0.012)
            CubicKeyframe(0.9, duration: 0.26)
        }
        KeyframeTrack(\.rootScaleY) {
            LinearKeyframe(0.92, duration: 0.18)          // crouch under the crest
            SpringKeyframe(1.07, duration: 0.26, spring: .init(response: 0.30, dampingRatio: 0.50))
            CubicKeyframe(1.0, duration: 0.12)
            SpringKeyframe(0.93, duration: 0.12, spring: .init(response: 0.28, dampingRatio: 0.50))  // landing
            SpringKeyframe(1.0, duration: 0.18, spring: .init(response: 0.30, dampingRatio: 0.60))
            Hold.moving(1.0, duration: 1.28, drift: 0.012)
            CubicKeyframe(1.04, duration: 0.26)
        }
        // Knees: tucked in the air, planted at the landing.
        KeyframeTrack(\.legL) {
            LinearKeyframe(-3, duration: 0.50)
            CubicKeyframe(0, duration: 0.18)
            Hold.moving(0, duration: 1.72, drift: 0.4)
        }
        KeyframeTrack(\.legR) {
            LinearKeyframe(-3, duration: 0.50)
            CubicKeyframe(0, duration: 0.18)
            Hold.moving(0, duration: 1.72, drift: 0.3)
        }
        // The point. Cocks back at the apex, lands on the plant, overshoots, sheathes
        // before the drop.
        KeyframeTrack(\.swordArmUpper) {
            LinearKeyframe(0, duration: 0.36)
            CubicKeyframe(-38, duration: 0.16)
            SpringKeyframe(30, duration: 0.16, spring: .init(response: 0.26, dampingRatio: 0.55))
            SpringKeyframe(24, duration: 0.14, spring: .init(response: 0.26, dampingRatio: 0.62))
            Hold.moving(24, duration: 0.98, drift: 0.6)
            CubicKeyframe(0, duration: 0.24)
            LinearKeyframe(0, duration: 0.36)
        }
        KeyframeTrack(\.swordFore) {
            LinearKeyframe(0, duration: 0.38)
            CubicKeyframe(-14, duration: 0.14)
            CubicKeyframe(62, duration: 0.14)             // strike lands on the plant
            CubicKeyframe(52, duration: 0.12)             // overshoot settles
            Hold.moving(52, duration: 1.02, drift: 0.6)
            CubicKeyframe(0, duration: 0.24)
            LinearKeyframe(0, duration: 0.36)
        }
        KeyframeTrack(\.katana) {
            LinearKeyframe(0, duration: 0.46)
            SpringKeyframe(-18, duration: 0.34, spring: .init(response: 0.30, dampingRatio: 0.50))
            Hold.moving(-18, duration: 1.00, drift: 0.6)
            CubicKeyframe(0, duration: 0.20)
            LinearKeyframe(0, duration: 0.40)
        }
        KeyframeTrack(\.torso) {
            LinearKeyframe(0, duration: 0.50)
            CubicKeyframe(-9, duration: 0.16)             // twists in on the strike
            SpringKeyframe(-6, duration: 0.14, spring: .init(response: 0.30, dampingRatio: 0.60))
            Hold.moving(-6, duration: 1.08, drift: 0.6)
            CubicKeyframe(0, duration: 0.28)
            LinearKeyframe(0, duration: 0.24)
        }
        KeyframeTrack(\.head) {
            LinearKeyframe(0, duration: 0.54)
            CubicKeyframe(4, duration: 0.16)
            Hold.moving(4, duration: 1.18, drift: 0.9)
            CubicKeyframe(0, duration: 0.28)
            LinearKeyframe(0, duration: 0.24)
        }
        KeyframeTrack(\.maedate) {
            LinearKeyframe(12, duration: 0.24)
            SpringKeyframe(-6, duration: 0.14, spring: .init(response: 0.50, dampingRatio: 0.35))
            SpringKeyframe(0, duration: 0.18, spring: .init(response: 0.50, dampingRatio: 0.35))
            Hold.moving(0, duration: 1.56, drift: 0.9)
            CubicKeyframe(-12, duration: 0.28)
        }
        // Skirt and sleeve plates trail the torso by about 0.1s and settle on a spring.
        KeyframeTrack(\.kusazuriL) { Lag.settle(from: -16, at: 0.58, kick: 4, total: 2.40) }
        KeyframeTrack(\.kusazuriFL) { Lag.settle(from: -9, at: 0.62, kick: 3, total: 2.40) }
        KeyframeTrack(\.kusazuriFR) { Lag.settle(from: 9, at: 0.66, kick: -3, total: 2.40) }
        KeyframeTrack(\.kusazuriR) { Lag.settle(from: 16, at: 0.70, kick: -4, total: 2.40) }
        KeyframeTrack(\.sodeL) { Lag.settle(from: -16, at: 0.64, kick: 4, total: 2.40) }
        KeyframeTrack(\.sodeR) { Lag.settle(from: 16, at: 0.68, kick: -4, total: 2.40) }
        // The off hand braces before the blade settles against it.
        KeyframeTrack(\.offArmUpper) {
            LinearKeyframe(0, duration: 0.34)
            CubicKeyframe(-16, duration: 0.16)
            SpringKeyframe(26, duration: 0.20, spring: .init(response: 0.26, dampingRatio: 0.56))
            Hold.moving(26, duration: 1.18, drift: 0.6)
            CubicKeyframe(0, duration: 0.28)
            LinearKeyframe(0, duration: 0.24)
        }
        KeyframeTrack(\.offArmFore) {
            LinearKeyframe(0, duration: 0.34)
            CubicKeyframe(-8, duration: 0.18)
            SpringKeyframe(44, duration: 0.24, spring: .init(response: 0.26, dampingRatio: 0.52))
            Hold.moving(44, duration: 1.12, drift: 1.0)
            CubicKeyframe(0, duration: 0.28)
            LinearKeyframe(0, duration: 0.24)
        }
        KeyframeTrack(\.pupilDrop) {
            LinearKeyframe(0, duration: 0.54)
            CubicKeyframe(-0.9, duration: 0.16)
            Hold.moving(-0.9, duration: 1.7, drift: 0.12)
        }
    }

    // MARK: - breakStart · "Doze off" (2.8s)
    //
    // Beat sheet: 0.35 pupils drop, 0.45 eyes snap shut, 0.45-0.9 head and torso
    // sag, 2.38 startle, 2.56 drop.

    /// He rises just far enough to lean on the pill, lets the blade drop, closes
    /// his eyes and nods off, drooping from the neck (not a whole-body tip), jerks
    /// up once, then startles awake and ducks away.
    @KeyframesBuilder<SamuraiPose>
    public static var exhale: some Keyframes<SamuraiPose> {
        KeyframeTrack(\.emergence) {
            SpringKeyframe(38, duration: 0.40, spring: .init(response: 0.50, dampingRatio: 0.85))
            Hold.moving(38, duration: 1.98, drift: 1.0)
            CubicKeyframe(30, duration: 0.18)              // startle: small rise
            CubicKeyframe(200, duration: 0.24, endVelocity: 900)
        }
        // Barely leans; the sag lives in the torso and head.
        KeyframeTrack(\.rootLean) {
            LinearKeyframe(0, duration: 0.40)
            CubicKeyframe(2.5, duration: 0.35)
            Hold.moving(2.5, duration: 1.81, drift: 0.4)
            CubicKeyframe(0, duration: 0.24)
        }
        KeyframeTrack(\.torsoScaleY) {
            LinearKeyframe(1.0, duration: 0.40)
            CubicKeyframe(0.95, duration: 0.30)
            LinearKeyframe(0.95, duration: 0.50)
            CubicKeyframe(0.98, duration: 0.45)
            CubicKeyframe(0.95, duration: 0.45)
            CubicKeyframe(0.98, duration: 0.40)
            LinearKeyframe(0.98, duration: 0.30)
        }
        KeyframeTrack(\.head) {
            LinearKeyframe(0, duration: 0.45)
            CubicKeyframe(13, duration: 0.45)            // chin drops to the chest
            LinearKeyframe(13, duration: 0.35)
            SpringKeyframe(-4, duration: 0.16, spring: .init(response: 0.24, dampingRatio: 0.5))
            SpringKeyframe(11, duration: 0.55, spring: .init(response: 0.60, dampingRatio: 0.85))
            Hold.moving(11, duration: 0.42, drift: 0.5)
            CubicKeyframe(-6, duration: 0.18)            // startle: head snaps up
            CubicKeyframe(0, duration: 0.24)
        }
        KeyframeTrack(\.kabuto) {
            LinearKeyframe(0, duration: 0.55)
            CubicKeyframe(5, duration: 0.45)
            Hold.moving(5, duration: 1.56, drift: 0.8)
            CubicKeyframe(0, duration: 0.24)
        }
        KeyframeTrack(\.maedate) {
            LinearKeyframe(10, duration: 0.24)
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.55, dampingRatio: 0.40))
            LinearKeyframe(0, duration: 0.72)
            SpringKeyframe(-7, duration: 0.20, spring: .init(response: 0.50, dampingRatio: 0.35))
            SpringKeyframe(0, duration: 0.54, spring: .init(response: 0.50, dampingRatio: 0.45))
            Hold.moving(0, duration: 0.80, drift: 0.8)
        }
        KeyframeTrack(\.swordArmUpper) {
            LinearKeyframe(0, duration: 0.40)
            CubicKeyframe(22, duration: 0.45)
            Hold.moving(22, duration: 1.71, drift: 0.5)
            CubicKeyframe(0, duration: 0.24)
        }
        KeyframeTrack(\.swordFore) {
            LinearKeyframe(0, duration: 0.40)
            CubicKeyframe(10, duration: 0.45)
            Hold.moving(10, duration: 1.71, drift: 0.5)
            CubicKeyframe(0, duration: 0.24)
        }
        KeyframeTrack(\.katana) {
            LinearKeyframe(0, duration: 0.40)
            SpringKeyframe(-16, duration: 0.50, spring: .init(response: 0.55, dampingRatio: 0.55))
            Hold.moving(-16, duration: 1.66, drift: 0.6)
            CubicKeyframe(0, duration: 0.24)
        }
        // Sleeves trail the torso by about 0.1s.
        KeyframeTrack(\.sodeL) {
            LinearKeyframe(0, duration: 0.54)
            SpringKeyframe(8, duration: 0.35, spring: .init(response: 0.60, dampingRatio: 0.70))
            Hold.moving(8, duration: 1.91, drift: 0.5)
        }
        KeyframeTrack(\.sodeR) {
            LinearKeyframe(0, duration: 0.58)
            SpringKeyframe(-8, duration: 0.35, spring: .init(response: 0.60, dampingRatio: 0.70))
            Hold.moving(-8, duration: 1.87, drift: 0.5)
        }
        KeyframeTrack(\.offArmUpper) {
            LinearKeyframe(0, duration: 0.44)
            SpringKeyframe(-9, duration: 0.50, spring: .init(response: 0.72, dampingRatio: 0.78))
            Hold.breathing(-9, duration: 1.62, drift: 1.0)
            CubicKeyframe(0, duration: 0.24)
        }
        KeyframeTrack(\.offArmFore) {
            LinearKeyframe(0, duration: 0.50)
            SpringKeyframe(-19, duration: 0.54, spring: .init(response: 0.78, dampingRatio: 0.74))
            Hold.breathing(-19, duration: 1.52, drift: 1.2)
            CubicKeyframe(0, duration: 0.24)
        }
        // Torso carries the sag (+3) and the slow breathing.
        KeyframeTrack(\.torso) {
            LinearKeyframe(0, duration: 0.44)
            CubicKeyframe(3, duration: 0.46)
            Hold.breathing(3, duration: 1.66, drift: 0.9)
            CubicKeyframe(0, duration: 0.24)
        }
        KeyframeTrack(\.kusazuriL) {
            LinearKeyframe(-6, duration: 0.26)
            SpringKeyframe(4, duration: 0.40, spring: .init(response: 0.55, dampingRatio: 0.50))
            Hold.moving(4, duration: 2.14, drift: 0.6)
        }
        KeyframeTrack(\.kusazuriR) {
            LinearKeyframe(6, duration: 0.30)
            SpringKeyframe(-4, duration: 0.40, spring: .init(response: 0.55, dampingRatio: 0.50))
            Hold.moving(-4, duration: 2.10, drift: 0.6)
        }
        // Eyes: pupils drop, then the whites and pupils snap shut in 0.10s. The two
        // brow sets swap one after the other, never as a half-and-half crossfade.
        KeyframeTrack(\.eyeOpacity) {
            LinearKeyframe(1, duration: 0.45)
            LinearKeyframe(0, duration: 0.10)
            LinearKeyframe(0, duration: 2.25)
        }
        KeyframeTrack(\.fierceOpacity) {
            LinearKeyframe(1, duration: 0.40)
            LinearKeyframe(0, duration: 0.08)
            LinearKeyframe(0, duration: 2.32)
        }
        KeyframeTrack(\.easeOpacity) {
            LinearKeyframe(0, duration: 0.48)
            LinearKeyframe(1, duration: 0.08)
            LinearKeyframe(1, duration: 2.24)
        }
        KeyframeTrack(\.pupilDrop) {
            LinearKeyframe(0, duration: 0.35)
            CubicKeyframe(1.4, duration: 0.10)
            Hold.moving(1.4, duration: 2.35, drift: 0.12)
        }
    }

    // MARK: - longBreak · "Cheer" (3.2s)
    //
    // Beat sheet: 0.20 launch (eyes swap), 0.66 land, bounces peak at 0.88 / 1.32 /
    // 1.76 and land at 1.10 / 1.54 / 1.98, kiai hold to 2.80, dip, drop at 2.90.

    /// Four sessions done. He springs up higher than the other two and cheers on
    /// three shrinking bounces, blade arm higher than the off arm, ending on a kiai.
    @KeyframesBuilder<SamuraiPose>
    public static var triumph: some Keyframes<SamuraiPose> {
        KeyframeTrack(\.emergence) {
            CubicKeyframe(170, duration: 0.10)           // crest peeks, a beat
            LinearKeyframe(170, duration: 0.10)
            SpringKeyframe(-26, duration: 0.28, spring: .init(response: 0.32, dampingRatio: 0.48))
            SpringKeyframe(-8, duration: 0.18, spring: .init(response: 0.32, dampingRatio: 0.55))
            // Three shrinking bounces: 22, 17, 12.
            CubicKeyframe(-22, duration: 0.22)
            CubicKeyframe(-8, duration: 0.22)
            CubicKeyframe(-17, duration: 0.22)
            CubicKeyframe(-8, duration: 0.22)
            CubicKeyframe(-12, duration: 0.22)
            CubicKeyframe(-8, duration: 0.22)
            Hold.moving(-8, duration: 0.82, drift: 0.8)   // kiai
            CubicKeyframe(-14, duration: 0.10)            // small rise before the drop
            CubicKeyframe(200, duration: 0.30, endVelocity: 900)
        }
        KeyframeTrack(\.rootScaleY) {
            LinearKeyframe(0.90, duration: 0.20)
            SpringKeyframe(1.08, duration: 0.28, spring: .init(response: 0.32, dampingRatio: 0.48))
            SpringKeyframe(1.0, duration: 0.18, spring: .init(response: 0.32, dampingRatio: 0.55))
            // Stretch on the way up, squash on each landing.
            CubicKeyframe(1.04, duration: 0.22)
            CubicKeyframe(0.95, duration: 0.22)
            CubicKeyframe(1.04, duration: 0.22)
            CubicKeyframe(0.95, duration: 0.22)
            CubicKeyframe(1.03, duration: 0.22)
            CubicKeyframe(0.96, duration: 0.22)
            Hold.moving(1.0, duration: 0.82, drift: 0.01)
            CubicKeyframe(1.04, duration: 0.40)
        }
        // Legs: tucked at launch, then alternate a small kick per bounce.
        KeyframeTrack(\.legL) {
            LinearKeyframe(-3, duration: 0.48)
            CubicKeyframe(0, duration: 0.18)
            CubicKeyframe(4, duration: 0.22); CubicKeyframe(0, duration: 0.22)
            CubicKeyframe(-4, duration: 0.22); CubicKeyframe(0, duration: 0.22)
            CubicKeyframe(4, duration: 0.22); CubicKeyframe(0, duration: 0.22)
            Hold.moving(0, duration: 1.22, drift: 0.4)
        }
        KeyframeTrack(\.legR) {
            LinearKeyframe(-3, duration: 0.48)
            CubicKeyframe(0, duration: 0.18)
            CubicKeyframe(-4, duration: 0.22); CubicKeyframe(0, duration: 0.22)
            CubicKeyframe(4, duration: 0.22); CubicKeyframe(0, duration: 0.22)
            CubicKeyframe(-4, duration: 0.22); CubicKeyframe(0, duration: 0.22)
            Hold.moving(0, duration: 1.22, drift: 0.3)
        }
        // Blade arm: the higher one (-85), swinging with the bounces.
        KeyframeTrack(\.swordArmUpper) {
            LinearKeyframe(0, duration: 0.24)
            SpringKeyframe(-85, duration: 0.30, spring: .init(response: 0.30, dampingRatio: 0.48))
            CubicKeyframe(-66, duration: 0.12)
            CubicKeyframe(-85, duration: 0.22); CubicKeyframe(-66, duration: 0.22)
            CubicKeyframe(-83, duration: 0.22); CubicKeyframe(-66, duration: 0.22)
            CubicKeyframe(-85, duration: 0.22); CubicKeyframe(-70, duration: 0.22)
            CubicKeyframe(-85, duration: 0.16)            // kiai
            Hold.moving(-85, duration: 0.66, drift: 0.6)
            CubicKeyframe(-10, duration: 0.40)
        }
        KeyframeTrack(\.swordFore) {
            LinearKeyframe(0, duration: 0.24)
            SpringKeyframe(-14, duration: 0.42, spring: .init(response: 0.30, dampingRatio: 0.50))
            CubicKeyframe(-20, duration: 0.22); CubicKeyframe(-10, duration: 0.22)
            CubicKeyframe(-20, duration: 0.22); CubicKeyframe(-10, duration: 0.22)
            CubicKeyframe(-20, duration: 0.22); CubicKeyframe(-10, duration: 0.22)
            Hold.moving(-10, duration: 0.82, drift: 0.6)
            CubicKeyframe(0, duration: 0.40)
        }
        // Katana flicks +-10 around 16, and goes out to 28 on the third bounce.
        KeyframeTrack(\.katana) {
            LinearKeyframe(0, duration: 0.30)
            SpringKeyframe(16, duration: 0.36, spring: .init(response: 0.35, dampingRatio: 0.45))
            CubicKeyframe(26, duration: 0.22); CubicKeyframe(6, duration: 0.22)
            CubicKeyframe(26, duration: 0.22); CubicKeyframe(6, duration: 0.22)
            CubicKeyframe(28, duration: 0.22); CubicKeyframe(12, duration: 0.22)
            Hold.moving(12, duration: 0.82, drift: 0.8)
            CubicKeyframe(0, duration: 0.40)
        }
        // Off arm: lower (-62 to -78) and leads the blade arm by 0.06s.
        KeyframeTrack(\.offArmUpper) {
            LinearKeyframe(0, duration: 0.18)
            SpringKeyframe(-78, duration: 0.30, spring: .init(response: 0.32, dampingRatio: 0.48))
            CubicKeyframe(-62, duration: 0.12)
            CubicKeyframe(-78, duration: 0.22); CubicKeyframe(-62, duration: 0.22)
            CubicKeyframe(-78, duration: 0.22); CubicKeyframe(-62, duration: 0.22)
            CubicKeyframe(-78, duration: 0.22); CubicKeyframe(-62, duration: 0.22)
            Hold.moving(-70, duration: 0.72, drift: 0.6)
            CubicKeyframe(0, duration: 0.40)
        }
        KeyframeTrack(\.offArmFore) {
            LinearKeyframe(0, duration: 0.18)
            SpringKeyframe(-46, duration: 0.42, spring: .init(response: 0.32, dampingRatio: 0.50))
            CubicKeyframe(-46, duration: 0.22); CubicKeyframe(-34, duration: 0.22)
            CubicKeyframe(-46, duration: 0.22); CubicKeyframe(-34, duration: 0.22)
            CubicKeyframe(-46, duration: 0.22); CubicKeyframe(-34, duration: 0.22)
            Hold.moving(-40, duration: 0.88, drift: 0.8)
            CubicKeyframe(0, duration: 0.40)
        }
        KeyframeTrack(\.head) {
            LinearKeyframe(0, duration: 0.34)
            CubicKeyframe(-11, duration: 0.24)           // chin up, looking skyward
            Hold.moving(-11, duration: 1.40, drift: 0.9)
            CubicKeyframe(-14, duration: 0.14)           // kiai
            Hold.moving(-14, duration: 0.68, drift: 0.6)
            CubicKeyframe(0, duration: 0.40)
        }
        KeyframeTrack(\.kabutoLift) {
            LinearKeyframe(0, duration: 0.56)
            SpringKeyframe(-4, duration: 0.18, spring: .init(response: 0.35, dampingRatio: 0.42))
            SpringKeyframe(0, duration: 0.24, spring: .init(response: 0.35, dampingRatio: 0.45))
            Hold.moving(0, duration: 1.92, drift: 0.5)
            CubicKeyframe(-3, duration: 0.30)
        }
        KeyframeTrack(\.maedate) {
            LinearKeyframe(0, duration: 0.62)
            SpringKeyframe(15, duration: 0.16, spring: .init(response: 0.50, dampingRatio: 0.28))
            SpringKeyframe(-11, duration: 0.16, spring: .init(response: 0.50, dampingRatio: 0.28))
            SpringKeyframe(0, duration: 0.16, spring: .init(response: 0.50, dampingRatio: 0.30))
            CubicKeyframe(9, duration: 0.22)
            CubicKeyframe(0, duration: 0.22)
            CubicKeyframe(8, duration: 0.22)
            CubicKeyframe(0, duration: 0.22)
            Hold.moving(0, duration: 0.92, drift: 0.9)
            CubicKeyframe(-12, duration: 0.30)
        }
        KeyframeTrack(\.rootLean) {
            Hold.moving(0, duration: 0.9, drift: 0.5)
            CubicKeyframe(-2.5, duration: 0.30)
            CubicKeyframe(2.5, duration: 0.44)
            CubicKeyframe(-2, duration: 0.44)
            CubicKeyframe(0, duration: 0.42)
            LinearKeyframe(0, duration: 0.70)
        }
        KeyframeTrack(\.kusazuriL) { Lag.settle(from: -15, at: 0.50, kick: 4, total: 3.20) }
        KeyframeTrack(\.kusazuriFL) { Lag.settle(from: -10, at: 0.54, kick: 3, total: 3.20) }
        KeyframeTrack(\.kusazuriFR) { Lag.settle(from: 10, at: 0.58, kick: -3, total: 3.20) }
        KeyframeTrack(\.kusazuriR) { Lag.settle(from: 15, at: 0.62, kick: -4, total: 3.20) }
        // Sash tails whip on every landing.
        KeyframeTrack(\.sashTailL) { Lag.sash(side: -1) }
        KeyframeTrack(\.sashTailR) { Lag.sash(side: 1) }
        // Eyes swap on the launch frame (0.20), a straight cut, not a fade.
        KeyframeTrack(\.eyeOpacity) {
            LinearKeyframe(1, duration: 0.16)
            LinearKeyframe(0, duration: 0.04)
            LinearKeyframe(0, duration: 3.00)
        }
        KeyframeTrack(\.fierceOpacity) {
            LinearKeyframe(1, duration: 0.16)
            LinearKeyframe(0, duration: 0.04)
            LinearKeyframe(0, duration: 3.00)
        }
        KeyframeTrack(\.triumphOpacity) {
            LinearKeyframe(0, duration: 0.16)
            LinearKeyframe(1, duration: 0.04)
            LinearKeyframe(1, duration: 3.00)
        }
    }
}

/// Secondary-motion helpers for plates and tails that trail what they hang from.
private enum Lag {

    /// Hangs at `initial` until `at`, kicks past rest, then settles on a spring.
    @KeyframeTrackContentBuilder<Double>
    static func settle(from initial: Double, at settleAt: Double, kick: Double, total: Double)
        -> some KeyframeTrackContent<Double> {
        LinearKeyframe(initial, duration: settleAt)
        SpringKeyframe(kick, duration: 0.14, spring: .init(response: 0.40, dampingRatio: 0.50))
        SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.45, dampingRatio: 0.45))
        Hold.moving(0, duration: total - settleAt - 0.44, drift: 0.5)
    }

    /// Cheer sash tail (3.2s): flung back at launch, then a kick on each landing.
    @KeyframeTrackContentBuilder<Double>
    static func sash(side s: Double) -> some KeyframeTrackContent<Double> {
        LinearKeyframe(24 * s, duration: 0.32)
        SpringKeyframe(0, duration: 0.34, spring: .init(response: 0.60, dampingRatio: 0.32))
        CubicKeyframe(-8 * s, duration: 0.22)
        SpringKeyframe(-18 * s, duration: 0.22, spring: .init(response: 0.30, dampingRatio: 0.45))
        CubicKeyframe(8 * s, duration: 0.22)
        SpringKeyframe(18 * s, duration: 0.22, spring: .init(response: 0.30, dampingRatio: 0.45))
        CubicKeyframe(-8 * s, duration: 0.22)
        SpringKeyframe(-18 * s, duration: 0.22, spring: .init(response: 0.30, dampingRatio: 0.45))
        SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.50, dampingRatio: 0.40))
        Hold.moving(0, duration: 0.92, drift: 1.0)
    }
}
