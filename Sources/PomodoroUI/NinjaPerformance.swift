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
            Hold.moving(0, duration: 1.44, drift: 1.4)
            CubicKeyframe(-12, duration: 0.10)        // small hop before the drop
            CubicKeyframe(200, duration: 0.26)
        }
        // Three puffs, 40ms apart, fast attack, 0.35s fade. The exit burst peaks
        // 0.1s earlier than before so it is already there when he drops.
        KeyframeTrack(\.smokeOpacity) {
            LinearKeyframe(0.7, duration: 0.04)      // burst covers the arrival
            LinearKeyframe(0.55, duration: 0.16)
            LinearKeyframe(0, duration: 0.26)
            LinearKeyframe(0, duration: 1.24)
            LinearKeyframe(0.7, duration: 0.06)       // and the exit
            LinearKeyframe(0, duration: 0.35)
            LinearKeyframe(0, duration: 0.09)
        }
        KeyframeTrack(\.smokeOpacityB) {
            LinearKeyframe(0, duration: 0.04)
            LinearKeyframe(0.7, duration: 0.04)
            LinearKeyframe(0.5, duration: 0.14)
            LinearKeyframe(0, duration: 0.24)
            LinearKeyframe(0, duration: 1.24)
            LinearKeyframe(0, duration: 0.04)
            LinearKeyframe(0.7, duration: 0.06)
            LinearKeyframe(0, duration: 0.35)
            LinearKeyframe(0, duration: 0.05)
        }
        KeyframeTrack(\.smokeOpacityC) {
            LinearKeyframe(0, duration: 0.08)
            LinearKeyframe(0.7, duration: 0.04)
            LinearKeyframe(0.45, duration: 0.14)
            LinearKeyframe(0, duration: 0.22)
            LinearKeyframe(0, duration: 1.24)
            LinearKeyframe(0, duration: 0.08)
            LinearKeyframe(0.7, duration: 0.06)
            LinearKeyframe(0, duration: 0.35)
            LinearKeyframe(0, duration: 0.01)
        }
        KeyframeTrack(\.smokeScale) {
            LinearKeyframe(0.5, duration: 0.02)
            CubicKeyframe(0.95, duration: 0.30)
            Hold.moving(0.95, duration: 1.38, drift: 0.014)
            CubicKeyframe(0.6, duration: 0.10)
            CubicKeyframe(0.9, duration: 0.40)
        }
        KeyframeTrack(\.smokeScaleB) {
            LinearKeyframe(0.5, duration: 0.06)
            CubicKeyframe(0.9, duration: 0.30)
            Hold.moving(0.9, duration: 1.34, drift: 0.014)
            CubicKeyframe(0.55, duration: 0.14)
            CubicKeyframe(0.85, duration: 0.36)
        }
        KeyframeTrack(\.smokeScaleC) {
            LinearKeyframe(0.5, duration: 0.10)
            CubicKeyframe(0.9, duration: 0.30)
            Hold.moving(0.9, duration: 1.30, drift: 0.014)
            CubicKeyframe(0.55, duration: 0.18)
            CubicKeyframe(0.85, duration: 0.32)
        }
        // Wind up behind the shoulder, then whip forward and stay extended.
        KeyframeTrack(\.throwArmUpper) {
            LinearKeyframe(-48, duration: 0.24)       // already cocked on arrival
            CubicKeyframe(-58, duration: 0.14)
            SpringKeyframe(46, duration: 0.14, spring: .init(response: 0.22, dampingRatio: 0.52))
            SpringKeyframe(38, duration: 0.12, spring: .init(response: 0.24, dampingRatio: 0.62))
            CubicKeyframe(28, duration: 0.25)         // recoil after the release
            Hold.moving(28, duration: 0.15, drift: 1.0)
            CubicKeyframe(-20, duration: 0.32)        // then pulls into a guard cross
            Hold.breathing(-20, duration: 0.46, drift: 3.0)
            CubicKeyframe(0, duration: 0.38)
        }
        KeyframeTrack(\.throwForearm) {
            LinearKeyframe(-30, duration: 0.24)
            CubicKeyframe(-44, duration: 0.14)
            SpringKeyframe(58, duration: 0.26, spring: .init(response: 0.22, dampingRatio: 0.55))
            Hold.moving(58, duration: 0.40, drift: 2.0)
            CubicKeyframe(70, duration: 0.34)         // forearm lags the shoulder into the guard
            Hold.breathing(70, duration: 0.44, drift: 3.0)
            CubicKeyframe(0, duration: 0.38)
        }
        // Spins through the throw, then vanishes — it left his hand.
        KeyframeTrack(\.shuriken) {
            LinearKeyframe(0, duration: 0.52)
            LinearKeyframe(1080, duration: 0.35)      // spins through the flight
            Hold.moving(1080, duration: 1.33, drift: 1.8)
        }
        // Leaves the hand at the release (0.52s), flies about 90 units forward-up on
        // an arc over 0.35s, then fades out near the end of the flight.
        KeyframeTrack(\.shurikenFlyX) {
            LinearKeyframe(0, duration: 0.52)
            CubicKeyframe(-78, duration: 0.35)
            LinearKeyframe(0, duration: 0.02)
            LinearKeyframe(0, duration: 1.31)
        }
        KeyframeTrack(\.shurikenFlyY) {
            LinearKeyframe(0, duration: 0.52)
            CubicKeyframe(-52, duration: 0.20)
            CubicKeyframe(-46, duration: 0.15)
            LinearKeyframe(0, duration: 0.02)
            LinearKeyframe(0, duration: 1.31)
        }
        KeyframeTrack(\.shurikenOpacity) {
            LinearKeyframe(1, duration: 0.77)
            LinearKeyframe(0, duration: 0.12)
            LinearKeyframe(0, duration: 0.93)
            LinearKeyframe(1, duration: 0.38)
        }
        // Body leads, the ninjato drags behind the lean by a few degrees.
        KeyframeTrack(\.ninjato) {
            LinearKeyframe(0, duration: 0.30)
            CubicKeyframe(3, duration: 0.26)
            CubicKeyframe(-1.5, duration: 0.30)
            Hold.moving(0, duration: 0.96, drift: 1.0)
            CubicKeyframe(-2, duration: 0.20)
            CubicKeyframe(0, duration: 0.18)
        }
        KeyframeTrack(\.eyesOffsetX) {
            LinearKeyframe(0, duration: 0.24)
            CubicKeyframe(-2.5, duration: 0.16)       // eyes follow the throw (screen left)
            Hold.moving(-2.5, duration: 1.42, drift: 0.3)
            CubicKeyframe(0, duration: 0.38)
        }
        KeyframeTrack(\.legFrontThigh) {
            LinearKeyframe(-14, duration: 0.24)
            CubicKeyframe(-6, duration: 0.30)
            Hold.moving(-6, duration: 1.28, drift: 1.2)
            CubicKeyframe(0, duration: 0.38)
        }
        KeyframeTrack(\.legFrontShin) {
            LinearKeyframe(18, duration: 0.24)
            CubicKeyframe(8, duration: 0.30)
            Hold.moving(8, duration: 1.28, drift: 1.2)
            CubicKeyframe(0, duration: 0.38)
        }
        KeyframeTrack(\.legBackThigh) {
            LinearKeyframe(8, duration: 0.24)
            CubicKeyframe(4, duration: 0.34)
            Hold.moving(4, duration: 1.24, drift: 1.0)
            CubicKeyframe(0, duration: 0.38)
        }
        KeyframeTrack(\.torso) {
            LinearKeyframe(8, duration: 0.24)         // coiled away from the throw
            CubicKeyframe(-10, duration: 0.28)        // uncoils into it
            Hold.breathing(-10, duration: 1.3, drift: 1.8)
            CubicKeyframe(0, duration: 0.38)
        }
        KeyframeTrack(\.head) {
            LinearKeyframe(0, duration: 0.38)
            CubicKeyframe(5, duration: 0.14)          // eyes down the line of the throw
            Hold.breathing(5, duration: 1.3, drift: 1.8)
            CubicKeyframe(0, duration: 0.38)
        }
        KeyframeTrack(\.eyesScaleY) {
            LinearKeyframe(1, duration: 0.38)
            CubicKeyframe(0.62, duration: 0.12)       // narrows — taking aim
            Hold.moving(0.62, duration: 1.32, drift: 0.014)
            CubicKeyframe(1, duration: 0.38)
        }
        // Ribbons stream opposite the body, 70ms late, and never fully settle.
        KeyframeTrack(\.ribbonNear) {
            LinearKeyframe(-34, duration: 0.30)
            SpringKeyframe(12, duration: 0.22, spring: .init(response: 0.42, dampingRatio: 0.32))
            SpringKeyframe(0, duration: 0.26, spring: .init(response: 0.42, dampingRatio: 0.32))
            Hold.moving(0, duration: 1.14, drift: 1.8)
            CubicKeyframe(-26, duration: 0.28)
        }
        KeyframeTrack(\.ribbonFar) {
            LinearKeyframe(-26, duration: 0.36)
            SpringKeyframe(9, duration: 0.22, spring: .init(response: 0.46, dampingRatio: 0.30))
            SpringKeyframe(0, duration: 0.26, spring: .init(response: 0.46, dampingRatio: 0.30))
            Hold.moving(0, duration: 1.08, drift: 1.8)
            CubicKeyframe(-20, duration: 0.28)
        }
        KeyframeTrack(\.sashTail) {
            LinearKeyframe(-18, duration: 0.32)
            SpringKeyframe(0, duration: 0.34, spring: .init(response: 0.50, dampingRatio: 0.36))
            Hold.moving(0, duration: 1.54, drift: 1.8)
        }
        KeyframeTrack(\.offArmUpper) {
            LinearKeyframe(-14, duration: 0.24)
            SpringKeyframe(16, duration: 0.28, spring: .init(response: 0.30, dampingRatio: 0.58))
            Hold.moving(16, duration: 0.56, drift: 1.5)
            CubicKeyframe(-24, duration: 0.34)        // off arm joins the guard
            Hold.breathing(-24, duration: 0.40, drift: 3.0)
            CubicKeyframe(0, duration: 0.38)
        }
        // The off arm's elbow, which until now never bent in any performance — the
        // whole limb swung from the shoulder as one rigid stick. It trails the upper
        // arm by ~80ms and overshoots it, which is what an unweighted forearm does
        // when the shoulder stops: the elbow keeps going, then catches up.
        KeyframeTrack(\.offForearm) {
            LinearKeyframe(-22, duration: 0.30)
            SpringKeyframe(30, duration: 0.30, spring: .init(response: 0.34, dampingRatio: 0.48))
            SpringKeyframe(21, duration: 0.20, spring: .init(response: 0.30, dampingRatio: 0.60))
            Hold.moving(21, duration: 1.02, drift: 2.2)
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
            SpringKeyframe(40, duration: 0.42, spring: .init(response: 0.48, dampingRatio: 0.82))
            Hold.moving(40, duration: 0.30, drift: 0.8)
            CubicKeyframe(46, duration: 0.60)         // settles lower as he relaxes
            Hold.moving(46, duration: 1.1, drift: 1.4)
            CubicKeyframe(200, duration: 0.38)
        }
        KeyframeTrack(\.torso) {
            LinearKeyframe(0, duration: 0.42)
            CubicKeyframe(9, duration: 0.42)          // slouches sideways
            Hold.breathing(9, duration: 0.46, drift: 1.0)
            CubicKeyframe(9, duration: 0.14)
            CubicKeyframe(12, duration: 0.30)         // body counters the head drop
            CubicKeyframe(10, duration: 0.40)
            Hold.breathing(10, duration: 0.28, drift: 1.0)
            CubicKeyframe(0, duration: 0.38)
        }
        KeyframeTrack(\.head) {
            LinearKeyframe(0, duration: 0.50)
            CubicKeyframe(-12, duration: 0.40)        // tips against his shoulder
            Hold.moving(-12, duration: 0.40, drift: 1.0)
            CubicKeyframe(-4, duration: 0.14)         // jerks up as he nods off
            SpringKeyframe(-16, duration: 0.30, spring: .init(response: 0.30, dampingRatio: 0.35))
            CubicKeyframe(-9, duration: 0.40)         // half recovers
            Hold.moving(-9, duration: 0.28, drift: 1.0)
            CubicKeyframe(0, duration: 0.38)
        }
        // The ninjato sways 5 degrees behind the nod.
        KeyframeTrack(\.ninjato) {
            Hold.moving(0, duration: 1.44, drift: 0.8)
            CubicKeyframe(-5, duration: 0.38)
            CubicKeyframe(2, duration: 0.34)
            Hold.moving(0, duration: 0.26, drift: 0.8)
            Hold.moving(0, duration: 0.38, drift: 0.6)
        }
        KeyframeTrack(\.legFrontThigh) {
            LinearKeyframe(0, duration: 0.30)
            CubicKeyframe(-70, duration: 0.40)
            Hold.breathing(-70, duration: 1.72, drift: 1.5)
            CubicKeyframe(0, duration: 0.38)
        }
        KeyframeTrack(\.legFrontShin) {
            LinearKeyframe(0, duration: 0.34)
            CubicKeyframe(80, duration: 0.40)
            Hold.breathing(80, duration: 1.68, drift: 1.5)
            CubicKeyframe(0, duration: 0.38)
        }
        KeyframeTrack(\.legBackThigh) {
            LinearKeyframe(0, duration: 0.36)
            CubicKeyframe(20, duration: 0.40)
            Hold.moving(20, duration: 1.66, drift: 1.2)
            CubicKeyframe(0, duration: 0.38)
        }
        KeyframeTrack(\.legBackShin) {
            LinearKeyframe(0, duration: 0.38)
            CubicKeyframe(10, duration: 0.40)
            Hold.moving(10, duration: 1.64, drift: 1.0)
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
            Hold.moving(-10, duration: 1.54, drift: 1.8)
            CubicKeyframe(0, duration: 0.38)
        }
        KeyframeTrack(\.throwForearm) {
            LinearKeyframe(0, duration: 0.42)
            SpringKeyframe(-16, duration: 0.46, spring: .init(response: 0.62, dampingRatio: 0.70))
            Hold.moving(-16, duration: 1.54, drift: 1.8)
            CubicKeyframe(0, duration: 0.38)
        }
        KeyframeTrack(\.offArmUpper) {
            LinearKeyframe(0, duration: 0.42)
            SpringKeyframe(12, duration: 0.46, spring: .init(response: 0.60, dampingRatio: 0.72))
            Hold.moving(12, duration: 1.54, drift: 1.8)
            CubicKeyframe(0, duration: 0.38)
        }
        // Elbow gives out further than the shoulder does. Going slack is not the
        // whole arm rotating by one angle — it is the upper arm dropping a little
        // and the forearm folding a lot, which is the difference between a resting
        // limb and a mannequin's.
        KeyframeTrack(\.offForearm) {
            LinearKeyframe(0, duration: 0.46)
            SpringKeyframe(26, duration: 0.52, spring: .init(response: 0.66, dampingRatio: 0.66))
            Hold.breathing(26, duration: 1.44, drift: 2.4)
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
            CubicKeyframe(-72, duration: 0.30)        // launch
            Hold.moving(-72, duration: 0.22, drift: 1.0) // apex
            CubicKeyframe(4, duration: 0.34)          // fall
            SpringKeyframe(0, duration: 0.24, spring: .init(response: 0.26, dampingRatio: 0.55))
            Hold.moving(0, duration: 1.06, drift: 1.4)
            CubicKeyframe(200, duration: 0.38)
        }
        // One clean revolution, timed to complete just before he lands.
        KeyframeTrack(\.figureRotation) {
            LinearKeyframe(0, duration: 0.46)
            CubicKeyframe(-360, duration: 0.84)       // one ease-in-out turn
            Hold.moving(-360, duration: 1.70, drift: 1.8)
        }
        // Squash keeps volume: wider as he flattens.
        KeyframeTrack(\.figureScaleX) {
            LinearKeyframe(1, duration: 1.12)
            CubicKeyframe(1.08, duration: 0.18)
            SpringKeyframe(1.0, duration: 0.30, spring: .init(response: 0.28, dampingRatio: 0.50))
            Hold.moving(1.0, duration: 1.4, drift: 0.01)
        }
        KeyframeTrack(\.torso) {
            LinearKeyframe(0, duration: 0.30)
            CubicKeyframe(-14, duration: 0.16)        // arches at launch
            CubicKeyframe(-6, duration: 0.50)
            CubicKeyframe(8, duration: 0.34)          // folds into the landing
            SpringKeyframe(0, duration: 0.32, spring: .init(response: 0.30, dampingRatio: 0.50))
            Hold.breathing(0, duration: 1.38, drift: 1.2)
        }
        KeyframeTrack(\.eyesOffsetX) {
            LinearKeyframe(0, duration: 1.30)
            CubicKeyframe(1.5, duration: 0.12)
            Hold.moving(1.5, duration: 1.20, drift: 0.3)
            CubicKeyframe(0, duration: 0.38)
        }
        KeyframeTrack(\.figureScaleY) {
            LinearKeyframe(1, duration: 0.30)
            CubicKeyframe(0.84, duration: 0.16)       // load
            CubicKeyframe(1.10, duration: 0.16)       // stretch off the ground
            LinearKeyframe(1.0, duration: 0.50)
            CubicKeyframe(0.82, duration: 0.18)       // landing squash
            SpringKeyframe(1.0, duration: 0.30, spring: .init(response: 0.28, dampingRatio: 0.50))
            Hold.moving(1.0, duration: 1.4, drift: 0.014)
        }
        // Tucks on the way round, opens for the landing.
        KeyframeTrack(\.legFrontThigh) {
            LinearKeyframe(0, duration: 0.46)
            CubicKeyframe(-62, duration: 0.24)
            LinearKeyframe(-62, duration: 0.40)
            CubicKeyframe(-16, duration: 0.20)
            CubicKeyframe(-28, duration: 0.16)        // landing crouch
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.34, dampingRatio: 0.55))
            Hold.moving(0, duration: 1.24, drift: 1.8)
        }
        KeyframeTrack(\.legFrontShin) {
            LinearKeyframe(0, duration: 0.46)
            CubicKeyframe(74, duration: 0.24)
            LinearKeyframe(74, duration: 0.40)
            CubicKeyframe(20, duration: 0.20)
            CubicKeyframe(30, duration: 0.16)
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.34, dampingRatio: 0.55))
            Hold.moving(0, duration: 1.24, drift: 1.8)
        }
        KeyframeTrack(\.legBackThigh) {
            LinearKeyframe(0, duration: 0.52)
            CubicKeyframe(-48, duration: 0.24)
            LinearKeyframe(-48, duration: 0.34)
            CubicKeyframe(-12, duration: 0.22)
            CubicKeyframe(18, duration: 0.16)         // landing crouch
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.36, dampingRatio: 0.55))
            Hold.moving(0, duration: 1.22, drift: 1.8)
        }
        KeyframeTrack(\.legBackShin) {
            LinearKeyframe(0, duration: 0.52)
            CubicKeyframe(62, duration: 0.24)
            LinearKeyframe(62, duration: 0.34)
            CubicKeyframe(16, duration: 0.22)
            SpringKeyframe(0, duration: 0.28, spring: .init(response: 0.36, dampingRatio: 0.55))
            Hold.moving(0, duration: 1.4, drift: 1.8)
        }
        KeyframeTrack(\.throwArmUpper) {
            LinearKeyframe(0, duration: 0.46)
            CubicKeyframe(-54, duration: 0.24)        // arms in for the spin
            LinearKeyframe(-54, duration: 0.40)
            SpringKeyframe(0, duration: 0.36, spring: .init(response: 0.32, dampingRatio: 0.55))
            Hold.moving(0, duration: 1.54, drift: 1.8)
        }
        KeyframeTrack(\.offArmUpper) {
            LinearKeyframe(0, duration: 0.46)
            CubicKeyframe(48, duration: 0.24)
            LinearKeyframe(48, duration: 0.40)
            SpringKeyframe(0, duration: 0.36, spring: .init(response: 0.32, dampingRatio: 0.55))
            Hold.moving(0, duration: 1.54, drift: 1.8)
        }
        // Both elbows fold hard for the rotation and fling open on the landing.
        //
        // Tucking is the whole reason a backflip is possible — pulling mass toward
        // the axis is what lets the spin come round in time. With straight arms the
        // physics read as wrong even to someone who could not say why, and until now
        // neither forearm moved at all through the entire revolution.
        KeyframeTrack(\.throwForearm) {
            LinearKeyframe(0, duration: 0.46)
            CubicKeyframe(-72, duration: 0.22)        // snaps in ahead of the shoulder
            Hold.moving(-72, duration: 0.42, drift: 2.5)
            CubicKeyframe(-26, duration: 0.20)        // starts opening for the ground
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.30, dampingRatio: 0.48))
            Hold.moving(0, duration: 1.40, drift: 1.8)
        }
        KeyframeTrack(\.offForearm) {
            LinearKeyframe(0, duration: 0.50)
            CubicKeyframe(66, duration: 0.22)
            Hold.moving(66, duration: 0.38, drift: 2.5)
            CubicKeyframe(24, duration: 0.20)
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.32, dampingRatio: 0.46))
            Hold.moving(0, duration: 1.40, drift: 1.8)
        }
        // Ribbons trail the whole rotation and are still catching up on landing.
        KeyframeTrack(\.ribbonNear) {
            LinearKeyframe(-22, duration: 0.46)
            CubicKeyframe(58, duration: 0.50)
            CubicKeyframe(-30, duration: 0.36)
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.42, dampingRatio: 0.30))
            Hold.moving(0, duration: 1.28, drift: 1.8)
        }
        KeyframeTrack(\.ribbonFar) {
            LinearKeyframe(-16, duration: 0.52)
            CubicKeyframe(48, duration: 0.50)
            CubicKeyframe(-24, duration: 0.36)
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.46, dampingRatio: 0.28))
            Hold.moving(0, duration: 1.22, drift: 1.8)
        }
        KeyframeTrack(\.sashTail) {
            LinearKeyframe(-14, duration: 0.46)
            CubicKeyframe(42, duration: 0.50)
            CubicKeyframe(-18, duration: 0.36)
            SpringKeyframe(0, duration: 0.42, spring: .init(response: 0.52, dampingRatio: 0.32))
            Hold.moving(0, duration: 1.26, drift: 1.8)
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
            Hold.moving(0.95, duration: 1.2, drift: 0.014)
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
            Hold.moving(1, duration: 1.38, drift: 0.014)
        }
    }
}
