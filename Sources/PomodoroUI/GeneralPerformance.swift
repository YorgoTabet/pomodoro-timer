import PomodoroCore
import SwiftUI

/// The General's three performances: "Inspection", "At ease" and "Parade".
///
/// His celebration is cadence rather than a spin: he marches. That suits him
/// better than acrobatics and keeps him distinct from the ninja's backflip and the
/// samurai's leap.
///
/// Arm angles come from solving the rig for where each hand has to be (hand on the
/// far palm, salute at the cap brim, hand behind his back). The arms are short, so
/// the salute and the hand-to-shades have the elbow up and out. Elbow bends keep the
/// elbow as the outward point of the bend in every frame; the forearm only crosses
/// "straight" while the arm is mid-swing between two poses.
public enum GeneralPerformance {

    public static func preferredEdge(for cue: CharacterCue) -> StageEdge { .top }

    public static func comesForward(for cue: CharacterCue) -> Bool {
        cue == .focusStart
    }

    public static func duration(for cue: CharacterCue) -> Double {
        switch cue {
        case .focusStart: 3.00
        case .breakStart: 2.40
        case .longBreak: 3.40
        }
    }


    // MARK: - focusStart · "Inspection" (3.0s)

    /// He rises at attention with his chest puffed, taps the stick into his far palm
    /// twice (the second tap is harder and makes his cap jump), levels it at you while
    /// he barks, tucks it along his forearm, salutes with the far hand and sinks.
    ///
    /// Stick angles are relative to the forearm. 172 rests it level on the far palm,
    /// 248 levels it across his chest at you, and 407 lays it back along the forearm,
    /// swept round through "pointing down" so it never passes the face.
    @KeyframesBuilder<GeneralPose>
    public static var backToTheFront: some Keyframes<GeneralPose> {
        backToTheFrontBody
        backToTheFrontArms
        backToTheFrontFace
    }

    @KeyframesBuilder<GeneralPose>
    static var backToTheFrontBody: some Keyframes<GeneralPose> {
        // 0.00 rise, 0.35 tap 1, 0.85 tap 2, 1.05 point, 1.30 hold, 1.90 tuck + salute,
        // 2.60 sink.
        KeyframeTrack(\.emergence) {
            SpringKeyframe(6, duration: 0.30, spring: .init(response: 0.42, dampingRatio: 0.65))
            SpringKeyframe(-12, duration: 0.65, spring: .init(response: 0.50, dampingRatio: 0.80))
            Hold.moving(-12, duration: 1.65, drift: 0.9)
            CubicKeyframe(-18, duration: 0.08)        // small rise before the drop
            CubicKeyframe(200, duration: 0.32, startVelocity: 0)
        }
        KeyframeTrack(\.figureScale) {
            LinearKeyframe(1, duration: 0.55)
            CubicKeyframe(1.1, duration: 0.40)        // proximity reads as size
            Hold.moving(1.1, duration: 1.5, drift: 0.014)
            CubicKeyframe(1.0, duration: 0.20)
            LinearKeyframe(1.0, duration: 0.35)
        }
        KeyframeTrack(\.figureScaleY) {
            LinearKeyframe(0.9, duration: 0.15)
            SpringKeyframe(1.04, duration: 0.20, spring: .init(response: 0.3, dampingRatio: 0.55))
            SpringKeyframe(1.0, duration: 0.20, spring: .init(response: 0.3, dampingRatio: 0.55))
            Hold.moving(1.0, duration: 2.45, drift: 0.014)
        }
        // Chest puffed on the rise, puffed harder for the bark, let down on the salute.
        KeyframeTrack(\.torsoScaleY) {
            LinearKeyframe(1, duration: 0.15)
            CubicKeyframe(1.06, duration: 0.20)
            Hold.moving(1.06, duration: 0.70, drift: 0.012)
            CubicKeyframe(1.09, duration: 0.20)
            Hold.moving(1.09, duration: 0.65, drift: 0.012)
            CubicKeyframe(1.0, duration: 0.35)
            Hold.moving(1.0, duration: 0.75, drift: 0.012)
        }
        // A small lean into each tap, a 5 degree lean into the point.
        KeyframeTrack(\.torso) {
            Hold.moving(0, duration: 0.55, drift: 0.4)
            CubicKeyframe(1.5, duration: 0.12)
            CubicKeyframe(0, duration: 0.15)
            CubicKeyframe(2.5, duration: 0.14)
            CubicKeyframe(0, duration: 0.09)
            CubicKeyframe(5, duration: 0.25)
            Hold.breathing(5, duration: 0.60, drift: 0.6)
            CubicKeyframe(0, duration: 0.35)
            Hold.moving(0, duration: 0.75, drift: 0.5)
        }
        // Chin up on the rise, eyes down at the palm for the taps, chin up for the bark.
        KeyframeTrack(\.head) {
            LinearKeyframe(0, duration: 0.15)
            CubicKeyframe(-3, duration: 0.20)
            CubicKeyframe(2, duration: 0.23)
            CubicKeyframe(4, duration: 0.08)
            CubicKeyframe(1.5, duration: 0.14)
            CubicKeyframe(2, duration: 0.08)
            CubicKeyframe(5.5, duration: 0.10)
            CubicKeyframe(-6, duration: 0.32)
            Hold.moving(-6, duration: 0.60, drift: 0.6)
            CubicKeyframe(0, duration: 0.35)
            Hold.moving(0, duration: 0.75, drift: 0.5)
        }
        // A small weight shift onto the near leg for the bark, boot counter-turned flat.
        KeyframeTrack(\.legNear) {
            Hold.moving(0, duration: 1.00, drift: 0.3)
            CubicKeyframe(2.5, duration: 0.20)
            Hold.moving(2.5, duration: 0.70, drift: 0.3)
            CubicKeyframe(0, duration: 0.30)
            Hold.moving(0, duration: 0.80, drift: 0.3)
        }
        KeyframeTrack(\.bootNear) {
            Hold.moving(0, duration: 1.00, drift: 0.3)
            CubicKeyframe(-2.5, duration: 0.20)
            Hold.moving(-2.5, duration: 0.70, drift: 0.3)
            CubicKeyframe(0, duration: 0.30)
            Hold.moving(0, duration: 0.80, drift: 0.3)
        }
    }

