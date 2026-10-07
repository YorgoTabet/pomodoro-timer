import PomodoroCore
import SwiftUI

/// Boa Hancock's three performances.
///
/// Proud and vain, never goofy. Every hold is contrapposto: hips and chest
/// tilted opposite, so she is never a stiff straight stand. Hips lead turns and
/// steps, the chest and head follow a few frames later. The bust is secondary
/// follow-through only: it lags a body move by about 0.04s, overshoots once and
/// settles in about 0.3s. A repeated beat (a sway, a bob, a fan) is always smaller.
///
/// Each cue is split into small groups of tracks, because a big keyframe builder
/// crashes debug builds.
public enum HancockPerformance {

    public static func preferredEdge(for cue: CharacterCue) -> StageEdge { .top }

    /// The long break steps through the skirt slit, so it shows her legs and
    /// stands in front of the bar; the other two stay behind it.
    public static func comesForward(for cue: CharacterCue) -> Bool {
        cue == .longBreak
    }

    public static func duration(for cue: CharacterCue) -> Double {
        switch cue {
        case .focusStart: 2.80
        case .breakStart: 3.00
        case .longBreak: 3.40
        }
    }

    // MARK: - Shared helpers

    /// Hair base angle that keeps the hair hanging down while the body tilts.
    /// `world` is the sum of figure, hips, chest and head rotation. Rest is 0.5
    /// (hips 4.5, chest -9, head 5).
    static func hang(_ world: Double) -> Double { -2 - 0.8 * (world - 0.5) }

    /// One bust bounce lasting `d` seconds: up (or down for `s` < 0), one
    /// overshoot the other way, settle. `a` is 0...1 strength.
    @KeyframeTrackContentBuilder<Double>
    static func bustLift(_ a: Double, _ d: Double) -> some KeyframeTrackContent<Double> {
        CubicKeyframe(-2.6 * a, duration: d * 0.30)
        CubicKeyframe(1.2 * a, duration: d * 0.38)
        CubicKeyframe(0, duration: d * 0.32)
    }

    /// Volume-preserving: when the bust stretches up it narrows, so scaleY goes
    /// up and scaleX goes to 1 / scaleY.
    @KeyframeTrackContentBuilder<Double>
    static func bustY(_ a: Double, _ d: Double) -> some KeyframeTrackContent<Double> {
        CubicKeyframe(1 + 0.05 * a, duration: d * 0.30)
        CubicKeyframe(1 - 0.025 * a, duration: d * 0.38)
        CubicKeyframe(1, duration: d * 0.32)
    }

    @KeyframeTrackContentBuilder<Double>
    static func bustX(_ a: Double, _ d: Double) -> some KeyframeTrackContent<Double> {
        CubicKeyframe(1 / (1 + 0.05 * a), duration: d * 0.30)
        CubicKeyframe(1 / (1 - 0.025 * a), duration: d * 0.38)
        CubicKeyframe(1, duration: d * 0.32)
    }

    // MARK: - focusStart · "Looking down on you" (2.8s)
    //
    // Segments: A rise 0.5, B wind-up 0.2, C arch 0.4, D/E/F hold with wink 0.6,
    // G hmph turn 0.35, H hold 0.25, I sink 0.5.

    @KeyframesBuilder<HancockPose>
    public static var lookingDown: some Keyframes<HancockPose> {
        lookingDownBody
        lookingDownHead
        lookingDownHair
        lookingDownArms
        lookingDownFaces
        lookingDownBust
        lookingDownSash
    }

    @KeyframesBuilder<HancockPose>
    static var lookingDownBody: some Keyframes<HancockPose> {
        KeyframeTrack(\.emergence) {
            CubicKeyframe(0, duration: 0.5)
            Hold.moving(0, duration: 1.8, drift: 1.0)
            CubicKeyframe(200, duration: 0.5)
        }
        KeyframeTrack(\.figureRotation) {
            Hold.moving(0, duration: 0.5, drift: 0.5)
            CubicKeyframe(1.5, duration: 0.2)
            CubicKeyframe(-7, duration: 0.4)
            Hold.breathing(-7, duration: 0.6, drift: 0.8)
            CubicKeyframe(0, duration: 0.35)
            Hold.moving(0, duration: 0.25, drift: 0.6)
            CubicKeyframe(1.5, duration: 0.5)
        }
        KeyframeTrack(\.figureLift) {
            Hold.moving(0, duration: 0.5, drift: 0.3)
            CubicKeyframe(1.5, duration: 0.2)
            CubicKeyframe(-1.5, duration: 0.4)
            Hold.breathing(-1.5, duration: 0.6, drift: 0.5)
            CubicKeyframe(0, duration: 0.35)
            Hold.moving(0, duration: 0.25, drift: 0.3)
            CubicKeyframe(1, duration: 0.5)
        }
        KeyframeTrack(\.figureScale) {
            Hold.moving(1, duration: 0.5, drift: 0.004)
            CubicKeyframe(0.99, duration: 0.2)
            CubicKeyframe(1.015, duration: 0.4)
            Hold.breathing(1.015, duration: 0.6, drift: 0.006)
            CubicKeyframe(1, duration: 0.35)
            Hold.moving(1, duration: 0.25, drift: 0.004)
            CubicKeyframe(1, duration: 0.5)
        }
        // Hips lead: the hips reach the new angle before the chest does.
        KeyframeTrack(\.hips) {
            Hold.moving(4.5, duration: 0.5, drift: 0.8)
            CubicKeyframe(6, duration: 0.2)
            CubicKeyframe(9.5, duration: 0.35)
            Hold.moving(9.5, duration: 0.05, drift: 0.2)
            Hold.breathing(9.5, duration: 0.6, drift: 0.8)
            CubicKeyframe(-0.5, duration: 0.3)
            Hold.moving(-0.5, duration: 0.3, drift: 0.6)
            CubicKeyframe(4.5, duration: 0.5)
        }
    }

    @KeyframesBuilder<HancockPose>
    static var lookingDownHead: some Keyframes<HancockPose> {
        KeyframeTrack(\.chest) {
            Hold.moving(-9, duration: 0.5, drift: 0.6)
            CubicKeyframe(-7, duration: 0.2)
            CubicKeyframe(-15, duration: 0.4)
            Hold.breathing(-15, duration: 0.6, drift: 0.8)
            CubicKeyframe(1.5, duration: 0.35)
            Hold.moving(1.5, duration: 0.25, drift: 0.6)
            CubicKeyframe(-9, duration: 0.5)
        }
        KeyframeTrack(\.head) {
            Hold.moving(5, duration: 0.5, drift: 1.0)
            CubicKeyframe(8, duration: 0.2)
            CubicKeyframe(-7, duration: 0.4)
            Hold.breathing(-7, duration: 0.6, drift: 0.8)
            CubicKeyframe(10, duration: 0.35)
            Hold.moving(10, duration: 0.25, drift: 0.8)
            CubicKeyframe(5, duration: 0.5)
        }
        KeyframeTrack(\.capeL) {
            CubicKeyframe(2, duration: 0.5)
            CubicKeyframe(-1, duration: 0.2)
            CubicKeyframe(4, duration: 0.4)
            Hold.breathing(2, duration: 0.6, drift: 1.0)
            CubicKeyframe(-1.5, duration: 0.35)
            Hold.moving(0, duration: 0.25, drift: 0.8)
            CubicKeyframe(2, duration: 0.5)
        }
        KeyframeTrack(\.capeR) {
            CubicKeyframe(-2, duration: 0.5)
            CubicKeyframe(1, duration: 0.2)
            CubicKeyframe(-4, duration: 0.4)
            Hold.breathing(-2, duration: 0.6, drift: -1.0)
            CubicKeyframe(1.5, duration: 0.35)
            Hold.moving(0, duration: 0.25, drift: -0.8)
            CubicKeyframe(-2, duration: 0.5)
        }
    }

