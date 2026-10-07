import PomodoroCore
import SwiftUI

/// The ninja's three performances.
///
/// Same conventions as `SamuraiPerformance`: positive rotation is clockwise,
/// `emergence` counts design units behind the pill edge (200 hidden, 0 risen,
/// negative overshoot). He faces screen left, so forward is a negative torso angle
/// and the throw arm is on the left.
///
/// Every cue starts with a smoke APPEAR and ends with a smoke VANISH: he is never
/// lowered behind the bar. `figureOpacity` fades the body while `figureScale*`
/// shrinks it to 0.9 and three smoke puffs, each 0.95 opaque at the peak, cover him,
/// so the swap reads as a teleport. `emergence` holds his standing (or seated)
/// height for the whole cue and only drops to 200 on the last 10 ms.
///
/// Elbow and knee ranges. The drawn rest pose is already slightly bent, so these are
/// in pose degrees rather than flexion: throw forearm -111...+29, off forearm
/// -48...+92, front shin -105...+25, back shin -133...-3. Nothing below crosses them.
public enum NinjaPerformance {

    public static func preferredEdge(for cue: CharacterCue) -> StageEdge { .top }

    /// All three cues play in front of the pill: he appears in smoke over it, sits on
    /// its edge for the nap and lands on it after the flip, so there is no reason to
    /// mask his legs behind the glass.
    public static func comesForward(for cue: CharacterCue) -> Bool { true }

    public static func duration(for cue: CharacterCue) -> Double {
        switch cue {
        case .focusStart: 2.20
        case .breakStart: 2.80
        case .longBreak: 3.00
        }
    }

    // MARK: - focusStart · "Strike" (2.2s)

    /// Smoke bursts, he is suddenly there crouched, rises, winds the shuriken back,
    /// whips it out (released at 0.70s) and holds the follow-through. A nod, then a
    /// second smoke puff swallows him. The star is a separate flight part so the
    /// recoiling hand cannot drag it.
    @KeyframesBuilder<NinjaPose>
    public static var shurikenThrow: some Keyframes<NinjaPose> {
        shurikenThrowBody
        shurikenThrowCloth
        shurikenThrowSmoke
    }

    /// shurikenThrow: the body: whole-figure transforms, torso, head, arms and legs.
    @KeyframesBuilder<NinjaPose>
    static var shurikenThrowBody: some Keyframes<NinjaPose> {
        KeyframeTrack(\.emergence) {
            LinearKeyframe(0, duration: 0.001)
            LinearKeyframe(0, duration: 2.189)
            LinearKeyframe(200, duration: 0.01)
        }
        KeyframeTrack(\.figureOpacity) {
            LinearKeyframe(0, duration: 0.001)
            LinearKeyframe(0, duration: 0.119)
            LinearKeyframe(1, duration: 0.08)
            LinearKeyframe(1, duration: 1.32)
            LinearKeyframe(0, duration: 0.24)
            LinearKeyframe(0, duration: 0.44)
        }
        KeyframeTrack(\.figureScaleX) {
            LinearKeyframe(0.9, duration: 0.001)
            LinearKeyframe(0.9, duration: 0.139)
            CubicKeyframe(1.05, duration: 0.12)   // crouch widens
            LinearKeyframe(1.05, duration: 0.08)
            CubicKeyframe(0.98, duration: 0.1)   // stretches as he rises
            CubicKeyframe(1.005, duration: 0.12)
            CubicKeyframe(1, duration: 0.1)
            Hold.moving(1, duration: 0.86, drift: 0.008)
            CubicKeyframe(0.9, duration: 0.24)   // shrinks inside the smoke
            LinearKeyframe(0.9, duration: 0.44)
        }
        KeyframeTrack(\.figureScaleY) {
            LinearKeyframe(0.9, duration: 0.001)
            LinearKeyframe(0.8, duration: 0.139)
            CubicKeyframe(0.88, duration: 0.1)   // appears crouched
            LinearKeyframe(0.88, duration: 0.07)
            CubicKeyframe(1.05, duration: 0.11)   // rises, overshoots
            CubicKeyframe(0.995, duration: 0.12)
            CubicKeyframe(1, duration: 0.12)
            Hold.breathing(1, duration: 0.86, drift: 0.012)
            CubicKeyframe(0.9, duration: 0.24)
            LinearKeyframe(0.9, duration: 0.44)
        }
        KeyframeTrack(\.torso) {
            LinearKeyframe(-3, duration: 0.001)
            CubicKeyframe(-5, duration: 0.299, startVelocity: 0)   // crouch, lean in
            CubicKeyframe(0, duration: 0.12)
            CubicKeyframe(10, duration: 0.2)   // turns back to wind up
            CubicKeyframe(-12, duration: 0.12)   // snaps forward
            Hold.breathing(-12, duration: 0.56, drift: 1.6)
            CubicKeyframe(-3, duration: 0.2)
            CubicKeyframe(0, duration: 0.26)
            Hold.moving(0, duration: 0.44, drift: 1)
        }
        KeyframeTrack(\.head) {
            LinearKeyframe(0, duration: 0.001)
            LinearKeyframe(0, duration: 0.399)
            CubicKeyframe(3, duration: 0.22)
            CubicKeyframe(-3, duration: 0.14)
            Hold.breathing(-3, duration: 0.54, drift: 1)
            CubicKeyframe(-9, duration: 0.08)   // nod
            CubicKeyframe(0, duration: 0.12)
            Hold.moving(0, duration: 0.7, drift: 0.8)
        }
        KeyframeTrack(\.throwArmUpper) {
            LinearKeyframe(-6, duration: 0.001)
            CubicKeyframe(-12, duration: 0.299, startVelocity: 0)
            CubicKeyframe(-10, duration: 0.1)   // tucked
            CubicKeyframe(-58, duration: 0.22)   // winds back
            CubicKeyframe(96, duration: 0.08)   // whips out, release
            CubicKeyframe(104, duration: 0.08)
            CubicKeyframe(92, duration: 0.52)   // relaxes 10
            CubicKeyframe(18, duration: 0.2)   // lowers
            CubicKeyframe(6, duration: 0.26)
            Hold.moving(6, duration: 0.44, drift: 1)
        }
        KeyframeTrack(\.throwForearm) {
            LinearKeyframe(-75, duration: 0.001)
            CubicKeyframe(-80, duration: 0.299, startVelocity: 0)
            CubicKeyframe(-75, duration: 0.1)
            CubicKeyframe(-61, duration: 0.22)   // elbow folded 90
            LinearKeyframe(-61, duration: 0.02)   // folded while the shoulder fires
            CubicKeyframe(22, duration: 0.06, startVelocity: 0)   // unfolds last, nearly straight
            CubicKeyframe(20, duration: 0.08)
            CubicKeyframe(12, duration: 0.52)
            CubicKeyframe(-35, duration: 0.2)
            CubicKeyframe(-10, duration: 0.26)
            Hold.moving(-10, duration: 0.44, drift: 1)
        }
        KeyframeTrack(\.offArmUpper) {
            LinearKeyframe(16, duration: 0.001)
            CubicKeyframe(22, duration: 0.299, startVelocity: 0)
            CubicKeyframe(20, duration: 0.1)   // guard
            CubicKeyframe(34, duration: 0.22)   // comes forward for balance
            CubicKeyframe(-32, duration: 0.12)   // swings back
            CubicKeyframe(-24, duration: 0.56)
            CubicKeyframe(-8, duration: 0.2)
            CubicKeyframe(0, duration: 0.26)
            Hold.moving(0, duration: 0.44, drift: 1)
        }
        KeyframeTrack(\.offForearm) {
            LinearKeyframe(60, duration: 0.001)
            CubicKeyframe(70, duration: 0.299, startVelocity: 0)
            CubicKeyframe(66, duration: 0.1)
            CubicKeyframe(52, duration: 0.22)
            CubicKeyframe(6, duration: 0.12)
            CubicKeyframe(14, duration: 0.56)
            CubicKeyframe(22, duration: 0.2)
            CubicKeyframe(8, duration: 0.26)
            Hold.moving(8, duration: 0.44, drift: 1)
        }
        KeyframeTrack(\.legFrontThigh) {
            LinearKeyframe(30, duration: 0.001)
            CubicKeyframe(32, duration: 0.259, startVelocity: 0)   // crouched on arrival
            CubicKeyframe(2, duration: 0.14)   // straightens
            CubicKeyframe(14, duration: 0.22)   // front knee bends
            CubicKeyframe(20, duration: 0.12)   // weight onto the front foot
            CubicKeyframe(16, duration: 0.56)
            CubicKeyframe(4, duration: 0.22)
            Hold.moving(4, duration: 0.68, drift: 1)
        }
        KeyframeTrack(\.legFrontShin) {
            LinearKeyframe(-45, duration: 0.001)
            CubicKeyframe(-47, duration: 0.259, startVelocity: 0)
            CubicKeyframe(-3, duration: 0.14)
            CubicKeyframe(-26, duration: 0.22)
            CubicKeyframe(-36, duration: 0.12)
            CubicKeyframe(-28, duration: 0.56)
            CubicKeyframe(-6, duration: 0.22)
            Hold.moving(-6, duration: 0.68, drift: 1)
        }
        KeyframeTrack(\.legBackThigh) {
            LinearKeyframe(22, duration: 0.001)
            CubicKeyframe(24, duration: 0.259, startVelocity: 0)
            CubicKeyframe(0, duration: 0.14)
            CubicKeyframe(-6, duration: 0.22)
            CubicKeyframe(-12, duration: 0.12)   // pushes off
            CubicKeyframe(-8, duration: 0.56)
            CubicKeyframe(0, duration: 0.22)
            Hold.moving(0, duration: 0.68, drift: 1)
        }
        KeyframeTrack(\.legBackShin) {
            LinearKeyframe(-62.4, duration: 0.001)
            CubicKeyframe(-65.3, duration: 0.259, startVelocity: 0)
            CubicKeyframe(-7.4, duration: 0.14)
            CubicKeyframe(-21.4, duration: 0.22)
            CubicKeyframe(-21.2, duration: 0.12)
            CubicKeyframe(-20.7, duration: 0.56)
            CubicKeyframe(-11.7, duration: 0.22)
            Hold.moving(-11.7, duration: 0.68, drift: 1)
        }
    }