    @KeyframesBuilder<GeneralPose>
    static var backToTheFrontArms: some Keyframes<GeneralPose> {
        // Far arm: palm up at his waist, fist on his hip, then up to the cap brim.
        KeyframeTrack(\.armFar) {
            Hold.moving(0, duration: 0.35, drift: 0.4)
            SpringKeyframe(-2, duration: 0.25, spring: .init(response: 0.35, dampingRatio: 0.72))
            Hold.moving(-2, duration: 0.45, drift: 0.6)
            SpringKeyframe(-22, duration: 0.25, spring: .init(response: 0.34, dampingRatio: 0.70))
            Hold.moving(-22, duration: 0.60, drift: 0.8)
            CubicKeyframe(-45, duration: 0.12)        // the elbow comes up beside him
            CubicKeyframe(-85, duration: 0.10)
            SpringKeyframe(-124, duration: 0.15, spring: .init(response: 0.28, dampingRatio: 0.66))
            Hold.moving(-124, duration: 0.33, drift: 0.8)
            CubicKeyframe(-118, duration: 0.40)
        }
        KeyframeTrack(\.foreFar) {
            Hold.moving(0, duration: 0.38, drift: 0.4)
            SpringKeyframe(50, duration: 0.27, spring: .init(response: 0.35, dampingRatio: 0.70))
            CubicKeyframe(55, duration: 0.07)         // the palm gives under tap 1
            CubicKeyframe(50, duration: 0.10)
            CubicKeyframe(52, duration: 0.12)
            CubicKeyframe(58, duration: 0.07)         // and gives more under the hard tap 2
            CubicKeyframe(50, duration: 0.07)
            SpringKeyframe(82, duration: 0.25, spring: .init(response: 0.34, dampingRatio: 0.70))
            Hold.moving(82, duration: 0.57, drift: 0.8)
            // The forearm unfolds while the arm still hangs, then folds up tight, so it
            // is never a straight arm swinging out.
            CubicKeyframe(-45, duration: 0.12)
            CubicKeyframe(-105, duration: 0.10)
            SpringKeyframe(-81, duration: 0.15, spring: .init(response: 0.28, dampingRatio: 0.66))
            Hold.moving(-81, duration: 0.33, drift: 0.8)
            CubicKeyframe(-70, duration: 0.40)
        }
        // Near arm: stick in to the far palm, across the chest, back to the forearm.
        KeyframeTrack(\.armNear) {
            Hold.moving(0, duration: 0.35, drift: 0.4)
            SpringKeyframe(-21, duration: 0.23, spring: .init(response: 0.34, dampingRatio: 0.72))
            CubicKeyframe(-23, duration: 0.08)
            CubicKeyframe(-20, duration: 0.14)
            CubicKeyframe(-18, duration: 0.08)
            CubicKeyframe(-26, duration: 0.10)
            CubicKeyframe(-21, duration: 0.10)
            SpringKeyframe(-45, duration: 0.22, spring: .init(response: 0.30, dampingRatio: 0.62))
            Hold.moving(-45, duration: 0.60, drift: 0.7)
            SpringKeyframe(0, duration: 0.35, spring: .init(response: 0.40, dampingRatio: 0.75))
            Hold.moving(0, duration: 0.75, drift: 0.5)
        }
        KeyframeTrack(\.foreNear) {
            Hold.moving(0, duration: 0.38, drift: 0.4)
            SpringKeyframe(-29, duration: 0.24, spring: .init(response: 0.34, dampingRatio: 0.72))
            CubicKeyframe(-26, duration: 0.06)
            CubicKeyframe(-30, duration: 0.12)
            CubicKeyframe(-34, duration: 0.09)
            CubicKeyframe(-27, duration: 0.10)
            CubicKeyframe(-29, duration: 0.09)
            SpringKeyframe(-78, duration: 0.25, spring: .init(response: 0.30, dampingRatio: 0.62))
            Hold.moving(-78, duration: 0.57, drift: 0.7)
            SpringKeyframe(-75, duration: 0.35, spring: .init(response: 0.40, dampingRatio: 0.75))
            Hold.moving(-75, duration: 0.35, drift: 0.7)
            Hold.moving(-75, duration: 0.40, drift: 0.5)
        }
        KeyframeTrack(\.stick) {
            Hold.moving(0, duration: 0.35, drift: 0.6)
            SpringKeyframe(142, duration: 0.25, spring: .init(response: 0.30, dampingRatio: 0.70))
            CubicKeyframe(172, duration: 0.07)        // tap 1, light
            CubicKeyframe(150, duration: 0.13)
            CubicKeyframe(124, duration: 0.08)        // wind up higher
            CubicKeyframe(172, duration: 0.09)        // tap 2, hard
            SpringKeyframe(160, duration: 0.11, spring: .init(response: 0.25, dampingRatio: 0.55))
            SpringKeyframe(182, duration: 0.22, spring: .init(response: 0.30, dampingRatio: 0.62))
            Hold.moving(182, duration: 0.60, drift: 0.8)
            SpringKeyframe(407, duration: 0.35, spring: .init(response: 0.40, dampingRatio: 0.78))
            Hold.moving(407, duration: 0.35, drift: 0.8)
            Hold.moving(407, duration: 0.40, drift: 0.5)
        }
        // Pointed at you the stick is foreshortened to a short stub, and lengthens again
        // as he lays it back along his forearm.
        KeyframeTrack(\.stickLength) {
            LinearKeyframe(1, duration: 1.08)
            SpringKeyframe(0.36, duration: 0.22, spring: .init(response: 0.30, dampingRatio: 0.62))
            Hold.moving(0.36, duration: 0.60, drift: 0.01)
            SpringKeyframe(1, duration: 0.30, spring: .init(response: 0.36, dampingRatio: 0.75))
            LinearKeyframe(1, duration: 0.80)
        }
    }