    @KeyframesBuilder<HancockPose>
    static var lookingDownHair: some Keyframes<HancockPose> {
        KeyframeTrack(\.hairBase) {
            Hold.moving(hang(0.5), duration: 0.5, drift: 0.6)
            CubicKeyframe(hang(8.5), duration: 0.2)
            CubicKeyframe(hang(-19.5), duration: 0.4)
            Hold.breathing(hang(-19.5), duration: 0.6, drift: 0.6)
            CubicKeyframe(hang(12), duration: 0.35)
            Hold.moving(hang(12), duration: 0.25, drift: 0.6)
            CubicKeyframe(hang(2), duration: 0.5)
        }
        KeyframeTrack(\.hairMid) {
            Hold.moving(0, duration: 0.5, drift: 1.0)
            CubicKeyframe(-2, duration: 0.2)
            CubicKeyframe(5, duration: 0.4)
            CubicKeyframe(-2, duration: 0.25)
            CubicKeyframe(1.5, duration: 0.2)
            CubicKeyframe(0, duration: 0.15)
            CubicKeyframe(-7, duration: 0.35)
            CubicKeyframe(2, duration: 0.1)
            CubicKeyframe(0, duration: 0.15)
            CubicKeyframe(-1, duration: 0.5)
        }
        // The tip trails the mid by 0.05 to 0.1s.
        KeyframeTrack(\.hairTip) {
            Hold.moving(0, duration: 0.55, drift: 1.4)
            CubicKeyframe(-3, duration: 0.15)
            CubicKeyframe(9, duration: 0.45)
            CubicKeyframe(-4, duration: 0.25)
            CubicKeyframe(3, duration: 0.2)
            CubicKeyframe(0, duration: 0.1)
            CubicKeyframe(-11, duration: 0.4)
            CubicKeyframe(2, duration: 0.25)
            CubicKeyframe(0, duration: 0.45)
        }
        KeyframeTrack(\.earringL) {
            Hold.moving(-3, duration: 0.5, drift: 1.0)
            CubicKeyframe(-6, duration: 0.2)
            CubicKeyframe(5, duration: 0.4)
            Hold.breathing(2, duration: 0.6, drift: 1.0)
            CubicKeyframe(-8, duration: 0.35)
            Hold.moving(-1, duration: 0.25, drift: 1.0)
            CubicKeyframe(-3, duration: 0.5)
        }
        KeyframeTrack(\.earringR) {
            Hold.moving(-3, duration: 0.5, drift: 1.0)
            CubicKeyframe(-6, duration: 0.2)
            CubicKeyframe(5, duration: 0.4)
            Hold.breathing(2, duration: 0.6, drift: 1.0)
            CubicKeyframe(-8, duration: 0.35)
            Hold.moving(-1, duration: 0.25, drift: 1.0)
            CubicKeyframe(-3, duration: 0.5)
        }
        KeyframeTrack(\.sideLockR) {
            Hold.moving(-3, duration: 0.5, drift: 1.0)
            CubicKeyframe(-4.5, duration: 0.2)
            CubicKeyframe(1, duration: 0.4)
            Hold.breathing(-0.5, duration: 0.6, drift: 1.0)
            CubicKeyframe(-5.5, duration: 0.35)
            Hold.moving(-2, duration: 0.25, drift: 1.0)
            CubicKeyframe(-3, duration: 0.5)
        }
        KeyframeTrack(\.sideLockL) {
            Hold.moving(-3, duration: 0.5, drift: 1.0)
            CubicKeyframe(-4.5, duration: 0.2)
            CubicKeyframe(1, duration: 0.4)
            Hold.breathing(-0.5, duration: 0.6, drift: 1.0)
            CubicKeyframe(-5.5, duration: 0.35)
            Hold.moving(-2, duration: 0.25, drift: 1.0)
            CubicKeyframe(-3, duration: 0.5)
        }
    }

    @KeyframesBuilder<HancockPose>
    static var lookingDownArms: some Keyframes<HancockPose> {
        // Left arm points at you from 0.7, drops at 1.7.
        KeyframeTrack(\.armL) {
            Hold.moving(17, duration: 0.5, drift: 1.5)
            CubicKeyframe(12, duration: 0.2)
            CubicKeyframe(58, duration: 0.4)
            Hold.breathing(58, duration: 0.6, drift: 2.0)
            CubicKeyframe(17, duration: 0.35)
            Hold.moving(17, duration: 0.25, drift: 1.0)
            Hold.moving(17, duration: 0.5, drift: 1.0)
        }
        KeyframeTrack(\.armL_fore) {
            Hold.moving(-6, duration: 0.5, drift: 1.0)
            CubicKeyframe(-8, duration: 0.2)
            CubicKeyframe(-18, duration: 0.4)
            Hold.breathing(-18, duration: 0.6, drift: 2.0)
            CubicKeyframe(-6, duration: 0.35)
            Hold.moving(-6, duration: 0.25, drift: 1.0)
            Hold.moving(-6, duration: 0.5, drift: 0.8)
        }
        KeyframeTrack(\.handL) {
            Hold.moving(0, duration: 0.5, drift: 1.0)
            CubicKeyframe(-3, duration: 0.2)
            CubicKeyframe(10, duration: 0.4)
            Hold.breathing(10, duration: 0.6, drift: 2.0)
            CubicKeyframe(0, duration: 0.35)
            Hold.moving(0, duration: 0.75, drift: 1.0)
        }
        // Right hand on her hip the whole time (the art's rest pose).
        KeyframeTrack(\.armR) {
            CubicKeyframe(-24, duration: 0.5)
            Hold.moving(-24, duration: 0.6, drift: 1.0)
            Hold.breathing(-24, duration: 0.6, drift: 1.2)
            Hold.moving(-24, duration: 0.6, drift: 1.0)
            Hold.moving(-24, duration: 0.5, drift: 0.5)
        }
        KeyframeTrack(\.armR_fore) {
            CubicKeyframe(74, duration: 0.5)
            Hold.moving(74, duration: 0.6, drift: -2.0)
            Hold.breathing(74, duration: 0.6, drift: -2.0)
            Hold.moving(74, duration: 0.6, drift: -2.0)
            Hold.moving(74, duration: 0.5, drift: -1.0)
        }
        KeyframeTrack(\.handR) {
            Hold.moving(24, duration: 2.8, drift: 1.5)
        }
    }

