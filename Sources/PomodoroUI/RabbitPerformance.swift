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
            LinearKeyframe(0, duration: 1.58)
            CubicKeyframe(200, duration: 0.50)
        }
        KeyframeTrack(\.rootScale) {
            CubicKeyframe(1.12, duration: 0.50)       // advances toward the viewer
            LinearKeyframe(1.12, duration: 1.80)
            CubicKeyframe(1.0, duration: 0.50)
        }
        KeyframeTrack(\.figureRotation) {
            CubicKeyframe(-3, duration: 0.50)
            LinearKeyframe(-3, duration: 1.40)
            CubicKeyframe(0, duration: 0.25)
            LinearKeyframe(0, duration: 0.65)
        }
        // The salute itself.
        KeyframeTrack(\.armR) {
            LinearKeyframe(0, duration: 0.55)
            SpringKeyframe(-162, duration: 0.20, spring: .init(response: 0.28, dampingRatio: 0.45))
            LinearKeyframe(-162, duration: 1.15)
            CubicKeyframe(0, duration: 0.25)
            LinearKeyframe(0, duration: 0.65)
        }
        KeyframeTrack(\.earL_base) {
            LinearKeyframe(0, duration: 0.55)
            SpringKeyframe(-14, duration: 0.20, spring: .init(response: 0.30, dampingRatio: 0.50))
            LinearKeyframe(-14, duration: 1.40)
            CubicKeyframe(0, duration: 0.65)
        }
        KeyframeTrack(\.earL_tip) {
            LinearKeyframe(22, duration: 0.62)
            SpringKeyframe(-6, duration: 0.16, spring: .init(response: 0.35, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.12, spring: .init(response: 0.35, dampingRatio: 0.45))
            LinearKeyframe(0, duration: 1.90)
        }
        // The flopped ear attempts attention and gives up.
        KeyframeTrack(\.earR_base) {
            LinearKeyframe(0, duration: 0.60)
            CubicKeyframe(-48, duration: 0.25)        // tries
            LinearKeyframe(-48, duration: 0.30)
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.50, dampingRatio: 0.60))
            LinearKeyframe(0, duration: 1.25)
        }
        KeyframeTrack(\.earR_tip) {
            LinearKeyframe(18, duration: 0.70)
            SpringKeyframe(-30, duration: 0.30, spring: .init(response: 0.45, dampingRatio: 0.50))
            LinearKeyframe(-30, duration: 0.25)
            SpringKeyframe(14, duration: 0.25, spring: .init(response: 0.45, dampingRatio: 0.40))
            SpringKeyframe(0, duration: 0.20, spring: .init(response: 0.45, dampingRatio: 0.40))
            LinearKeyframe(0, duration: 1.10)
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
            LinearKeyframe(0, duration: 1.40)
        }
    }

    // MARK: - breakStart · "Two hops" (3.0s)

    /// Two joyful hops with a paw raised, ears flapping opposite the body. The
    /// human's whole reaction is one small frown at the peak.
    @KeyframesBuilder<RabbitPose>
    public static var twoHops: some Keyframes<RabbitPose> {
        KeyframeTrack(\.emergence) {
            SpringKeyframe(0, duration: 0.45, spring: .init(response: 0.45, dampingRatio: 0.60))
            LinearKeyframe(0, duration: 2.10)
            CubicKeyframe(200, duration: 0.45)
        }
        KeyframeTrack(\.figureLift) {
            LinearKeyframe(0, duration: 0.60)
            CubicKeyframe(-16, duration: 0.25)        // hop 1
            CubicKeyframe(0, duration: 0.20)
            LinearKeyframe(0, duration: 0.25)
            CubicKeyframe(-20, duration: 0.25)        // hop 2, higher
            CubicKeyframe(0, duration: 0.23)
            LinearKeyframe(0, duration: 1.22)
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
            LinearKeyframe(1.0, duration: 0.95)
        }
        // Ears flap opposite the body — down as he goes up.
        KeyframeTrack(\.earL_base) {
            LinearKeyframe(0, duration: 0.62)
            CubicKeyframe(16, duration: 0.23)
            SpringKeyframe(0, duration: 0.45, spring: .init(response: 0.40, dampingRatio: 0.45))
            CubicKeyframe(18, duration: 0.23)
            SpringKeyframe(0, duration: 0.45, spring: .init(response: 0.40, dampingRatio: 0.45))
            LinearKeyframe(0, duration: 1.02)
        }
        KeyframeTrack(\.earR_base) {
            LinearKeyframe(0, duration: 0.62)
            CubicKeyframe(-22, duration: 0.23)
            SpringKeyframe(0, duration: 0.45, spring: .init(response: 0.40, dampingRatio: 0.45))
            CubicKeyframe(-26, duration: 0.23)
            SpringKeyframe(0, duration: 0.45, spring: .init(response: 0.40, dampingRatio: 0.45))
            LinearKeyframe(0, duration: 1.02)
        }
        KeyframeTrack(\.earL_tip) {
            LinearKeyframe(30, duration: 0.70)
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.35, dampingRatio: 0.45))
            LinearKeyframe(0, duration: 2.00)
        }
        KeyframeTrack(\.earR_tip) {
            LinearKeyframe(-40, duration: 0.72)
            SpringKeyframe(0, duration: 0.33, spring: .init(response: 0.45, dampingRatio: 0.40))
            LinearKeyframe(0, duration: 1.95)
        }
        KeyframeTrack(\.armL) {
            LinearKeyframe(0, duration: 1.32)
            SpringKeyframe(120, duration: 0.23, spring: .init(response: 0.28, dampingRatio: 0.45))
            LinearKeyframe(120, duration: 0.45)
            CubicKeyframe(0, duration: 0.25)
            LinearKeyframe(0, duration: 0.75)
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
            LinearKeyframe(0, duration: 1.20)
        }
        KeyframeTrack(\.zipperPull) {
            LinearKeyframe(0, duration: 0.62)
            SpringKeyframe(30, duration: 0.28, spring: .init(response: 0.50, dampingRatio: 0.32))
            SpringKeyframe(-16, duration: 0.28, spring: .init(response: 0.50, dampingRatio: 0.32))
            SpringKeyframe(24, duration: 0.28, spring: .init(response: 0.50, dampingRatio: 0.32))
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.50, dampingRatio: 0.32))
            LinearKeyframe(0, duration: 1.14)
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
            LinearKeyframe(0, duration: 2.35)
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
            LinearKeyframe(1.0, duration: 1.55)
        }
        KeyframeTrack(\.figureLift) {
            LinearKeyframe(0, duration: 0.75)
            CubicKeyframe(-24, duration: 0.30)
            LinearKeyframe(-24, duration: 0.00)
            CubicKeyframe(0, duration: 0.40)
            LinearKeyframe(0, duration: 1.95)
        }
        KeyframeTrack(\.figureRotation) {
            LinearKeyframe(0, duration: 0.75)
            CubicKeyframe(360, duration: 0.70)        // the spin
            LinearKeyframe(360, duration: 1.95)
        }
        // Ears, tail and zipper pull all trail as streamers through the spin.
        KeyframeTrack(\.earL_base) {
            LinearKeyframe(0, duration: 0.58)
            CubicKeyframe(-18, duration: 0.17)
            CubicKeyframe(25, duration: 0.35)
            SpringKeyframe(0, duration: 0.50, spring: .init(response: 0.40, dampingRatio: 0.42))
            LinearKeyframe(0, duration: 1.80)
        }
        KeyframeTrack(\.earR_base) {
            LinearKeyframe(0, duration: 0.58)
            CubicKeyframe(8, duration: 0.17)
            CubicKeyframe(-35, duration: 0.35)
            SpringKeyframe(0, duration: 0.50, spring: .init(response: 0.45, dampingRatio: 0.40))
            LinearKeyframe(0, duration: 1.80)
        }
        KeyframeTrack(\.earL_tip) {
            LinearKeyframe(0, duration: 0.85)
            CubicKeyframe(40, duration: 0.30)
            SpringKeyframe(0, duration: 0.55, spring: .init(response: 0.35, dampingRatio: 0.40))
            LinearKeyframe(0, duration: 1.70)
        }
        KeyframeTrack(\.earR_tip) {
            LinearKeyframe(0, duration: 0.85)
            CubicKeyframe(-60, duration: 0.30)
            SpringKeyframe(0, duration: 0.55, spring: .init(response: 0.45, dampingRatio: 0.38))
            LinearKeyframe(0, duration: 1.70)
        }
        KeyframeTrack(\.zipperPull) {
            LinearKeyframe(0, duration: 0.80)
            CubicKeyframe(35, duration: 0.32)
            CubicKeyframe(-35, duration: 0.33)
            SpringKeyframe(0, duration: 0.45, spring: .init(response: 0.50, dampingRatio: 0.35))
            LinearKeyframe(0, duration: 1.50)
        }
        KeyframeTrack(\.tail) {
            LinearKeyframe(0, duration: 0.80)
            SpringKeyframe(18, duration: 0.20, spring: .init(response: 0.40, dampingRatio: 0.50))
            SpringKeyframe(0, duration: 0.20, spring: .init(response: 0.40, dampingRatio: 0.50))
            LinearKeyframe(0, duration: 2.20)
        }
        // Ta-da.
        KeyframeTrack(\.armL) {
            LinearKeyframe(0, duration: 1.95)
            SpringKeyframe(140, duration: 0.25, spring: .init(response: 0.28, dampingRatio: 0.45))
            LinearKeyframe(140, duration: 0.30)
            CubicKeyframe(0, duration: 0.25)
            LinearKeyframe(0, duration: 0.65)
        }
        KeyframeTrack(\.armR) {
            LinearKeyframe(0, duration: 1.95)
            SpringKeyframe(-140, duration: 0.25, spring: .init(response: 0.28, dampingRatio: 0.45))
            LinearKeyframe(-140, duration: 0.30)
            CubicKeyframe(0, duration: 0.25)
            LinearKeyframe(0, duration: 0.65)
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
