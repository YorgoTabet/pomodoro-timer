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
            LinearKeyframe(-12, duration: 1.50)
            CubicKeyframe(20, duration: 0.20)
            CubicKeyframe(200, duration: 0.35)
        }
        KeyframeTrack(\.figureScale) {
            LinearKeyframe(1, duration: 0.55)
            CubicKeyframe(1.1, duration: 0.40)        // proximity reads as size
            LinearKeyframe(1.1, duration: 1.50)
            CubicKeyframe(1.0, duration: 0.20)
            LinearKeyframe(1.0, duration: 0.35)
        }
        KeyframeTrack(\.figureScaleY) {
            LinearKeyframe(0.9, duration: 0.15)
            SpringKeyframe(1.04, duration: 0.20, spring: .init(response: 0.3, dampingRatio: 0.55))
            SpringKeyframe(1.0, duration: 0.20, spring: .init(response: 0.3, dampingRatio: 0.55))
            LinearKeyframe(1.0, duration: 2.45)
        }
        KeyframeTrack(\.torsoScaleY) {
            LinearKeyframe(1, duration: 0.35)
            CubicKeyframe(1.08, duration: 0.25)       // chest puff
            LinearKeyframe(1.08, duration: 1.60)
            CubicKeyframe(1.0, duration: 0.25)
            LinearKeyframe(1.0, duration: 0.55)
        }
        KeyframeTrack(\.head) {
            LinearKeyframe(0, duration: 0.35)
            CubicKeyframe(-4, duration: 0.25)         // chin rises
            LinearKeyframe(-4, duration: 1.80)
            CubicKeyframe(0, duration: 0.25)
            LinearKeyframe(0, duration: 0.35)
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
            LinearKeyframe(0, duration: 1.05)
            SpringKeyframe(-45, duration: 0.30, spring: .init(response: 0.32, dampingRatio: 0.55))
            LinearKeyframe(-45, duration: 0.70)
            CubicKeyframe(0, duration: 0.35)
            LinearKeyframe(0, duration: 0.60)
        }
        KeyframeTrack(\.stick) {
            LinearKeyframe(0, duration: 1.10)
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
            LinearKeyframe(0, duration: 1.10)
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
            LinearKeyframe(0, duration: 1.10)
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
            LinearKeyframe(0, duration: 1.40)
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
            LinearKeyframe(0, duration: 1.60)
            CubicKeyframe(200, duration: 0.40)
        }
        KeyframeTrack(\.shadesSlide) {
            LinearKeyframe(0, duration: 0.40)
            CubicKeyframe(5, duration: 0.30)          // aviators creep down the nose
            LinearKeyframe(5, duration: 0.90)
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
            LinearKeyframe(-2, duration: 0.95)
            SpringKeyframe(0, duration: 0.25, spring: .init(response: 0.40, dampingRatio: 0.50))
            LinearKeyframe(0, duration: 0.40)
        }
        KeyframeTrack(\.stacheScaleY) {
            LinearKeyframe(1, duration: 0.50)
            SpringKeyframe(1.1, duration: 0.30, spring: .init(response: 0.35, dampingRatio: 0.50))
            LinearKeyframe(1.1, duration: 0.95)
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
            LinearKeyframe(0, duration: 1.15)
            SpringKeyframe(-4, duration: 0.22, spring: .init(response: 0.45, dampingRatio: 0.35))
            SpringKeyframe(4, duration: 0.23, spring: .init(response: 0.45, dampingRatio: 0.35))
            SpringKeyframe(0, duration: 0.25, spring: .init(response: 0.45, dampingRatio: 0.35))
            LinearKeyframe(0, duration: 0.55)
        }
        KeyframeTrack(\.medalsLift) {
            LinearKeyframe(0, duration: 0.08)
            SpringKeyframe(2, duration: 0.20, spring: .init(response: 0.40, dampingRatio: 0.35))
            SpringKeyframe(0, duration: 0.22, spring: .init(response: 0.40, dampingRatio: 0.35))
            LinearKeyframe(0, duration: 1.52)
            CubicKeyframe(-2, duration: 0.38)
        }
        KeyframeTrack(\.figureScaleY) {
            LinearKeyframe(1, duration: 2.00)
            CubicKeyframe(0.92, duration: 0.15)
            LinearKeyframe(0.92, duration: 0.25)
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
            LinearKeyframe(0, duration: 2.68)
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
            LinearKeyframe(0, duration: 1.80)
        }
        KeyframeTrack(\.legFar) {
            LinearKeyframe(0, duration: 0.70)
            CubicKeyframe(-28, duration: 0.30)
            CubicKeyframe(0, duration: 0.30)
            CubicKeyframe(-28, duration: 0.30)
            CubicKeyframe(0, duration: 0.25)
            LinearKeyframe(0, duration: 1.55)
        }
        KeyframeTrack(\.bootNear) {
            LinearKeyframe(0, duration: 0.48)
            SpringKeyframe(-14, duration: 0.30, spring: .init(response: 0.30, dampingRatio: 0.50))
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.30, dampingRatio: 0.50))
            LinearKeyframe(0, duration: 2.32)
        }
        KeyframeTrack(\.bootFar) {
            LinearKeyframe(0, duration: 0.78)
            SpringKeyframe(-14, duration: 0.30, spring: .init(response: 0.30, dampingRatio: 0.50))
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.30, dampingRatio: 0.50))
            LinearKeyframe(0, duration: 2.02)
        }
        KeyframeTrack(\.torso) {
            LinearKeyframe(0, duration: 0.40)
            CubicKeyframe(3, duration: 0.30)
            CubicKeyframe(-3, duration: 0.30)
            CubicKeyframe(3, duration: 0.30)
            CubicKeyframe(0, duration: 0.55)
            LinearKeyframe(0, duration: 1.55)
        }
        // Cap and medals bounce on every step and never quite settle.
        KeyframeTrack(\.cap) {
            LinearKeyframe(0, duration: 0.45)
            SpringKeyframe(-3, duration: 0.20, spring: .init(response: 0.35, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.20, spring: .init(response: 0.35, dampingRatio: 0.45))
            SpringKeyframe(-3, duration: 0.20, spring: .init(response: 0.35, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.20, spring: .init(response: 0.35, dampingRatio: 0.45))
            LinearKeyframe(0, duration: 2.15)
        }
        KeyframeTrack(\.medalsLift) {
            LinearKeyframe(0, duration: 0.45)
            SpringKeyframe(2.5, duration: 0.18, spring: .init(response: 0.40, dampingRatio: 0.30))
            SpringKeyframe(-1.5, duration: 0.17, spring: .init(response: 0.40, dampingRatio: 0.30))
            SpringKeyframe(2.5, duration: 0.18, spring: .init(response: 0.40, dampingRatio: 0.30))
            SpringKeyframe(0, duration: 0.22, spring: .init(response: 0.40, dampingRatio: 0.30))
            LinearKeyframe(0, duration: 0.90)
            SpringKeyframe(2.5, duration: 0.20, spring: .init(response: 0.40, dampingRatio: 0.30))
            SpringKeyframe(0, duration: 0.25, spring: .init(response: 0.40, dampingRatio: 0.30))
            LinearKeyframe(0, duration: 0.85)
        }
        // Stick raised high for the finish.
        KeyframeTrack(\.armNear) {
            LinearKeyframe(0, duration: 1.85)
            SpringKeyframe(-112, duration: 0.35, spring: .init(response: 0.38, dampingRatio: 0.60))
            LinearKeyframe(-112, duration: 0.40)
            CubicKeyframe(0, duration: 0.30)
            LinearKeyframe(0, duration: 0.50)
        }
        KeyframeTrack(\.foreNear) {
            LinearKeyframe(0, duration: 1.95)
            SpringKeyframe(-50, duration: 0.35, spring: .init(response: 0.32, dampingRatio: 0.55))
            LinearKeyframe(-50, duration: 0.30)
            CubicKeyframe(0, duration: 0.30)
            LinearKeyframe(0, duration: 0.50)
        }
        KeyframeTrack(\.stick) {
            LinearKeyframe(0, duration: 2.00)
            SpringKeyframe(40, duration: 0.35, spring: .init(response: 0.35, dampingRatio: 0.50))
            LinearKeyframe(40, duration: 0.25)
            CubicKeyframe(0, duration: 0.30)
            LinearKeyframe(0, duration: 0.50)
        }
        KeyframeTrack(\.torsoScaleY) {
            LinearKeyframe(1, duration: 2.00)
            CubicKeyframe(1.08, duration: 0.30)       // triumphant puff
            LinearKeyframe(1.08, duration: 0.40)
            CubicKeyframe(1.0, duration: 0.20)
            LinearKeyframe(1.0, duration: 0.50)
        }
        KeyframeTrack(\.capLift) {
            LinearKeyframe(0, duration: 2.05)
            SpringKeyframe(-8, duration: 0.15, spring: .init(response: 0.30, dampingRatio: 0.40))
            SpringKeyframe(-3, duration: 0.15, spring: .init(response: 0.30, dampingRatio: 0.40))
            LinearKeyframe(-3, duration: 0.65)
            SpringKeyframe(0, duration: 0.20, spring: .init(response: 0.40, dampingRatio: 0.50))
            CubicKeyframe(-6, duration: 0.20)         // lags as he sinks
        }
        KeyframeTrack(\.figureScaleY) {
            LinearKeyframe(1, duration: 3.00)
            CubicKeyframe(0.92, duration: 0.15)
            LinearKeyframe(0.92, duration: 0.25)
        }
    }
}