    @KeyframesBuilder<HancockPose>
    static var lookingDownFaces: some Keyframes<HancockPose> {
        // Faces and hands switch in one 0.01s step.
        KeyframeTrack(\.smugOpacity) {
            LinearKeyframe(0, duration: 0.7)
            LinearKeyframe(1, duration: 0.01)
            LinearKeyframe(1, duration: 0.69)
            LinearKeyframe(0, duration: 0.01)
            LinearKeyframe(0, duration: 0.18)
            LinearKeyframe(1, duration: 0.01)
            LinearKeyframe(1, duration: 1.2)
        }
        KeyframeTrack(\.winkOpacity) {
            LinearKeyframe(0, duration: 1.4)
            LinearKeyframe(1, duration: 0.01)
            LinearKeyframe(1, duration: 0.18)
            LinearKeyframe(0, duration: 0.01)
            LinearKeyframe(0, duration: 1.2)
        }
        KeyframeTrack(\.pointL) {
            LinearKeyframe(0, duration: 0.68)
            LinearKeyframe(1, duration: 0.02)
            LinearKeyframe(1, duration: 1.25)
            LinearKeyframe(0, duration: 0.01)
            LinearKeyframe(0, duration: 0.84)
        }
        KeyframeTrack(\.hipR) {
            LinearKeyframe(1, duration: 0.01)
            LinearKeyframe(1, duration: 2.79)
        }
    }

    // The sash tail trails the hips by about 0.15s: it swings the other way as
    // she arches, overshoots once, then trails the hmph turn and settles.
    @KeyframesBuilder<HancockPose>
    static var lookingDownSash: some Keyframes<HancockPose> {
        KeyframeTrack(\.sashTail) {
            Hold.moving(0, duration: 0.7, drift: 0.6)
            CubicKeyframe(-10, duration: 0.45)
            CubicKeyframe(3, duration: 0.3)
            CubicKeyframe(0, duration: 0.25)
            CubicKeyframe(12, duration: 0.3)
            CubicKeyframe(-4, duration: 0.25)
            CubicKeyframe(0, duration: 0.25)
            Hold.moving(0, duration: 0.3, drift: 0.6)
        }
    }

    // Bust: rise (quick, small), then the arch (full).
    @KeyframesBuilder<HancockPose>
    static var lookingDownBust: some Keyframes<HancockPose> {
        KeyframeTrack(\.bustLift) {
            LinearKeyframe(0, duration: 0.52)
            bustLift(0.5, 0.2)
            LinearKeyframe(0, duration: 0.04)
            bustLift(1.0, 0.32)
            LinearKeyframe(0, duration: 1.72)
        }
        KeyframeTrack(\.bustScaleY) {
            LinearKeyframe(1, duration: 0.52)
            bustY(0.5, 0.2)
            LinearKeyframe(1, duration: 0.04)
            bustY(1.0, 0.32)
            LinearKeyframe(1, duration: 1.72)
        }
        KeyframeTrack(\.bustScaleX) {
            LinearKeyframe(1, duration: 0.52)
            bustX(0.5, 0.2)
            LinearKeyframe(1, duration: 0.04)
            bustX(1.0, 0.32)
            LinearKeyframe(1, duration: 1.72)
        }
    }

    // MARK: - breakStart · "Love-struck" (3.0s)
    //
    // Segments: A rise 0.45, B freeze-jolt 0.2, C lean + hands up 0.35,
    // D sway left 0.35, E sway right (smaller) 0.35, F fan x2 0.5 (0.12, 0.10,
    // 0.10, 0.08, 0.10), G composed 0.3, H sink 0.5.

    @KeyframesBuilder<HancockPose>
    public static var loveStruck: some Keyframes<HancockPose> {
        loveStruckBody
        loveStruckHead
        loveStruckHair
        loveStruckLeftArm
        loveStruckRightArm
        loveStruckRightHand
        loveStruckFaces
        loveStruckHeart
        loveStruckBust
        loveStruckSash
    }

    @KeyframesBuilder<HancockPose>
    static var loveStruckBody: some Keyframes<HancockPose> {
        KeyframeTrack(\.emergence) {
            CubicKeyframe(0, duration: 0.45)
            Hold.moving(0, duration: 2.05, drift: 1.0)
            CubicKeyframe(200, duration: 0.5)
        }
        KeyframeTrack(\.figureRotation) {
            Hold.moving(0, duration: 0.45, drift: 0.5)
            Hold.moving(0, duration: 0.2, drift: 0.2)
            CubicKeyframe(2, duration: 0.35)
            CubicKeyframe(-4, duration: 0.35)
            CubicKeyframe(3, duration: 0.35)
            Hold.moving(0, duration: 0.5, drift: 0.8)
            CubicKeyframe(0, duration: 0.3)
            CubicKeyframe(1.5, duration: 0.5)
        }
        KeyframeTrack(\.figureLift) {
            Hold.moving(0, duration: 0.45, drift: 0.3)
            CubicKeyframe(-2.5, duration: 0.08)
            CubicKeyframe(-1.5, duration: 0.12)
            CubicKeyframe(1, duration: 0.35)
            Hold.moving(1, duration: 0.35, drift: 0.4)
            Hold.moving(1, duration: 0.35, drift: 0.3)
            Hold.breathing(0.5, duration: 0.5, drift: 0.5)
            CubicKeyframe(0, duration: 0.3)
            CubicKeyframe(1, duration: 0.5)
        }
        // Each sway is led by the hips; the second is smaller.
        KeyframeTrack(\.hips) {
            Hold.moving(4.5, duration: 0.45, drift: 0.8)
            CubicKeyframe(5, duration: 0.2)
            CubicKeyframe(6.5, duration: 0.35)
            CubicKeyframe(9.5, duration: 0.28)
            Hold.moving(9.5, duration: 0.07, drift: 0.2)
            CubicKeyframe(1.5, duration: 0.3)
            Hold.moving(1.5, duration: 0.05, drift: 0.2)
            Hold.breathing(4, duration: 0.5, drift: 0.8)
            Hold.moving(4.5, duration: 0.3, drift: 0.6)
            CubicKeyframe(4.5, duration: 0.5)
        }
        KeyframeTrack(\.chest) {
            Hold.moving(-9, duration: 0.45, drift: 0.6)
            CubicKeyframe(-7.5, duration: 0.2)
            CubicKeyframe(-9, duration: 0.35)
            CubicKeyframe(-16, duration: 0.35)
            CubicKeyframe(-2, duration: 0.35)
            Hold.breathing(-9.5, duration: 0.5, drift: 0.8)
            CubicKeyframe(-9, duration: 0.3)
            CubicKeyframe(-9, duration: 0.5)
        }
        KeyframeTrack(\.head) {
            Hold.moving(5, duration: 0.45, drift: 1.0)
            CubicKeyframe(0, duration: 0.2)
            CubicKeyframe(11, duration: 0.35)
            CubicKeyframe(15, duration: 0.35)
            CubicKeyframe(-3, duration: 0.35)
            Hold.breathing(3, duration: 0.5, drift: 1.0)
            CubicKeyframe(-2, duration: 0.3)
            CubicKeyframe(5, duration: 0.5)
        }
    }