    /// shurikenThrow: eyes, ribbons, sash, sword and the thrown star.
    @KeyframesBuilder<NinjaPose>
    static var shurikenThrowCloth: some Keyframes<NinjaPose> {
        KeyframeTrack(\.eyesScaleY) {
            LinearKeyframe(1, duration: 0.4)
            CubicKeyframe(0.62, duration: 0.12)   // eyes narrow on the target
            Hold.moving(0.62, duration: 0.78, drift: 0.01)
            CubicKeyframe(1, duration: 0.16)
            Hold.still(1, duration: 0.74)
        }
        KeyframeTrack(\.eyesOffsetX) {
            LinearKeyframe(0, duration: 0.4)
            CubicKeyframe(-2.2, duration: 0.12)
            Hold.moving(-2.2, duration: 0.78, drift: 0.2)
            CubicKeyframe(0, duration: 0.16)
            Hold.still(0, duration: 0.74)
        }
        KeyframeTrack(\.shuriken) {
            LinearKeyframe(0, duration: 0.7)
            LinearKeyframe(0, duration: 0.001)
            LinearKeyframe(1130, duration: 0.519)   // spins three turns in flight
            LinearKeyframe(0, duration: 0.001)   // reset while invisible
            Hold.moving(0, duration: 0.979, drift: 2)
        }
        KeyframeTrack(\.shurikenOpacity) {
            LinearKeyframe(1, duration: 0.7)
            LinearKeyframe(0, duration: 0.001)
            LinearKeyframe(0, duration: 1.499)
        }
        KeyframeTrack(\.shurikenFlyOpacity) {
            LinearKeyframe(0, duration: 0.7)
            LinearKeyframe(1, duration: 0.001)
            LinearKeyframe(1, duration: 0.399)
            LinearKeyframe(0, duration: 0.12)
            LinearKeyframe(0, duration: 0.98)
        }
        KeyframeTrack(\.shurikenFlyX) {
            LinearKeyframe(-59.8, duration: 0.7)
            CubicKeyframe(-139.8, duration: 0.5, startVelocity: -380, endVelocity: 0)   // leaves the hand fast and slows, 80 units
            LinearKeyframe(-139.8, duration: 1)
        }
        KeyframeTrack(\.shurikenFlyY) {
            LinearKeyframe(-58.5, duration: 0.7)
            CubicKeyframe(-92.5, duration: 0.22, startVelocity: -260, endVelocity: 0)   // arcs up
            CubicKeyframe(-82.5, duration: 0.28, startVelocity: 0)   // and starts to fall
            LinearKeyframe(-82.5, duration: 1)
        }
        KeyframeTrack(\.ninjato) {
            LinearKeyframe(0, duration: 0.001)
            CubicKeyframe(2, duration: 0.299, startVelocity: 0)
            CubicKeyframe(-2, duration: 0.26)
            CubicKeyframe(4, duration: 0.24)
            CubicKeyframe(-2, duration: 0.4)
            CubicKeyframe(2, duration: 0.3)
            Hold.moving(0, duration: 0.7, drift: 1)
        }
        KeyframeTrack(\.ribbonNear) {
            LinearKeyframe(-20, duration: 0.001)
            CubicKeyframe(-34, duration: 0.199, startVelocity: 0)   // trail upward as he arrives
            SpringKeyframe(10, duration: 0.2, spring: .init(response: 0.42, dampingRatio: 0.34))
            SpringKeyframe(-4, duration: 0.22, spring: .init(response: 0.42, dampingRatio: 0.34))
            CubicKeyframe(24, duration: 0.14)   // lag behind the whip
            SpringKeyframe(-10, duration: 0.24, spring: .init(response: 0.4, dampingRatio: 0.36))
            CubicKeyframe(6, duration: 0.3)
            CubicKeyframe(-3, duration: 0.22)
            Hold.moving(0, duration: 0.68, drift: 1.5)
        }
        KeyframeTrack(\.ribbonFar) {
            LinearKeyframe(-14, duration: 0.001)
            CubicKeyframe(-28, duration: 0.239, startVelocity: 0)
            SpringKeyframe(8, duration: 0.2, spring: .init(response: 0.46, dampingRatio: 0.32))
            SpringKeyframe(-3, duration: 0.22, spring: .init(response: 0.46, dampingRatio: 0.32))
            CubicKeyframe(20, duration: 0.14)
            SpringKeyframe(-8, duration: 0.24, spring: .init(response: 0.42, dampingRatio: 0.36))
            CubicKeyframe(5, duration: 0.3)
            CubicKeyframe(-2, duration: 0.22)
            Hold.moving(0, duration: 0.64, drift: 1.5)
        }
        KeyframeTrack(\.sashTail) {
            LinearKeyframe(-18, duration: 0.001)
            SpringKeyframe(0, duration: 0.399, spring: .init(response: 0.5, dampingRatio: 0.36), startVelocity: 0)
            CubicKeyframe(6, duration: 0.22)
            CubicKeyframe(-14, duration: 0.14)
            SpringKeyframe(2, duration: 0.34, spring: .init(response: 0.5, dampingRatio: 0.38))
            CubicKeyframe(-4, duration: 0.4)
            Hold.moving(0, duration: 0.7, drift: 1.2)
        }
    }

