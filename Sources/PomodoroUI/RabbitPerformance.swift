import PomodoroCore
import SwiftUI

/// The rabbit costume's three performances.
///
/// Every timeline keys the costume — hops, ear flaps, a salute — and leaves the
/// human face alone apart from a single blink or a 1.5-unit frown, timed to land
/// at the peak of the celebration. The gap between how hard the suit is trying and
/// how little the occupant cares is the entire character, so nothing here should be
/// "fixed" by making the face more expressive.
public enum RabbitPerformance {

    public static func preferredEdge(for cue: CharacterCue) -> StageEdge { .top }

    public static func comesForward(for cue: CharacterCue) -> Bool {
        cue == .focusStart
    }

    public static func duration(for cue: CharacterCue) -> Double {
        switch cue {
        case .focusStart: 2.80
        case .breakStart: 3.00
        case .longBreak: 3.40
        }
    }

    // MARK: - focusStart · "Reluctant salute" (2.8s)

    /// The costume snaps a crisp salute. The half-upright ear manages attention;
    /// the flopped one tries, fails, and collapses back. The human blinks once.
    ///
    /// The body dips before the salute (anticipation), pops with it, and the head
    /// counter-rotates a beat behind the figure so the neck reads as a joint.
    @KeyframesBuilder<RabbitPose>
    public static var reluctantSalute: some Keyframes<RabbitPose> {
        KeyframeTrack(\.emergence) {
            SpringKeyframe(-8, duration: 0.50, spring: .init(response: 0.50, dampingRatio: 0.68))
            CubicKeyframe(0, duration: 0.22)
            Hold.moving(0, duration: 1.58, drift: 0.9)
            CubicKeyframe(-7, duration: 0.10)         // small rise before the drop
            CubicKeyframe(200, duration: 0.40)
        }
        KeyframeTrack(\.rootScale) {
            CubicKeyframe(1.16, duration: 0.35)       // overshoots toward the viewer
            CubicKeyframe(1.10, duration: 0.25)
            Hold.moving(1.10, duration: 1.70, drift: 0.012)
            CubicKeyframe(1.0, duration: 0.50)
        }
        KeyframeTrack(\.figureScaleY) {
            CubicKeyframe(0.95, duration: 0.30)       // anticipation dip
            CubicKeyframe(1.04, duration: 0.32)       // pops with the salute
            SpringKeyframe(1.0, duration: 0.25, spring: .init(response: 0.30, dampingRatio: 0.55))
            Hold.moving(1.0, duration: 1.43, drift: 0.010)
            CubicKeyframe(1.03, duration: 0.10)
            CubicKeyframe(0.98, duration: 0.40)
        }
        KeyframeTrack(\.figureRotation) {
            CubicKeyframe(-3, duration: 0.50)
            CubicKeyframe(2, duration: 0.25)          // settles into the salute
            Hold.moving(2, duration: 1.00, drift: 0.9)
            CubicKeyframe(0, duration: 0.30)
            Hold.moving(0, duration: 0.75, drift: 0.4)
        }
        // The head follows the figure about 0.12s late, against its direction.
        KeyframeTrack(\.head) {
            CubicKeyframe(0, duration: 0.12)
            CubicKeyframe(4, duration: 0.50)
            CubicKeyframe(-3, duration: 0.25)
            Hold.moving(-3, duration: 0.90, drift: 0.9)
            CubicKeyframe(0, duration: 0.40)
            Hold.moving(0, duration: 0.63, drift: 0.5)
        }
        // The torso leans into the saluting side.
        KeyframeTrack(\.torso) {
            CubicKeyframe(0, duration: 0.45)
            CubicKeyframe(3, duration: 0.25)
            Hold.moving(3, duration: 1.20, drift: 0.6)
            CubicKeyframe(0, duration: 0.35)
            Hold.moving(0, duration: 0.55, drift: 0.4)
        }
        // The salute itself.
        KeyframeTrack(\.armR) {
            LinearKeyframe(0, duration: 0.55)
            SpringKeyframe(-162, duration: 0.20, spring: .init(response: 0.28, dampingRatio: 0.45))
            Hold.moving(-162, duration: 1.15, drift: 0.8)
            CubicKeyframe(0, duration: 0.25)
            Hold.moving(0, duration: 0.65, drift: 0.4)
        }
        // The elbow does most of the salute.
        //
        // A salute is not the shoulder rotating 162° — it is the shoulder lifting a
        // little and the elbow folding hard to bring the paw to the brow. With one
        // rigid arm the paw could only reach by swinging the whole limb past the
        // head, which is why this read as a wave rather than a salute.
        KeyframeTrack(\.armR_fore) {
            LinearKeyframe(0, duration: 0.58)
            SpringKeyframe(58, duration: 0.22, spring: .init(response: 0.26, dampingRatio: 0.42))
            Hold.moving(58, duration: 1.10, drift: 1.0)
            CubicKeyframe(0, duration: 0.25)
            Hold.moving(0, duration: 0.65, drift: 0.4)
        }
        // The idle arm swings back a little as the other comes up, to keep balance.
        KeyframeTrack(\.armL) {
            LinearKeyframe(0, duration: 0.55)
            SpringKeyframe(11, duration: 0.28, spring: .init(response: 0.42, dampingRatio: 0.62))
            Hold.breathing(11, duration: 1.07, drift: 0.8)
            CubicKeyframe(0, duration: 0.25)
            Hold.moving(0, duration: 0.65, drift: 0.4)
        }
        KeyframeTrack(\.armL_fore) {
            LinearKeyframe(0, duration: 0.60)
            SpringKeyframe(17, duration: 0.30, spring: .init(response: 0.46, dampingRatio: 0.58))
            Hold.breathing(17, duration: 1.00, drift: 1.0)
            CubicKeyframe(0, duration: 0.25)
            Hold.moving(0, duration: 0.65, drift: 0.4)
        }
        // Each tip starts 0.08s after its base and swings about 1.5x as far.
        KeyframeTrack(\.earL_base) {
            LinearKeyframe(0, duration: 0.55)
            SpringKeyframe(-14, duration: 0.20, spring: .init(response: 0.30, dampingRatio: 0.50))
            Hold.moving(-14, duration: 1.4, drift: 1.0)
            CubicKeyframe(0, duration: 0.65)
        }
        KeyframeTrack(\.earL_tip) {
            LinearKeyframe(22, duration: 0.63)
            SpringKeyframe(-21, duration: 0.20, spring: .init(response: 0.35, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.20, spring: .init(response: 0.35, dampingRatio: 0.45))
            Hold.moving(0, duration: 1.77, drift: 1.0)
        }
        // The flopped ear attempts attention and gives up.
        KeyframeTrack(\.earR_base) {
            LinearKeyframe(0, duration: 0.60)
            CubicKeyframe(-48, duration: 0.25)        // tries
            LinearKeyframe(-48, duration: 0.30)
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.50, dampingRatio: 0.60))
            Hold.moving(0, duration: 1.25, drift: 1.0)
        }
        KeyframeTrack(\.earR_tip) {
            LinearKeyframe(18, duration: 0.68)
            SpringKeyframe(-60, duration: 0.25, spring: .init(response: 0.45, dampingRatio: 0.50))
            LinearKeyframe(-50, duration: 0.30)
            SpringKeyframe(20, duration: 0.25, spring: .init(response: 0.45, dampingRatio: 0.40))
            SpringKeyframe(0, duration: 0.20, spring: .init(response: 0.45, dampingRatio: 0.40))
            Hold.moving(0, duration: 1.12, drift: 1.0)
        }
        // The occupant's entire contribution.
        KeyframeTrack(\.blinkOpacity) {
            LinearKeyframe(0, duration: 1.40)
            LinearKeyframe(1, duration: 0.08)
            LinearKeyframe(1, duration: 0.12)
            LinearKeyframe(0, duration: 0.10)
            LinearKeyframe(0, duration: 1.10)
        }
        // The tail flicks as the salute lands.
        KeyframeTrack(\.tail) {
            LinearKeyframe(0, duration: 0.70)
            SpringKeyframe(14, duration: 0.12, spring: .init(response: 0.30, dampingRatio: 0.50))
            SpringKeyframe(0, duration: 0.25, spring: .init(response: 0.40, dampingRatio: 0.50))
            Hold.moving(0, duration: 1.73, drift: 0.8)
        }
        KeyframeTrack(\.zipperPull) {
            LinearKeyframe(0, duration: 0.50)
            SpringKeyframe(18, duration: 0.30, spring: .init(response: 0.50, dampingRatio: 0.35))
            SpringKeyframe(-8, duration: 0.30, spring: .init(response: 0.50, dampingRatio: 0.35))
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.50, dampingRatio: 0.35))
            Hold.moving(0, duration: 1.4, drift: 0.5)
        }
    }

    // MARK: - breakStart · "Two hops" (3.0s)

    /// Two joyful hops with a paw raised, ears flapping opposite the body. The
    /// human's whole reaction is one small frown at the peak of the second hop,
    /// where the paw wave also lands, so the beats overlap.
    @KeyframesBuilder<RabbitPose>
    public static var twoHops: some Keyframes<RabbitPose> {
        KeyframeTrack(\.emergence) {
            SpringKeyframe(0, duration: 0.45, spring: .init(response: 0.45, dampingRatio: 0.60))
            Hold.moving(0, duration: 2.10, drift: 0.9)
            CubicKeyframe(-7, duration: 0.10)         // small rise before the drop
            CubicKeyframe(200, duration: 0.35)
        }
        // Hop 1 apex at 0.85s, hop 2 apex at 1.61s.
        KeyframeTrack(\.figureLift) {
            LinearKeyframe(0, duration: 0.55)
            CubicKeyframe(-24, duration: 0.30)
            CubicKeyframe(0, duration: 0.26)
            LinearKeyframe(0, duration: 0.20)
            CubicKeyframe(-30, duration: 0.30)        // hop 2, higher
            CubicKeyframe(0, duration: 0.26)
            Hold.moving(0, duration: 1.13, drift: 0.5)
        }
        KeyframeTrack(\.figureScaleY) {
            LinearKeyframe(1, duration: 0.40)
            CubicKeyframe(0.92, duration: 0.15)       // crouch
            CubicKeyframe(1.07, duration: 0.30)       // stretch
            CubicKeyframe(0.92, duration: 0.26)       // landing squash
            SpringKeyframe(1.0, duration: 0.12, spring: .init(response: 0.30, dampingRatio: 0.55))
            CubicKeyframe(0.92, duration: 0.08)
            CubicKeyframe(1.08, duration: 0.30)
            CubicKeyframe(0.90, duration: 0.26)
            SpringKeyframe(1.0, duration: 0.28, spring: .init(response: 0.35, dampingRatio: 0.50))
            Hold.moving(1.0, duration: 0.85, drift: 0.012)
        }
        KeyframeTrack(\.figureRotation) {
            CubicKeyframe(0, duration: 0.55)
            CubicKeyframe(4, duration: 0.30)
            CubicKeyframe(0, duration: 0.26)
            LinearKeyframe(0, duration: 0.20)
            CubicKeyframe(-4, duration: 0.30)
            CubicKeyframe(0, duration: 0.26)
            Hold.moving(0, duration: 1.13, drift: 0.9)
        }
        // Head 0.12s behind the figure, against it.
        KeyframeTrack(\.head) {
            CubicKeyframe(0, duration: 0.67)
            CubicKeyframe(-4, duration: 0.30)
            CubicKeyframe(0, duration: 0.26)
            LinearKeyframe(0, duration: 0.20)
            CubicKeyframe(5, duration: 0.30)
            CubicKeyframe(0, duration: 0.26)
            Hold.moving(0, duration: 1.01, drift: 0.9)
        }
        KeyframeTrack(\.torso) {
            CubicKeyframe(0, duration: 0.45)
            CubicKeyframe(3, duration: 0.40)
            CubicKeyframe(-1, duration: 0.40)
            CubicKeyframe(-3, duration: 0.36)
            CubicKeyframe(0, duration: 0.40)
            Hold.moving(0, duration: 0.99, drift: 0.6)
        }
        KeyframeTrack(\.torsoSway) {
            CubicKeyframe(0, duration: 0.45)
            CubicKeyframe(2, duration: 0.40)
            CubicKeyframe(-1, duration: 0.40)
            CubicKeyframe(-2, duration: 0.36)
            CubicKeyframe(0, duration: 0.40)
            Hold.moving(0, duration: 0.99, drift: 0.4)
        }
        // The legs absorb each landing.
        KeyframeTrack(\.legsScaleY) {
            LinearKeyframe(1, duration: 0.85)
            CubicKeyframe(0.95, duration: 0.26)
            SpringKeyframe(1.0, duration: 0.20, spring: .init(response: 0.30, dampingRatio: 0.55))
            LinearKeyframe(1.0, duration: 0.30)
            CubicKeyframe(0.94, duration: 0.26)
            SpringKeyframe(1.0, duration: 0.25, spring: .init(response: 0.30, dampingRatio: 0.55))
            Hold.moving(1.0, duration: 0.88, drift: 0.01)
        }
        // Ears flap opposite the body. Each tip trails its base by 0.08s and
        // swings about 1.5x as far.
        KeyframeTrack(\.earL_base) {
            LinearKeyframe(0, duration: 0.58)
            CubicKeyframe(16, duration: 0.32)
            SpringKeyframe(0, duration: 0.36, spring: .init(response: 0.40, dampingRatio: 0.45))
            CubicKeyframe(18, duration: 0.40)
            SpringKeyframe(0, duration: 0.50, spring: .init(response: 0.40, dampingRatio: 0.45))
            Hold.moving(0, duration: 0.84, drift: 1.0)
        }
        KeyframeTrack(\.earR_base) {
            LinearKeyframe(0, duration: 0.58)
            CubicKeyframe(-22, duration: 0.32)
            SpringKeyframe(0, duration: 0.36, spring: .init(response: 0.40, dampingRatio: 0.45))
            CubicKeyframe(-26, duration: 0.40)
            SpringKeyframe(0, duration: 0.50, spring: .init(response: 0.40, dampingRatio: 0.45))
            Hold.moving(0, duration: 0.84, drift: 1.0)
        }
        KeyframeTrack(\.earL_tip) {
            LinearKeyframe(30, duration: 0.60)
            CubicKeyframe(24, duration: 0.38)
            SpringKeyframe(0, duration: 0.36, spring: .init(response: 0.35, dampingRatio: 0.45))
            CubicKeyframe(27, duration: 0.40)
            SpringKeyframe(0, duration: 0.50, spring: .init(response: 0.35, dampingRatio: 0.45))
            Hold.moving(0, duration: 0.76, drift: 1.0)
        }
        KeyframeTrack(\.earR_tip) {
            LinearKeyframe(-40, duration: 0.60)
            CubicKeyframe(-33, duration: 0.38)
            SpringKeyframe(0, duration: 0.36, spring: .init(response: 0.45, dampingRatio: 0.40))
            CubicKeyframe(-39, duration: 0.40)
            SpringKeyframe(0, duration: 0.50, spring: .init(response: 0.45, dampingRatio: 0.40))
            Hold.moving(0, duration: 0.76, drift: 1.0)
        }
        // The wave peaks on hop 2's apex (1.61s).
        KeyframeTrack(\.armL) {
            Hold.moving(0, duration: 1.38, drift: 0.8)
            SpringKeyframe(120, duration: 0.24, spring: .init(response: 0.28, dampingRatio: 0.45))
            LinearKeyframe(120, duration: 0.45)
            CubicKeyframe(0, duration: 0.28)
            Hold.moving(0, duration: 0.65, drift: 0.5)
        }
        // Elbow trails the shoulder on the way up and down.
        KeyframeTrack(\.armL_fore) {
            Hold.moving(0, duration: 1.43, drift: 0.9)
            SpringKeyframe(42, duration: 0.25, spring: .init(response: 0.30, dampingRatio: 0.40))
            LinearKeyframe(42, duration: 0.42)
            CubicKeyframe(0, duration: 0.30)
            Hold.moving(0, duration: 0.60, drift: 0.5)
        }
        // The other arm bounces with the hops, a little behind the body.
        KeyframeTrack(\.armR) {
            LinearKeyframe(0, duration: 0.50)
            CubicKeyframe(-18, duration: 0.40)
            CubicKeyframe(4, duration: 0.30)
            CubicKeyframe(-16, duration: 0.46)
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.44, dampingRatio: 0.55))
            Hold.breathing(0, duration: 0.94, drift: 0.9)
        }
        KeyframeTrack(\.armR_fore) {
            LinearKeyframe(0, duration: 0.52)
            CubicKeyframe(-26, duration: 0.44)
            CubicKeyframe(7, duration: 0.30)
            CubicKeyframe(-22, duration: 0.46)
            SpringKeyframe(0, duration: 0.42, spring: .init(response: 0.48, dampingRatio: 0.50))
            Hold.breathing(0, duration: 0.86, drift: 1.0)
        }
        // The frown, landing at hop 2's apex with the wave.
        KeyframeTrack(\.sighOpacity) {
            LinearKeyframe(0, duration: 1.55)
            LinearKeyframe(1, duration: 0.08)
            LinearKeyframe(1, duration: 0.50)
            LinearKeyframe(0, duration: 0.10)
            LinearKeyframe(0, duration: 0.77)
        }
        // Tail flicks at each landing.
        KeyframeTrack(\.tail) {
            LinearKeyframe(0, duration: 0.90)
            SpringKeyframe(18, duration: 0.22, spring: .init(response: 0.40, dampingRatio: 0.50))
            SpringKeyframe(0, duration: 0.26, spring: .init(response: 0.40, dampingRatio: 0.50))
            LinearKeyframe(0, duration: 0.47)
            SpringKeyframe(16, duration: 0.22, spring: .init(response: 0.40, dampingRatio: 0.50))
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.40, dampingRatio: 0.50))
            Hold.moving(0, duration: 0.63, drift: 0.8)
        }
        KeyframeTrack(\.zipperPull) {
            LinearKeyframe(0, duration: 0.60)
            SpringKeyframe(30, duration: 0.30, spring: .init(response: 0.50, dampingRatio: 0.32))
            SpringKeyframe(-16, duration: 0.30, spring: .init(response: 0.50, dampingRatio: 0.32))
            SpringKeyframe(24, duration: 0.40, spring: .init(response: 0.50, dampingRatio: 0.32))
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.50, dampingRatio: 0.32))
            Hold.moving(0, duration: 1.00, drift: 0.5)
        }
    }

    // MARK: - longBreak · "Full mascot mode" (3.4s)

    /// A deep crouch, one airborne 360, a stuck landing and a ta-da — held just
    /// long enough for the human to blink once at the audience.
    ///
    /// Beats: crouch 0.45-0.75s, launch and spin 0.75-1.33s (lands at 1.33s),
    /// ta-da 1.55-2.88s, exit from 2.90s.
    @KeyframesBuilder<RabbitPose>
    public static var fullMascotMode: some Keyframes<RabbitPose> {
        KeyframeTrack(\.emergence) {
            SpringKeyframe(-14, duration: 0.40, spring: .init(response: 0.42, dampingRatio: 0.55))
            CubicKeyframe(0, duration: 0.15)
            Hold.moving(0, duration: 2.25, drift: 0.9)
            CubicKeyframe(-7, duration: 0.10)         // small rise before the drop
            CubicKeyframe(200, duration: 0.50)
        }
        KeyframeTrack(\.figureScaleY) {
            LinearKeyframe(1, duration: 0.45)
            CubicKeyframe(0.88, duration: 0.30)       // deep crouch
            CubicKeyframe(1.08, duration: 0.15)       // launch
            CubicKeyframe(1.03, duration: 0.25)
            CubicKeyframe(0.90, duration: 0.18)       // landing squash
            SpringKeyframe(1.02, duration: 0.15, spring: .init(response: 0.35, dampingRatio: 0.50))
            SpringKeyframe(1.0, duration: 0.12, spring: .init(response: 0.35, dampingRatio: 0.50))
            Hold.moving(1.0, duration: 1.20, drift: 0.012)
            CubicKeyframe(1.03, duration: 0.10)
            CubicKeyframe(0.98, duration: 0.50)
        }
        KeyframeTrack(\.figureLift) {
            LinearKeyframe(0, duration: 0.75)
            CubicKeyframe(-34, duration: 0.30)
            CubicKeyframe(0, duration: 0.28)
            Hold.moving(0, duration: 2.07, drift: 0.5)
        }
        // The spin eases out: fast off the ground, slowing as the landing nears,
        // so the character is readable face-on as it comes down.
        KeyframeTrack(\.figureRotation) {
            LinearKeyframe(0, duration: 0.45)
            CubicKeyframe(-6, duration: 0.30)         // wind-up
            CubicKeyframe(360, duration: 0.58, startVelocity: 1500, endVelocity: 0)
            Hold.moving(360, duration: 2.07, drift: 0.9)
        }
        KeyframeTrack(\.head) {
            LinearKeyframe(0, duration: 0.60)
            CubicKeyframe(4, duration: 0.15)
            CubicKeyframe(-6, duration: 0.35)         // lags the spin
            CubicKeyframe(5, duration: 0.30)          // carries on past the landing
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.35, dampingRatio: 0.55))
            Hold.moving(0, duration: 1.70, drift: 0.9)
        }
        KeyframeTrack(\.torso) {
            LinearKeyframe(0, duration: 0.50)
            CubicKeyframe(3, duration: 0.25)
            CubicKeyframe(-3, duration: 0.30)
            CubicKeyframe(3, duration: 0.28)
            SpringKeyframe(0, duration: 0.27, spring: .init(response: 0.35, dampingRatio: 0.55))
            CubicKeyframe(-3, duration: 0.20)         // leans back into the ta-da
            Hold.moving(-3, duration: 0.80, drift: 0.7)
            CubicKeyframe(0, duration: 0.30)
            Hold.moving(0, duration: 0.50, drift: 0.4)
        }
        KeyframeTrack(\.legsScaleY) {
            LinearKeyframe(1, duration: 0.45)
            CubicKeyframe(0.94, duration: 0.30)
            CubicKeyframe(1.03, duration: 0.15)
            CubicKeyframe(1.0, duration: 0.20)
            CubicKeyframe(0.94, duration: 0.23)       // lands
            SpringKeyframe(1.0, duration: 0.27, spring: .init(response: 0.30, dampingRatio: 0.55))
            Hold.moving(1.0, duration: 1.80, drift: 0.01)
        }
        // Ears, tail and zipper pull trail as streamers through the spin. Tips start
        // 0.08s after their bases and swing about 1.5x as far.
        KeyframeTrack(\.earL_base) {
            LinearKeyframe(0, duration: 0.60)
            CubicKeyframe(10, duration: 0.15)
            CubicKeyframe(-22, duration: 0.25)
            CubicKeyframe(30, duration: 0.33)
            SpringKeyframe(0, duration: 0.45, spring: .init(response: 0.40, dampingRatio: 0.42))
            Hold.moving(0, duration: 1.62, drift: 1.0)
        }
        KeyframeTrack(\.earR_base) {
            LinearKeyframe(0, duration: 0.60)
            CubicKeyframe(-8, duration: 0.15)
            CubicKeyframe(26, duration: 0.25)
            CubicKeyframe(-38, duration: 0.33)
            SpringKeyframe(0, duration: 0.45, spring: .init(response: 0.45, dampingRatio: 0.40))
            Hold.moving(0, duration: 1.62, drift: 1.0)
        }
        KeyframeTrack(\.earL_tip) {
            LinearKeyframe(0, duration: 0.68)
            CubicKeyframe(15, duration: 0.15)
            CubicKeyframe(-33, duration: 0.25)
            CubicKeyframe(45, duration: 0.33)
            SpringKeyframe(0, duration: 0.45, spring: .init(response: 0.35, dampingRatio: 0.40))
            Hold.moving(0, duration: 1.54, drift: 1.0)
        }
        KeyframeTrack(\.earR_tip) {
            LinearKeyframe(0, duration: 0.68)
            CubicKeyframe(-12, duration: 0.15)
            CubicKeyframe(39, duration: 0.25)
            CubicKeyframe(-57, duration: 0.33)
            SpringKeyframe(0, duration: 0.45, spring: .init(response: 0.45, dampingRatio: 0.38))
            Hold.moving(0, duration: 1.54, drift: 1.0)
        }
        KeyframeTrack(\.zipperPull) {
            LinearKeyframe(0, duration: 0.80)
            CubicKeyframe(35, duration: 0.30)
            CubicKeyframe(-35, duration: 0.30)
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.50, dampingRatio: 0.35))
            Hold.moving(0, duration: 1.60, drift: 0.5)
        }
        // Three flicks around the landing at 1.33s.
        KeyframeTrack(\.tail) {
            Hold.moving(0, duration: 1.10, drift: 0.8)
            SpringKeyframe(22, duration: 0.10, spring: .init(response: 0.25, dampingRatio: 0.50))
            SpringKeyframe(0, duration: 0.12, spring: .init(response: 0.25, dampingRatio: 0.50))
            SpringKeyframe(22, duration: 0.10, spring: .init(response: 0.25, dampingRatio: 0.50))
            SpringKeyframe(0, duration: 0.12, spring: .init(response: 0.25, dampingRatio: 0.50))
            SpringKeyframe(22, duration: 0.10, spring: .init(response: 0.25, dampingRatio: 0.50))
            SpringKeyframe(0, duration: 0.16, spring: .init(response: 0.30, dampingRatio: 0.50))
            Hold.moving(0, duration: 1.60, drift: 0.8)
        }
        // Arms fling out in the spin, tuck, then open for the ta-da at 1.55s.
        // The elbows open 0.1s after the shoulders.
        KeyframeTrack(\.armL) {
            LinearKeyframe(0, duration: 0.75)
            CubicKeyframe(38, duration: 0.30)
            CubicKeyframe(8, duration: 0.28)
            CubicKeyframe(0, duration: 0.22)
            SpringKeyframe(140, duration: 0.25, spring: .init(response: 0.28, dampingRatio: 0.45))
            Hold.moving(140, duration: 0.80, drift: 0.8)
            CubicKeyframe(0, duration: 0.28)
            Hold.moving(0, duration: 0.52, drift: 0.4)
        }
        KeyframeTrack(\.armR) {
            LinearKeyframe(0, duration: 0.75)
            CubicKeyframe(-38, duration: 0.30)
            CubicKeyframe(-8, duration: 0.28)
            CubicKeyframe(0, duration: 0.22)
            SpringKeyframe(-140, duration: 0.25, spring: .init(response: 0.28, dampingRatio: 0.45))
            Hold.moving(-140, duration: 0.80, drift: 0.8)
            CubicKeyframe(0, duration: 0.28)
            Hold.moving(0, duration: 0.52, drift: 0.4)
        }
        KeyframeTrack(\.armL_fore) {
            LinearKeyframe(0, duration: 0.80)
            CubicKeyframe(18, duration: 0.30)
            CubicKeyframe(0, duration: 0.55)
            SpringKeyframe(46, duration: 0.26, spring: .init(response: 0.32, dampingRatio: 0.38))
            Hold.moving(46, duration: 0.74, drift: 1.0)
            CubicKeyframe(0, duration: 0.28)
            Hold.moving(0, duration: 0.47, drift: 0.4)
        }
        KeyframeTrack(\.armR_fore) {
            LinearKeyframe(0, duration: 0.80)
            CubicKeyframe(-18, duration: 0.30)
            CubicKeyframe(0, duration: 0.55)
            SpringKeyframe(-46, duration: 0.26, spring: .init(response: 0.32, dampingRatio: 0.38))
            Hold.moving(-46, duration: 0.74, drift: 1.0)
            CubicKeyframe(0, duration: 0.28)
            Hold.moving(0, duration: 0.47, drift: 0.4)
        }
        // The human blinks at the ta-da, held long enough to be seen.
        KeyframeTrack(\.blinkOpacity) {
            LinearKeyframe(0, duration: 1.90)
            LinearKeyframe(1, duration: 0.08)
            LinearKeyframe(1, duration: 0.12)
            LinearKeyframe(0, duration: 0.10)
            LinearKeyframe(0, duration: 1.20)
        }
    }
}