    @KeyframesBuilder<HancockPose>
    static var loveStruckHead: some Keyframes<HancockPose> {
        KeyframeTrack(\.capeL) {
            CubicKeyframe(2, duration: 0.45)
            CubicKeyframe(5, duration: 0.2)
            CubicKeyframe(0, duration: 0.35)
            CubicKeyframe(-4, duration: 0.35)
            CubicKeyframe(3, duration: 0.35)
            Hold.breathing(0, duration: 0.5, drift: 1.0)
            Hold.moving(0, duration: 0.3, drift: 0.6)
            CubicKeyframe(2, duration: 0.5)
        }
        KeyframeTrack(\.capeR) {
            CubicKeyframe(-2, duration: 0.45)
            CubicKeyframe(-5, duration: 0.2)
            CubicKeyframe(0, duration: 0.35)
            CubicKeyframe(4, duration: 0.35)
            CubicKeyframe(-3, duration: 0.35)
            Hold.breathing(0, duration: 0.5, drift: -1.0)
            Hold.moving(0, duration: 0.3, drift: -0.6)
            CubicKeyframe(-2, duration: 0.5)
        }
    }

    @KeyframesBuilder<HancockPose>
    static var loveStruckHair: some Keyframes<HancockPose> {
        KeyframeTrack(\.hairBase) {
            Hold.moving(hang(0.5), duration: 0.45, drift: 0.6)
            CubicKeyframe(hang(-2.5), duration: 0.2)
            CubicKeyframe(hang(10.5), duration: 0.35)
            CubicKeyframe(hang(4.5), duration: 0.35)
            CubicKeyframe(hang(-0.5), duration: 0.35)
            Hold.breathing(hang(-2), duration: 0.5, drift: 0.6)
            Hold.moving(hang(-6.5), duration: 0.3, drift: 0.6)
            CubicKeyframe(hang(2), duration: 0.5)
        }
        // Hair lifts on the jolt, then swings opposite each sway.
        KeyframeTrack(\.hairMid) {
            Hold.moving(0, duration: 0.45, drift: 1.0)
            CubicKeyframe(-3, duration: 0.2)
            CubicKeyframe(2, duration: 0.35)
            CubicKeyframe(-6, duration: 0.35)
            CubicKeyframe(3, duration: 0.35)
            CubicKeyframe(-1.5, duration: 0.25)
            CubicKeyframe(0, duration: 0.25)
            Hold.moving(0, duration: 0.3, drift: 0.8)
            CubicKeyframe(-1, duration: 0.5)
        }
        KeyframeTrack(\.hairTip) {
            Hold.moving(0, duration: 0.5, drift: 1.4)
            CubicKeyframe(-5, duration: 0.2)
            CubicKeyframe(3, duration: 0.35)
            CubicKeyframe(-9, duration: 0.35)
            CubicKeyframe(5, duration: 0.3)
            CubicKeyframe(-2, duration: 0.3)
            CubicKeyframe(0, duration: 0.3)
            Hold.moving(0, duration: 0.2, drift: 1.0)
            CubicKeyframe(1, duration: 0.5)
        }
        KeyframeTrack(\.earringL) {
            Hold.moving(-3, duration: 0.45, drift: 1.0)
            CubicKeyframe(2, duration: 0.2)
            CubicKeyframe(-4, duration: 0.35)
            CubicKeyframe(-9, duration: 0.35)
            CubicKeyframe(2, duration: 0.35)
            Hold.breathing(-3, duration: 0.5, drift: 1.0)
            Hold.moving(-3, duration: 0.3, drift: 0.8)
            CubicKeyframe(-3, duration: 0.5)
        }
        KeyframeTrack(\.earringR) {
            Hold.moving(-3, duration: 0.45, drift: 1.0)
            CubicKeyframe(2, duration: 0.2)
            CubicKeyframe(-4, duration: 0.35)
            CubicKeyframe(-9, duration: 0.35)
            CubicKeyframe(2, duration: 0.35)
            Hold.breathing(-3, duration: 0.5, drift: 1.0)
            Hold.moving(-3, duration: 0.3, drift: 0.8)
            CubicKeyframe(-3, duration: 0.5)
        }
        KeyframeTrack(\.sideLockR) {
            Hold.moving(-3, duration: 0.45, drift: 1.0)
            CubicKeyframe(-0.5, duration: 0.2)
            CubicKeyframe(-3.5, duration: 0.35)
            CubicKeyframe(-6, duration: 0.35)
            CubicKeyframe(-0.5, duration: 0.35)
            Hold.breathing(-3, duration: 0.5, drift: 1.0)
            Hold.moving(-3, duration: 0.3, drift: 0.8)
            CubicKeyframe(-3, duration: 0.5)
        }
        KeyframeTrack(\.sideLockL) {
            Hold.moving(-3, duration: 0.45, drift: 1.0)
            CubicKeyframe(-0.5, duration: 0.2)
            CubicKeyframe(-3.5, duration: 0.35)
            CubicKeyframe(-6, duration: 0.35)
            CubicKeyframe(-0.5, duration: 0.35)
            Hold.breathing(-3, duration: 0.5, drift: 1.0)
            Hold.moving(-3, duration: 0.3, drift: 0.8)
            CubicKeyframe(-3, duration: 0.5)
        }
    }

    // Both hands come up and cross in front of her, so they meet just under her
    // chin, fingers up. The forearm only folds about 150 degrees, so they stop
    // under the chin instead of reaching the cheeks.
    @KeyframesBuilder<HancockPose>
    static var loveStruckLeftArm: some Keyframes<HancockPose> {
        KeyframeTrack(\.armL) {
            Hold.moving(17, duration: 0.45, drift: 1.0)
            CubicKeyframe(20, duration: 0.2)
            CubicKeyframe(-22, duration: 0.35)
            Hold.moving(-22, duration: 0.35, drift: 1.2)
            Hold.moving(-22, duration: 0.35, drift: 1.0)
            Hold.breathing(-22, duration: 0.5, drift: 1.2)
            CubicKeyframe(17, duration: 0.3)
            Hold.moving(17, duration: 0.5, drift: 1.0)
        }
        KeyframeTrack(\.armL_fore) {
            Hold.moving(-6, duration: 0.45, drift: 1.0)
            CubicKeyframe(-1, duration: 0.2)
            CubicKeyframe(-150, duration: 0.35)
            Hold.moving(-150, duration: 0.35, drift: 2.0)
            Hold.moving(-150, duration: 0.35, drift: 2.0)
            Hold.breathing(-150, duration: 0.5, drift: 2.0)
            CubicKeyframe(-6, duration: 0.3)
            Hold.moving(-6, duration: 0.5, drift: 1.0)
        }
        KeyframeTrack(\.handL) {
            Hold.moving(0, duration: 0.45, drift: 1.0)
            CubicKeyframe(0, duration: 0.2)
            CubicKeyframe(-15, duration: 0.35)
            Hold.moving(-15, duration: 0.35, drift: 2.0)
            Hold.moving(-15, duration: 0.35, drift: 2.0)
            Hold.breathing(-15, duration: 0.5, drift: 2.0)
            CubicKeyframe(0, duration: 0.3)
            Hold.moving(0, duration: 0.5, drift: 1.5)
        }
    }