    /// shurikenThrow: the smoke puffs that cover the appear and the vanish.
    @KeyframesBuilder<NinjaPose>
    static var shurikenThrowSmoke: some Keyframes<NinjaPose> {
        KeyframeTrack(\.smokeOpacity) {
            LinearKeyframe(0, duration: 0.001)
            LinearKeyframe(0.95, duration: 0.059)
            LinearKeyframe(0.95, duration: 0.14)
            LinearKeyframe(0, duration: 0.3)
            LinearKeyframe(0, duration: 0.96)
            LinearKeyframe(0.95, duration: 0.06)
            LinearKeyframe(0.95, duration: 0.18)
            LinearKeyframe(0, duration: 0.38)
            LinearKeyframe(0, duration: 0.12)
        }
        KeyframeTrack(\.smokeScale) {
            LinearKeyframe(0.6, duration: 0.001)
            CubicKeyframe(1.4, duration: 0.199, startVelocity: 0)   // burst grows
            CubicKeyframe(1.568, duration: 0.3)
            LinearKeyframe(0.6, duration: 0.958)
            CubicKeyframe(1.4, duration: 0.242)   // burst grows
            CubicKeyframe(1.568, duration: 0.38)
            Hold.moving(1.568, duration: 0.12, drift: 0.02)
        }
        KeyframeTrack(\.smokeOpacityB) {
            LinearKeyframe(0, duration: 0.001)
            LinearKeyframe(0, duration: 0.039)
            LinearKeyframe(0.95, duration: 0.06)
            LinearKeyframe(0.95, duration: 0.14)
            LinearKeyframe(0, duration: 0.3)
            LinearKeyframe(0, duration: 0.96)
            LinearKeyframe(0.95, duration: 0.06)
            LinearKeyframe(0.95, duration: 0.18)
            LinearKeyframe(0, duration: 0.38)
            LinearKeyframe(0, duration: 0.08)
        }
        KeyframeTrack(\.smokeScaleB) {
            LinearKeyframe(0.55, duration: 0.001)
            LinearKeyframe(0.55, duration: 0.037)
            CubicKeyframe(1.45, duration: 0.202, startVelocity: 0)   // burst grows
            CubicKeyframe(1.624, duration: 0.3)
            LinearKeyframe(0.55, duration: 0.958)
            CubicKeyframe(1.45, duration: 0.242)   // burst grows
            CubicKeyframe(1.624, duration: 0.38)
            Hold.moving(1.624, duration: 0.08, drift: 0.02)
        }
        KeyframeTrack(\.smokeOpacityC) {
            LinearKeyframe(0, duration: 0.001)
            LinearKeyframe(0, duration: 0.079)
            LinearKeyframe(0.95, duration: 0.06)
            LinearKeyframe(0.95, duration: 0.14)
            LinearKeyframe(0, duration: 0.3)
            LinearKeyframe(0, duration: 0.96)
            LinearKeyframe(0.95, duration: 0.06)
            LinearKeyframe(0.95, duration: 0.18)
            LinearKeyframe(0, duration: 0.38)
            LinearKeyframe(0, duration: 0.04)
        }
        KeyframeTrack(\.smokeScaleC) {
            LinearKeyframe(0.55, duration: 0.001)
            LinearKeyframe(0.55, duration: 0.077)
            CubicKeyframe(1.3, duration: 0.202)   // burst grows
            CubicKeyframe(1.456, duration: 0.3)
            LinearKeyframe(0.55, duration: 0.958)
            CubicKeyframe(1.3, duration: 0.242)   // burst grows
            CubicKeyframe(1.456, duration: 0.38)
            Hold.moving(1.456, duration: 0.04, drift: 0.02)
        }
    }

    // MARK: - breakStart · "Shadow nap" (2.8s)

    /// Appears in smoke already seated on the edge of the bar, one leg dangling and
    /// one tucked, leaning back on one hand. Eyes close, one slow breath, a sleep nod
    /// he catches, then one eye opens and he vanishes in smoke.
    @KeyframesBuilder<NinjaPose>
    public static var perch: some Keyframes<NinjaPose> {
        perchBody
        perchCloth
        perchSmoke
    }

