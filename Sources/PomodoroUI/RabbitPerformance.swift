import PomodoroCore
import SwiftUI

/// The rabbit costume's three performances.
///
/// The costume is cheerful and the man inside is deadpan. The costume parts (ears,
/// tail, zipper pull) act happy; the face stays flat, apart from a half-closed
/// eye, a blink, a sigh and, once, a tiny smile. Nothing here should be "fixed" by
/// making the face more expressive.
///
/// Elbow rule for every track below: an elbow folds one way only, 0 to 140
/// degrees, never past straight. The LEFT elbow folds with a positive angle and the
/// RIGHT elbow with a negative one. A raised arm therefore folds its forearm toward
/// the head. Spring keyframes on an elbow only ever settle on a fold large enough
/// that their overshoot cannot cross zero, and moving holds on an elbow drift in
/// the folding direction.
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

    /// The ears pop up happily, the man sighs and slumps, and he gives a limp salute:
    /// elbow out, paw flopping to his brow. Held, unimpressed, one slow blink. The arm
    /// drops and he sinks.
    @KeyframesBuilder<RabbitPose>
    public static var reluctantSalute: some Keyframes<RabbitPose> {
        // Rise 0 to 0.45, hold to 2.40, sink 2.40 to 2.80.
        KeyframeTrack(\.emergence) {
            SpringKeyframe(-8, duration: 0.45, spring: .init(response: 0.45, dampingRatio: 0.65))
            CubicKeyframe(0, duration: 0.15)
            Hold.moving(0, duration: 1.80, drift: 0.9)
            CubicKeyframe(-5, duration: 0.08)
            CubicKeyframe(200, duration: 0.32)
        }
        KeyframeTrack(\.rootScale) {
            CubicKeyframe(1.16, duration: 0.35)
            CubicKeyframe(1.10, duration: 0.25)
            Hold.moving(1.10, duration: 1.70, drift: 0.012)
            CubicKeyframe(1.0, duration: 0.50)
        }
        // Pop on the rise, then the sigh squashes him to 0.95, then he straightens a little.
        KeyframeTrack(\.figureScaleY) {
            CubicKeyframe(1.03, duration: 0.25)
            SpringKeyframe(1.0, duration: 0.20, spring: .init(response: 0.30, dampingRatio: 0.55))
            CubicKeyframe(0.95, duration: 0.55)
            CubicKeyframe(0.985, duration: 0.35)
            Hold.moving(0.985, duration: 0.75, drift: 0.010)
            CubicKeyframe(0.99, duration: 0.30)
            CubicKeyframe(1.03, duration: 0.08)
            CubicKeyframe(0.98, duration: 0.32)
        }
        // The slump: 3 degrees during the sigh, a little less in the salute.
        KeyframeTrack(\.figureRotation) {
            Hold.moving(0, duration: 0.45, drift: 0.5)
            CubicKeyframe(3, duration: 0.55)
            CubicKeyframe(1.2, duration: 0.35)
            Hold.moving(1.2, duration: 0.75, drift: 0.5)
            CubicKeyframe(0, duration: 0.30)
            Hold.moving(0, duration: 0.40, drift: 0.4)
        }
        // The head dips with the sigh, then tips back a touch into the salute.
        KeyframeTrack(\.head) {
            Hold.moving(0, duration: 0.45, drift: 0.5)
            CubicKeyframe(4, duration: 0.30)
            CubicKeyframe(2.5, duration: 0.25)
            CubicKeyframe(-2, duration: 0.35)
            Hold.moving(-2, duration: 0.75, drift: 0.8)
            CubicKeyframe(0, duration: 0.30)
            Hold.moving(0, duration: 0.40, drift: 0.5)
        }
        KeyframeTrack(\.torso) {
            Hold.moving(0, duration: 1.00, drift: 0.5)
            CubicKeyframe(2.5, duration: 0.35)
            Hold.moving(2.5, duration: 0.75, drift: 0.6)
            CubicKeyframe(0, duration: 0.30)
            Hold.moving(0, duration: 0.40, drift: 0.4)
        }
        // The salute arm. Shoulder: hangs and drops with the sigh, the elbow lifts out
        // to the side (-110), then up to -135. Elbow: 0 to -86 folds the forearm to the
        // brow, a slow limp flop that settles at -74.
        KeyframeTrack(\.armR) {
            Hold.moving(0, duration: 0.45, drift: 0.5)
            CubicKeyframe(3, duration: 0.55)
            CubicKeyframe(-110, duration: 0.20)
            CubicKeyframe(-135, duration: 0.22)
            Hold.moving(-135, duration: 0.68, drift: 1.2)
            CubicKeyframe(0, duration: 0.30)
            Hold.moving(0, duration: 0.40, drift: 0.5)
        }
        KeyframeTrack(\.armR_fore) {
            Hold.moving(0, duration: 0.45, drift: -0.6)
            CubicKeyframe(-6, duration: 0.55)
            CubicKeyframe(-12, duration: 0.12)
            CubicKeyframe(-72, duration: 0.22)
            CubicKeyframe(-62, duration: 0.16)
            Hold.moving(-62, duration: 0.60, drift: -1.5)
            CubicKeyframe(-4, duration: 0.30)
            Hold.moving(-4, duration: 0.40, drift: -0.8)
        }
        // The idle arm hangs, drops with the sigh and breathes.
        KeyframeTrack(\.armL) {
            Hold.moving(0, duration: 0.45, drift: 0.5)
            CubicKeyframe(2, duration: 0.55)
            Hold.breathing(2, duration: 1.40, drift: 0.8)
            Hold.moving(0, duration: 0.40, drift: 0.5)
        }
        KeyframeTrack(\.armL_fore) {
            Hold.moving(0, duration: 0.45, drift: 0.5)
            CubicKeyframe(5, duration: 0.55)
            Hold.breathing(5, duration: 1.40, drift: 1.0)
            Hold.moving(3, duration: 0.40, drift: 0.5)
        }
        // Left ear: pops up, then droops. Tips start 0.08s after their bases and swing further.
        KeyframeTrack(\.earL_base) {
            Hold.moving(0, duration: 0.15, drift: 0.5)
            SpringKeyframe(12, duration: 0.30, spring: .init(response: 0.30, dampingRatio: 0.50))
            Hold.moving(12, duration: 0.10, drift: 0.8)
            CubicKeyframe(-18, duration: 0.40)
            Hold.moving(-18, duration: 0.45, drift: -1.0)
            Hold.moving(-18, duration: 1.00, drift: -1.2)
            CubicKeyframe(0, duration: 0.40)
        }
        KeyframeTrack(\.earL_tip) {
            Hold.moving(0, duration: 0.23, drift: 0.8)
            SpringKeyframe(16, duration: 0.30, spring: .init(response: 0.35, dampingRatio: 0.45))
            Hold.moving(16, duration: 0.10, drift: 0.8)
            CubicKeyframe(-26, duration: 0.40)
            Hold.moving(-26, duration: 0.45, drift: -1.5)
            Hold.moving(-26, duration: 0.92, drift: -1.5)
            CubicKeyframe(0, duration: 0.40)
        }
        // Right ear: pops up, droops 0.15s after the left one, tries to rise again at
        // the salute and fails.
        KeyframeTrack(\.earR_base) {
            Hold.moving(0, duration: 0.10, drift: -0.5)
            SpringKeyframe(-72, duration: 0.35, spring: .init(response: 0.40, dampingRatio: 0.55))
            Hold.moving(-72, duration: 0.25, drift: -1.5)
            CubicKeyframe(0, duration: 0.40)
            CubicKeyframe(-34, duration: 0.20)
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.40, dampingRatio: 0.50))
            Hold.moving(0, duration: 0.80, drift: 0.8)
            Hold.moving(0, duration: 0.40, drift: 0.8)
        }
        KeyframeTrack(\.earR_tip) {
            Hold.moving(0, duration: 0.18, drift: -1)
            SpringKeyframe(-30, duration: 0.35, spring: .init(response: 0.45, dampingRatio: 0.50))
            Hold.moving(-30, duration: 0.25, drift: -1.5)
            CubicKeyframe(10, duration: 0.35)
            CubicKeyframe(-38, duration: 0.22)
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.45, dampingRatio: 0.45))
            Hold.moving(0, duration: 0.75, drift: 1.0)
            Hold.moving(0, duration: 0.40, drift: 1.0)
        }
        // The face: eyes half-close through the sigh, open for the salute, then one slow
        // blink at 1.7s.
        KeyframeTrack(\.blinkOpacity) {
            LinearKeyframe(0, duration: 0.45)
            LinearKeyframe(0.55, duration: 0.40)
            LinearKeyframe(0.55, duration: 0.40)
            LinearKeyframe(0, duration: 0.25)
            LinearKeyframe(0, duration: 0.10)
            LinearKeyframe(1, duration: 0.12)
            LinearKeyframe(1, duration: 0.08)
            LinearKeyframe(0, duration: 0.12)
            LinearKeyframe(0, duration: 0.88)
        }
        KeyframeTrack(\.tail) {
            LinearKeyframe(0, duration: 0.20)
            SpringKeyframe(14, duration: 0.12, spring: .init(response: 0.30, dampingRatio: 0.50))
            SpringKeyframe(0, duration: 0.25, spring: .init(response: 0.40, dampingRatio: 0.50))
            Hold.moving(0, duration: 2.23, drift: 0.8)
        }
        KeyframeTrack(\.zipperPull) {
            LinearKeyframe(0, duration: 0.50)
            SpringKeyframe(18, duration: 0.30, spring: .init(response: 0.50, dampingRatio: 0.35))
            SpringKeyframe(-8, duration: 0.30, spring: .init(response: 0.50, dampingRatio: 0.35))
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.50, dampingRatio: 0.35))
            Hold.moving(0, duration: 1.40, drift: 0.5)
        }
    }

    // MARK: - breakStart · "Mandatory fun" (3.0s)

    /// The costume makes him do one big hop with half-hearted jazz hands at the top. He
    /// lands, one ear flops over his face, he slowly pushes it away with a paw and the
    /// ear springs back. He sighs and sinks.
    ///
    /// The plan has the left paw push the ear. The flopped ear is the right one, so the
    /// right paw does it: the left paw would have to reach across the whole face.
    @KeyframesBuilder<RabbitPose>
    public static var twoHops: some Keyframes<RabbitPose> {
        // Rise 0 to 0.45, hold to 2.50, sink 2.50 to 3.00.
        KeyframeTrack(\.emergence) {
            SpringKeyframe(0, duration: 0.45, spring: .init(response: 0.45, dampingRatio: 0.60))
            Hold.moving(0, duration: 2.05, drift: 0.9)
            CubicKeyframe(-6, duration: 0.10)
            CubicKeyframe(200, duration: 0.40)
        }
        // Crouch 0.45-0.65, hop 0.65-1.05 with the apex at 0.85, land at 1.05.
        KeyframeTrack(\.figureLift) {
            Hold.moving(0, duration: 0.65, drift: 0.3)
            CubicKeyframe(-30, duration: 0.20)
            CubicKeyframe(0, duration: 0.20)
            Hold.moving(0, duration: 1.95, drift: 0.4)
        }
        KeyframeTrack(\.figureScaleY) {
            Hold.moving(1, duration: 0.45, drift: 0.01)
            CubicKeyframe(0.92, duration: 0.20)
            CubicKeyframe(1.07, duration: 0.12)
            CubicKeyframe(1.02, duration: 0.28)
            CubicKeyframe(0.90, duration: 0.07)
            SpringKeyframe(1.0, duration: 0.18, spring: .init(response: 0.30, dampingRatio: 0.55))
            Hold.moving(1.0, duration: 0.55, drift: 0.012)
            CubicKeyframe(0.975, duration: 0.35)
            CubicKeyframe(1.0, duration: 0.30)
            CubicKeyframe(1.03, duration: 0.10)
            CubicKeyframe(0.98, duration: 0.40)
        }
        KeyframeTrack(\.legsScaleY) {
            Hold.moving(1, duration: 0.45, drift: 0.01)
            CubicKeyframe(0.93, duration: 0.20)
            CubicKeyframe(1.03, duration: 0.12)
            CubicKeyframe(1.0, duration: 0.28)
            CubicKeyframe(0.92, duration: 0.08)
            SpringKeyframe(1.0, duration: 0.20, spring: .init(response: 0.30, dampingRatio: 0.55))
            Hold.moving(1.0, duration: 1.67, drift: 0.01)
        }
        KeyframeTrack(\.figureRotation) {
            Hold.moving(0, duration: 0.45, drift: 0.4)
            CubicKeyframe(-3, duration: 0.20)
            CubicKeyframe(4, duration: 0.20)
            CubicKeyframe(1, duration: 0.20)
            CubicKeyframe(-2, duration: 0.12)
            CubicKeyframe(0, duration: 0.28)
            Hold.moving(0, duration: 1.55, drift: 0.5)
        }
        // Head 0.12s behind the figure, against it. A deadpan nod on the sigh.
        KeyframeTrack(\.head) {
            Hold.moving(0, duration: 0.45, drift: 0.4)
            CubicKeyframe(2, duration: 0.25)
            CubicKeyframe(-4, duration: 0.25)
            CubicKeyframe(3, duration: 0.25)
            CubicKeyframe(-3, duration: 0.25)
            Hold.moving(-3, duration: 0.45, drift: 0.5)
            CubicKeyframe(2.5, duration: 0.35)
            CubicKeyframe(0, duration: 0.35)
            Hold.moving(0, duration: 0.40, drift: 0.4)
        }
        KeyframeTrack(\.torso) {
            Hold.moving(0, duration: 0.45, drift: 0.4)
            CubicKeyframe(2, duration: 0.40)
            CubicKeyframe(-2, duration: 0.35)
            CubicKeyframe(0, duration: 0.40)
            Hold.moving(0, duration: 1.40, drift: 0.5)
        }
        KeyframeTrack(\.torsoSway) {
            Hold.moving(0, duration: 0.45, drift: 0.3)
            CubicKeyframe(1.5, duration: 0.40)
            CubicKeyframe(-1, duration: 0.35)
            CubicKeyframe(0, duration: 0.40)
            Hold.moving(0, duration: 1.40, drift: 0.3)
        }
        // LEFT arm: jazz hands at the top (shoulder 70, elbow 30), drops at the landing.
        KeyframeTrack(\.armL) {
            Hold.moving(0, duration: 0.45, drift: 0.5)
            CubicKeyframe(8, duration: 0.20)
            SpringKeyframe(70, duration: 0.18, spring: .init(response: 0.26, dampingRatio: 0.50))
            Hold.moving(70, duration: 0.17, drift: 2.0)
            CubicKeyframe(4, duration: 0.22)
            SpringKeyframe(0, duration: 0.18, spring: .init(response: 0.30, dampingRatio: 0.55))
            Hold.breathing(0, duration: 1.60, drift: 0.8)
        }
        KeyframeTrack(\.armL_fore) {
            Hold.moving(0, duration: 0.45, drift: 0.5)
            CubicKeyframe(4, duration: 0.20)
            SpringKeyframe(30, duration: 0.25, spring: .init(response: 0.28, dampingRatio: 0.50))
            Hold.moving(30, duration: 0.10, drift: 2.0)
            CubicKeyframe(10, duration: 0.22)
            CubicKeyframe(3, duration: 0.18)
            Hold.breathing(3, duration: 1.60, drift: 1.0)
        }
        // RIGHT arm: jazz hands a hair late, drops, then rises slowly to the ear on his
        // face, pushes it outward (forearm extends) and goes down.
        KeyframeTrack(\.armR) {
            Hold.moving(0, duration: 0.45, drift: -0.5)
            CubicKeyframe(-8, duration: 0.20)
            SpringKeyframe(-70, duration: 0.19, spring: .init(response: 0.26, dampingRatio: 0.50))
            Hold.moving(-70, duration: 0.16, drift: -2.0)
            CubicKeyframe(-4, duration: 0.22)
            CubicKeyframe(-100, duration: 0.42)
            CubicKeyframe(-132, duration: 0.20)
            CubicKeyframe(-140, duration: 0.16)
            Hold.moving(-140, duration: 0.10, drift: -1.0)
            CubicKeyframe(0, duration: 0.40)
            Hold.breathing(0, duration: 0.50, drift: -0.8)
        }
        KeyframeTrack(\.armR_fore) {
            Hold.moving(0, duration: 0.45, drift: -0.5)
            CubicKeyframe(-4, duration: 0.20)
            SpringKeyframe(-30, duration: 0.25, spring: .init(response: 0.28, dampingRatio: 0.50))
            Hold.moving(-30, duration: 0.10, drift: -2.0)
            CubicKeyframe(-8, duration: 0.22)
            CubicKeyframe(-70, duration: 0.42)
            CubicKeyframe(-80, duration: 0.20)
            CubicKeyframe(-30, duration: 0.16)
            Hold.moving(-30, duration: 0.10, drift: -2.0)
            CubicKeyframe(-6, duration: 0.40)
            Hold.breathing(-3, duration: 0.50, drift: -0.8)
        }
        // Left ear streams back on the hop and bounces on the landing.
        KeyframeTrack(\.earL_base) {
            Hold.moving(0, duration: 0.45, drift: 0.5)
            CubicKeyframe(6, duration: 0.20)
            CubicKeyframe(-18, duration: 0.20)
            CubicKeyframe(8, duration: 0.25)
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.40, dampingRatio: 0.45))
            Hold.moving(0, duration: 1.60, drift: 1.0)
        }
        KeyframeTrack(\.earL_tip) {
            Hold.moving(0, duration: 0.53, drift: 0.8)
            CubicKeyframe(10, duration: 0.20)
            CubicKeyframe(-28, duration: 0.20)
            CubicKeyframe(12, duration: 0.25)
            SpringKeyframe(0, duration: 0.32, spring: .init(response: 0.35, dampingRatio: 0.45))
            Hold.moving(0, duration: 1.50, drift: 1.0)
        }
        // Right ear: whips up on the hop, flops forward over his face at the landing,
        // stays there while he pushes it, then springs back.
        KeyframeTrack(\.earR_base) {
            Hold.moving(0, duration: 0.45, drift: -0.5)
            CubicKeyframe(6, duration: 0.20)
            CubicKeyframe(-24, duration: 0.20)
            CubicKeyframe(-6, duration: 0.20)
            CubicKeyframe(66, duration: 0.22)
            Hold.moving(66, duration: 0.48, drift: 2.0)
            SpringKeyframe(0, duration: 0.35, spring: .init(response: 0.45, dampingRatio: 0.40))
            Hold.moving(0, duration: 0.90, drift: -1.0)
        }
        KeyframeTrack(\.earR_tip) {
            Hold.moving(0, duration: 0.53, drift: -0.8)
            CubicKeyframe(8, duration: 0.20)
            CubicKeyframe(-36, duration: 0.20)
            CubicKeyframe(-8, duration: 0.20)
            CubicKeyframe(14, duration: 0.20)
            Hold.moving(14, duration: 0.50, drift: 2.0)
            SpringKeyframe(0, duration: 0.35, spring: .init(response: 0.45, dampingRatio: 0.40))
            Hold.moving(0, duration: 0.82, drift: 1.0)
        }
        // Flat face, a sigh once the ear is back, one blink after it.
        KeyframeTrack(\.sighOpacity) {
            LinearKeyframe(0, duration: 1.80)
            LinearKeyframe(1, duration: 0.10)
            LinearKeyframe(1, duration: 0.40)
            LinearKeyframe(0, duration: 0.15)
            LinearKeyframe(0, duration: 0.55)
        }
        KeyframeTrack(\.blinkOpacity) {
            LinearKeyframe(0, duration: 2.15)
            LinearKeyframe(1, duration: 0.07)
            LinearKeyframe(1, duration: 0.08)
            LinearKeyframe(0, duration: 0.10)
            LinearKeyframe(0, duration: 0.60)
        }
        // The tail flicks at the landing.
        KeyframeTrack(\.tail) {
            Hold.moving(0, duration: 0.95, drift: 0.5)
            SpringKeyframe(20, duration: 0.12, spring: .init(response: 0.30, dampingRatio: 0.50))
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.40, dampingRatio: 0.50))
            Hold.moving(0, duration: 1.63, drift: 0.8)
        }
        KeyframeTrack(\.zipperPull) {
            Hold.moving(0, duration: 0.65, drift: 0.5)
            SpringKeyframe(25, duration: 0.25, spring: .init(response: 0.50, dampingRatio: 0.35))
            SpringKeyframe(-14, duration: 0.25, spring: .init(response: 0.50, dampingRatio: 0.35))
            SpringKeyframe(0, duration: 0.35, spring: .init(response: 0.50, dampingRatio: 0.35))
            Hold.moving(0, duration: 1.50, drift: 0.5)
        }
    }

    // MARK: - longBreak · "Mascot mode" (3.4s)

    /// For once he commits: deep crouch, a jump with one full spin, a landing straight
    /// into a ta-da with both arms wide. His face cracks into a tiny smile for half a
    /// second, then goes flat again. He lowers his arms, blinks and sinks.
    @KeyframesBuilder<RabbitPose>
    public static var fullMascotMode: some Keyframes<RabbitPose> {
        // Rise 0 to 0.50, hold to 2.90, sink 2.90 to 3.40.
        KeyframeTrack(\.emergence) {
            SpringKeyframe(-10, duration: 0.40, spring: .init(response: 0.42, dampingRatio: 0.55))
            CubicKeyframe(0, duration: 0.10)
            Hold.moving(0, duration: 2.40, drift: 0.9)
            CubicKeyframe(-5, duration: 0.08)
            CubicKeyframe(200, duration: 0.42)
        }
        // Crouch 0.50-0.80, jump 0.80-1.40 (apex 1.10), land and squash 1.40-1.60.
        KeyframeTrack(\.figureLift) {
            Hold.moving(0, duration: 0.80, drift: 0.3)
            CubicKeyframe(-34, duration: 0.30)
            CubicKeyframe(0, duration: 0.30)
            Hold.moving(0, duration: 2.00, drift: 0.5)
        }
        KeyframeTrack(\.figureScaleY) {
            Hold.moving(1, duration: 0.50, drift: 0.01)
            CubicKeyframe(0.88, duration: 0.30)
            CubicKeyframe(1.08, duration: 0.12)
            CubicKeyframe(1.03, duration: 0.38)
            CubicKeyframe(1.06, duration: 0.10)
            CubicKeyframe(0.90, duration: 0.10)
            CubicKeyframe(1.04, duration: 0.10)
            SpringKeyframe(1.0, duration: 0.20, spring: .init(response: 0.35, dampingRatio: 0.50))
            Hold.moving(1.0, duration: 0.70, drift: 0.012)
            Hold.moving(1.0, duration: 0.40, drift: 0.012)
            CubicKeyframe(1.03, duration: 0.08)
            CubicKeyframe(0.97, duration: 0.42)
        }
        KeyframeTrack(\.legsScaleY) {
            Hold.moving(1, duration: 0.50, drift: 0.01)
            CubicKeyframe(0.93, duration: 0.30)
            CubicKeyframe(1.03, duration: 0.12)
            CubicKeyframe(1.0, duration: 0.48)
            CubicKeyframe(0.92, duration: 0.10)
            SpringKeyframe(1.0, duration: 0.30, spring: .init(response: 0.30, dampingRatio: 0.55))
            Hold.moving(1.0, duration: 1.60, drift: 0.01)
        }
        // One turn about the vertical axis. A small wind-up the other way, then a fast
        // turn that eases out so he faces front again as he lands at 1.40.
        KeyframeTrack(\.figureSpin) {
            LinearKeyframe(0, duration: 0.50)
            CubicKeyframe(-22, duration: 0.30)
            CubicKeyframe(360, duration: 0.60, startVelocity: 1500, endVelocity: 0)
            LinearKeyframe(360, duration: 2.00)
        }
        KeyframeTrack(\.figureRotation) {
            Hold.moving(0, duration: 0.50, drift: 0.3)
            CubicKeyframe(-3, duration: 0.30)
            CubicKeyframe(3, duration: 0.30)
            CubicKeyframe(0, duration: 0.30)
            Hold.moving(0, duration: 2.00, drift: 0.5)
        }
        KeyframeTrack(\.head) {
            Hold.moving(0, duration: 0.50, drift: 0.4)
            CubicKeyframe(5, duration: 0.30)
            CubicKeyframe(-5, duration: 0.30)
            CubicKeyframe(4, duration: 0.30)
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.35, dampingRatio: 0.55))
            Hold.moving(0, duration: 1.70, drift: 0.9)
        }
        KeyframeTrack(\.torso) {
            Hold.moving(0, duration: 0.50, drift: 0.4)
            CubicKeyframe(4, duration: 0.30)
            CubicKeyframe(-2, duration: 0.30)
            CubicKeyframe(2, duration: 0.30)
            CubicKeyframe(-3, duration: 0.20)
            Hold.moving(-3, duration: 0.90, drift: 0.7)
            CubicKeyframe(0, duration: 0.30)
            Hold.moving(0, duration: 0.60, drift: 0.4)
        }
        // Ears, tail and zipper pull trail through the jump. Tips start 0.08s after their bases.
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
        // Tail wags twice at the ta-da, the second wag smaller.
        KeyframeTrack(\.tail) {
            Hold.moving(0, duration: 1.55, drift: 0.8)
            SpringKeyframe(24, duration: 0.10, spring: .init(response: 0.25, dampingRatio: 0.50))
            SpringKeyframe(-14, duration: 0.12, spring: .init(response: 0.25, dampingRatio: 0.50))
            SpringKeyframe(11, duration: 0.10, spring: .init(response: 0.25, dampingRatio: 0.50))
            SpringKeyframe(-5, duration: 0.12, spring: .init(response: 0.25, dampingRatio: 0.50))
            SpringKeyframe(0, duration: 0.20, spring: .init(response: 0.30, dampingRatio: 0.50))
            Hold.moving(0, duration: 1.21, drift: 0.8)
        }
        // Left arm. Swings back in the crouch, stays close to the body in the jump, dips
        // at the landing, then goes up and out to 128 (plan: 140; 140 hugged the head). The elbow folds as the arm starts
        // up and opens 0.1s after the shoulder arrives.
        KeyframeTrack(\.armL) {
            Hold.moving(0, duration: 0.50, drift: 0.5)
            CubicKeyframe(12, duration: 0.30)
            CubicKeyframe(3, duration: 0.25)
            Hold.moving(3, duration: 0.35, drift: 0.8)
            CubicKeyframe(8, duration: 0.10)
            SpringKeyframe(128, duration: 0.28, spring: .init(response: 0.30, dampingRatio: 0.72))
            Hold.moving(128, duration: 0.72, drift: 1.5)
            CubicKeyframe(0, duration: 0.40)
            Hold.moving(0, duration: 0.50, drift: 0.5)
        }
        KeyframeTrack(\.armL_fore) {
            Hold.moving(0, duration: 0.50, drift: 0.5)
            CubicKeyframe(8, duration: 0.30)
            CubicKeyframe(10, duration: 0.25)
            Hold.moving(10, duration: 0.35, drift: 0.8)
            CubicKeyframe(14, duration: 0.10)
            CubicKeyframe(26, duration: 0.28)
            SpringKeyframe(8, duration: 0.26, spring: .init(response: 0.32, dampingRatio: 0.60))
            Hold.breathing(8, duration: 0.46, drift: 0.8)
            CubicKeyframe(4, duration: 0.40)
            Hold.breathing(4, duration: 0.50, drift: 0.6)
        }
        // Right arm: the same, a hair later so the two do not move as a mirror image.
        KeyframeTrack(\.armR) {
            Hold.moving(0, duration: 0.50, drift: -0.5)
            CubicKeyframe(-12, duration: 0.30)
            CubicKeyframe(-4, duration: 0.25)
            Hold.moving(-4, duration: 0.37, drift: -0.8)
            CubicKeyframe(-8, duration: 0.10)
            SpringKeyframe(-128, duration: 0.28, spring: .init(response: 0.30, dampingRatio: 0.72))
            Hold.moving(-128, duration: 0.70, drift: -1.5)
            CubicKeyframe(0, duration: 0.40)
            Hold.moving(0, duration: 0.50, drift: -0.5)
        }
        KeyframeTrack(\.armR_fore) {
            Hold.moving(0, duration: 0.50, drift: -0.5)
            CubicKeyframe(-8, duration: 0.30)
            CubicKeyframe(-10, duration: 0.25)
            Hold.moving(-10, duration: 0.37, drift: -0.8)
            CubicKeyframe(-14, duration: 0.10)
            CubicKeyframe(-26, duration: 0.28)
            SpringKeyframe(-8, duration: 0.26, spring: .init(response: 0.32, dampingRatio: 0.60))
            Hold.breathing(-8, duration: 0.44, drift: -0.8)
            CubicKeyframe(-4, duration: 0.40)
            Hold.breathing(-4, duration: 0.50, drift: -0.6)
        }
        // Tiny smile 1.8 to 2.3, then flat. A blink while the arms come down.
        KeyframeTrack(\.smileOpacity) {
            LinearKeyframe(0, duration: 1.75)
            LinearKeyframe(1, duration: 0.10)
            LinearKeyframe(1, duration: 0.40)
            LinearKeyframe(0, duration: 0.10)
            LinearKeyframe(0, duration: 1.05)
        }
        KeyframeTrack(\.blinkOpacity) {
            LinearKeyframe(0, duration: 2.55)
            LinearKeyframe(1, duration: 0.08)
            LinearKeyframe(1, duration: 0.10)
            LinearKeyframe(0, duration: 0.10)
            LinearKeyframe(0, duration: 0.57)
        }
    }
}