    // The right arm leaves the hip at the freeze, goes to her face, fans, then
    // goes back to the hip.
    @KeyframesBuilder<HancockPose>
    static var loveStruckRightArm: some Keyframes<HancockPose> {
        KeyframeTrack(\.armR) {
            Hold.moving(-24, duration: 0.45, drift: -1.0)
            CubicKeyframe(-20, duration: 0.2)
            CubicKeyframe(22, duration: 0.35)
            Hold.moving(22, duration: 0.35, drift: 1.2)
            Hold.moving(22, duration: 0.35, drift: 1.0)
            // Fan: the hand leaves the face, two strokes, the second smaller.
            CubicKeyframe(55, duration: 0.12)
            CubicKeyframe(4, duration: 0.10)
            CubicKeyframe(42, duration: 0.10)
            CubicKeyframe(14, duration: 0.08)
            CubicKeyframe(22, duration: 0.10)
            CubicKeyframe(-24, duration: 0.3)
            Hold.moving(-24, duration: 0.5, drift: -1.0)
        }
        KeyframeTrack(\.armR_fore) {
            Hold.moving(74, duration: 0.45, drift: 1.0)
            CubicKeyframe(40, duration: 0.2)
            CubicKeyframe(150, duration: 0.35)
            Hold.moving(150, duration: 0.35, drift: -2.0)
            Hold.moving(150, duration: 0.35, drift: -2.0)
            CubicKeyframe(115, duration: 0.12)
            CubicKeyframe(148, duration: 0.10)
            CubicKeyframe(125, duration: 0.10)
            CubicKeyframe(149, duration: 0.08)
            CubicKeyframe(150, duration: 0.10)
            CubicKeyframe(74, duration: 0.3)
            Hold.moving(74, duration: 0.5, drift: 1.0)
        }
    }

    @KeyframesBuilder<HancockPose>
    static var loveStruckRightHand: some Keyframes<HancockPose> {
        KeyframeTrack(\.handR) {
            Hold.moving(24, duration: 0.45, drift: 1.0)
            CubicKeyframe(10, duration: 0.2)
            CubicKeyframe(15, duration: 0.35)
            Hold.moving(15, duration: 0.35, drift: 2.0)
            Hold.moving(15, duration: 0.35, drift: 2.0)
            CubicKeyframe(40, duration: 0.12)
            CubicKeyframe(-30, duration: 0.10)
            CubicKeyframe(25, duration: 0.10)
            CubicKeyframe(-12, duration: 0.08)
            CubicKeyframe(15, duration: 0.10)
            CubicKeyframe(24, duration: 0.3)
            Hold.moving(24, duration: 0.5, drift: 1.5)
        }
    }

    @KeyframesBuilder<HancockPose>
    static var loveStruckFaces: some Keyframes<HancockPose> {
        // Blush from 0.62 (the freeze), smug beat 2.0 to 2.2, haughty at 2.2.
        KeyframeTrack(\.flusteredOpacity) {
            LinearKeyframe(0, duration: 0.62)
            LinearKeyframe(1, duration: 0.01)
            LinearKeyframe(1, duration: 1.37)
            LinearKeyframe(0, duration: 0.01)
            LinearKeyframe(0, duration: 0.99)
        }
        KeyframeTrack(\.smugOpacity) {
            LinearKeyframe(0, duration: 2.0)
            LinearKeyframe(1, duration: 0.01)
            LinearKeyframe(1, duration: 0.19)
            LinearKeyframe(0, duration: 0.01)
            LinearKeyframe(0, duration: 0.79)
        }
        // The right hand is off the hip while it goes to her face and fans.
        KeyframeTrack(\.hipR) {
            LinearKeyframe(1, duration: 0.45)
            LinearKeyframe(0, duration: 0.01)
            LinearKeyframe(0, duration: 1.99)
            LinearKeyframe(1, duration: 0.01)
            LinearKeyframe(1, duration: 0.54)
        }
    }

    // Heart pops above her head at 0.7 (0.6 -> 1.1 -> 1.0), floats up 10 and fades.
    @KeyframesBuilder<HancockPose>
    static var loveStruckHeart: some Keyframes<HancockPose> {
        KeyframeTrack(\.heartOpacity) {
            LinearKeyframe(0, duration: 0.7)
            LinearKeyframe(1, duration: 0.01)
            LinearKeyframe(1, duration: 0.49)
            CubicKeyframe(0, duration: 0.5)
            LinearKeyframe(0, duration: 1.3)
        }
        KeyframeTrack(\.heartScale) {
            LinearKeyframe(0.6, duration: 0.7)
            CubicKeyframe(1.1, duration: 0.15)
            CubicKeyframe(1.0, duration: 0.15)
            Hold.moving(1.0, duration: 0.7, drift: 0.03)
            LinearKeyframe(1, duration: 1.3)
        }
        KeyframeTrack(\.heartLift) {
            LinearKeyframe(0, duration: 1.0)
            CubicKeyframe(-10, duration: 0.7)
            LinearKeyframe(-10, duration: 1.3)
        }
    }

    // The sash tail trails each sway by about 0.12s; the second is smaller.
    @KeyframesBuilder<HancockPose>
    static var loveStruckSash: some Keyframes<HancockPose> {
        KeyframeTrack(\.sashTail) {
            Hold.moving(0, duration: 1.0, drift: 0.6)
            CubicKeyframe(-9, duration: 0.45)
            CubicKeyframe(6, duration: 0.35)
            CubicKeyframe(-2, duration: 0.3)
            CubicKeyframe(0, duration: 0.3)
            Hold.moving(0, duration: 0.6, drift: 0.5)
        }
    }

    // Bust: the jolt, sway left, sway right (smaller).
    @KeyframesBuilder<HancockPose>
    static var loveStruckBust: some Keyframes<HancockPose> {
        KeyframeTrack(\.bustLift) {
            LinearKeyframe(0, duration: 0.49)
            bustLift(0.9, 0.3)
            LinearKeyframe(0, duration: 0.26)
            bustLift(0.8, 0.3)
            LinearKeyframe(0, duration: 0.03)
            bustLift(0.45, 0.28)
            LinearKeyframe(0, duration: 1.34)
        }
        KeyframeTrack(\.bustScaleY) {
            LinearKeyframe(1, duration: 0.49)
            bustY(0.9, 0.3)
            LinearKeyframe(1, duration: 0.26)
            bustY(0.8, 0.3)
            LinearKeyframe(1, duration: 0.03)
            bustY(0.45, 0.28)
            LinearKeyframe(1, duration: 1.34)
        }
        KeyframeTrack(\.bustScaleX) {
            LinearKeyframe(1, duration: 0.49)
            bustX(0.9, 0.3)
            LinearKeyframe(1, duration: 0.26)
            bustX(0.8, 0.3)
            LinearKeyframe(1, duration: 0.03)
            bustX(0.45, 0.28)
            LinearKeyframe(1, duration: 1.34)
        }
    }