    /// perch: the body: whole-figure transforms, torso, head, arms and legs.
    @KeyframesBuilder<NinjaPose>
    static var perchBody: some Keyframes<NinjaPose> {
        KeyframeTrack(\.emergence) {
            LinearKeyframe(29, duration: 0.001)
            CubicKeyframe(30, duration: 0.399, startVelocity: 0)
            CubicKeyframe(31.4, duration: 0.5)
            CubicKeyframe(31, duration: 1.3)
            LinearKeyframe(31, duration: 0.59)
            LinearKeyframe(200, duration: 0.01)
        }
        KeyframeTrack(\.figureOpacity) {
            LinearKeyframe(0, duration: 0.001)
            LinearKeyframe(0, duration: 0.099)
            LinearKeyframe(1, duration: 0.1)
            LinearKeyframe(1, duration: 2.02)
            LinearKeyframe(0, duration: 0.24)
            LinearKeyframe(0, duration: 0.34)
        }
        KeyframeTrack(\.figureScaleX) {
            LinearKeyframe(0.9, duration: 0.001)
            LinearKeyframe(0.9, duration: 0.119)
            CubicKeyframe(1.03, duration: 0.18)   // pops in
            CubicKeyframe(1, duration: 0.2)
            Hold.moving(1, duration: 1.72, drift: 0.006)
            CubicKeyframe(0.9, duration: 0.24)   // shrinks inside the smoke
            LinearKeyframe(0.9, duration: 0.34)
        }
        KeyframeTrack(\.figureScaleY) {
            LinearKeyframe(0.9, duration: 0.001)
            LinearKeyframe(0.9, duration: 0.119)
            CubicKeyframe(1.03, duration: 0.18)
            CubicKeyframe(1, duration: 0.2)
            Hold.moving(1, duration: 1.72, drift: 0.006)
            CubicKeyframe(0.9, duration: 0.24)
            LinearKeyframe(0.9, duration: 0.34)
        }
        KeyframeTrack(\.footPlant) {
            LinearKeyframe(0, duration: 0.001)
            LinearKeyframe(0, duration: 2.799)
        }
        KeyframeTrack(\.torso) {
            LinearKeyframe(2, duration: 0.001)
            LinearKeyframe(2, duration: 0.299)
            CubicKeyframe(8, duration: 0.6)   // leans back 8
            CubicKeyframe(9, duration: 0.4)
            CubicKeyframe(7, duration: 0.6)   // body counters the nod
            CubicKeyframe(5, duration: 0.3)
            CubicKeyframe(0, duration: 0.3)
            Hold.moving(0, duration: 0.3, drift: 1)
        }
        KeyframeTrack(\.head) {
            LinearKeyframe(0, duration: 0.001)
            LinearKeyframe(0, duration: 0.299)
            CubicKeyframe(10, duration: 0.4)   // head tips back
            CubicKeyframe(12, duration: 0.6)
            CubicKeyframe(-12, duration: 0.2)   // sleep nod, droops
            CubicKeyframe(6, duration: 0.12)   // catches it
            CubicKeyframe(4, duration: 0.28)
            CubicKeyframe(0, duration: 0.3)
            Hold.moving(0, duration: 0.6, drift: 0.8)
        }
        KeyframeTrack(\.breath) {
            LinearKeyframe(1, duration: 0.001)
            LinearKeyframe(1, duration: 0.999)
            CubicKeyframe(0.96, duration: 0.35)   // one slow breath out
            CubicKeyframe(1, duration: 0.5)
            Hold.moving(1, duration: 0.95, drift: 0.006)
        }
        KeyframeTrack(\.throwArmUpper) {
            LinearKeyframe(0, duration: 0.001)
            CubicKeyframe(-2, duration: 0.299, startVelocity: 0)
            CubicKeyframe(-8, duration: 0.5)   // front hand rests in his lap
            Hold.moving(-8, duration: 1.3, drift: 1.2)
            CubicKeyframe(-2, duration: 0.4)
            Hold.moving(-2, duration: 0.3, drift: 0.8)
        }
        KeyframeTrack(\.throwForearm) {
            LinearKeyframe(-2, duration: 0.001)
            CubicKeyframe(4, duration: 0.299, startVelocity: 0)
            CubicKeyframe(12, duration: 0.5)
            Hold.moving(12, duration: 1.3, drift: 1.5)
            CubicKeyframe(0, duration: 0.4)
            Hold.moving(0, duration: 0.3, drift: 0.8)
        }
        KeyframeTrack(\.offArmUpper) {
            LinearKeyframe(-4, duration: 0.001)
            CubicKeyframe(-5, duration: 0.299, startVelocity: 0)
            CubicKeyframe(-12, duration: 0.3)   // back hand props him up
            Hold.moving(-12, duration: 1.5, drift: 1.5)
            CubicKeyframe(-4, duration: 0.4)
            Hold.moving(-4, duration: 0.3, drift: 0.8)
        }
        KeyframeTrack(\.offForearm) {
            LinearKeyframe(-6, duration: 0.001)
            CubicKeyframe(-10, duration: 0.299, startVelocity: 0)
            CubicKeyframe(-22, duration: 0.3)
            Hold.moving(-22, duration: 1.5, drift: 2)
            CubicKeyframe(-10, duration: 0.4)
            Hold.moving(-10, duration: 0.3, drift: 0.8)
        }
        KeyframeTrack(\.legFrontThigh) {
            LinearKeyframe(70, duration: 0.001)
            CubicKeyframe(73.3, duration: 0.299, startVelocity: 0)   // front leg dangles
            Hold.breathing(73.3, duration: 1.8, drift: 1.2)
            CubicKeyframe(60, duration: 0.4)
            Hold.moving(60, duration: 0.3, drift: 1)
        }
        KeyframeTrack(\.legFrontShin) {
            LinearKeyframe(-60, duration: 0.001)
            CubicKeyframe(-64.8, duration: 0.299, startVelocity: 0)
            LinearKeyframe(-64.8, duration: 0.25)
            CubicKeyframe(-48, duration: 0.3)   // dangling leg swings once
            CubicKeyframe(-76, duration: 0.4)
            CubicKeyframe(-62, duration: 0.35)
            CubicKeyframe(-66, duration: 0.3)
            Hold.moving(-66, duration: 0.2, drift: 1.5)
            CubicKeyframe(-60, duration: 0.4)
            Hold.moving(-60, duration: 0.3, drift: 1)
        }
        KeyframeTrack(\.legBackThigh) {
            LinearKeyframe(80, duration: 0.001)
            CubicKeyframe(87, duration: 0.299, startVelocity: 0)   // back leg tucked
            Hold.breathing(87, duration: 1.8, drift: 1)
            CubicKeyframe(75, duration: 0.4)
            Hold.moving(75, duration: 0.3, drift: 1)
        }
        KeyframeTrack(\.legBackShin) {
            LinearKeyframe(-110, duration: 0.001)
            CubicKeyframe(-123, duration: 0.299, startVelocity: 0)
            Hold.moving(-123, duration: 1.8, drift: 2)
            CubicKeyframe(-110, duration: 0.4)
            Hold.moving(-110, duration: 0.3, drift: 1)
        }
    }

