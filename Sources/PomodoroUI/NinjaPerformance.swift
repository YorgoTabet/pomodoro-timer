import PomodoroCore
import SwiftUI

/// The ninja's three performances.
///
/// Same conventions as `SamuraiPerformance`: positive rotation is clockwise,
/// `emergence` counts design units behind the pill edge (200 hidden, 0 risen,
/// negative overshoot). Where the samurai is heavy and deliberate, the ninja is
/// fast and asymmetric — nothing here eases in slowly, and every beat starts
/// before the previous one has settled.
public enum NinjaPerformance {

    public static func preferredEdge(for cue: CharacterCue) -> StageEdge { .top }

    /// Only the back-to-work cue steps in front of the pill.
    public static func comesForward(for cue: CharacterCue) -> Bool {
        cue == .focusStart
    }

    public static func duration(for cue: CharacterCue) -> Double {
        switch cue {
        case .focusStart: 2.20
        case .breakStart: 2.80
        case .longBreak: 3.00
        }
    }

    // MARK: - focusStart · "Shuriken" (2.2s)

    /// Appears in a puff of smoke already mid-throw, snaps the shuriken toward the
    /// viewer, and holds the follow-through. The smoke is what covers the arrival —
    /// he never *walks* on, he is simply there.
    @KeyframesBuilder<NinjaPose>
    public static var shurikenThrow: some Keyframes<NinjaPose> {
        KeyframeTrack(\.emergence) {
            // Twice the samurai's entry speed; no peek, no anticipation.
            SpringKeyframe(-14, duration: 0.24, spring: .init(response: 0.24, dampingRatio: 0.55))
            SpringKeyframe(0, duration: 0.16, spring: .init(response: 0.26, dampingRatio: 0.65))
            LinearKeyframe(0, duration: 1.42)
            CubicKeyframe(-8, duration: 0.10)
            CubicKeyframe(200, duration: 0.28)
        }
        KeyframeTrack(\.smokeOpacity) {
            LinearKeyframe(0.7, duration: 0.06)      // burst covers the arrival
            LinearKeyframe(0.55, duration: 0.16)
            LinearKeyframe(0, duration: 0.24)
            LinearKeyframe(0, duration: 1.34)
            LinearKeyframe(0.7, duration: 0.10)       // and the exit
            LinearKeyframe(0, duration: 0.30)
        }
        KeyframeTrack(\.smokeScale) {
            LinearKeyframe(0.5, duration: 0.02)
            CubicKeyframe(0.95, duration: 0.30)
            LinearKeyframe(0.95, duration: 1.48)
            CubicKeyframe(0.6, duration: 0.10)
            CubicKeyframe(0.9, duration: 0.30)
        }
        // Wind up behind the shoulder, then whip forward and stay extended.
        KeyframeTrack(\.throwArmUpper) {
            LinearKeyframe(-48, duration: 0.24)       // already cocked on arrival
            CubicKeyframe(-58, duration: 0.14)
            SpringKeyframe(46, duration: 0.14, spring: .init(response: 0.22, dampingRatio: 0.52))
            SpringKeyframe(38, duration: 0.12, spring: .init(response: 0.24, dampingRatio: 0.62))
            LinearKeyframe(38, duration: 1.18)
            CubicKeyframe(0, duration: 0.38)
        }
        KeyframeTrack(\.throwForearm) {
            LinearKeyframe(-30, duration: 0.24)
            CubicKeyframe(-44, duration: 0.14)
            SpringKeyframe(58, duration: 0.26, spring: .init(response: 0.22, dampingRatio: 0.55))
            LinearKeyframe(58, duration: 1.18)
            CubicKeyframe(0, duration: 0.38)
        }
        // Spins through the throw, then vanishes — it left his hand.
        KeyframeTrack(\.shuriken) {
            LinearKeyframe(0, duration: 0.38)
            CubicKeyframe(540, duration: 0.14)
            LinearKeyframe(540, duration: 1.68)
        }
        KeyframeTrack(\.shurikenOpacity) {
            LinearKeyframe(1, duration: 0.46)
            LinearKeyframe(0, duration: 0.10)         // gone the instant it releases
            LinearKeyframe(0, duration: 1.26)
            LinearKeyframe(1, duration: 0.38)
        }
        KeyframeTrack(\.torso) {
            LinearKeyframe(8, duration: 0.24)         // coiled away from the throw
            CubicKeyframe(-10, duration: 0.28)        // uncoils into it
            LinearKeyframe(-10, duration: 1.30)
            CubicKeyframe(0, duration: 0.38)
        }
        KeyframeTrack(\.head) {
            LinearKeyframe(0, duration: 0.38)
            CubicKeyframe(5, duration: 0.14)          // eyes down the line of the throw
            LinearKeyframe(5, duration: 1.30)
            CubicKeyframe(0, duration: 0.38)
        }
        KeyframeTrack(\.eyesScaleY) {
            LinearKeyframe(1, duration: 0.38)
            CubicKeyframe(0.62, duration: 0.12)       // narrows — taking aim
            LinearKeyframe(0.62, duration: 1.32)
            CubicKeyframe(1, duration: 0.38)
        }
        // Ribbons stream opposite the body, 70ms late, and never fully settle.
        KeyframeTrack(\.ribbonNear) {
            LinearKeyframe(-34, duration: 0.30)
            SpringKeyframe(12, duration: 0.22, spring: .init(response: 0.42, dampingRatio: 0.32))
            SpringKeyframe(0, duration: 0.26, spring: .init(response: 0.42, dampingRatio: 0.32))
            LinearKeyframe(0, duration: 1.14)
            CubicKeyframe(-26, duration: 0.28)
        }
        KeyframeTrack(\.ribbonFar) {
            LinearKeyframe(-26, duration: 0.36)
            SpringKeyframe(9, duration: 0.22, spring: .init(response: 0.46, dampingRatio: 0.30))
            SpringKeyframe(0, duration: 0.26, spring: .init(response: 0.46, dampingRatio: 0.30))
            LinearKeyframe(0, duration: 1.08)
            CubicKeyframe(-20, duration: 0.28)
        }
        KeyframeTrack(\.sashTail) {
            LinearKeyframe(-18, duration: 0.32)
            SpringKeyframe(0, duration: 0.34, spring: .init(response: 0.50, dampingRatio: 0.36))
            LinearKeyframe(0, duration: 1.54)
        }
        KeyframeTrack(\.offArmUpper) {
            LinearKeyframe(-14, duration: 0.24)
            SpringKeyframe(16, duration: 0.28, spring: .init(response: 0.30, dampingRatio: 0.58))
            LinearKeyframe(16, duration: 1.30)
            CubicKeyframe(0, duration: 0.38)
        }
    }