    // MARK: - longBreak · "Empress" (3.4s)
    //
    // Segments: A rise 0.45, B wind-up 0.2, C sweep 0.35, D step 0.25,
    // E hold + laugh 1.05 (0.2, 0.15, 0.15, 0.15, 0.1, 0.1, 0.2), F straighten +
    // hair flick 0.45, G sink 0.65.

    @KeyframesBuilder<HancockPose>
    public static var empress: some Keyframes<HancockPose> {
        empressBody
        empressHead
        empressHair
        empressLegs
        empressRightArm
        empressLeftArm
        empressFaces
        empressBust
        empressSash
    }

    @KeyframesBuilder<HancockPose>
    static var empressBody: some Keyframes<HancockPose> {
        KeyframeTrack(\.emergence) {
            CubicKeyframe(0, duration: 0.45)
            Hold.moving(0, duration: 2.3, drift: 1.0)
            CubicKeyframe(200, duration: 0.65)
        }
        KeyframeTrack(\.figureRotation) {
            Hold.moving(0, duration: 0.45, drift: 0.5)
            CubicKeyframe(-3, duration: 0.2)
            CubicKeyframe(2, duration: 0.35)
            CubicKeyframe(-1, duration: 0.25)
            Hold.breathing(-1.5, duration: 1.05, drift: 0.7)
            CubicKeyframe(0, duration: 0.45)
            Hold.moving(0, duration: 0.65, drift: 0.8)
        }
        // Laugh bobs: the whole body dips and recovers, the second smaller.
        KeyframeTrack(\.figureLift) {
            Hold.moving(0, duration: 0.45, drift: 0.3)
            CubicKeyframe(1, duration: 0.2)
            CubicKeyframe(-1.5, duration: 0.35)
            CubicKeyframe(-0.5, duration: 0.25)
            Hold.moving(-1, duration: 0.2, drift: 0.3)
            CubicKeyframe(1.2, duration: 0.15)
            CubicKeyframe(-1, duration: 0.15)
            CubicKeyframe(0.4, duration: 0.15)
            CubicKeyframe(-0.8, duration: 0.1)
            CubicKeyframe(-0.8, duration: 0.1)
            Hold.moving(-0.8, duration: 0.2, drift: 0.3)
            CubicKeyframe(0, duration: 0.45)
            CubicKeyframe(1.2, duration: 0.65)
        }
        KeyframeTrack(\.hips) {
            Hold.moving(4.5, duration: 0.45, drift: 0.8)
            CubicKeyframe(7, duration: 0.2)
            CubicKeyframe(5.5, duration: 0.35)
            CubicKeyframe(-3.5, duration: 0.25)
            Hold.breathing(-3.5, duration: 1.05, drift: 0.8)
            CubicKeyframe(4.5, duration: 0.45)
            Hold.moving(4.5, duration: 0.65, drift: 0.8)
        }
        KeyframeTrack(\.chest) {
            Hold.moving(-9, duration: 0.45, drift: 0.6)
            CubicKeyframe(-6, duration: 0.2)
            CubicKeyframe(-10, duration: 0.35)
            CubicKeyframe(1, duration: 0.25)
            Hold.breathing(4, duration: 1.05, drift: 0.8)
            CubicKeyframe(-9, duration: 0.45)
            Hold.moving(-9, duration: 0.65, drift: 0.6)
        }
    }

    @KeyframesBuilder<HancockPose>
    static var empressHead: some Keyframes<HancockPose> {
        KeyframeTrack(\.head) {
            Hold.moving(5, duration: 0.45, drift: 1.0)
            CubicKeyframe(7, duration: 0.2)
            CubicKeyframe(3, duration: 0.35)
            CubicKeyframe(-2, duration: 0.25)
            CubicKeyframe(-7, duration: 0.2)
            CubicKeyframe(-12, duration: 0.15)
            CubicKeyframe(-6, duration: 0.15)
            CubicKeyframe(-10, duration: 0.15)
            CubicKeyframe(-6.5, duration: 0.1)
            CubicKeyframe(-7, duration: 0.1)
            Hold.moving(-7, duration: 0.2, drift: 0.8)
            CubicKeyframe(6, duration: 0.45)
            Hold.moving(5, duration: 0.65, drift: 1.0)
        }
        // The cape is pulled in on the wind-up, billows wide 0.15s after the arm.
        KeyframeTrack(\.capeR) {
            Hold.moving(0, duration: 0.45, drift: -1.0)
            CubicKeyframe(4, duration: 0.2)
            CubicKeyframe(-12, duration: 0.35)
            CubicKeyframe(-34, duration: 0.25)
            CubicKeyframe(-14, duration: 0.2)
            CubicKeyframe(-22, duration: 0.2)
            Hold.breathing(-16, duration: 0.65, drift: -1.5)
            CubicKeyframe(-3, duration: 0.45)
            Hold.moving(-2, duration: 0.65, drift: -1.0)
        }
        KeyframeTrack(\.capeL) {
            Hold.moving(0, duration: 0.45, drift: 1.0)
            CubicKeyframe(-2, duration: 0.2)
            CubicKeyframe(6, duration: 0.35)
            CubicKeyframe(14, duration: 0.25)
            CubicKeyframe(6, duration: 0.2)
            CubicKeyframe(9, duration: 0.2)
            Hold.breathing(7, duration: 0.65, drift: 1.0)
            CubicKeyframe(1, duration: 0.45)
            Hold.moving(1, duration: 0.65, drift: 0.8)
        }
    }