    /// perch: eyes, ribbons, sash, sword and the thrown star.
    @KeyframesBuilder<NinjaPose>
    static var perchCloth: some Keyframes<NinjaPose> {
        KeyframeTrack(\.alertOpacity) {
            LinearKeyframe(1, duration: 0.6)
            LinearKeyframe(0, duration: 0.1)   // eyes close
            LinearKeyframe(0, duration: 2.1)
        }
        KeyframeTrack(\.contentOpacity) {
            LinearKeyframe(0, duration: 0.6)
            LinearKeyframe(1, duration: 0.1)
            LinearKeyframe(1, duration: 2.1)
        }
        KeyframeTrack(\.leftEyeOpen) {
            LinearKeyframe(0, duration: 1.9)
            LinearKeyframe(1, duration: 0.15)   // one eye opens
            LinearKeyframe(1, duration: 0.75)
        }
        KeyframeTrack(\.shurikenOpacity) {
            LinearKeyframe(0, duration: 0.001)
            LinearKeyframe(0, duration: 2.799)
        }
        KeyframeTrack(\.ninjato) {
            LinearKeyframe(0, duration: 0.001)
            LinearKeyframe(0, duration: 0.299)
            CubicKeyframe(3, duration: 0.6)
            CubicKeyframe(-4, duration: 0.6)
            CubicKeyframe(2, duration: 0.2)
            CubicKeyframe(0, duration: 0.4)
            Hold.moving(0, duration: 0.7, drift: 0.8)
        }
        KeyframeTrack(\.ribbonNear) {
            LinearKeyframe(-20, duration: 0.001)
            SpringKeyframe(0, duration: 0.299, spring: .init(response: 0.5, dampingRatio: 0.4), startVelocity: 0)
            CubicKeyframe(7, duration: 0.6)
            CubicKeyframe(-4, duration: 0.6)
            CubicKeyframe(5, duration: 0.6)
            CubicKeyframe(-14, duration: 0.4)
            Hold.moving(0, duration: 0.3, drift: 1)
        }
        KeyframeTrack(\.ribbonFar) {
            LinearKeyframe(-14, duration: 0.001)
            SpringKeyframe(0, duration: 0.339, spring: .init(response: 0.52, dampingRatio: 0.4), startVelocity: 0)
            CubicKeyframe(5, duration: 0.62)
            CubicKeyframe(-3, duration: 0.6)
            CubicKeyframe(4, duration: 0.58)
            CubicKeyframe(-10, duration: 0.38)
            Hold.moving(0, duration: 0.28, drift: 1)
        }
        KeyframeTrack(\.sashTail) {
            LinearKeyframe(-10, duration: 0.001)
            CubicKeyframe(6, duration: 0.299, startVelocity: 0)
            CubicKeyframe(-5, duration: 0.6)
            CubicKeyframe(5, duration: 0.6)
            CubicKeyframe(-4, duration: 0.6)
            CubicKeyframe(0, duration: 0.4)
            Hold.moving(0, duration: 0.3, drift: 1)
        }
    }

    /// perch: the smoke puffs that cover the appear and the vanish.
    @KeyframesBuilder<NinjaPose>
    static var perchSmoke: some Keyframes<NinjaPose> {
        KeyframeTrack(\.smokeOpacity) {
            LinearKeyframe(0, duration: 0.001)
            LinearKeyframe(0.95, duration: 0.059)
            LinearKeyframe(0.95, duration: 0.12)
            LinearKeyframe(0, duration: 0.32)
            LinearKeyframe(0, duration: 1.68)
            LinearKeyframe(0.95, duration: 0.06)
            LinearKeyframe(0.95, duration: 0.14)
            LinearKeyframe(0, duration: 0.36)
            LinearKeyframe(0, duration: 0.06)
        }
        KeyframeTrack(\.smokeScale) {
            LinearKeyframe(0.6, duration: 0.001)
            CubicKeyframe(1.4, duration: 0.179, startVelocity: 0)   // burst grows
            CubicKeyframe(1.568, duration: 0.32)
            LinearKeyframe(0.6, duration: 1.678)
            CubicKeyframe(1.4, duration: 0.202)   // burst grows
            CubicKeyframe(1.568, duration: 0.36)
            Hold.moving(1.568, duration: 0.06, drift: 0.02)
        }
        KeyframeTrack(\.smokeOpacityB) {
            LinearKeyframe(0, duration: 0.001)
            LinearKeyframe(0, duration: 0.039)
            LinearKeyframe(0.95, duration: 0.06)
            LinearKeyframe(0.95, duration: 0.12)
            LinearKeyframe(0, duration: 0.32)
            LinearKeyframe(0, duration: 1.68)
            LinearKeyframe(0.95, duration: 0.06)
            LinearKeyframe(0.95, duration: 0.14)
            LinearKeyframe(0, duration: 0.36)
            LinearKeyframe(0, duration: 0.02)
        }
        KeyframeTrack(\.smokeScaleB) {
            LinearKeyframe(0.55, duration: 0.001)
            LinearKeyframe(0.55, duration: 0.037)
            CubicKeyframe(1.45, duration: 0.182, startVelocity: 0)   // burst grows
            CubicKeyframe(1.624, duration: 0.32)
            LinearKeyframe(0.55, duration: 1.678)
            CubicKeyframe(1.45, duration: 0.202)   // burst grows
            CubicKeyframe(1.624, duration: 0.36)
            Hold.moving(1.624, duration: 0.02, drift: 0.02)
        }
        KeyframeTrack(\.smokeOpacityC) {
            LinearKeyframe(0, duration: 0.001)
            LinearKeyframe(0, duration: 0.079)
            LinearKeyframe(0.95, duration: 0.06)
            LinearKeyframe(0.95, duration: 0.12)
            LinearKeyframe(0, duration: 0.32)
            LinearKeyframe(0, duration: 1.68)
            LinearKeyframe(0.95, duration: 0.06)
            LinearKeyframe(0.95, duration: 0.14)
            LinearKeyframe(0, duration: 0.34)
        }
        KeyframeTrack(\.smokeScaleC) {
            LinearKeyframe(0.55, duration: 0.001)
            LinearKeyframe(0.55, duration: 0.077)
            CubicKeyframe(1.3, duration: 0.182)   // burst grows
            CubicKeyframe(1.456, duration: 0.32)
            LinearKeyframe(0.55, duration: 1.678)
            CubicKeyframe(1.3, duration: 0.202)   // burst grows
            CubicKeyframe(1.456, duration: 0.33)
            Hold.moving(1.456, duration: 0.01, drift: 0.02)
        }
    }

