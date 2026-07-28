import PomodoroCore
import SwiftUI

/// The General's three performances.
///
/// His celebration is cadence rather than a spin — he marches. That suits him
/// better than acrobatics and keeps him distinct from the ninja's backflip and the
/// samurai's leap.
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

    // MARK: - focusStart · "Back to the front" (3.0s)

    /// Rises, puffs his chest, advances in front of the pill, and levels the swagger
    /// stick at you while bellowing. The cap pops off his head on the bark; the
    /// medals jiggle for a full half-second afterwards.
    @KeyframesBuilder<GeneralPose>
    public static var backToTheFront: some Keyframes<GeneralPose> {
        KeyframeTrack(\.emergence) {
            SpringKeyframe(6, duration: 0.30, spring: .init(response: 0.42, dampingRatio: 0.65))
            LinearKeyframe(6, duration: 0.25)
            CubicKeyframe(-12, duration: 0.40)        // advances in front of the pill
            Hold.moving(-12, duration: 1.5, drift: 1.4)
            CubicKeyframe(20, duration: 0.20)
            CubicKeyframe(200, duration: 0.35)
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
        KeyframeTrack(\.torsoScaleY) {
            LinearKeyframe(1, duration: 0.35)
            CubicKeyframe(1.08, duration: 0.25)       // chest puff
            Hold.moving(1.08, duration: 1.6, drift: 0.014)
            CubicKeyframe(1.0, duration: 0.25)
            LinearKeyframe(1.0, duration: 0.55)
        }
        KeyframeTrack(\.head) {
            LinearKeyframe(0, duration: 0.35)
            CubicKeyframe(-4, duration: 0.25)         // chin rises
            Hold.breathing(-4, duration: 1.8, drift: 1.8)
            CubicKeyframe(0, duration: 0.25)
            LinearKeyframe(0, duration: 0.35)
        }
        // The bracing arm and the lean behind the point, neither of which existed.
        //
        // Levelling a stick at someone is a two-sided action: the far arm drives
        // back as the near arm drives forward, and the torso turns into it. Animating
        // only the pointing arm is why the gesture read as a puppet's, not a person's.
        KeyframeTrack(\.armFar) {
            LinearKeyframe(0, duration: 0.80)
            CubicKeyframe(-12, duration: 0.15)        // counter-swing on the wind-up
            SpringKeyframe(22, duration: 0.30, spring: .init(response: 0.36, dampingRatio: 0.58))
            Hold.moving(22, duration: 0.80, drift: 1.6)
            CubicKeyframe(0, duration: 0.35)
            LinearKeyframe(0, duration: 0.60)
        }
        KeyframeTrack(\.foreFar) {
            LinearKeyframe(0, duration: 0.86)
            CubicKeyframe(-6, duration: 0.14)
            SpringKeyframe(31, duration: 0.30, spring: .init(response: 0.38, dampingRatio: 0.54))
            Hold.moving(31, duration: 0.75, drift: 2.0)
            CubicKeyframe(0, duration: 0.35)
            LinearKeyframe(0, duration: 0.60)
        }
        KeyframeTrack(\.torso) {
            LinearKeyframe(0, duration: 0.80)
            CubicKeyframe(-5, duration: 0.20)         // leans in behind the stick
            Hold.breathing(-5, duration: 1.05, drift: 2.2)
            CubicKeyframe(0, duration: 0.35)
            LinearKeyframe(0, duration: 0.60)
        }
        // Wind up, then the stick whips round and levels at the viewer.
        KeyframeTrack(\.armNear) {
            LinearKeyframe(0, duration: 0.80)
            CubicKeyframe(20, duration: 0.15)
            SpringKeyframe(-100, duration: 0.30, spring: .init(response: 0.35, dampingRatio: 0.60))
            LinearKeyframe(-100, duration: 0.80)
            CubicKeyframe(0, duration: 0.35)
            LinearKeyframe(0, duration: 0.60)
        }
        KeyframeTrack(\.foreNear) {
            Hold.moving(0, duration: 1.05, drift: 1.8)
            SpringKeyframe(-45, duration: 0.30, spring: .init(response: 0.32, dampingRatio: 0.55))
            LinearKeyframe(-45, duration: 0.70)
            CubicKeyframe(0, duration: 0.35)
            LinearKeyframe(0, duration: 0.60)
        }
        KeyframeTrack(\.stick) {
            Hold.moving(0, duration: 1.1, drift: 1.8)
            SpringKeyframe(65, duration: 0.35, spring: .init(response: 0.35, dampingRatio: 0.50))
            LinearKeyframe(65, duration: 0.60)
            CubicKeyframe(0, duration: 0.35)
            LinearKeyframe(0, duration: 0.60)
        }
        // The moustache lifts to let the shout out — the mouth is hidden otherwise.
        KeyframeTrack(\.shoutOpacity) {
            LinearKeyframe(0, duration: 1.10)
            LinearKeyframe(1, duration: 0.15)
            LinearKeyframe(1, duration: 0.65)
            LinearKeyframe(0, duration: 0.15)
            LinearKeyframe(0, duration: 0.95)
        }
        KeyframeTrack(\.stacheLift) {
            Hold.moving(0, duration: 1.1, drift: 0.5)
            SpringKeyframe(-2.5, duration: 0.30, spring: .init(response: 0.30, dampingRatio: 0.50))
            LinearKeyframe(-2.5, duration: 0.50)
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.40, dampingRatio: 0.50))
            LinearKeyframe(0, duration: 0.80)
        }
        KeyframeTrack(\.stache) {
            LinearKeyframe(0, duration: 0.10)
            SpringKeyframe(5, duration: 0.18, spring: .init(response: 0.35, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.17, spring: .init(response: 0.35, dampingRatio: 0.45))
            LinearKeyframe(0, duration: 0.65)
            SpringKeyframe(-6, duration: 0.30, spring: .init(response: 0.30, dampingRatio: 0.50))
            LinearKeyframe(-6, duration: 0.50)
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.40, dampingRatio: 0.50))
            LinearKeyframe(0, duration: 0.80)
        }
        KeyframeTrack(\.capLift) {
            Hold.moving(0, duration: 1.1, drift: 0.5)
            SpringKeyframe(-7, duration: 0.15, spring: .init(response: 0.30, dampingRatio: 0.40))
            SpringKeyframe(-3, duration: 0.15, spring: .init(response: 0.30, dampingRatio: 0.40))
            LinearKeyframe(-3, duration: 0.50)
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.40, dampingRatio: 0.50))
            LinearKeyframe(0, duration: 0.45)
            CubicKeyframe(-5, duration: 0.35)         // floats up as he drops
        }
        // Pure secondary: they jiggle on every torso beat and settle late.
        KeyframeTrack(\.medalsLift) {
            LinearKeyframe(0, duration: 0.08)
            SpringKeyframe(2.5, duration: 0.20, spring: .init(response: 0.40, dampingRatio: 0.35))
            SpringKeyframe(0, duration: 0.22, spring: .init(response: 0.40, dampingRatio: 0.35))
            LinearKeyframe(0, duration: 0.65)
            SpringKeyframe(2, duration: 0.22, spring: .init(response: 0.40, dampingRatio: 0.30))
            SpringKeyframe(0, duration: 0.23, spring: .init(response: 0.40, dampingRatio: 0.30))
            Hold.moving(0, duration: 1.4, drift: 0.5)
        }
    }

    // MARK: - breakStart · "At ease" (2.4s)

    /// The aviators slide down his nose, a grin he would deny appears under the
    /// moustache, and he rocks heel-to-toe. Then the shades snap back up and
    /// dignity is restored.
    @KeyframesBuilder<GeneralPose>
    public static var atEase: some Keyframes<GeneralPose> {
        KeyframeTrack(\.emergence) {
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.50, dampingRatio: 0.72))
            Hold.moving(0, duration: 1.6, drift: 1.4)
            CubicKeyframe(200, duration: 0.40)
        }
        KeyframeTrack(\.shadesSlide) {
            LinearKeyframe(0, duration: 0.40)
            CubicKeyframe(5, duration: 0.30)          // aviators creep down the nose
            Hold.moving(5, duration: 0.9, drift: 0.5)
            SpringKeyframe(0, duration: 0.25, spring: .init(response: 0.30, dampingRatio: 0.50))
            LinearKeyframe(0, duration: 0.55)
        }
        KeyframeTrack(\.grinOpacity) {
            LinearKeyframe(0, duration: 0.50)
            LinearKeyframe(1, duration: 0.15)
            LinearKeyframe(1, duration: 1.10)
            LinearKeyframe(0, duration: 0.15)
            LinearKeyframe(0, duration: 0.50)
        }
        KeyframeTrack(\.stacheLift) {
            LinearKeyframe(0, duration: 0.50)
            SpringKeyframe(-2, duration: 0.30, spring: .init(response: 0.35, dampingRatio: 0.50))
            Hold.moving(-2, duration: 0.95, drift: 0.5)
            SpringKeyframe(0, duration: 0.25, spring: .init(response: 0.40, dampingRatio: 0.50))
            LinearKeyframe(0, duration: 0.40)
        }
        KeyframeTrack(\.stacheScaleY) {
            LinearKeyframe(1, duration: 0.50)
            SpringKeyframe(1.1, duration: 0.30, spring: .init(response: 0.35, dampingRatio: 0.50))
            Hold.moving(1.1, duration: 0.95, drift: 0.014)
            SpringKeyframe(1.0, duration: 0.25, spring: .init(response: 0.40, dampingRatio: 0.50))
            LinearKeyframe(1.0, duration: 0.40)
        }
        // Heel-toe rock, with the legs counter-rotating so his feet stay planted.
        KeyframeTrack(\.figureRotation) {
            LinearKeyframe(0, duration: 0.70)
            CubicKeyframe(3, duration: 0.40)
            CubicKeyframe(-3, duration: 0.40)
            CubicKeyframe(0, duration: 0.30)
            LinearKeyframe(0, duration: 0.60)
        }
        KeyframeTrack(\.legNear) {
            LinearKeyframe(0, duration: 0.70)
            CubicKeyframe(-3, duration: 0.40)
            CubicKeyframe(3, duration: 0.40)
            CubicKeyframe(0, duration: 0.30)
            LinearKeyframe(0, duration: 0.60)
        }
        KeyframeTrack(\.legFar) {
            LinearKeyframe(0, duration: 0.70)
            CubicKeyframe(-3, duration: 0.40)
            CubicKeyframe(3, duration: 0.40)
            CubicKeyframe(0, duration: 0.30)
            LinearKeyframe(0, duration: 0.60)
        }
        KeyframeTrack(\.medals) {
            Hold.moving(0, duration: 1.15, drift: 1.8)
            SpringKeyframe(-4, duration: 0.22, spring: .init(response: 0.45, dampingRatio: 0.35))
            SpringKeyframe(4, duration: 0.23, spring: .init(response: 0.45, dampingRatio: 0.35))
            SpringKeyframe(0, duration: 0.25, spring: .init(response: 0.45, dampingRatio: 0.35))
            LinearKeyframe(0, duration: 0.55)
        }
        KeyframeTrack(\.medalsLift) {
            LinearKeyframe(0, duration: 0.08)
            SpringKeyframe(2, duration: 0.20, spring: .init(response: 0.40, dampingRatio: 0.35))
            SpringKeyframe(0, duration: 0.22, spring: .init(response: 0.40, dampingRatio: 0.35))
            Hold.moving(0, duration: 1.52, drift: 0.5)
            CubicKeyframe(-2, duration: 0.38)
        }
        KeyframeTrack(\.figureScaleY) {
            Hold.moving(1, duration: 2.0, drift: 0.014)
            CubicKeyframe(0.92, duration: 0.15)
            LinearKeyframe(0.92, duration: 0.25)
        }
        // "At ease" is a posture, and this performance had none: every arm track was
        // absent, so the whole upper body was a statue with a moving moustache.
        //
        // The near arm lowers the swagger stick; the far arm goes behind the back,
        // which is what the real stance actually is. Both elbows carry more of the
        // change than the shoulders do — relaxing bends, it does not swing.
        KeyframeTrack(\.armNear) {
            LinearKeyframe(0, duration: 0.40)
            SpringKeyframe(-13, duration: 0.40, spring: .init(response: 0.55, dampingRatio: 0.74))
            Hold.moving(-13, duration: 1.20, drift: 1.6)
            CubicKeyframe(0, duration: 0.40)
        }
        KeyframeTrack(\.foreNear) {
            LinearKeyframe(0, duration: 0.45)
            SpringKeyframe(-24, duration: 0.40, spring: .init(response: 0.58, dampingRatio: 0.70))
            Hold.moving(-24, duration: 1.15, drift: 2.1)
            CubicKeyframe(0, duration: 0.40)
        }
        KeyframeTrack(\.stick) {
            LinearKeyframe(0, duration: 0.45)
            SpringKeyframe(22, duration: 0.40, spring: .init(response: 0.50, dampingRatio: 0.52))
            Hold.moving(22, duration: 1.15, drift: 2.4)
            CubicKeyframe(0, duration: 0.40)
        }
        KeyframeTrack(\.armFar) {
            LinearKeyframe(0, duration: 0.40)
            SpringKeyframe(17, duration: 0.44, spring: .init(response: 0.56, dampingRatio: 0.74))
            Hold.moving(17, duration: 1.16, drift: 1.6)
            CubicKeyframe(0, duration: 0.40)
        }
        KeyframeTrack(\.foreFar) {
            LinearKeyframe(0, duration: 0.45)
            SpringKeyframe(36, duration: 0.44, spring: .init(response: 0.60, dampingRatio: 0.70))
            Hold.moving(36, duration: 1.11, drift: 2.1)
            CubicKeyframe(0, duration: 0.40)
        }
        KeyframeTrack(\.torso) {
            LinearKeyframe(0, duration: 0.40)
            CubicKeyframe(3, duration: 0.45)
            Hold.breathing(3, duration: 1.15, drift: 2.6)
            CubicKeyframe(0, duration: 0.40)
        }
    }

    // MARK: - longBreak · "Parade of one" (3.4s)

    /// Four marching steps, then the stick raised overhead. No spin — cadence is
    /// his idiom, and it keeps him distinct from the other two celebrations.
    @KeyframesBuilder<GeneralPose>
    public static var paradeOfOne: some Keyframes<GeneralPose> {
        KeyframeTrack(\.emergence) {
            SpringKeyframe(-12, duration: 0.22, spring: .init(response: 0.40, dampingRatio: 0.55))
            SpringKeyframe(0, duration: 0.10, spring: .init(response: 0.40, dampingRatio: 0.55))
            Hold.moving(0, duration: 2.68, drift: 1.4)
            CubicKeyframe(200, duration: 0.40)
        }
        KeyframeTrack(\.grinOpacity) {
            LinearKeyframe(0, duration: 0.20)
            LinearKeyframe(1, duration: 0.15)
            LinearKeyframe(1, duration: 2.50)
            LinearKeyframe(0, duration: 0.15)
            LinearKeyframe(0, duration: 0.40)
        }
        // Four alternating steps.
        KeyframeTrack(\.legNear) {
            LinearKeyframe(0, duration: 0.40)
            CubicKeyframe(-28, duration: 0.30)
            CubicKeyframe(0, duration: 0.30)
            CubicKeyframe(-28, duration: 0.30)
            CubicKeyframe(0, duration: 0.30)
            Hold.moving(0, duration: 1.8, drift: 1.8)
        }
        KeyframeTrack(\.legFar) {
            LinearKeyframe(0, duration: 0.70)
            CubicKeyframe(-28, duration: 0.30)
            CubicKeyframe(0, duration: 0.30)
            CubicKeyframe(-28, duration: 0.30)
            CubicKeyframe(0, duration: 0.25)
            Hold.moving(0, duration: 1.55, drift: 1.8)
        }
        KeyframeTrack(\.bootNear) {
            LinearKeyframe(0, duration: 0.48)
            SpringKeyframe(-14, duration: 0.30, spring: .init(response: 0.30, dampingRatio: 0.50))
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.30, dampingRatio: 0.50))
            Hold.moving(0, duration: 2.32, drift: 1.8)
        }
        KeyframeTrack(\.bootFar) {
            LinearKeyframe(0, duration: 0.78)
            SpringKeyframe(-14, duration: 0.30, spring: .init(response: 0.30, dampingRatio: 0.50))
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.30, dampingRatio: 0.50))
            Hold.moving(0, duration: 2.02, drift: 1.8)
        }
        // Contralateral arm swing — the far arm goes forward as the near leg goes
        // back, on the same 0.30s cadence as the steps.
        //
        // This is the thing that makes a walk read as a walk. Without it a marching
        // figure looks like it is being dragged along, and this arm was static
        // through all three of his performances.
        KeyframeTrack(\.armFar) {
            LinearKeyframe(0, duration: 0.40)
            CubicKeyframe(24, duration: 0.30)
            CubicKeyframe(-10, duration: 0.30)
            CubicKeyframe(24, duration: 0.30)
            CubicKeyframe(0, duration: 0.30)
            Hold.moving(0, duration: 1.8, drift: 1.8)
        }
        KeyframeTrack(\.foreFar) {
            // Trails the shoulder by a beat's fraction, so the elbow leads on the
            // way back rather than the whole arm moving as one plank.
            LinearKeyframe(0, duration: 0.46)
            CubicKeyframe(30, duration: 0.30)
            CubicKeyframe(-6, duration: 0.30)
            CubicKeyframe(30, duration: 0.30)
            CubicKeyframe(0, duration: 0.30)
            Hold.moving(0, duration: 1.74, drift: 1.8)
        }
        KeyframeTrack(\.torso) {
            LinearKeyframe(0, duration: 0.40)
            CubicKeyframe(3, duration: 0.30)
            CubicKeyframe(-3, duration: 0.30)
            CubicKeyframe(3, duration: 0.30)
            CubicKeyframe(0, duration: 0.55)
            Hold.breathing(0, duration: 1.55, drift: 1.8)
        }
        // Cap and medals bounce on every step and never quite settle.
        KeyframeTrack(\.cap) {
            LinearKeyframe(0, duration: 0.45)
            SpringKeyframe(-3, duration: 0.20, spring: .init(response: 0.35, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.20, spring: .init(response: 0.35, dampingRatio: 0.45))
            SpringKeyframe(-3, duration: 0.20, spring: .init(response: 0.35, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.20, spring: .init(response: 0.35, dampingRatio: 0.45))
            Hold.moving(0, duration: 2.15, drift: 1.8)
        }
        KeyframeTrack(\.medalsLift) {
            LinearKeyframe(0, duration: 0.45)
            SpringKeyframe(2.5, duration: 0.18, spring: .init(response: 0.40, dampingRatio: 0.30))
            SpringKeyframe(-1.5, duration: 0.17, spring: .init(response: 0.40, dampingRatio: 0.30))
            SpringKeyframe(2.5, duration: 0.18, spring: .init(response: 0.40, dampingRatio: 0.30))
            SpringKeyframe(0, duration: 0.22, spring: .init(response: 0.40, dampingRatio: 0.30))
            Hold.moving(0, duration: 0.9, drift: 0.5)
            SpringKeyframe(2.5, duration: 0.20, spring: .init(response: 0.40, dampingRatio: 0.30))
            SpringKeyframe(0, duration: 0.25, spring: .init(response: 0.40, dampingRatio: 0.30))
            LinearKeyframe(0, duration: 0.85)
        }
        // Stick raised high for the finish.
        KeyframeTrack(\.armNear) {
            Hold.moving(0, duration: 1.85, drift: 1.8)
            SpringKeyframe(-112, duration: 0.35, spring: .init(response: 0.38, dampingRatio: 0.60))
            LinearKeyframe(-112, duration: 0.40)
            CubicKeyframe(0, duration: 0.30)
            LinearKeyframe(0, duration: 0.50)
        }
        KeyframeTrack(\.foreNear) {
            Hold.moving(0, duration: 1.95, drift: 1.8)
            SpringKeyframe(-50, duration: 0.35, spring: .init(response: 0.32, dampingRatio: 0.55))
            LinearKeyframe(-50, duration: 0.30)
            CubicKeyframe(0, duration: 0.30)
            LinearKeyframe(0, duration: 0.50)
        }
        KeyframeTrack(\.stick) {
            Hold.moving(0, duration: 2.0, drift: 1.8)
            SpringKeyframe(40, duration: 0.35, spring: .init(response: 0.35, dampingRatio: 0.50))
            LinearKeyframe(40, duration: 0.25)
            CubicKeyframe(0, duration: 0.30)
            LinearKeyframe(0, duration: 0.50)
        }
        KeyframeTrack(\.torsoScaleY) {
            Hold.moving(1, duration: 2.0, drift: 0.014)
            CubicKeyframe(1.08, duration: 0.30)       // triumphant puff
            LinearKeyframe(1.08, duration: 0.40)
            CubicKeyframe(1.0, duration: 0.20)
            LinearKeyframe(1.0, duration: 0.50)
        }
        KeyframeTrack(\.capLift) {
            Hold.moving(0, duration: 2.05, drift: 0.5)
            SpringKeyframe(-8, duration: 0.15, spring: .init(response: 0.30, dampingRatio: 0.40))
            SpringKeyframe(-3, duration: 0.15, spring: .init(response: 0.30, dampingRatio: 0.40))
            LinearKeyframe(-3, duration: 0.65)
            SpringKeyframe(0, duration: 0.20, spring: .init(response: 0.40, dampingRatio: 0.50))
            CubicKeyframe(-6, duration: 0.20)         // lags as he sinks
        }
        KeyframeTrack(\.figureScaleY) {
            Hold.moving(1, duration: 3.0, drift: 0.014)
            CubicKeyframe(0.92, duration: 0.15)
            LinearKeyframe(0.92, duration: 0.25)
        }
    }
}