    // MARK: - breakStart · "Perch" (2.8s)

    /// Rises only far enough to sit on the pill's edge, drops his guard, and lets
    /// his eyes fall shut. The samurai dozes standing; the ninja makes himself
    /// comfortable.
    @KeyframesBuilder<NinjaPose>
    public static var perch: some Keyframes<NinjaPose> {
        KeyframeTrack(\.emergence) {
            // Stops well short of fully risen — perched, not standing.
            SpringKeyframe(44, duration: 0.42, spring: .init(response: 0.48, dampingRatio: 0.82))
            LinearKeyframe(44, duration: 0.30)
            CubicKeyframe(52, duration: 0.60)         // settles lower as he relaxes
            LinearKeyframe(52, duration: 1.10)
            CubicKeyframe(200, duration: 0.38)
        }
        KeyframeTrack(\.torso) {
            LinearKeyframe(0, duration: 0.42)
            CubicKeyframe(9, duration: 0.42)          // slouches sideways
            LinearKeyframe(9, duration: 1.58)
            CubicKeyframe(0, duration: 0.38)
        }
        KeyframeTrack(\.head) {
            LinearKeyframe(0, duration: 0.50)
            CubicKeyframe(-12, duration: 0.40)        // tips against his shoulder
            LinearKeyframe(-12, duration: 0.40)
            CubicKeyframe(-7, duration: 0.30)         // one slow nod
            CubicKeyframe(-14, duration: 0.40)
            LinearKeyframe(-14, duration: 0.42)
            CubicKeyframe(0, duration: 0.38)
        }
        // Eyes close to content crescents and stay shut.
        KeyframeTrack(\.alertOpacity) {
            LinearKeyframe(1, duration: 0.56)
            LinearKeyframe(0, duration: 0.20)
            LinearKeyframe(0, duration: 1.66)
            LinearKeyframe(1, duration: 0.38)
        }
        KeyframeTrack(\.contentOpacity) {
            LinearKeyframe(0, duration: 0.56)
            LinearKeyframe(1, duration: 0.20)
            LinearKeyframe(1, duration: 1.66)
            LinearKeyframe(0, duration: 0.38)
        }
        // Arms go slack; the throwing hand gives up on the shuriken entirely.
        KeyframeTrack(\.throwArmUpper) {
            LinearKeyframe(0, duration: 0.42)
            SpringKeyframe(-10, duration: 0.46, spring: .init(response: 0.60, dampingRatio: 0.72))
            LinearKeyframe(-10, duration: 1.54)
            CubicKeyframe(0, duration: 0.38)
        }
        KeyframeTrack(\.throwForearm) {
            LinearKeyframe(0, duration: 0.42)
            SpringKeyframe(-16, duration: 0.46, spring: .init(response: 0.62, dampingRatio: 0.70))
            LinearKeyframe(-16, duration: 1.54)
            CubicKeyframe(0, duration: 0.38)
        }
        KeyframeTrack(\.offArmUpper) {
            LinearKeyframe(0, duration: 0.42)
            SpringKeyframe(12, duration: 0.46, spring: .init(response: 0.60, dampingRatio: 0.72))
            LinearKeyframe(12, duration: 1.54)
            CubicKeyframe(0, duration: 0.38)
        }
        // Ribbons drift rather than whip — the one place they are calm.
        KeyframeTrack(\.ribbonNear) {
            LinearKeyframe(-16, duration: 0.42)
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.70, dampingRatio: 0.50))
            CubicKeyframe(7, duration: 0.62)
            CubicKeyframe(-4, duration: 0.62)
            CubicKeyframe(0, duration: 0.74)
        }
        KeyframeTrack(\.ribbonFar) {
            LinearKeyframe(-12, duration: 0.48)
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.74, dampingRatio: 0.48))
            CubicKeyframe(5, duration: 0.62)
            CubicKeyframe(-3, duration: 0.62)
            CubicKeyframe(0, duration: 0.68)
        }
        KeyframeTrack(\.sashTail) {
            LinearKeyframe(0, duration: 0.42)
            CubicKeyframe(9, duration: 0.70)
            CubicKeyframe(-5, duration: 0.70)
            CubicKeyframe(0, duration: 0.98)
        }
    }

    // MARK: - longBreak · "Backflip" (3.0s)

    /// Launches off the pill, turns a full backflip, and lands in a crouch with a
    /// spark in his eye. The flip is on `figure` rather than `root` so it does not
    /// fight the emergence offset.
    @KeyframesBuilder<NinjaPose>
    public static var backflip: some Keyframes<NinjaPose> {
        KeyframeTrack(\.emergence) {
            SpringKeyframe(6, duration: 0.30, spring: .init(response: 0.30, dampingRatio: 0.62))
            CubicKeyframe(22, duration: 0.16)         // crouches to load
            CubicKeyframe(-58, duration: 0.30)        // launch
            LinearKeyframe(-58, duration: 0.22)       // apex
            CubicKeyframe(4, duration: 0.34)          // fall
            SpringKeyframe(0, duration: 0.24, spring: .init(response: 0.26, dampingRatio: 0.55))
            LinearKeyframe(0, duration: 1.06)
            CubicKeyframe(200, duration: 0.38)
        }
        // One clean revolution, timed to complete just before he lands.
        KeyframeTrack(\.figureRotation) {
            LinearKeyframe(0, duration: 0.46)
            CubicKeyframe(-120, duration: 0.30)
            LinearKeyframe(-240, duration: 0.22)
            CubicKeyframe(-360, duration: 0.34)
            LinearKeyframe(-360, duration: 1.68)
        }
        KeyframeTrack(\.figureScaleY) {
            LinearKeyframe(1, duration: 0.30)
            CubicKeyframe(0.84, duration: 0.16)       // load
            CubicKeyframe(1.10, duration: 0.16)       // stretch off the ground
            LinearKeyframe(1.0, duration: 0.50)
            CubicKeyframe(0.82, duration: 0.18)       // landing squash
            SpringKeyframe(1.0, duration: 0.30, spring: .init(response: 0.28, dampingRatio: 0.50))
            LinearKeyframe(1.0, duration: 1.40)
        }
        // Tucks on the way round, opens for the landing.
        KeyframeTrack(\.legFrontThigh) {
            LinearKeyframe(0, duration: 0.46)
            CubicKeyframe(-62, duration: 0.24)
            LinearKeyframe(-62, duration: 0.40)
            CubicKeyframe(-16, duration: 0.22)
            SpringKeyframe(0, duration: 0.28, spring: .init(response: 0.34, dampingRatio: 0.55))
            LinearKeyframe(0, duration: 1.40)
        }
        KeyframeTrack(\.legFrontShin) {
            LinearKeyframe(0, duration: 0.46)
            CubicKeyframe(74, duration: 0.24)
            LinearKeyframe(74, duration: 0.40)
            CubicKeyframe(20, duration: 0.22)
            SpringKeyframe(0, duration: 0.28, spring: .init(response: 0.34, dampingRatio: 0.55))
            LinearKeyframe(0, duration: 1.40)
        }
        KeyframeTrack(\.legBackThigh) {
            LinearKeyframe(0, duration: 0.52)
            CubicKeyframe(-48, duration: 0.24)
            LinearKeyframe(-48, duration: 0.34)
            CubicKeyframe(-12, duration: 0.22)
            SpringKeyframe(0, duration: 0.28, spring: .init(response: 0.36, dampingRatio: 0.55))
            LinearKeyframe(0, duration: 1.40)
        }
        KeyframeTrack(\.legBackShin) {
            LinearKeyframe(0, duration: 0.52)
            CubicKeyframe(62, duration: 0.24)
            LinearKeyframe(62, duration: 0.34)
            CubicKeyframe(16, duration: 0.22)
            SpringKeyframe(0, duration: 0.28, spring: .init(response: 0.36, dampingRatio: 0.55))
            LinearKeyframe(0, duration: 1.40)
        }
        KeyframeTrack(\.throwArmUpper) {
            LinearKeyframe(0, duration: 0.46)
            CubicKeyframe(-54, duration: 0.24)        // arms in for the spin
            LinearKeyframe(-54, duration: 0.40)
            SpringKeyframe(0, duration: 0.36, spring: .init(response: 0.32, dampingRatio: 0.55))
            LinearKeyframe(0, duration: 1.54)
        }
        KeyframeTrack(\.offArmUpper) {
            LinearKeyframe(0, duration: 0.46)
            CubicKeyframe(48, duration: 0.24)
            LinearKeyframe(48, duration: 0.40)
            SpringKeyframe(0, duration: 0.36, spring: .init(response: 0.32, dampingRatio: 0.55))
            LinearKeyframe(0, duration: 1.54)
        }
        // Ribbons trail the whole rotation and are still catching up on landing.
        KeyframeTrack(\.ribbonNear) {
            LinearKeyframe(-22, duration: 0.46)
            CubicKeyframe(58, duration: 0.50)
            CubicKeyframe(-30, duration: 0.36)
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.42, dampingRatio: 0.30))
            LinearKeyframe(0, duration: 1.28)
        }
        KeyframeTrack(\.ribbonFar) {
            LinearKeyframe(-16, duration: 0.52)
            CubicKeyframe(48, duration: 0.50)
            CubicKeyframe(-24, duration: 0.36)
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.46, dampingRatio: 0.28))
            LinearKeyframe(0, duration: 1.22)
        }
        KeyframeTrack(\.sashTail) {
            LinearKeyframe(-14, duration: 0.46)
            CubicKeyframe(42, duration: 0.50)
            CubicKeyframe(-18, duration: 0.36)
            SpringKeyframe(0, duration: 0.42, spring: .init(response: 0.52, dampingRatio: 0.32))
            LinearKeyframe(0, duration: 1.26)
        }
        // Smoke on the launch and again on the landing.
        KeyframeTrack(\.smokeOpacity) {
            LinearKeyframe(0, duration: 0.46)
            LinearKeyframe(0.6, duration: 0.10)
            LinearKeyframe(0, duration: 0.26)
            LinearKeyframe(0, duration: 0.50)
            LinearKeyframe(0.7, duration: 0.14)
            LinearKeyframe(0, duration: 0.34)
            LinearKeyframe(0, duration: 1.20)
        }
        KeyframeTrack(\.smokeScale) {
            LinearKeyframe(0.5, duration: 0.46)
            CubicKeyframe(0.85, duration: 0.36)
            LinearKeyframe(0.5, duration: 0.50)
            CubicKeyframe(0.95, duration: 0.48)
            LinearKeyframe(0.95, duration: 1.20)
        }
        // A spark of satisfaction on the landing, then back to neutral.
        KeyframeTrack(\.sparkOpacity) {
            LinearKeyframe(0, duration: 1.32)
            LinearKeyframe(1, duration: 0.14)
            LinearKeyframe(1, duration: 1.16)
            LinearKeyframe(0, duration: 0.38)
        }
        KeyframeTrack(\.eyesScaleY) {
            LinearKeyframe(1, duration: 0.46)
            CubicKeyframe(0.55, duration: 0.24)       // squeezed shut through the spin
            LinearKeyframe(0.55, duration: 0.62)
            SpringKeyframe(1, duration: 0.30, spring: .init(response: 0.30, dampingRatio: 0.55))
            LinearKeyframe(1, duration: 1.38)
        }
    }
}