    // MARK: - longBreak · "Backflip" (3.0s)

    /// Smoke, and he is standing. Deep crouch, launch, one clean backflip with the
    /// body tucked, a crouching landing with a dust puff, stand, a quick bow with the
    /// hands together, and a smoke vanish. The flip is on `figure` rather than `root`
    /// so it does not fight the emergence offset.
    @KeyframesBuilder<NinjaPose>
    public static var backflip: some Keyframes<NinjaPose> {
        backflipBody
        backflipCloth
        backflipSmoke
    }

    /// backflip: the body: whole-figure transforms, torso, head, arms and legs.
    @KeyframesBuilder<NinjaPose>
    static var backflipBody: some Keyframes<NinjaPose> {
        KeyframeTrack(\.emergence) {
            LinearKeyframe(0, duration: 0.001)
            LinearKeyframe(0, duration: 0.549)
            CubicKeyframe(-72, duration: 0.4, endVelocity: 0)   // launch
            CubicKeyframe(0, duration: 0.4, startVelocity: 0)   // lands
            LinearKeyframe(0, duration: 1.64)
            LinearKeyframe(200, duration: 0.01)
        }
        KeyframeTrack(\.figureOpacity) {
            LinearKeyframe(0, duration: 0.001)
            LinearKeyframe(0, duration: 0.099)
            LinearKeyframe(1, duration: 0.1)
            LinearKeyframe(1, duration: 2.02)
            LinearKeyframe(0, duration: 0.24)
            LinearKeyframe(0, duration: 0.54)
        }
        KeyframeTrack(\.figureScaleX) {
            LinearKeyframe(0.9, duration: 0.001)
            LinearKeyframe(0.9, duration: 0.119)
            CubicKeyframe(1.03, duration: 0.18)
            CubicKeyframe(1, duration: 0.1)
            CubicKeyframe(1.05, duration: 0.12)   // crouch
            CubicKeyframe(0.95, duration: 0.12)   // stretch off the ground
            CubicKeyframe(1, duration: 0.66)
            CubicKeyframe(1.08, duration: 0.08)   // landing squash
            SpringKeyframe(1, duration: 0.24, spring: .init(response: 0.3, dampingRatio: 0.5))
            Hold.moving(1, duration: 0.6, drift: 0.006)
            CubicKeyframe(0.9, duration: 0.24)
            LinearKeyframe(0.9, duration: 0.54)
        }
        KeyframeTrack(\.figureScaleY) {
            LinearKeyframe(0.9, duration: 0.001)
            LinearKeyframe(0.9, duration: 0.119)
            CubicKeyframe(1.03, duration: 0.18)
            CubicKeyframe(1, duration: 0.1)
            CubicKeyframe(0.9, duration: 0.12)   // deep crouch
            CubicKeyframe(1.1, duration: 0.12)   // stretch off the ground
            CubicKeyframe(1, duration: 0.66)
            CubicKeyframe(0.88, duration: 0.08)   // landing squash
            SpringKeyframe(1, duration: 0.24, spring: .init(response: 0.3, dampingRatio: 0.5))
            Hold.moving(1, duration: 0.6, drift: 0.006)
            CubicKeyframe(0.9, duration: 0.24)
            LinearKeyframe(0.9, duration: 0.54)
        }
        KeyframeTrack(\.figureRotation) {
            LinearKeyframe(0, duration: 0.001)
            LinearKeyframe(0, duration: 0.579)
            CubicKeyframe(360, duration: 0.7, startVelocity: 0, endVelocity: 0)   // one eased backflip
            Hold.moving(360, duration: 1.72, drift: 1)
        }
        KeyframeTrack(\.footPlant) {
            LinearKeyframe(1, duration: 0.001)
            LinearKeyframe(1, duration: 0.579)
            LinearKeyframe(0, duration: 0.08)   // feet leave the floor
            LinearKeyframe(0, duration: 0.64)
            LinearKeyframe(1, duration: 0.08)   // and meet it again
            LinearKeyframe(1, duration: 1.62)
        }
        KeyframeTrack(\.torso) {
            LinearKeyframe(0, duration: 0.001)
            LinearKeyframe(0, duration: 0.399)
            CubicKeyframe(-12, duration: 0.12)   // leans in to load
            CubicKeyframe(10, duration: 0.12)   // arches into the launch
            CubicKeyframe(4, duration: 0.31)
            CubicKeyframe(-6, duration: 0.35)
            CubicKeyframe(-13, duration: 0.1)   // folds into the landing
            CubicKeyframe(-2, duration: 0.22)
            CubicKeyframe(-14, duration: 0.2)   // bows
            Hold.breathing(-14, duration: 0.3, drift: 1)
            CubicKeyframe(-3, duration: 0.18)
            Hold.moving(0, duration: 0.7, drift: 1)
        }
        KeyframeTrack(\.head) {
            LinearKeyframe(0, duration: 0.001)
            CubicKeyframe(-4, duration: 0.519, startVelocity: 0)
            CubicKeyframe(6, duration: 0.12)
            CubicKeyframe(-4, duration: 0.66)
            CubicKeyframe(-6, duration: 0.1)
            CubicKeyframe(0, duration: 0.22)
            CubicKeyframe(-8, duration: 0.2)   // head follows the bow
            Hold.breathing(-8, duration: 0.3, drift: 0.8)
            CubicKeyframe(-1, duration: 0.18)
            Hold.moving(0, duration: 0.7, drift: 0.8)
        }
        KeyframeTrack(\.throwArmUpper) {
            LinearKeyframe(0, duration: 0.001)
            LinearKeyframe(0, duration: 0.299)
            CubicKeyframe(-34, duration: 0.22)   // arms swing back
            CubicKeyframe(120, duration: 0.14)   // and up
            CubicKeyframe(40, duration: 0.2)   // tuck
            LinearKeyframe(40, duration: 0.22)
            CubicKeyframe(70, duration: 0.2)
            CubicKeyframe(24, duration: 0.12)   // one hand reaches down
            CubicKeyframe(-10, duration: 0.24)
            CubicKeyframe(-44, duration: 0.22)   // hands fold together
            Hold.breathing(-44, duration: 0.26, drift: 1.5)
            CubicKeyframe(0, duration: 0.18)
            Hold.moving(0, duration: 0.7, drift: 1)
        }
        KeyframeTrack(\.throwForearm) {
            LinearKeyframe(0, duration: 0.001)
            LinearKeyframe(0, duration: 0.299)
            CubicKeyframe(-30, duration: 0.22)
            CubicKeyframe(10, duration: 0.14)
            CubicKeyframe(-70, duration: 0.2)
            LinearKeyframe(-70, duration: 0.22)
            CubicKeyframe(0, duration: 0.2)
            CubicKeyframe(18, duration: 0.12)
            CubicKeyframe(-5, duration: 0.24)
            CubicKeyframe(-45, duration: 0.22)
            Hold.breathing(-45, duration: 0.26, drift: 1.5)
            CubicKeyframe(-8, duration: 0.18)
            Hold.moving(-8, duration: 0.7, drift: 1)
        }
        KeyframeTrack(\.offArmUpper) {
            LinearKeyframe(0, duration: 0.001)
            LinearKeyframe(0, duration: 0.299)
            CubicKeyframe(-38, duration: 0.22)
            CubicKeyframe(-120, duration: 0.14)
            CubicKeyframe(-30, duration: 0.2)
            LinearKeyframe(-30, duration: 0.22)
            CubicKeyframe(-62, duration: 0.2)
            CubicKeyframe(-22, duration: 0.12)
            CubicKeyframe(6, duration: 0.24)
            CubicKeyframe(-26, duration: 0.22)
            Hold.breathing(-26, duration: 0.26, drift: 1.5)
            CubicKeyframe(0, duration: 0.18)
            Hold.moving(0, duration: 0.7, drift: 1)
        }
        KeyframeTrack(\.offForearm) {
            LinearKeyframe(10, duration: 0.001)
            LinearKeyframe(10, duration: 0.299)
            CubicKeyframe(20, duration: 0.22)
            CubicKeyframe(-20, duration: 0.14)
            CubicKeyframe(75, duration: 0.2)
            LinearKeyframe(75, duration: 0.22)
            CubicKeyframe(10, duration: 0.2)
            CubicKeyframe(30, duration: 0.12)
            CubicKeyframe(12, duration: 0.24)
            CubicKeyframe(70, duration: 0.22)
            Hold.breathing(70, duration: 0.26, drift: 1.5)
            CubicKeyframe(14, duration: 0.18)
            Hold.moving(14, duration: 0.7, drift: 1)
        }
        KeyframeTrack(\.legFrontThigh) {
            LinearKeyframe(2, duration: 0.001)
            LinearKeyframe(2, duration: 0.299)
            CubicKeyframe(38, duration: 0.22)   // deep crouch
            CubicKeyframe(-4, duration: 0.12)   // drives up
            CubicKeyframe(85, duration: 0.18)   // tucks
            LinearKeyframe(85, duration: 0.26)
            CubicKeyframe(30, duration: 0.2)   // opens for the floor
            CubicKeyframe(52, duration: 0.12)   // landing crouch
            CubicKeyframe(2, duration: 0.3)   // stands
            Hold.moving(2, duration: 1.3, drift: 1)
        }
        KeyframeTrack(\.legFrontShin) {
            LinearKeyframe(-4, duration: 0.001)
            LinearKeyframe(-4, duration: 0.299)
            CubicKeyframe(-70, duration: 0.22)
            CubicKeyframe(10, duration: 0.12)
            CubicKeyframe(-96, duration: 0.18)
            LinearKeyframe(-96, duration: 0.26)
            CubicKeyframe(-48, duration: 0.2)
            CubicKeyframe(-95, duration: 0.12)
            CubicKeyframe(-4, duration: 0.3)
            Hold.moving(-4, duration: 1.3, drift: 1)
        }
        KeyframeTrack(\.legBackThigh) {
            LinearKeyframe(0, duration: 0.001)
            LinearKeyframe(0, duration: 0.299)
            CubicKeyframe(26, duration: 0.22)
            CubicKeyframe(-4, duration: 0.12)
            CubicKeyframe(80, duration: 0.2)
            LinearKeyframe(80, duration: 0.24)
            CubicKeyframe(24, duration: 0.2)
            CubicKeyframe(34, duration: 0.12)
            CubicKeyframe(0, duration: 0.3)
            Hold.moving(0, duration: 1.3, drift: 1)
        }
        KeyframeTrack(\.legBackShin) {
            LinearKeyframe(-2, duration: 0.001)
            LinearKeyframe(-2, duration: 0.299)
            CubicKeyframe(-81.4, duration: 0.22)
            CubicKeyframe(-2, duration: 0.12)
            CubicKeyframe(-115, duration: 0.2)
            LinearKeyframe(-115, duration: 0.24)
            CubicKeyframe(-50, duration: 0.2)
            CubicKeyframe(-104.6, duration: 0.12)
            CubicKeyframe(-8, duration: 0.3)
            Hold.moving(-8, duration: 1.3, drift: 1)
        }
    }