    @KeyframesBuilder<HancockPose>
    static var empressHair: some Keyframes<HancockPose> {
        KeyframeTrack(\.hairBase) {
            Hold.moving(hang(0.5), duration: 0.45, drift: 0.6)
            CubicKeyframe(hang(5), duration: 0.2)
            CubicKeyframe(hang(0.5), duration: 0.35)
            CubicKeyframe(hang(-5.5), duration: 0.25)
            CubicKeyframe(hang(-8), duration: 0.2)
            CubicKeyframe(hang(-13), duration: 0.15)
            CubicKeyframe(hang(-7), duration: 0.15)
            CubicKeyframe(hang(-11), duration: 0.15)
            CubicKeyframe(hang(-7.5), duration: 0.1)
            CubicKeyframe(hang(-8), duration: 0.1)
            Hold.moving(hang(-8), duration: 0.2, drift: 0.5)
            CubicKeyframe(hang(1.5), duration: 0.45)
            Hold.moving(hang(0.5), duration: 0.65, drift: 0.6)
        }
        KeyframeTrack(\.hairMid) {
            Hold.moving(0, duration: 0.45, drift: 1.0)
            CubicKeyframe(-2, duration: 0.2)
            CubicKeyframe(3, duration: 0.35)
            CubicKeyframe(-6, duration: 0.25)
            CubicKeyframe(3, duration: 0.2)
            CubicKeyframe(-2, duration: 0.15)
            CubicKeyframe(1.5, duration: 0.15)
            CubicKeyframe(-1.5, duration: 0.15)
            CubicKeyframe(0.8, duration: 0.1)
            CubicKeyframe(0, duration: 0.1)
            Hold.moving(0, duration: 0.2, drift: 0.8)
            CubicKeyframe(-6, duration: 0.2)
            CubicKeyframe(3, duration: 0.25)
            Hold.moving(0, duration: 0.65, drift: 1.0)
        }
        KeyframeTrack(\.hairTip) {
            Hold.moving(0, duration: 0.5, drift: 1.4)
            CubicKeyframe(-4, duration: 0.2)
            CubicKeyframe(7, duration: 0.35)
            CubicKeyframe(-10, duration: 0.25)
            CubicKeyframe(5, duration: 0.2)
            CubicKeyframe(-3, duration: 0.2)
            CubicKeyframe(1.5, duration: 0.15)
            CubicKeyframe(-1.5, duration: 0.15)
            CubicKeyframe(0, duration: 0.2)
            CubicKeyframe(-10, duration: 0.25)
            CubicKeyframe(6, duration: 0.25)
            CubicKeyframe(-1, duration: 0.2)
            Hold.moving(0, duration: 0.5, drift: 1.2)
        }
        KeyframeTrack(\.earringL) {
            Hold.moving(-3, duration: 0.45, drift: 1.0)
            CubicKeyframe(-8, duration: 0.2)
            CubicKeyframe(0, duration: 0.35)
            CubicKeyframe(6, duration: 0.25)
            CubicKeyframe(-3, duration: 0.2)
            CubicKeyframe(4, duration: 0.15)
            CubicKeyframe(-2, duration: 0.15)
            CubicKeyframe(2, duration: 0.15)
            Hold.moving(-1, duration: 0.4, drift: 1.0)
            CubicKeyframe(-3, duration: 0.45)
            Hold.moving(-3, duration: 0.65, drift: 1.0)
        }
        KeyframeTrack(\.earringR) {
            Hold.moving(-3, duration: 0.45, drift: 1.0)
            CubicKeyframe(-8, duration: 0.2)
            CubicKeyframe(0, duration: 0.35)
            CubicKeyframe(6, duration: 0.25)
            CubicKeyframe(-3, duration: 0.2)
            CubicKeyframe(4, duration: 0.15)
            CubicKeyframe(-2, duration: 0.15)
            CubicKeyframe(2, duration: 0.15)
            Hold.moving(-1, duration: 0.4, drift: 1.0)
            CubicKeyframe(-3, duration: 0.45)
            Hold.moving(-3, duration: 0.65, drift: 1.0)
        }
        KeyframeTrack(\.sideLockR) {
            Hold.moving(-3, duration: 0.45, drift: 1.0)
            CubicKeyframe(-5.5, duration: 0.2)
            CubicKeyframe(-1.5, duration: 0.35)
            CubicKeyframe(1.5, duration: 0.25)
            CubicKeyframe(-3, duration: 0.2)
            CubicKeyframe(0.5, duration: 0.15)
            CubicKeyframe(-2.5, duration: 0.15)
            CubicKeyframe(-0.5, duration: 0.15)
            Hold.moving(-2, duration: 0.4, drift: 1.0)
            CubicKeyframe(-3, duration: 0.45)
            Hold.moving(-3, duration: 0.65, drift: 1.0)
        }
        KeyframeTrack(\.sideLockL) {
            Hold.moving(-3, duration: 0.45, drift: 1.0)
            CubicKeyframe(-5.5, duration: 0.2)
            CubicKeyframe(-1.5, duration: 0.35)
            CubicKeyframe(1.5, duration: 0.25)
            CubicKeyframe(-3, duration: 0.2)
            CubicKeyframe(0.5, duration: 0.15)
            CubicKeyframe(-2.5, duration: 0.15)
            CubicKeyframe(-0.5, duration: 0.15)
            Hold.moving(-2, duration: 0.4, drift: 1.0)
            CubicKeyframe(-3, duration: 0.45)
            Hold.moving(-3, duration: 0.65, drift: 1.0)
        }
    }

    // The slit leg steps through at 1.0 to 1.25, the skirt panel swings open.
    @KeyframesBuilder<HancockPose>
    static var empressLegs: some Keyframes<HancockPose> {
        KeyframeTrack(\.legL) {
            Hold.moving(-6, duration: 0.45, drift: 0.5)
            CubicKeyframe(-7, duration: 0.2)
            CubicKeyframe(-6, duration: 0.35)
            CubicKeyframe(30, duration: 0.25)
            Hold.moving(30, duration: 1.05, drift: 0.8)
            CubicKeyframe(-6, duration: 0.45)
            Hold.moving(-6, duration: 0.65, drift: 0.5)
        }
        KeyframeTrack(\.shinL) {
            Hold.moving(2, duration: 0.45, drift: 0.8)
            CubicKeyframe(2, duration: 0.2)
            CubicKeyframe(2, duration: 0.35)
            CubicKeyframe(-8, duration: 0.25)
            Hold.moving(-8, duration: 1.05, drift: 1.0)
            CubicKeyframe(2, duration: 0.45)
            Hold.moving(2, duration: 0.65, drift: 0.8)
        }
        KeyframeTrack(\.skirtPanel) {
            Hold.moving(0, duration: 1.0, drift: 0.6)
            CubicKeyframe(25, duration: 0.25)
            Hold.moving(23, duration: 1.05, drift: 1.0)
            CubicKeyframe(0, duration: 0.45)
            Hold.moving(0, duration: 0.65, drift: 0.6)
        }
        KeyframeTrack(\.legR) {
            Hold.moving(-1, duration: 1.0, drift: 0.5)
            CubicKeyframe(-2, duration: 0.25)
            Hold.moving(-2, duration: 1.05, drift: 0.5)
            CubicKeyframe(-1, duration: 0.45)
            Hold.moving(-1, duration: 0.65, drift: 0.5)
        }
        KeyframeTrack(\.shinR) {
            Hold.moving(2, duration: 3.4, drift: 0.6)
        }
    }

