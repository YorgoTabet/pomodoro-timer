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
    @KeyframesBuilder<RabbitPose>
    public static var reluctantSalute: some Keyframes<RabbitPose> {
        KeyframeTrack(\.emergence) {
            SpringKeyframe(-8, duration: 0.50, spring: .init(response: 0.50, dampingRatio: 0.68))
            CubicKeyframe(0, duration: 0.22)
            Hold.moving(0, duration: 1.58, drift: 1.4)
            CubicKeyframe(200, duration: 0.50)
        }
        KeyframeTrack(\.rootScale) {
            CubicKeyframe(1.12, duration: 0.50)       // advances toward the viewer
            Hold.moving(1.12, duration: 1.8, drift: 0.014)
            CubicKeyframe(1.0, duration: 0.50)
        }
        KeyframeTrack(\.figureRotation) {
            CubicKeyframe(-3, duration: 0.50)
            Hold.moving(-3, duration: 1.4, drift: 1.8)
            CubicKeyframe(0, duration: 0.25)
            LinearKeyframe(0, duration: 0.65)
        }
        // The salute itself.
        KeyframeTrack(\.armR) {
            LinearKeyframe(0, duration: 0.55)
            SpringKeyframe(-162, duration: 0.20, spring: .init(response: 0.28, dampingRatio: 0.45))
            Hold.moving(-162, duration: 1.15, drift: 1.8)
            CubicKeyframe(0, duration: 0.25)
            LinearKeyframe(0, duration: 0.65)
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
            Hold.moving(58, duration: 1.10, drift: 2.6)
            CubicKeyframe(0, duration: 0.25)
            LinearKeyframe(0, duration: 0.65)
        }
        // The idle arm. It was completely static; now it swings back a little as the
        // other comes up, which is what a body does to stay balanced.
        KeyframeTrack(\.armL) {
            LinearKeyframe(0, duration: 0.55)
            SpringKeyframe(11, duration: 0.28, spring: .init(response: 0.42, dampingRatio: 0.62))
            Hold.breathing(11, duration: 1.07, drift: 1.8)
            CubicKeyframe(0, duration: 0.25)
            LinearKeyframe(0, duration: 0.65)
        }
        KeyframeTrack(\.armL_fore) {
            LinearKeyframe(0, duration: 0.60)
            SpringKeyframe(17, duration: 0.30, spring: .init(response: 0.46, dampingRatio: 0.58))
            Hold.breathing(17, duration: 1.00, drift: 2.2)
            CubicKeyframe(0, duration: 0.25)
            LinearKeyframe(0, duration: 0.65)
        }
        KeyframeTrack(\.earL_base) {
            LinearKeyframe(0, duration: 0.55)
            SpringKeyframe(-14, duration: 0.20, spring: .init(response: 0.30, dampingRatio: 0.50))
            Hold.moving(-14, duration: 1.4, drift: 1.8)
            CubicKeyframe(0, duration: 0.65)
        }
        KeyframeTrack(\.earL_tip) {
            LinearKeyframe(22, duration: 0.62)
            SpringKeyframe(-6, duration: 0.16, spring: .init(response: 0.35, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.12, spring: .init(response: 0.35, dampingRatio: 0.45))
            Hold.moving(0, duration: 1.9, drift: 1.8)
        }
        // The flopped ear attempts attention and gives up.
        KeyframeTrack(\.earR_base) {
            LinearKeyframe(0, duration: 0.60)
            CubicKeyframe(-48, duration: 0.25)        // tries
            LinearKeyframe(-48, duration: 0.30)
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.50, dampingRatio: 0.60))
            Hold.moving(0, duration: 1.25, drift: 1.8)
        }
        KeyframeTrack(\.earR_tip) {
            LinearKeyframe(18, duration: 0.70)
            SpringKeyframe(-30, duration: 0.30, spring: .init(response: 0.45, dampingRatio: 0.50))
            LinearKeyframe(-30, duration: 0.25)
            SpringKeyframe(14, duration: 0.25, spring: .init(response: 0.45, dampingRatio: 0.40))
            SpringKeyframe(0, duration: 0.20, spring: .init(response: 0.45, dampingRatio: 0.40))
            Hold.moving(0, duration: 1.1, drift: 1.8)
        }
        // The occupant's entire contribution.
        KeyframeTrack(\.blinkOpacity) {
            LinearKeyframe(0, duration: 1.40)
            LinearKeyframe(1, duration: 0.08)
            LinearKeyframe(1, duration: 0.07)
            LinearKeyframe(0, duration: 0.10)
            LinearKeyframe(0, duration: 1.15)
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
    /// human's whole reaction is one small frown at the peak.
    @KeyframesBuilder<RabbitPose>
    public static var twoHops: some Keyframes<RabbitPose> {
        KeyframeTrack(\.emergence) {
            SpringKeyframe(0, duration: 0.45, spring: .init(response: 0.45, dampingRatio: 0.60))
            Hold.moving(0, duration: 2.1, drift: 1.4)
            CubicKeyframe(200, duration: 0.45)
        }
        KeyframeTrack(\.figureLift) {
            LinearKeyframe(0, duration: 0.60)
            CubicKeyframe(-16, duration: 0.25)        // hop 1
            CubicKeyframe(0, duration: 0.20)
            LinearKeyframe(0, duration: 0.25)
            CubicKeyframe(-20, duration: 0.25)        // hop 2, higher
            CubicKeyframe(0, duration: 0.23)
            Hold.moving(0, duration: 1.22, drift: 0.5)
        }
        KeyframeTrack(\.figureScaleY) {
            LinearKeyframe(1, duration: 0.45)
            CubicKeyframe(0.92, duration: 0.15)       // crouch
            CubicKeyframe(1.07, duration: 0.25)       // stretch
            CubicKeyframe(0.93, duration: 0.20)
            SpringKeyframe(1.0, duration: 0.20, spring: .init(response: 0.30, dampingRatio: 0.55))
            CubicKeyframe(0.94, duration: 0.05)
            CubicKeyframe(1.08, duration: 0.25)
            CubicKeyframe(0.92, duration: 0.23)
            SpringKeyframe(1.0, duration: 0.27, spring: .init(response: 0.35, dampingRatio: 0.50))
            Hold.moving(1.0, duration: 0.95, drift: 0.014)
        }
        // Ears flap opposite the body — down as he goes up.
        KeyframeTrack(\.earL_base) {
            LinearKeyframe(0, duration: 0.62)
            CubicKeyframe(16, duration: 0.23)
            SpringKeyframe(0, duration: 0.45, spring: .init(response: 0.40, dampingRatio: 0.45))
            CubicKeyframe(18, duration: 0.23)
            SpringKeyframe(0, duration: 0.45, spring: .init(response: 0.40, dampingRatio: 0.45))
            Hold.moving(0, duration: 1.02, drift: 1.8)
        }
        KeyframeTrack(\.earR_base) {
            LinearKeyframe(0, duration: 0.62)
            CubicKeyframe(-22, duration: 0.23)
            SpringKeyframe(0, duration: 0.45, spring: .init(response: 0.40, dampingRatio: 0.45))
            CubicKeyframe(-26, duration: 0.23)
            SpringKeyframe(0, duration: 0.45, spring: .init(response: 0.40, dampingRatio: 0.45))
            Hold.moving(0, duration: 1.02, drift: 1.8)
        }
        KeyframeTrack(\.earL_tip) {
            LinearKeyframe(30, duration: 0.70)
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.35, dampingRatio: 0.45))
            Hold.moving(0, duration: 2.0, drift: 1.8)
        }
        KeyframeTrack(\.earR_tip) {
            LinearKeyframe(-40, duration: 0.72)
            SpringKeyframe(0, duration: 0.33, spring: .init(response: 0.45, dampingRatio: 0.40))
            Hold.moving(0, duration: 1.95, drift: 1.8)
        }
        KeyframeTrack(\.armL) {
            Hold.moving(0, duration: 1.32, drift: 1.8)
            SpringKeyframe(120, duration: 0.23, spring: .init(response: 0.28, dampingRatio: 0.45))
            LinearKeyframe(120, duration: 0.45)
            CubicKeyframe(0, duration: 0.25)
            LinearKeyframe(0, duration: 0.75)
        }
        // Elbow leads the wave up and trails it down — the classic overlap that
        // makes a limb read as jointed rather than hinged at one end.
        KeyframeTrack(\.armL_fore) {
            Hold.moving(0, duration: 1.36, drift: 1.8)
            SpringKeyframe(42, duration: 0.25, spring: .init(response: 0.30, dampingRatio: 0.40))
            LinearKeyframe(42, duration: 0.41)
            CubicKeyframe(0, duration: 0.28)
            LinearKeyframe(0, duration: 0.70)
        }
        // The other arm, static until now, bounces with the hops.
        KeyframeTrack(\.armR) {
            LinearKeyframe(0, duration: 0.42)
            CubicKeyframe(-15, duration: 0.30)        // lifts on the first hop
            CubicKeyframe(4, duration: 0.32)
            CubicKeyframe(-13, duration: 0.30)        // and again on the second
            SpringKeyframe(0, duration: 0.36, spring: .init(response: 0.44, dampingRatio: 0.55))
            Hold.breathing(0, duration: 1.30, drift: 1.7)
        }
        KeyframeTrack(\.armR_fore) {
            LinearKeyframe(0, duration: 0.48)
            CubicKeyframe(-24, duration: 0.30)
            CubicKeyframe(7, duration: 0.32)
            CubicKeyframe(-21, duration: 0.30)
            SpringKeyframe(0, duration: 0.38, spring: .init(response: 0.48, dampingRatio: 0.50))
            Hold.breathing(0, duration: 1.22, drift: 2.1)
        }
        // The frown, landing exactly at the peak of the costume's joy.
        KeyframeTrack(\.sighOpacity) {
            LinearKeyframe(0, duration: 1.90)
            LinearKeyframe(1, duration: 0.10)
            LinearKeyframe(1, duration: 0.35)
            LinearKeyframe(0, duration: 0.10)
            LinearKeyframe(0, duration: 0.55)
        }
        KeyframeTrack(\.tail) {
            LinearKeyframe(0, duration: 0.70)
            SpringKeyframe(18, duration: 0.25, spring: .init(response: 0.40, dampingRatio: 0.50))
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.40, dampingRatio: 0.50))
            SpringKeyframe(16, duration: 0.25, spring: .init(response: 0.40, dampingRatio: 0.50))
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.40, dampingRatio: 0.50))
            Hold.moving(0, duration: 1.2, drift: 1.8)
        }
        KeyframeTrack(\.zipperPull) {
            LinearKeyframe(0, duration: 0.62)
            SpringKeyframe(30, duration: 0.28, spring: .init(response: 0.50, dampingRatio: 0.32))
            SpringKeyframe(-16, duration: 0.28, spring: .init(response: 0.50, dampingRatio: 0.32))
            SpringKeyframe(24, duration: 0.28, spring: .init(response: 0.50, dampingRatio: 0.32))
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.50, dampingRatio: 0.32))
            Hold.moving(0, duration: 1.14, drift: 0.5)
        }
    }

    // MARK: - longBreak · "Full mascot mode" (3.4s)

    /// A deep crouch, one airborne 360, a stuck landing and a ta-da — held just
    /// long enough for the human to blink once at the audience.
    @KeyframesBuilder<RabbitPose>
    public static var fullMascotMode: some Keyframes<RabbitPose> {
        KeyframeTrack(\.emergence) {
            SpringKeyframe(-14, duration: 0.40, spring: .init(response: 0.42, dampingRatio: 0.55))
            CubicKeyframe(0, duration: 0.15)
            Hold.moving(0, duration: 2.35, drift: 1.4)
            CubicKeyframe(200, duration: 0.50)
        }
        KeyframeTrack(\.figureScaleY) {
            LinearKeyframe(1, duration: 0.55)
            CubicKeyframe(0.88, duration: 0.20)       // deep crouch
            CubicKeyframe(1.06, duration: 0.20)       // launch
            LinearKeyframe(1.0, duration: 0.50)
            CubicKeyframe(0.90, duration: 0.13)       // landing squash
            SpringKeyframe(1.02, duration: 0.15, spring: .init(response: 0.35, dampingRatio: 0.50))
            SpringKeyframe(1.0, duration: 0.12, spring: .init(response: 0.35, dampingRatio: 0.50))
            Hold.moving(1.0, duration: 1.55, drift: 0.014)
        }
        KeyframeTrack(\.figureLift) {
            LinearKeyframe(0, duration: 0.75)
            CubicKeyframe(-24, duration: 0.30)
            LinearKeyframe(-24, duration: 0.00)
            CubicKeyframe(0, duration: 0.40)
            Hold.moving(0, duration: 1.95, drift: 0.5)
        }
        KeyframeTrack(\.figureRotation) {
            LinearKeyframe(0, duration: 0.75)
            CubicKeyframe(360, duration: 0.70)        // the spin
            Hold.moving(360, duration: 1.95, drift: 1.8)
        }
        // Ears, tail and zipper pull all trail as streamers through the spin.
        KeyframeTrack(\.earL_base) {
            LinearKeyframe(0, duration: 0.58)
            CubicKeyframe(-18, duration: 0.17)
            CubicKeyframe(25, duration: 0.35)
            SpringKeyframe(0, duration: 0.50, spring: .init(response: 0.40, dampingRatio: 0.42))
            Hold.moving(0, duration: 1.8, drift: 1.8)
        }
        KeyframeTrack(\.earR_base) {
            LinearKeyframe(0, duration: 0.58)
            CubicKeyframe(8, duration: 0.17)
            CubicKeyframe(-35, duration: 0.35)
            SpringKeyframe(0, duration: 0.50, spring: .init(response: 0.45, dampingRatio: 0.40))
            Hold.moving(0, duration: 1.8, drift: 1.8)
        }
        KeyframeTrack(\.earL_tip) {
            LinearKeyframe(0, duration: 0.85)
            CubicKeyframe(40, duration: 0.30)
            SpringKeyframe(0, duration: 0.55, spring: .init(response: 0.35, dampingRatio: 0.40))
            Hold.moving(0, duration: 1.7, drift: 1.8)
        }
        KeyframeTrack(\.earR_tip) {
            LinearKeyframe(0, duration: 0.85)
            CubicKeyframe(-60, duration: 0.30)
            SpringKeyframe(0, duration: 0.55, spring: .init(response: 0.45, dampingRatio: 0.38))
            Hold.moving(0, duration: 1.7, drift: 1.8)
        }
        KeyframeTrack(\.zipperPull) {
            LinearKeyframe(0, duration: 0.80)
            CubicKeyframe(35, duration: 0.32)
            CubicKeyframe(-35, duration: 0.33)
            SpringKeyframe(0, duration: 0.45, spring: .init(response: 0.50, dampingRatio: 0.35))
            Hold.moving(0, duration: 1.5, drift: 0.5)
        }
        KeyframeTrack(\.tail) {
            LinearKeyframe(0, duration: 0.80)
            SpringKeyframe(18, duration: 0.20, spring: .init(response: 0.40, dampingRatio: 0.50))
            SpringKeyframe(0, duration: 0.20, spring: .init(response: 0.40, dampingRatio: 0.50))
            Hold.moving(0, duration: 2.2, drift: 1.8)
        }
        // Ta-da.
        KeyframeTrack(\.armL) {
            Hold.moving(0, duration: 1.95, drift: 1.8)
            SpringKeyframe(140, duration: 0.25, spring: .init(response: 0.28, dampingRatio: 0.45))
            LinearKeyframe(140, duration: 0.30)
            CubicKeyframe(0, duration: 0.25)
            LinearKeyframe(0, duration: 0.65)
        }
        KeyframeTrack(\.armR) {
            Hold.moving(0, duration: 1.95, drift: 1.8)
            SpringKeyframe(-140, duration: 0.25, spring: .init(response: 0.28, dampingRatio: 0.45))
            LinearKeyframe(-140, duration: 0.30)
            CubicKeyframe(0, duration: 0.25)
            LinearKeyframe(0, duration: 0.65)
        }
        // Both elbows fling open a beat after the shoulders — the follow-through
        // that turns a stiff "arms up" into a ta-da.
        KeyframeTrack(\.armL_fore) {
            Hold.moving(0, duration: 2.00, drift: 1.8)
            SpringKeyframe(46, duration: 0.26, spring: .init(response: 0.32, dampingRatio: 0.38))
            LinearKeyframe(46, duration: 0.24)
            CubicKeyframe(0, duration: 0.28)
            LinearKeyframe(0, duration: 0.62)
        }
        KeyframeTrack(\.armR_fore) {
            Hold.moving(0, duration: 2.00, drift: 1.8)
            SpringKeyframe(-46, duration: 0.26, spring: .init(response: 0.32, dampingRatio: 0.38))
            LinearKeyframe(-46, duration: 0.24)
            CubicKeyframe(0, duration: 0.28)
            LinearKeyframe(0, duration: 0.62)
        }
        KeyframeTrack(\.blinkOpacity) {
            LinearKeyframe(0, duration: 2.30)
            LinearKeyframe(1, duration: 0.10)
            LinearKeyframe(1, duration: 0.08)
            LinearKeyframe(0, duration: 0.10)
            LinearKeyframe(0, duration: 0.82)
        }
    }
}