    /// backflip: eyes, ribbons, sash, sword and the thrown star.
    @KeyframesBuilder<NinjaPose>
    static var backflipCloth: some Keyframes<NinjaPose> {
        KeyframeTrack(\.eyesScaleY) {
            LinearKeyframe(1, duration: 0.4)
            CubicKeyframe(0.55, duration: 0.18)   // eyes squeeze shut through the spin
            LinearKeyframe(0.55, duration: 0.62)
            CubicKeyframe(1, duration: 0.22)
            Hold.moving(1, duration: 1.58, drift: 0.012)
        }
        KeyframeTrack(\.eyesOffsetX) {
            LinearKeyframe(0, duration: 1.3)
            CubicKeyframe(1.2, duration: 0.12)
            Hold.moving(1.2, duration: 0.78, drift: 0.2)
            CubicKeyframe(0, duration: 0.2)
            Hold.still(0, duration: 0.6)
        }
        KeyframeTrack(\.sparkOpacity) {
            LinearKeyframe(0, duration: 1.38)
            LinearKeyframe(1, duration: 0.14)
            LinearKeyframe(1, duration: 0.68)
            LinearKeyframe(0, duration: 0.1)
            LinearKeyframe(0, duration: 0.7)
        }
        KeyframeTrack(\.shurikenOpacity) {
            LinearKeyframe(0, duration: 0.001)
            LinearKeyframe(0, duration: 2.999)
        }
        KeyframeTrack(\.ninjato) {
            LinearKeyframe(0, duration: 0.001)
            CubicKeyframe(-4, duration: 0.519, startVelocity: 0)
            CubicKeyframe(10, duration: 0.18)
            CubicKeyframe(-8, duration: 0.4)
            CubicKeyframe(5, duration: 0.3)
            CubicKeyframe(-3, duration: 0.3)
            CubicKeyframe(0, duration: 0.3)
            Hold.moving(0, duration: 1, drift: 0.8)
        }
        KeyframeTrack(\.ribbonNear) {
            LinearKeyframe(-20, duration: 0.001)
            SpringKeyframe(0, duration: 0.299, spring: .init(response: 0.5, dampingRatio: 0.4), startVelocity: 0)
            CubicKeyframe(-25, duration: 0.25)
            CubicKeyframe(58, duration: 0.25)   // stream behind the spin
            CubicKeyframe(-30, duration: 0.35)
            SpringKeyframe(0, duration: 0.4, spring: .init(response: 0.42, dampingRatio: 0.3))
            Hold.moving(0, duration: 1.45, drift: 1.5)
        }
        KeyframeTrack(\.ribbonFar) {
            LinearKeyframe(-14, duration: 0.001)
            SpringKeyframe(0, duration: 0.339, spring: .init(response: 0.52, dampingRatio: 0.4), startVelocity: 0)
            CubicKeyframe(-18, duration: 0.24)
            CubicKeyframe(48, duration: 0.26)
            CubicKeyframe(-24, duration: 0.36)
            SpringKeyframe(0, duration: 0.4, spring: .init(response: 0.46, dampingRatio: 0.28))
            Hold.moving(0, duration: 1.4, drift: 1.5)
        }
        KeyframeTrack(\.sashTail) {
            LinearKeyframe(-10, duration: 0.001)
            CubicKeyframe(0, duration: 0.299, startVelocity: 0)
            CubicKeyframe(-14, duration: 0.28)
            CubicKeyframe(42, duration: 0.26)
            CubicKeyframe(-18, duration: 0.36)
            SpringKeyframe(0, duration: 0.42, spring: .init(response: 0.52, dampingRatio: 0.32))
            Hold.moving(0, duration: 1.38, drift: 1.2)
        }
    }