    @KeyframesBuilder<HancockPose>
    static var empressRightArm: some Keyframes<HancockPose> {
        // Crosses the body gathering the cape, sweeps out wide, then to her hip.
        KeyframeTrack(\.armR) {
            Hold.moving(-24, duration: 0.45, drift: -1.0)
            CubicKeyframe(28, duration: 0.2)
            CubicKeyframe(-88, duration: 0.35)
            CubicKeyframe(-24, duration: 0.25)
            Hold.moving(-24, duration: 1.05, drift: 1.0)
            Hold.moving(-24, duration: 0.45, drift: 0.8)
            Hold.moving(-24, duration: 0.65, drift: 0.5)
        }
        KeyframeTrack(\.armR_fore) {
            Hold.moving(74, duration: 0.45, drift: 1.0)
            CubicKeyframe(100, duration: 0.2)
            CubicKeyframe(2, duration: 0.35)
            CubicKeyframe(74, duration: 0.25)
            Hold.moving(74, duration: 1.05, drift: -2.0)
            Hold.moving(74, duration: 0.45, drift: -1.5)
            Hold.moving(74, duration: 0.65, drift: -1.0)
        }
        KeyframeTrack(\.handR) {
            Hold.moving(24, duration: 0.45, drift: 1.0)
            CubicKeyframe(-10, duration: 0.2)
            CubicKeyframe(8, duration: 0.35)
            CubicKeyframe(24, duration: 0.25)
            Hold.moving(24, duration: 1.05, drift: 1.5)
            Hold.moving(24, duration: 0.45, drift: 1.0)
            Hold.moving(24, duration: 0.65, drift: 1.0)
        }
    }

    @KeyframesBuilder<HancockPose>
    static var empressLeftArm: some Keyframes<HancockPose> {
        // Hand to her mouth during the step, then the hair flick.
        KeyframeTrack(\.armL) {
            Hold.moving(17, duration: 0.45, drift: 1.0)
            CubicKeyframe(14, duration: 0.2)
            CubicKeyframe(14, duration: 0.35)
            CubicKeyframe(-22, duration: 0.25)
            Hold.moving(-22, duration: 1.05, drift: 1.2)
            CubicKeyframe(34, duration: 0.2)
            CubicKeyframe(46, duration: 0.25)
            CubicKeyframe(17, duration: 0.35)
            Hold.moving(17, duration: 0.3, drift: 1.0)
        }
        KeyframeTrack(\.armL_fore) {
            Hold.moving(-6, duration: 0.45, drift: 1.0)
            CubicKeyframe(-6, duration: 0.2)
            CubicKeyframe(-8, duration: 0.35)
            CubicKeyframe(-145, duration: 0.25)
            Hold.moving(-145, duration: 1.05, drift: 2.0)
            CubicKeyframe(-148, duration: 0.2)
            CubicKeyframe(-105, duration: 0.25)
            CubicKeyframe(-6, duration: 0.35)
            Hold.moving(-6, duration: 0.3, drift: 1.0)
        }
        KeyframeTrack(\.handL) {
            Hold.moving(0, duration: 0.45, drift: 1.0)
            CubicKeyframe(0, duration: 0.2)
            CubicKeyframe(0, duration: 0.35)
            CubicKeyframe(-20, duration: 0.25)
            Hold.moving(-20, duration: 1.05, drift: 2.0)
            CubicKeyframe(25, duration: 0.2)
            CubicKeyframe(-12, duration: 0.25)
            CubicKeyframe(0, duration: 0.35)
            Hold.moving(0, duration: 0.3, drift: 1.0)
        }
    }

    @KeyframesBuilder<HancockPose>
    static var empressFaces: some Keyframes<HancockPose> {
        KeyframeTrack(\.laughOpacity) {
            LinearKeyframe(0, duration: 1.2)
            LinearKeyframe(1, duration: 0.01)
            LinearKeyframe(1, duration: 1.08)
            LinearKeyframe(0, duration: 0.01)
            LinearKeyframe(0, duration: 1.1)
        }
        KeyframeTrack(\.smugOpacity) {
            LinearKeyframe(0, duration: 2.3)
            LinearKeyframe(1, duration: 0.01)
            LinearKeyframe(1, duration: 1.09)
        }
        KeyframeTrack(\.mouthL) {
            LinearKeyframe(0, duration: 1.2)
            LinearKeyframe(1, duration: 0.01)
            LinearKeyframe(1, duration: 1.09)
            LinearKeyframe(0, duration: 0.01)
            LinearKeyframe(0, duration: 1.09)
        }
        // On the hip at rest, off it for the wind-up, sweep and step, back on at 1.15.
        KeyframeTrack(\.hipR) {
            LinearKeyframe(1, duration: 0.45)
            LinearKeyframe(0, duration: 0.01)
            LinearKeyframe(0, duration: 0.69)
            LinearKeyframe(1, duration: 0.01)
            LinearKeyframe(1, duration: 2.24)
        }
    }

    // The sash tail trails the hips: it lags the turn, swings out when the hips
    // shift for the step (and again on the plant), then settles and follows the
    // hips back as she straightens.
    @KeyframesBuilder<HancockPose>
    static var empressSash: some Keyframes<HancockPose> {
        KeyframeTrack(\.sashTail) {
            Hold.moving(0, duration: 0.55, drift: 0.5)
            CubicKeyframe(-5, duration: 0.25)
            CubicKeyframe(2, duration: 0.3)
            CubicKeyframe(14, duration: 0.3)
            CubicKeyframe(-5, duration: 0.25)
            CubicKeyframe(3, duration: 0.2)
            Hold.breathing(1, duration: 0.55, drift: 1.0)
            CubicKeyframe(-8, duration: 0.3)
            CubicKeyframe(2, duration: 0.3)
            CubicKeyframe(0, duration: 0.2)
            Hold.moving(0, duration: 0.2, drift: 0.5)
        }
    }

    // Bust: rise, the plant of the step, then two laugh bobs (the second smaller).
    @KeyframesBuilder<HancockPose>
    static var empressBust: some Keyframes<HancockPose> {
        KeyframeTrack(\.bustLift) {
            LinearKeyframe(0, duration: 0.47)
            bustLift(0.5, 0.25)
            LinearKeyframe(0, duration: 0.55)
            bustLift(1.0, 0.2)
            LinearKeyframe(0, duration: 0.02)
            bustLift(0.5, 0.24)
            LinearKeyframe(0, duration: 0.19)
            bustLift(0.3, 0.22)
            LinearKeyframe(0, duration: 1.26)
        }
        KeyframeTrack(\.bustScaleY) {
            LinearKeyframe(1, duration: 0.47)
            bustY(0.5, 0.25)
            LinearKeyframe(1, duration: 0.55)
            bustY(1.0, 0.2)
            LinearKeyframe(1, duration: 0.02)
            bustY(0.5, 0.24)
            LinearKeyframe(1, duration: 0.19)
            bustY(0.3, 0.22)
            LinearKeyframe(1, duration: 1.26)
        }
        KeyframeTrack(\.bustScaleX) {
            LinearKeyframe(1, duration: 0.47)
            bustX(0.5, 0.25)
            LinearKeyframe(1, duration: 0.55)
            bustX(1.0, 0.2)
            LinearKeyframe(1, duration: 0.02)
            bustX(0.5, 0.24)
            LinearKeyframe(1, duration: 0.19)
            bustX(0.3, 0.22)
            LinearKeyframe(1, duration: 1.26)
        }
    }
}