    @KeyframesBuilder<GeneralPose>
    static var backToTheFrontFace: some Keyframes<GeneralPose> {
        // The bark: mouth open, moustache lifts and bristles, cap hops on tap 2.
        KeyframeTrack(\.shoutOpacity) {
            LinearKeyframe(0, duration: 1.12)
            LinearKeyframe(1, duration: 0.12)
            LinearKeyframe(1, duration: 0.64)
            LinearKeyframe(0, duration: 0.12)
            LinearKeyframe(0, duration: 1.00)
        }
        KeyframeTrack(\.stacheLift) {
            Hold.moving(0, duration: 1.10, drift: 0.4)
            SpringKeyframe(-2.5, duration: 0.30, spring: .init(response: 0.30, dampingRatio: 0.50))
            LinearKeyframe(-2.5, duration: 0.48)
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.40, dampingRatio: 0.50))
            LinearKeyframe(0, duration: 0.82)
        }
        KeyframeTrack(\.stache) {
            Hold.moving(0, duration: 1.15, drift: 0.5)
            SpringKeyframe(-5, duration: 0.30, spring: .init(response: 0.30, dampingRatio: 0.50))
            LinearKeyframe(-5, duration: 0.45)
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.40, dampingRatio: 0.50))
            Hold.moving(0, duration: 0.80, drift: 0.5)
        }
        KeyframeTrack(\.capLift) {
            Hold.moving(0, duration: 0.97, drift: 0.4)
            SpringKeyframe(-3, duration: 0.08, spring: .init(response: 0.25, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.22, spring: .init(response: 0.35, dampingRatio: 0.45))
            Hold.moving(0, duration: 0.63, drift: 0.4)
            Hold.moving(0, duration: 0.35, drift: 0.4)
            Hold.moving(0, duration: 0.35, drift: 0.4)
            CubicKeyframe(-5, duration: 0.40)         // floats up as he drops
        }
        // Medals trail every beat by about two frames and settle late.
        KeyframeTrack(\.medalsLift) {
            LinearKeyframe(0, duration: 0.70)
            SpringKeyframe(1.2, duration: 0.10, spring: .init(response: 0.40, dampingRatio: 0.35))
            SpringKeyframe(0, duration: 0.12, spring: .init(response: 0.40, dampingRatio: 0.35))
            SpringKeyframe(2.5, duration: 0.10, spring: .init(response: 0.40, dampingRatio: 0.35))
            SpringKeyframe(-1, duration: 0.12, spring: .init(response: 0.40, dampingRatio: 0.35))
            SpringKeyframe(2, duration: 0.10, spring: .init(response: 0.40, dampingRatio: 0.30))
            SpringKeyframe(0, duration: 0.20, spring: .init(response: 0.40, dampingRatio: 0.30))
            Hold.moving(0, duration: 0.56, drift: 0.5)
            SpringKeyframe(2.5, duration: 0.10, spring: .init(response: 0.40, dampingRatio: 0.35))
            SpringKeyframe(-1, duration: 0.12, spring: .init(response: 0.40, dampingRatio: 0.35))
            SpringKeyframe(0, duration: 0.20, spring: .init(response: 0.40, dampingRatio: 0.35))
            Hold.moving(0, duration: 0.18, drift: 0.4)
            CubicKeyframe(-4, duration: 0.40)
        }
    }

    // MARK: - breakStart · "At ease" (2.4s)

    /// Hands go behind his back and his chest lets down. He rocks back on his heels
    /// and forward again, the aviators slide down his nose so his eyes peek over them,
    /// and a grin he would deny shows under the moustache. Then the near hand comes
    /// round and pushes the shades back up, dignity is restored, and he sinks.
    @KeyframesBuilder<GeneralPose>
    public static var atEase: some Keyframes<GeneralPose> {
        atEaseBody
        atEaseFace
        atEaseArms
    }

    @KeyframesBuilder<GeneralPose>
    static var atEaseBody: some Keyframes<GeneralPose> {
        // 0.00 rise, 0.40 hands behind, 0.72 shades slide, 1.10 grin, 1.45 near hand
        // comes round, 1.80 hand down, 2.10 sink.
        KeyframeTrack(\.emergence) {
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.50, dampingRatio: 0.72))
            Hold.moving(0, duration: 1.6, drift: 0.9)
            CubicKeyframe(-6, duration: 0.08)         // small rise before the drop
            CubicKeyframe(200, duration: 0.32, startVelocity: 0)
        }
        KeyframeTrack(\.figureScaleY) {
            Hold.moving(1, duration: 2.0, drift: 0.014)
            CubicKeyframe(1.03, duration: 0.08)
            CubicKeyframe(0.92, duration: 0.12)
            LinearKeyframe(0.92, duration: 0.20)
        }
        // The sigh: his chest lets down to 0.97 and stays relaxed until the shades go back.
        KeyframeTrack(\.torsoScaleY) {
            LinearKeyframe(1, duration: 0.35)
            CubicKeyframe(0.97, duration: 0.35)
            Hold.moving(0.97, duration: 1.00, drift: 0.012)
            CubicKeyframe(1.0, duration: 0.30)
            Hold.moving(1.0, duration: 0.40, drift: 0.012)
        }
        KeyframeTrack(\.torso) {
            Hold.moving(0, duration: 0.35, drift: 0.4)
            CubicKeyframe(2, duration: 0.35)
            Hold.breathing(2, duration: 0.80, drift: 0.6)
            CubicKeyframe(0, duration: 0.30)
            Hold.moving(0, duration: 0.60, drift: 0.4)
        }
        // Heel-toe rock: 4 back, 3 forward, home. The legs counter-rotate so the feet
        // stay planted.
        KeyframeTrack(\.figureRotation) {
            Hold.moving(0, duration: 0.70, drift: 0.3)
            CubicKeyframe(-4, duration: 0.20)
            CubicKeyframe(3, duration: 0.20)
            CubicKeyframe(0, duration: 0.25)
            Hold.moving(0, duration: 1.05, drift: 0.3)
        }
        KeyframeTrack(\.legNear) {
            Hold.moving(0, duration: 0.70, drift: 0.3)
            CubicKeyframe(4, duration: 0.20)
            CubicKeyframe(-3, duration: 0.20)
            CubicKeyframe(0, duration: 0.25)
            Hold.moving(0, duration: 1.05, drift: 0.3)
        }
        KeyframeTrack(\.legFar) {
            Hold.moving(0, duration: 0.70, drift: 0.3)
            CubicKeyframe(4, duration: 0.20)
            CubicKeyframe(-3, duration: 0.20)
            CubicKeyframe(0, duration: 0.25)
            Hold.moving(0, duration: 1.05, drift: 0.3)
        }
        // Head tilts 5 with the grin, back to level as the hand arrives.
        KeyframeTrack(\.head) {
            Hold.moving(0, duration: 1.10, drift: 0.4)
            CubicKeyframe(5, duration: 0.25)
            Hold.moving(5, duration: 0.15, drift: 0.4)
            CubicKeyframe(0, duration: 0.30)
            Hold.moving(0, duration: 0.60, drift: 0.4)
        }
    }

    @KeyframesBuilder<GeneralPose>
    static var atEaseFace: some Keyframes<GeneralPose> {
        // The aviators creep 19 down his nose, which is what lets the eyes show.
        KeyframeTrack(\.shadesSlide) {
            LinearKeyframe(0, duration: 0.72)
            CubicKeyframe(19, duration: 0.28)
            Hold.moving(19, duration: 0.70, drift: 0.4)       // held until the hand arrives
            SpringKeyframe(0, duration: 0.20, spring: .init(response: 0.28, dampingRatio: 0.50))
            Hold.moving(0, duration: 0.50, drift: 0.3)
        }
        KeyframeTrack(\.grinOpacity) {
            LinearKeyframe(0, duration: 1.05)
            LinearKeyframe(1, duration: 0.15)
            LinearKeyframe(1, duration: 0.30)
            LinearKeyframe(0, duration: 0.15)
            LinearKeyframe(0, duration: 0.75)
        }
        KeyframeTrack(\.stacheLift) {
            Hold.moving(0, duration: 1.05, drift: 0.3)
            SpringKeyframe(-2.5, duration: 0.25, spring: .init(response: 0.35, dampingRatio: 0.50))
            LinearKeyframe(-2.5, duration: 0.20)
            SpringKeyframe(0, duration: 0.25, spring: .init(response: 0.40, dampingRatio: 0.50))
            Hold.moving(0, duration: 0.65, drift: 0.3)
        }
        KeyframeTrack(\.stacheScaleY) {
            LinearKeyframe(1, duration: 1.05)
            SpringKeyframe(1.1, duration: 0.25, spring: .init(response: 0.35, dampingRatio: 0.50))
            Hold.moving(1.1, duration: 0.20, drift: 0.01)
            SpringKeyframe(1.0, duration: 0.25, spring: .init(response: 0.40, dampingRatio: 0.50))
            Hold.moving(1.0, duration: 0.65, drift: 0.01)
        }
        KeyframeTrack(\.medals) {
            Hold.moving(0, duration: 0.85, drift: 0.5)
            SpringKeyframe(-4, duration: 0.20, spring: .init(response: 0.45, dampingRatio: 0.35))
            SpringKeyframe(3, duration: 0.20, spring: .init(response: 0.45, dampingRatio: 0.35))
            SpringKeyframe(0, duration: 0.25, spring: .init(response: 0.45, dampingRatio: 0.35))
            Hold.moving(0, duration: 0.90, drift: 0.4)
        }
        KeyframeTrack(\.medalsLift) {
            LinearKeyframe(0, duration: 0.08)
            SpringKeyframe(2, duration: 0.20, spring: .init(response: 0.40, dampingRatio: 0.35))
            SpringKeyframe(0, duration: 0.22, spring: .init(response: 0.40, dampingRatio: 0.35))
            Hold.moving(0, duration: 0.45, drift: 0.4)
            SpringKeyframe(1.8, duration: 0.12, spring: .init(response: 0.40, dampingRatio: 0.35))
            SpringKeyframe(0, duration: 0.20, spring: .init(response: 0.40, dampingRatio: 0.35))
            Hold.moving(0, duration: 0.93, drift: 0.4)
            CubicKeyframe(-2, duration: 0.20)
        }
    }

    @KeyframesBuilder<GeneralPose>
    static var atEaseArms: some Keyframes<GeneralPose> {
        // Hands behind his back. The forearms swap to the layers behind his torso while
        // they still hang outside it (0.34 to 0.40), and come back out the same way.
        KeyframeTrack(\.nearBehind) {
            LinearKeyframe(0, duration: 0.34)
            LinearKeyframe(1, duration: 0.06)
            LinearKeyframe(1, duration: 0.94)
            LinearKeyframe(0, duration: 0.06)
            LinearKeyframe(0, duration: 1.00)
        }
        KeyframeTrack(\.farBehind) {
            LinearKeyframe(0, duration: 0.34)
            LinearKeyframe(1, duration: 0.06)
            LinearKeyframe(1, duration: 1.70)
            LinearKeyframe(0, duration: 0.06)
            LinearKeyframe(0, duration: 0.24)
        }
        // The stick goes out of sight while it is behind his back.
        KeyframeTrack(\.stickOpacity) {
            LinearKeyframe(1, duration: 1.20)
            LinearKeyframe(0, duration: 0.08)
            LinearKeyframe(0, duration: 1.12)
        }
        // Near arm: behind the back, then the forearm unfolds at his side (the layers swap
        // there), and the arm rises folded tight so the hand never swings out wide.
        KeyframeTrack(\.armNear) {
            Hold.moving(0, duration: 0.40, drift: 0.3)
            SpringKeyframe(12, duration: 0.30, spring: .init(response: 0.45, dampingRatio: 0.74))
            Hold.moving(12, duration: 0.52, drift: 0.5)
            CubicKeyframe(18, duration: 0.12)
            Hold.moving(18, duration: 0.06, drift: 0.3)
            CubicKeyframe(72, duration: 0.10)
            SpringKeyframe(150, duration: 0.16, spring: .init(response: 0.26, dampingRatio: 0.70))
            Hold.moving(150, duration: 0.22, drift: 0.4)
            SpringKeyframe(0, duration: 0.28, spring: .init(response: 0.36, dampingRatio: 0.78))
            Hold.moving(0, duration: 0.24, drift: 0.3)
        }
        KeyframeTrack(\.foreNear) {
            Hold.moving(0, duration: 0.43, drift: 0.3)
            SpringKeyframe(-70, duration: 0.30, spring: .init(response: 0.45, dampingRatio: 0.74))
            Hold.moving(-70, duration: 0.49, drift: 0.6)
            CubicKeyframe(-5, duration: 0.12)
            Hold.moving(-5, duration: 0.06, drift: 0.3)
            CubicKeyframe(110, duration: 0.10)
            SpringKeyframe(72, duration: 0.16, spring: .init(response: 0.26, dampingRatio: 0.70))
            Hold.moving(72, duration: 0.22, drift: 0.4)
            CubicKeyframe(100, duration: 0.08)        // stays folded while the arm lowers
            SpringKeyframe(0, duration: 0.20, spring: .init(response: 0.30, dampingRatio: 0.78))
            Hold.moving(0, duration: 0.24, drift: 0.3)
        }
        // Held behind his back, pointing in across it so it stays hidden.
        KeyframeTrack(\.stick) {
            Hold.moving(0, duration: 0.40, drift: 0.4)
            SpringKeyframe(163, duration: 0.30, spring: .init(response: 0.45, dampingRatio: 0.74))
            Hold.moving(163, duration: 1.70, drift: 0.5)
        }
        // Far arm stays behind until he is nearly gone.
        KeyframeTrack(\.armFar) {
            Hold.moving(0, duration: 0.40, drift: 0.3)
            SpringKeyframe(-12, duration: 0.30, spring: .init(response: 0.45, dampingRatio: 0.74))
            Hold.moving(-12, duration: 1.25, drift: 0.5)
            CubicKeyframe(-9, duration: 0.15)
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.36, dampingRatio: 0.78))
        }
        KeyframeTrack(\.foreFar) {
            Hold.moving(0, duration: 0.43, drift: 0.3)
            SpringKeyframe(70, duration: 0.30, spring: .init(response: 0.45, dampingRatio: 0.74))
            Hold.moving(70, duration: 1.22, drift: 0.6)
            CubicKeyframe(8, duration: 0.15)
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.36, dampingRatio: 0.78))
        }
    }

    // MARK: - longBreak · "Parade" (3.4s)

    /// Two marching steps in place, near knee high then far knee high, each landing with
    /// a bob. A stomp halts him, and the stick goes straight up beside his head while the
    /// medals jingle twice. He lowers it, nods once and sinks.
    @KeyframesBuilder<GeneralPose>
    public static var paradeOfOne: some Keyframes<GeneralPose> {
        paradeOfOneLegs
        paradeOfOneFarLeg
        paradeOfOneArms
        paradeOfOneHead
    }

    @KeyframesBuilder<GeneralPose>
    static var paradeOfOneLegs: some Keyframes<GeneralPose> {
        // 0.00 rise, 0.35 step 1 (lands 0.80), 0.80 step 2 (lands 1.25), 1.25 halt,
        // 1.45 stick up, 1.85 hold, 2.70 nod and lower, 3.00 sink.
        KeyframeTrack(\.emergence) {
            SpringKeyframe(-10, duration: 0.20, spring: .init(response: 0.40, dampingRatio: 0.55))
            SpringKeyframe(0, duration: 0.15, spring: .init(response: 0.40, dampingRatio: 0.55))
            CubicKeyframe(-1.5, duration: 0.22)
            CubicKeyframe(3, duration: 0.23)          // lands, 0.80
            CubicKeyframe(-1.5, duration: 0.22)
            CubicKeyframe(3, duration: 0.23)          // lands, 1.25
            CubicKeyframe(4, duration: 0.07)          // the halt stomp
            SpringKeyframe(0, duration: 0.13, spring: .init(response: 0.30, dampingRatio: 0.55))
            Hold.moving(0, duration: 1.55, drift: 0.9)
            CubicKeyframe(-6, duration: 0.08)         // small rise before the drop
            CubicKeyframe(200, duration: 0.32, startVelocity: 0)
        }
        KeyframeTrack(\.figureScaleY) {
            LinearKeyframe(1, duration: 1.25)
            CubicKeyframe(0.97, duration: 0.05)
            SpringKeyframe(1.0, duration: 0.15, spring: .init(response: 0.30, dampingRatio: 0.55))
            Hold.moving(1, duration: 1.55, drift: 0.014)
            CubicKeyframe(1.03, duration: 0.08)
            CubicKeyframe(0.92, duration: 0.12)
            LinearKeyframe(0.92, duration: 0.20)
        }
        // Each knee lifts toward you: the thigh shortens (it points at the viewer), the
        // boot rises, and the legs barely turn. No sideways kick.
        KeyframeTrack(\.legNearLift) {
            LinearKeyframe(0, duration: 0.35)
            CubicKeyframe(-4, duration: 0.20)
            LinearKeyframe(-4, duration: 0.07)
            CubicKeyframe(0, duration: 0.18)
            LinearKeyframe(0, duration: 2.60)
        }
        KeyframeTrack(\.legNearScaleY) {
            LinearKeyframe(1, duration: 0.35)
            CubicKeyframe(0.8, duration: 0.20)
            LinearKeyframe(0.8, duration: 0.07)
            CubicKeyframe(1, duration: 0.18)
            LinearKeyframe(1, duration: 2.60)
        }
        KeyframeTrack(\.legNear) {
            Hold.moving(0, duration: 0.35, drift: 0.3)
            CubicKeyframe(3, duration: 0.20)
            LinearKeyframe(3, duration: 0.07)
            CubicKeyframe(0, duration: 0.18)
            Hold.moving(0, duration: 2.60, drift: 0.3)
        }
        KeyframeTrack(\.bootNearLift) {
            LinearKeyframe(0, duration: 0.35)
            CubicKeyframe(-7, duration: 0.20)
            LinearKeyframe(-7, duration: 0.07)
            CubicKeyframe(0, duration: 0.16)
            LinearKeyframe(0, duration: 2.62)
        }
    }

    @KeyframesBuilder<GeneralPose>
    static var paradeOfOneFarLeg: some Keyframes<GeneralPose> {
        KeyframeTrack(\.legFarLift) {
            LinearKeyframe(0, duration: 0.80)
            CubicKeyframe(-4, duration: 0.20)
            LinearKeyframe(-4, duration: 0.07)
            CubicKeyframe(0, duration: 0.18)
            LinearKeyframe(0, duration: 2.15)
        }
        KeyframeTrack(\.legFarScaleY) {
            LinearKeyframe(1, duration: 0.80)
            CubicKeyframe(0.8, duration: 0.20)
            LinearKeyframe(0.8, duration: 0.07)
            CubicKeyframe(1, duration: 0.18)
            LinearKeyframe(1, duration: 2.15)
        }
        KeyframeTrack(\.legFar) {
            Hold.moving(0, duration: 0.80, drift: 0.3)
            CubicKeyframe(-3, duration: 0.20)
            LinearKeyframe(-3, duration: 0.07)
            CubicKeyframe(0, duration: 0.18)
            Hold.moving(0, duration: 2.15, drift: 0.3)
        }
        KeyframeTrack(\.bootFarLift) {
            LinearKeyframe(0, duration: 0.80)
            CubicKeyframe(-7, duration: 0.20)
            LinearKeyframe(-7, duration: 0.07)
            CubicKeyframe(0, duration: 0.16)
            LinearKeyframe(0, duration: 2.17)
        }
    }

    @KeyframesBuilder<GeneralPose>
    static var paradeOfOneArms: some Keyframes<GeneralPose> {
        // Contralateral swing: far arm forward on step 1, near arm forward on step 2.
        // Forward is toward his centre, with the forearm bending that way too.
        KeyframeTrack(\.armFar) {
            Hold.moving(0, duration: 0.35, drift: 0.3)
            CubicKeyframe(12, duration: 0.22)
            CubicKeyframe(4, duration: 0.23)
            CubicKeyframe(-8, duration: 0.22)
            CubicKeyframe(-4, duration: 0.23)
            CubicKeyframe(0, duration: 0.20)
            Hold.moving(0, duration: 1.95, drift: 0.6)
        }
        KeyframeTrack(\.foreFar) {
            Hold.moving(0, duration: 0.39, drift: 0.3)
            CubicKeyframe(26, duration: 0.20)
            CubicKeyframe(6, duration: 0.23)
            CubicKeyframe(0, duration: 0.22)
            CubicKeyframe(0, duration: 0.23)
            Hold.moving(0, duration: 2.13, drift: 0.6)
        }
        KeyframeTrack(\.armNear) {
            Hold.moving(0, duration: 0.35, drift: 0.3)
            CubicKeyframe(10, duration: 0.22)
            CubicKeyframe(6, duration: 0.23)
            CubicKeyframe(-14, duration: 0.22)
            CubicKeyframe(-6, duration: 0.23)
            CubicKeyframe(6, duration: 0.20)          // winds back on the stomp
            SpringKeyframe(67, duration: 0.40, spring: .init(response: 0.36, dampingRatio: 0.72))
            Hold.moving(67, duration: 0.85, drift: 0.8)
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.36, dampingRatio: 0.80))
            Hold.moving(0, duration: 0.40, drift: 0.4)
        }
        KeyframeTrack(\.foreNear) {
            Hold.moving(0, duration: 0.39, drift: 0.3)
            CubicKeyframe(0, duration: 0.20)
            CubicKeyframe(0, duration: 0.23)
            CubicKeyframe(-26, duration: 0.22)
            CubicKeyframe(-8, duration: 0.23)
            CubicKeyframe(-4, duration: 0.18)
            SpringKeyframe(104, duration: 0.40, spring: .init(response: 0.36, dampingRatio: 0.72))
            Hold.moving(104, duration: 0.85, drift: 0.8)
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.36, dampingRatio: 0.80))
            Hold.moving(0, duration: 0.40, drift: 0.4)
        }
        // The stick swings loosely in his fist on the march, then comes up vertical.
        KeyframeTrack(\.stick) {
            Hold.moving(0, duration: 0.35, drift: 0.5)
            CubicKeyframe(5, duration: 0.25)
            CubicKeyframe(-5, duration: 0.25)
            CubicKeyframe(6, duration: 0.25)
            CubicKeyframe(0, duration: 0.15)
            Hold.moving(0, duration: 0.20, drift: 0.4)
            SpringKeyframe(-136, duration: 0.40, spring: .init(response: 0.36, dampingRatio: 0.72))
            Hold.moving(-136, duration: 0.85, drift: 0.8)
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.36, dampingRatio: 0.80))
            Hold.moving(0, duration: 0.40, drift: 0.4)
        }
    }

    @KeyframesBuilder<GeneralPose>
    static var paradeOfOneHead: some Keyframes<GeneralPose> {
        // A sway over the standing foot, then the chest puffs for the stick.
        KeyframeTrack(\.torso) {
            Hold.moving(0, duration: 0.35, drift: 0.3)
            CubicKeyframe(2.5, duration: 0.22)
            CubicKeyframe(0.5, duration: 0.23)
            CubicKeyframe(-2.5, duration: 0.22)
            CubicKeyframe(-0.5, duration: 0.23)
            CubicKeyframe(0, duration: 0.20)
            Hold.breathing(0, duration: 1.55, drift: 0.6)
            Hold.moving(0, duration: 0.40, drift: 0.4)
        }
        KeyframeTrack(\.torsoScaleY) {
            Hold.moving(1, duration: 1.45, drift: 0.014)
            CubicKeyframe(1.08, duration: 0.40)
            Hold.moving(1.08, duration: 0.85, drift: 0.014)
            CubicKeyframe(1.0, duration: 0.30)
            Hold.moving(1.0, duration: 0.40, drift: 0.014)
        }
        // The head bobs against each landing, looks up at the stick, nods once.
        KeyframeTrack(\.head) {
            Hold.moving(0, duration: 0.35, drift: 0.3)
            CubicKeyframe(-2, duration: 0.22)
            CubicKeyframe(1, duration: 0.23)
            CubicKeyframe(-2, duration: 0.22)
            CubicKeyframe(1, duration: 0.23)
            CubicKeyframe(0, duration: 0.20)
            SpringKeyframe(-3, duration: 0.40, spring: .init(response: 0.40, dampingRatio: 0.65))
            Hold.moving(-3, duration: 0.85, drift: 0.5)
            CubicKeyframe(7, duration: 0.15)          // the nod
            CubicKeyframe(0, duration: 0.15)
            Hold.moving(0, duration: 0.40, drift: 0.3)
        }
        // The moustache trails the head by a hair.
        KeyframeTrack(\.stache) {
            Hold.moving(0, duration: 0.41, drift: 0.3)
            CubicKeyframe(1.5, duration: 0.22)
            CubicKeyframe(-1.5, duration: 0.23)
            CubicKeyframe(1.5, duration: 0.22)
            CubicKeyframe(-1.5, duration: 0.23)
            CubicKeyframe(0, duration: 0.20)
            Hold.moving(0, duration: 1.89, drift: 0.4)
        }
        // The cap lags each landing, tips +5 on the halt, floats up as he drops.
        KeyframeTrack(\.cap) {
            Hold.moving(0, duration: 0.45, drift: 0.3)
            SpringKeyframe(-2, duration: 0.20, spring: .init(response: 0.35, dampingRatio: 0.45))
            SpringKeyframe(1, duration: 0.20, spring: .init(response: 0.35, dampingRatio: 0.45))
            SpringKeyframe(-2, duration: 0.20, spring: .init(response: 0.35, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.20, spring: .init(response: 0.35, dampingRatio: 0.45))
            SpringKeyframe(5, duration: 0.12, spring: .init(response: 0.30, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.25, spring: .init(response: 0.35, dampingRatio: 0.50))
            Hold.moving(0, duration: 1.38, drift: 0.5)
            Hold.moving(0, duration: 0.40, drift: 0.4)
        }
        KeyframeTrack(\.capLift) {
            Hold.moving(0, duration: 0.84, drift: 0.3)
            CubicKeyframe(3.5, duration: 0.07)
            CubicKeyframe(0, duration: 0.13)
            Hold.moving(0, duration: 0.25, drift: 0.3)
            CubicKeyframe(5, duration: 0.07)
            SpringKeyframe(0, duration: 0.20, spring: .init(response: 0.35, dampingRatio: 0.50))
            Hold.moving(0, duration: 1.44, drift: 0.4)
            CubicKeyframe(2, duration: 0.08)
            CubicKeyframe(-6, duration: 0.32)
        }
        // Medals trail each landing, then jingle twice on the hold, the second smaller.
        KeyframeTrack(\.medalsLift) {
            Hold.moving(0, duration: 0.84, drift: 0.3)
            SpringKeyframe(2, duration: 0.10, spring: .init(response: 0.40, dampingRatio: 0.30))
            SpringKeyframe(0, duration: 0.18, spring: .init(response: 0.40, dampingRatio: 0.30))
            Hold.moving(0, duration: 0.20, drift: 0.3)
            SpringKeyframe(2.5, duration: 0.10, spring: .init(response: 0.40, dampingRatio: 0.30))
            SpringKeyframe(-1, duration: 0.15, spring: .init(response: 0.40, dampingRatio: 0.30))
            SpringKeyframe(0, duration: 0.18, spring: .init(response: 0.40, dampingRatio: 0.30))
            Hold.moving(0, duration: 0.20, drift: 0.3)
            SpringKeyframe(3, duration: 0.10, spring: .init(response: 0.40, dampingRatio: 0.30))
            SpringKeyframe(-2, duration: 0.14, spring: .init(response: 0.40, dampingRatio: 0.30))
            SpringKeyframe(0, duration: 0.16, spring: .init(response: 0.40, dampingRatio: 0.30))
            Hold.moving(0, duration: 0.20, drift: 0.3)
            SpringKeyframe(1.5, duration: 0.10, spring: .init(response: 0.40, dampingRatio: 0.30))
            SpringKeyframe(-1, duration: 0.14, spring: .init(response: 0.40, dampingRatio: 0.30))
            SpringKeyframe(0, duration: 0.16, spring: .init(response: 0.40, dampingRatio: 0.30))
            Hold.moving(0, duration: 0.05, drift: 0.1)
            CubicKeyframe(-3, duration: 0.40)
        }
    }
}