    /// backflip: the smoke puffs that cover the appear and the vanish.
    @KeyframesBuilder<NinjaPose>
    static var backflipSmoke: some Keyframes<NinjaPose> {
        KeyframeTrack(\.smokeOpacity) {
            LinearKeyframe(0, duration: 0.001)
            LinearKeyframe(0.95, duration: 0.059)
            LinearKeyframe(0.95, duration: 0.12)
            LinearKeyframe(0, duration: 0.32)
            LinearKeyframe(0, duration: 1.68)
            LinearKeyframe(0.95, duration: 0.06)
            LinearKeyframe(0.95, duration: 0.14)
            LinearKeyframe(0, duration: 0.36)
            LinearKeyframe(0, duration: 0.26)
        }
        KeyframeTrack(\.smokeScale) {
            LinearKeyframe(0.6, duration: 0.001)
            CubicKeyframe(1.4, duration: 0.179, startVelocity: 0)   // burst grows
            CubicKeyframe(1.568, duration: 0.32)
            LinearKeyframe(0.6, duration: 1.678)
            CubicKeyframe(1.4, duration: 0.202)   // burst grows
            CubicKeyframe(1.568, duration: 0.36)
            Hold.moving(1.568, duration: 0.26, drift: 0.02)
        }
        KeyframeTrack(\.smokeOpacityB) {
            LinearKeyframe(0, duration: 0.001)
            LinearKeyframe(0, duration: 0.039)
            LinearKeyframe(0.95, duration: 0.06)
            LinearKeyframe(0.95, duration: 0.12)
            LinearKeyframe(0, duration: 0.32)
            LinearKeyframe(0, duration: 1.68)
            LinearKeyframe(0.95, duration: 0.06)
            LinearKeyframe(0.95, duration: 0.14)
            LinearKeyframe(0, duration: 0.36)
            LinearKeyframe(0, duration: 0.22)
        }
        KeyframeTrack(\.smokeScaleB) {
            LinearKeyframe(0.55, duration: 0.001)
            LinearKeyframe(0.55, duration: 0.037)
            CubicKeyframe(1.45, duration: 0.182, startVelocity: 0)   // burst grows
            CubicKeyframe(1.624, duration: 0.32)
            LinearKeyframe(0.55, duration: 1.678)
            CubicKeyframe(1.45, duration: 0.202)   // burst grows
            CubicKeyframe(1.624, duration: 0.36)
            Hold.moving(1.624, duration: 0.22, drift: 0.02)
        }
        KeyframeTrack(\.smokeOpacityC) {
            LinearKeyframe(0, duration: 0.001)
            LinearKeyframe(0, duration: 0.079)
            LinearKeyframe(0.95, duration: 0.06)
            LinearKeyframe(0.95, duration: 0.12)
            LinearKeyframe(0, duration: 0.32)
            LinearKeyframe(0, duration: 0.76)
            LinearKeyframe(0.55, duration: 0.04)   // dust on landing
            LinearKeyframe(0, duration: 0.24)
            LinearKeyframe(0, duration: 0.62)
            LinearKeyframe(0.95, duration: 0.06)
            LinearKeyframe(0.95, duration: 0.16)
            LinearKeyframe(0, duration: 0.36)
            LinearKeyframe(0, duration: 0.18)
        }
        KeyframeTrack(\.smokeScaleC) {
            LinearKeyframe(0.55, duration: 0.001)
            CubicKeyframe(1.3, duration: 0.299, startVelocity: 0)
            CubicKeyframe(1.45, duration: 0.28)
            LinearKeyframe(0.6, duration: 0.76)
            CubicKeyframe(1.2, duration: 0.28)   // dust spreads
            LinearKeyframe(0.55, duration: 0.62)
            CubicKeyframe(1.3, duration: 0.22)
            CubicKeyframe(1.45, duration: 0.36)
            Hold.moving(1.45, duration: 0.18, drift: 0.02)
        }
    }
}
