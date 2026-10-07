import PomodoroCore
import SwiftUI

/// The samurai's three performances, written from the round-2 animation plan.
///
/// Each is a `KeyframeTrack` set over `SamuraiPose`; a row of the plan's tables maps
/// to a handful of keyframes here, so the two can be diffed by eye.
///
/// Convention: positive rotation is clockwise on screen, `emergence` counts design
/// units *behind* the pill edge (200 = hidden, 0 = risen, negative = overshoot).
///
/// The arm and sword angles are solved so the off hand lands on the hilt: the sword
/// hand sets where the katana is, and the off hand sits one fist's width behind it on
/// the handle. Each pose is annotated with the hand positions it was solved for.
public enum SamuraiPerformance {

    /// Preferred emergence edge per cue. The stage flips these when the pill is too
    /// close to a screen edge.
    /// Everything reveals from the top. Rising from behind the pill is the one
    /// gesture that makes the pill feel like the thing he lives in.
    public static func preferredEdge(for cue: CharacterCue) -> StageEdge { .top }

    /// Whether he comes *in front of* the pill rather than staying behind it.
    /// Only the back-to-work cue does: stepping into the foreground and aiming at
    /// you is what makes it read as a demand rather than a wave.
    public static func comesForward(for cue: CharacterCue) -> Bool {
        cue == .focusStart
    }

    public static func duration(for cue: CharacterCue) -> Double {
        switch cue {
        case .focusStart: 2.40
        case .breakStart: 2.80
        case .longBreak: 3.20
        }
    }

    // MARK: - focusStart: "One cut" (2.4s)
    //
    // 0.00-0.45 rise (blade low)  0.45-0.60 sink, off hand joins the hilt
    // 0.60-0.95 blade arcs into high guard  0.95-1.10 hold  1.10-1.22 the cut
    // 1.22-1.70 finish pose, armour catches up  1.70-2.05 straighten, bow  2.05-2.40 sink
    //
    // Hand targets (design units): A0 sword hand (128,172) blade 150 deg; A1 (112,152)
    // blade 140; A2 high guard (127,98) blade 62; A3 finish (100,154) blade 205;
    // A4 rest (104,156) blade 180. The off hand is always 10.5 behind the sword hand.
    // Elbow bend stays between 0 and 140 degrees in every pose.

    /// He rises calmly with the blade low, settles, lifts it over his shoulder into
    /// high guard, holds, and cuts once, fast, down across the bar.
    @KeyframesBuilder<SamuraiPose>
    public static var snapToGuard: some Keyframes<SamuraiPose> {
        KeyframeTrack(\.swordArmUpper) {
            LinearKeyframe(-6.52, duration: 0.12)
            Rest.moving(-6.52, duration: 0.33, drift: 0.8)
            CubicKeyframe(-6.73, duration: 0.15, startVelocity: 0)
            CubicKeyframe(-130.28, duration: 0.35, endVelocity: 0)
            Rest.moving(-130.28, duration: 0.15, drift: 0.7)
            CubicKeyframe(13.11, duration: 0.12, startVelocity: 0)
            SpringKeyframe(13.11, duration: 0.3, spring: .init(response: 0.24, dampingRatio: 0.5))
            Rest.moving(13.11, duration: 0.18, drift: 0.8)
            CubicKeyframe(8.67, duration: 0.35, startVelocity: 0, endVelocity: 0)
            Rest.moving(8.67, duration: 0.35, drift: 0.8)
        }
        KeyframeTrack(\.swordFore) {
            LinearKeyframe(21.36, duration: 0.12)
            Rest.moving(21.36, duration: 0.33, drift: 0.8)
            CubicKeyframe(97.48, duration: 0.15, startVelocity: 0)
            CubicKeyframe(-121.03, duration: 0.35, endVelocity: 0)
            Rest.moving(-121.03, duration: 0.15, drift: 0.7)
            CubicKeyframe(73.3, duration: 0.12, startVelocity: 0)
            SpringKeyframe(73.3, duration: 0.3, spring: .init(response: 0.24, dampingRatio: 0.5))
            Rest.moving(73.3, duration: 0.18, drift: 0.8)
            CubicKeyframe(72.73, duration: 0.35, startVelocity: 0, endVelocity: 0)
            Rest.moving(72.73, duration: 0.35, drift: 0.8)
        }
        KeyframeTrack(\.katana) {
            LinearKeyframe(111.03, duration: 0.12)
            Rest.moving(111.03, duration: 0.33, drift: 0.8)
            CubicKeyframe(20.13, duration: 0.15, startVelocity: 0)
            CubicKeyframe(-76.81, duration: 0.35, endVelocity: 0)
            Rest.moving(-76.81, duration: 0.15, drift: 0.7)
            CubicKeyframe(-255.53, duration: 0.12, startVelocity: 0)
            SpringKeyframe(-255.53, duration: 0.3, spring: .init(response: 0.24, dampingRatio: 0.5))
            Rest.moving(-255.53, duration: 0.18, drift: 0.8)
            CubicKeyframe(-285.52, duration: 0.35, startVelocity: 0, endVelocity: 0)
            Rest.moving(-285.52, duration: 0.35, drift: 0.8)
        }
        KeyframeTrack(\.offArmUpper) {
            LinearKeyframe(0, duration: 0.12)
            Rest.moving(0, duration: 0.33, drift: 0.8)
            CubicKeyframe(-26.29, duration: 0.15, startVelocity: 0)
            CubicKeyframe(-105.85, duration: 0.35, endVelocity: 0)
            Rest.moving(-105.85, duration: 0.15, drift: 0.7)
            CubicKeyframe(-33.08, duration: 0.12, startVelocity: 0)
            SpringKeyframe(-33.08, duration: 0.3, spring: .init(response: 0.24, dampingRatio: 0.5))
            Rest.moving(-33.08, duration: 0.18, drift: 0.8)
            CubicKeyframe(-25.94, duration: 0.35, startVelocity: 0, endVelocity: 0)
            Rest.moving(-25.94, duration: 0.35, drift: 0.8)
        }
        KeyframeTrack(\.offArmFore) {
            LinearKeyframe(0, duration: 0.12)
            Rest.moving(0, duration: 0.33, drift: 0.8)
            CubicKeyframe(-85.81, duration: 0.15, startVelocity: 0)
            CubicKeyframe(-56.45, duration: 0.35, endVelocity: 0)
            Rest.moving(-56.45, duration: 0.15, drift: 0.7)
            CubicKeyframe(-70.97, duration: 0.12, startVelocity: 0)
            SpringKeyframe(-70.97, duration: 0.3, spring: .init(response: 0.24, dampingRatio: 0.5))
            Rest.moving(-70.97, duration: 0.18, drift: 0.8)
            CubicKeyframe(-81.01, duration: 0.35, startVelocity: 0, endVelocity: 0)
            Rest.moving(-81.01, duration: 0.35, drift: 0.8)
        }
        KeyframeTrack(\.legL) {
            LinearKeyframe(0, duration: 0.45)
            CubicKeyframe(6, duration: 0.15)
            CubicKeyframe(3, duration: 0.35)
            LinearKeyframe(3, duration: 0.15)
            CubicKeyframe(11, duration: 0.12)
            SpringKeyframe(10, duration: 0.3, spring: .init(response: 0.3, dampingRatio: 0.6))
            LinearKeyframe(10, duration: 0.18)
            CubicKeyframe(0, duration: 0.35, endVelocity: 0)
            Rest.moving(0, duration: 0.35, drift: 0.4)
        }
        KeyframeTrack(\.shinL) {
            LinearKeyframe(0, duration: 0.45)
            CubicKeyframe(-14.47, duration: 0.15)
            CubicKeyframe(-7.23, duration: 0.35)
            LinearKeyframe(-7.23, duration: 0.15)
            CubicKeyframe(-26.6, duration: 0.12)
            SpringKeyframe(-24.16, duration: 0.3, spring: .init(response: 0.3, dampingRatio: 0.6))
            LinearKeyframe(-24.16, duration: 0.18)
            CubicKeyframe(0, duration: 0.35, endVelocity: 0)
            Rest.moving(0, duration: 0.35, drift: 0.4)
        }
        KeyframeTrack(\.legR) {
            LinearKeyframe(0, duration: 0.45)
            CubicKeyframe(-6, duration: 0.15)
            CubicKeyframe(-4, duration: 0.35)
            LinearKeyframe(-4, duration: 0.15)
            CubicKeyframe(-1, duration: 0.12)
            SpringKeyframe(-2, duration: 0.3, spring: .init(response: 0.3, dampingRatio: 0.6))
            LinearKeyframe(-2, duration: 0.18)
            CubicKeyframe(0, duration: 0.35, endVelocity: 0)
            Rest.moving(0, duration: 0.35, drift: 0.4)
        }
        KeyframeTrack(\.shinR) {
            LinearKeyframe(0, duration: 0.45)
            CubicKeyframe(14.47, duration: 0.15)
            CubicKeyframe(9.64, duration: 0.35)
            LinearKeyframe(9.64, duration: 0.15)
            CubicKeyframe(2.41, duration: 0.12)
            SpringKeyframe(4.82, duration: 0.3, spring: .init(response: 0.3, dampingRatio: 0.6))
            LinearKeyframe(4.82, duration: 0.18)
            CubicKeyframe(0, duration: 0.35, endVelocity: 0)
            Rest.moving(0, duration: 0.35, drift: 0.4)
        }
        KeyframeTrack(\.emergence) {
            CubicKeyframe(0, duration: 0.45, startVelocity: -900, endVelocity: 0)
            Rest.breathing(0, duration: 1.6, drift: 0.8)
            CubicKeyframe(200, duration: 0.35, startVelocity: 0, endVelocity: 900)
        }
        KeyframeTrack(\.rootScaleY) {
            LinearKeyframe(1, duration: 0.45)
            CubicKeyframe(0.99, duration: 0.15)
            CubicKeyframe(1, duration: 0.35)
            LinearKeyframe(1, duration: 0.15)
            CubicKeyframe(0.97, duration: 0.12)
            SpringKeyframe(0.98, duration: 0.3, spring: .init(response: 0.3, dampingRatio: 0.6))
            LinearKeyframe(0.98, duration: 0.18)
            CubicKeyframe(0.97, duration: 0.35)
            LinearKeyframe(0.97, duration: 0.35)
        }
        KeyframeTrack(\.rootLean) {
            Rest.breathing(0, duration: 1.1, drift: 0.4)
            CubicKeyframe(-0.8, duration: 0.12)
            CubicKeyframe(-0.5, duration: 0.48)
            CubicKeyframe(0, duration: 0.35)
            LinearKeyframe(0, duration: 0.35)
        }
        KeyframeTrack(\.torso) {
            LinearKeyframe(0, duration: 0.45)
            CubicKeyframe(5, duration: 0.15)
            CubicKeyframe(6, duration: 0.35, endVelocity: 0)
            Rest.moving(6, duration: 0.15, drift: 0.5)
            CubicKeyframe(-10, duration: 0.12, startVelocity: 0)
            SpringKeyframe(-9, duration: 0.3, spring: .init(response: 0.28, dampingRatio: 0.5))
            Rest.moving(-9, duration: 0.18, drift: 0.5)
            CubicKeyframe(0, duration: 0.35, startVelocity: 0, endVelocity: 0)
            Rest.moving(0, duration: 0.35, drift: 0.4)
        }
        KeyframeTrack(\.torsoScaleY) {
            LinearKeyframe(1, duration: 1.7)
            CubicKeyframe(0.93, duration: 0.35)
            LinearKeyframe(0.93, duration: 0.35)
        }
        KeyframeTrack(\.head) {
            LinearKeyframe(0, duration: 0.45)
            CubicKeyframe(-2, duration: 0.15)
            CubicKeyframe(-3, duration: 0.35, endVelocity: 0)
            Rest.moving(-3, duration: 0.15, drift: 0.4)
            CubicKeyframe(5, duration: 0.12, startVelocity: 0)
            SpringKeyframe(3, duration: 0.3, spring: .init(response: 0.3, dampingRatio: 0.5))
            Rest.moving(3, duration: 0.18, drift: 0.4)
            CubicKeyframe(0, duration: 0.35, startVelocity: 0)
            LinearKeyframe(0, duration: 0.35)
        }
        KeyframeTrack(\.headScale) {
            LinearKeyframe(1, duration: 1.7)
            CubicKeyframe(0.94, duration: 0.35)
            LinearKeyframe(0.94, duration: 0.35)
        }
        KeyframeTrack(\.kabuto) {
            Rest.breathing(0, duration: 1.1, drift: 0.4)
            CubicKeyframe(-3, duration: 0.12)
            SpringKeyframe(0, duration: 0.3, spring: .init(response: 0.3, dampingRatio: 0.5))
            LinearKeyframe(0, duration: 0.18)
            CubicKeyframe(3, duration: 0.35)
            LinearKeyframe(3, duration: 0.35)
        }
        KeyframeTrack(\.maedate) {
            CubicKeyframe(6, duration: 0.3)
            SpringKeyframe(-3, duration: 0.15, spring: .init(response: 0.45, dampingRatio: 0.35))
            SpringKeyframe(0, duration: 0.15, spring: .init(response: 0.45, dampingRatio: 0.4))
            CubicKeyframe(-5, duration: 0.35, endVelocity: 0)
            Rest.moving(-5, duration: 0.15, drift: 0.6)
            CubicKeyframe(9, duration: 0.12, startVelocity: 0)
            SpringKeyframe(-3, duration: 0.28, spring: .init(response: 0.4, dampingRatio: 0.35))
            SpringKeyframe(0, duration: 0.3, spring: .init(response: 0.45, dampingRatio: 0.4))
            Rest.moving(0, duration: 0.25, drift: 0.6)
            CubicKeyframe(4, duration: 0.35, startVelocity: 0, endVelocity: 0)
        }
        KeyframeTrack(\.sodeL) {
            LinearKeyframe(0, duration: 0.6)
            CubicKeyframe(6, duration: 0.35, endVelocity: 0)
            Rest.moving(6, duration: 0.15, drift: 0.5)
            CubicKeyframe(2, duration: 0.12, startVelocity: 0)
            SpringKeyframe(-7, duration: 0.18, spring: .init(response: 0.3, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.35, spring: .init(response: 0.4, dampingRatio: 0.5))
            Rest.moving(0, duration: 0.65, drift: 0.5)
        }
        KeyframeTrack(\.sodeR) {
            LinearKeyframe(0, duration: 0.6)
            CubicKeyframe(-6, duration: 0.35, endVelocity: 0)
            Rest.moving(-6, duration: 0.15, drift: 0.5)
            CubicKeyframe(-2, duration: 0.12, startVelocity: 0)
            SpringKeyframe(7, duration: 0.2, spring: .init(response: 0.3, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.36, spring: .init(response: 0.4, dampingRatio: 0.5))
            Rest.moving(0, duration: 0.62, drift: 0.5)
        }
        KeyframeTrack(\.kusazuriL) {
            Rest.breathing(0, duration: 1.1, drift: 0.4)
            CubicKeyframe(8, duration: 0.14)
            SpringKeyframe(-5, duration: 0.22, spring: .init(response: 0.3, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.34, spring: .init(response: 0.4, dampingRatio: 0.5))
            Rest.moving(0, duration: 0.6, drift: 0.5)
        }
        KeyframeTrack(\.kusazuriFL) {
            Rest.breathing(0, duration: 1.1, drift: 0.4)
            CubicKeyframe(6, duration: 0.14)
            SpringKeyframe(-4, duration: 0.22, spring: .init(response: 0.3, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.34, spring: .init(response: 0.4, dampingRatio: 0.5))
            Rest.moving(0, duration: 0.6, drift: 0.5)
        }
        KeyframeTrack(\.kusazuriFR) {
            Rest.breathing(0, duration: 1.1, drift: 0.4)
            CubicKeyframe(-6, duration: 0.14)
            SpringKeyframe(4, duration: 0.22, spring: .init(response: 0.3, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.34, spring: .init(response: 0.4, dampingRatio: 0.5))
            Rest.moving(0, duration: 0.6, drift: 0.5)
        }
        KeyframeTrack(\.kusazuriR) {
            Rest.breathing(0, duration: 1.1, drift: 0.4)
            CubicKeyframe(-8, duration: 0.14)
            SpringKeyframe(5, duration: 0.22, spring: .init(response: 0.3, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.34, spring: .init(response: 0.4, dampingRatio: 0.5))
            Rest.moving(0, duration: 0.6, drift: 0.5)
        }
        KeyframeTrack(\.sashTailL) {
            LinearKeyframe(0, duration: 0.6)
            CubicKeyframe(8, duration: 0.2)
            CubicKeyframe(-2, duration: 0.3)
            CubicKeyframe(14, duration: 0.16)
            SpringKeyframe(-7, duration: 0.29, spring: .init(response: 0.3, dampingRatio: 0.4))
            SpringKeyframe(0, duration: 0.4, spring: .init(response: 0.4, dampingRatio: 0.45))
            Rest.moving(0, duration: 0.45, drift: 0.8)
        }
        KeyframeTrack(\.sashTailR) {
            LinearKeyframe(0, duration: 0.6)
            CubicKeyframe(-8, duration: 0.2)
            CubicKeyframe(2, duration: 0.3)
            CubicKeyframe(-14, duration: 0.16)
            SpringKeyframe(7, duration: 0.29, spring: .init(response: 0.3, dampingRatio: 0.4))
            SpringKeyframe(0, duration: 0.4, spring: .init(response: 0.4, dampingRatio: 0.45))
            Rest.moving(0, duration: 0.45, drift: 0.8)
        }
        KeyframeTrack(\.chestCord) {
            Rest.breathing(0, duration: 1.1, drift: 0.4)
            CubicKeyframe(7, duration: 0.14)
            SpringKeyframe(-4, duration: 0.26, spring: .init(response: 0.3, dampingRatio: 0.4))
            SpringKeyframe(0, duration: 0.4, spring: .init(response: 0.4, dampingRatio: 0.5))
            Rest.moving(0, duration: 0.5, drift: 0.6)
        }
        KeyframeTrack(\.scabbard) {
            Rest.breathing(0, duration: 1.1, drift: 0.4)
            CubicKeyframe(4, duration: 0.14)
            SpringKeyframe(-2, duration: 0.26, spring: .init(response: 0.3, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.4, spring: .init(response: 0.4, dampingRatio: 0.5))
            Rest.moving(0, duration: 0.5, drift: 0.4)
        }
        KeyframeTrack(\.pupilDrop) {
            LinearKeyframe(0, duration: 0.6)
            CubicKeyframe(-0.9, duration: 0.35, endVelocity: 0)
            Rest.moving(-0.9, duration: 0.15, drift: 0.1)
            CubicKeyframe(0.5, duration: 0.16, startVelocity: 0, endVelocity: 0)
            Rest.moving(0.5, duration: 0.79, drift: 0.1)
            CubicKeyframe(0, duration: 0.35, startVelocity: 0, endVelocity: 0)
        }
    }

    // MARK: - breakStart: "Rest on the blade" (2.8s)
    //
    // Both fists stack on the pommel at (100,136), blade straight down. He stands
    // 33 units taller than at rest (emergence -17) so the tip lands on the bar edge
    // instead of vanishing behind it.

    /// He rises, plants the blade tip on the bar, rests both hands on the pommel and
    /// dozes with one small head bob, then jolts awake and sinks with the blade lifting.
    @KeyframesBuilder<SamuraiPose>
    public static var exhale: some Keyframes<SamuraiPose> {
        KeyframeTrack(\.swordArmUpper) {
            LinearKeyframe(-0.29, duration: 0.12)
            Rest.moving(-0.29, duration: 0.28, drift: 0.6)
            SpringKeyframe(28.19, duration: 0.4, spring: .init(response: 0.32, dampingRatio: 0.7))
            CubicKeyframe(29.74, duration: 0.6, endVelocity: 0)
            Rest.breathing(29.74, duration: 0.5, drift: 0.7)
            SpringKeyframe(36.35, duration: 0.2, spring: .init(response: 0.18, dampingRatio: 0.55))
            Rest.moving(36.35, duration: 0.22, drift: 0.4)
            CubicKeyframe(43.92, duration: 0.48, startVelocity: 0, endVelocity: 0)
        }
        KeyframeTrack(\.swordFore) {
            LinearKeyframe(95.83, duration: 0.12)
            Rest.moving(95.83, duration: 0.28, drift: 0.6)
            SpringKeyframe(106.41, duration: 0.4, spring: .init(response: 0.32, dampingRatio: 0.7))
            CubicKeyframe(104.02, duration: 0.6, endVelocity: 0)
            Rest.breathing(104.02, duration: 0.5, drift: 0.7)
            SpringKeyframe(112.91, duration: 0.2, spring: .init(response: 0.18, dampingRatio: 0.55))
            Rest.moving(112.91, duration: 0.22, drift: 0.4)
            CubicKeyframe(129.73, duration: 0.48, startVelocity: 0, endVelocity: 0)
        }
        KeyframeTrack(\.katana) {
            LinearKeyframe(45.34, duration: 0.12)
            Rest.moving(45.34, duration: 0.28, drift: 0.6)
            SpringKeyframe(21.28, duration: 0.4, spring: .init(response: 0.32, dampingRatio: 0.7))
            CubicKeyframe(20.12, duration: 0.6, endVelocity: 0)
            Rest.breathing(20.12, duration: 0.5, drift: 0.7)
            SpringKeyframe(5.62, duration: 0.2, spring: .init(response: 0.18, dampingRatio: 0.55))
            Rest.moving(5.62, duration: 0.22, drift: 0.4)
            CubicKeyframe(-37.77, duration: 0.48, startVelocity: 0, endVelocity: 0)
        }
        KeyframeTrack(\.offArmUpper) {
            LinearKeyframe(-32.63, duration: 0.12)
            Rest.moving(-32.63, duration: 0.28, drift: 0.6)
            SpringKeyframe(-49.13, duration: 0.4, spring: .init(response: 0.32, dampingRatio: 0.7))
            CubicKeyframe(-48.08, duration: 0.6, endVelocity: 0)
            Rest.breathing(-48.08, duration: 0.5, drift: 0.7)
            SpringKeyframe(-61.25, duration: 0.2, spring: .init(response: 0.18, dampingRatio: 0.55))
            Rest.moving(-61.25, duration: 0.22, drift: 0.4)
            CubicKeyframe(-71.94, duration: 0.48, startVelocity: 0, endVelocity: 0)
        }
        KeyframeTrack(\.offArmFore) {
            LinearKeyframe(-87.42, duration: 0.12)
            Rest.moving(-87.42, duration: 0.28, drift: 0.6)
            SpringKeyframe(-114.05, duration: 0.4, spring: .init(response: 0.32, dampingRatio: 0.7))
            CubicKeyframe(-117.55, duration: 0.6, endVelocity: 0)
            Rest.breathing(-117.55, duration: 0.5, drift: 0.7)
            SpringKeyframe(-112.48, duration: 0.2, spring: .init(response: 0.18, dampingRatio: 0.55))
            Rest.moving(-112.48, duration: 0.22, drift: 0.4)
            CubicKeyframe(-104.39, duration: 0.48, startVelocity: 0, endVelocity: 0)
        }
        KeyframeTrack(\.emergence) {
            CubicKeyframe(-17, duration: 0.4, startVelocity: -1000, endVelocity: 0)
            Rest.moving(-17, duration: 0.4, drift: 0.8)
            Rest.breathing(-17, duration: 1.1, drift: 0.8)
            CubicKeyframe(-24, duration: 0.2, startVelocity: 0, endVelocity: 0)
            Rest.moving(-24, duration: 0.22, drift: 0.5)
            CubicKeyframe(200, duration: 0.48, startVelocity: 0, endVelocity: 900)
        }
        KeyframeTrack(\.rootScaleY) {
            CubicKeyframe(1.03, duration: 0.4)
            SpringKeyframe(1, duration: 0.4, spring: .init(response: 0.3, dampingRatio: 0.6))
            Rest.breathing(1, duration: 2, drift: 0.01)
        }
        KeyframeTrack(\.torso) {
            LinearKeyframe(0, duration: 0.8)
            CubicKeyframe(2, duration: 0.6, endVelocity: 0)
            Rest.breathing(2, duration: 0.5, drift: 0.5)
            SpringKeyframe(-1, duration: 0.2, spring: .init(response: 0.2, dampingRatio: 0.5))
            CubicKeyframe(0, duration: 0.22, endVelocity: 0)
            Rest.moving(0, duration: 0.48, drift: 0.3)
        }
        KeyframeTrack(\.torsoScaleY) {
            LinearKeyframe(1, duration: 0.8)
            CubicKeyframe(0.96, duration: 0.6)
            CubicKeyframe(0.98, duration: 0.25)
            CubicKeyframe(0.96, duration: 0.25)
            SpringKeyframe(1, duration: 0.2, spring: .init(response: 0.2, dampingRatio: 0.55))
            Rest.moving(1, duration: 0.7, drift: 0.01)
        }
        KeyframeTrack(\.head) {
            Rest.moving(0, duration: 0.8, drift: 0.4)
            CubicKeyframe(13, duration: 0.6, startVelocity: 0)
            CubicKeyframe(16, duration: 0.25)
            CubicKeyframe(12, duration: 0.25)
            SpringKeyframe(-4, duration: 0.2, spring: .init(response: 0.18, dampingRatio: 0.5))
            Rest.moving(-4, duration: 0.22, drift: 0.4)
            CubicKeyframe(0, duration: 0.48, startVelocity: 0, endVelocity: 0)
        }
        KeyframeTrack(\.kabuto) {
            LinearKeyframe(0, duration: 0.8)
            CubicKeyframe(2, duration: 0.6, endVelocity: 0)
            Rest.breathing(2, duration: 0.5, drift: 0.6)
            SpringKeyframe(-2, duration: 0.2, spring: .init(response: 0.2, dampingRatio: 0.5))
            CubicKeyframe(0, duration: 0.7, endVelocity: 0)
        }
        KeyframeTrack(\.maedate) {
            CubicKeyframe(8, duration: 0.3)
            SpringKeyframe(-4, duration: 0.25, spring: .init(response: 0.45, dampingRatio: 0.35))
            SpringKeyframe(0, duration: 0.35, spring: .init(response: 0.45, dampingRatio: 0.4))
            CubicKeyframe(3, duration: 0.5)
            CubicKeyframe(0, duration: 0.5)
            SpringKeyframe(-8, duration: 0.2, spring: .init(response: 0.2, dampingRatio: 0.35))
            SpringKeyframe(2, duration: 0.3, spring: .init(response: 0.4, dampingRatio: 0.4))
            CubicKeyframe(5, duration: 0.4, endVelocity: 0)
        }
        KeyframeTrack(\.sodeL) {
            LinearKeyframe(0, duration: 0.8)
            CubicKeyframe(-4, duration: 0.6, endVelocity: 0)
            Rest.breathing(-4, duration: 0.5, drift: 0.5)
            SpringKeyframe(3, duration: 0.2, spring: .init(response: 0.2, dampingRatio: 0.5))
            SpringKeyframe(0, duration: 0.4, spring: .init(response: 0.4, dampingRatio: 0.5))
            Rest.moving(0, duration: 0.3, drift: 0.4)
        }
        KeyframeTrack(\.sodeR) {
            LinearKeyframe(0, duration: 0.8)
            CubicKeyframe(4, duration: 0.6, endVelocity: 0)
            Rest.breathing(4, duration: 0.5, drift: 0.5)
            SpringKeyframe(-3, duration: 0.2, spring: .init(response: 0.2, dampingRatio: 0.5))
            SpringKeyframe(0, duration: 0.4, spring: .init(response: 0.4, dampingRatio: 0.5))
            Rest.moving(0, duration: 0.3, drift: 0.4)
        }
        KeyframeTrack(\.kusazuriL) {
            CubicKeyframe(-5, duration: 0.3)
            SpringKeyframe(2, duration: 0.3, spring: .init(response: 0.4, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.4, spring: .init(response: 0.45, dampingRatio: 0.5))
            Rest.moving(0, duration: 0.9, drift: 0.6)
            SpringKeyframe(-3.5, duration: 0.2, spring: .init(response: 0.22, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.5, spring: .init(response: 0.4, dampingRatio: 0.5))
            Rest.moving(0, duration: 0.2, drift: 0.4)
        }
        KeyframeTrack(\.kusazuriFL) {
            CubicKeyframe(-3, duration: 0.3)
            SpringKeyframe(1.2, duration: 0.3, spring: .init(response: 0.4, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.4, spring: .init(response: 0.45, dampingRatio: 0.5))
            Rest.moving(0, duration: 0.9, drift: 0.6)
            SpringKeyframe(-2.1, duration: 0.2, spring: .init(response: 0.22, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.5, spring: .init(response: 0.4, dampingRatio: 0.5))
            Rest.moving(0, duration: 0.2, drift: 0.4)
        }
        KeyframeTrack(\.kusazuriFR) {
            CubicKeyframe(3, duration: 0.3)
            SpringKeyframe(-1.2, duration: 0.3, spring: .init(response: 0.4, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.4, spring: .init(response: 0.45, dampingRatio: 0.5))
            Rest.moving(0, duration: 0.9, drift: 0.6)
            SpringKeyframe(2.1, duration: 0.2, spring: .init(response: 0.22, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.5, spring: .init(response: 0.4, dampingRatio: 0.5))
            Rest.moving(0, duration: 0.2, drift: 0.4)
        }
        KeyframeTrack(\.kusazuriR) {
            CubicKeyframe(5, duration: 0.3)
            SpringKeyframe(-2, duration: 0.3, spring: .init(response: 0.4, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.4, spring: .init(response: 0.45, dampingRatio: 0.5))
            Rest.moving(0, duration: 0.9, drift: 0.6)
            SpringKeyframe(3.5, duration: 0.2, spring: .init(response: 0.22, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.5, spring: .init(response: 0.4, dampingRatio: 0.5))
            Rest.moving(0, duration: 0.2, drift: 0.4)
        }
        KeyframeTrack(\.sashTailL) {
            CubicKeyframe(10, duration: 0.4)
            SpringKeyframe(-3, duration: 0.4, spring: .init(response: 0.4, dampingRatio: 0.4))
            SpringKeyframe(0, duration: 0.6, spring: .init(response: 0.5, dampingRatio: 0.5))
            CubicKeyframe(2, duration: 0.5)
            SpringKeyframe(10, duration: 0.2, spring: .init(response: 0.2, dampingRatio: 0.4))
            SpringKeyframe(0, duration: 0.5, spring: .init(response: 0.4, dampingRatio: 0.45))
            Rest.moving(0, duration: 0.2, drift: 0.5)
        }
        KeyframeTrack(\.sashTailR) {
            CubicKeyframe(-10, duration: 0.4)
            SpringKeyframe(3, duration: 0.4, spring: .init(response: 0.4, dampingRatio: 0.4))
            SpringKeyframe(0, duration: 0.6, spring: .init(response: 0.5, dampingRatio: 0.5))
            CubicKeyframe(-2, duration: 0.5)
            SpringKeyframe(-10, duration: 0.2, spring: .init(response: 0.2, dampingRatio: 0.4))
            SpringKeyframe(0, duration: 0.5, spring: .init(response: 0.4, dampingRatio: 0.45))
            Rest.moving(0, duration: 0.2, drift: 0.5)
        }
        KeyframeTrack(\.chestCord) {
            LinearKeyframe(0, duration: 0.8)
            CubicKeyframe(3, duration: 0.6)
            CubicKeyframe(2, duration: 0.5)
            SpringKeyframe(-5, duration: 0.2, spring: .init(response: 0.2, dampingRatio: 0.4))
            SpringKeyframe(0, duration: 0.5, spring: .init(response: 0.4, dampingRatio: 0.5))
            Rest.moving(0, duration: 0.2, drift: 0.4)
        }
        KeyframeTrack(\.legL) {
            LinearKeyframe(0, duration: 0.4)
            CubicKeyframe(3, duration: 0.4)
            CubicKeyframe(2, duration: 1.1)
            CubicKeyframe(5, duration: 0.2)
            CubicKeyframe(0, duration: 0.4, endVelocity: 0)
            Rest.moving(0, duration: 0.3, drift: 0.4)
        }
        KeyframeTrack(\.shinL) {
            LinearKeyframe(0, duration: 0.4)
            CubicKeyframe(-7.23, duration: 0.4)
            CubicKeyframe(-4.82, duration: 1.1)
            CubicKeyframe(-12.05, duration: 0.2)
            CubicKeyframe(0, duration: 0.4, endVelocity: 0)
            Rest.moving(0, duration: 0.3, drift: 0.4)
        }
        KeyframeTrack(\.legR) {
            LinearKeyframe(0, duration: 0.4)
            CubicKeyframe(-3, duration: 0.4)
            CubicKeyframe(-2, duration: 1.1)
            CubicKeyframe(-5, duration: 0.2)
            CubicKeyframe(0, duration: 0.4, endVelocity: 0)
            Rest.moving(0, duration: 0.3, drift: 0.4)
        }
        KeyframeTrack(\.shinR) {
            LinearKeyframe(0, duration: 0.4)
            CubicKeyframe(7.23, duration: 0.4)
            CubicKeyframe(4.82, duration: 1.1)
            CubicKeyframe(12.05, duration: 0.2)
            CubicKeyframe(0, duration: 0.4, endVelocity: 0)
            Rest.moving(0, duration: 0.3, drift: 0.4)
        }
        KeyframeTrack(\.eyeOpacity) {
            LinearKeyframe(1, duration: 1.05)
            LinearKeyframe(0, duration: 0.1)
            LinearKeyframe(0, duration: 0.75)
            LinearKeyframe(1, duration: 0.06)
            LinearKeyframe(1, duration: 0.84)
        }
        KeyframeTrack(\.fierceOpacity) {
            LinearKeyframe(1, duration: 1)
            LinearKeyframe(0, duration: 0.08)
            LinearKeyframe(0, duration: 0.82)
            LinearKeyframe(1, duration: 0.06)
            LinearKeyframe(1, duration: 0.84)
        }
        KeyframeTrack(\.easeOpacity) {
            LinearKeyframe(0, duration: 1.08)
            LinearKeyframe(1, duration: 0.08)
            LinearKeyframe(1, duration: 0.74)
            LinearKeyframe(0, duration: 0.06)
            LinearKeyframe(0, duration: 0.84)
        }
        KeyframeTrack(\.scabbard) {
            CubicKeyframe(3, duration: 0.4)
            SpringKeyframe(-1, duration: 0.4, spring: .init(response: 0.4, dampingRatio: 0.4))
            LinearKeyframe(0, duration: 1.3)
            SpringKeyframe(4, duration: 0.2, spring: .init(response: 0.2, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.5, spring: .init(response: 0.4, dampingRatio: 0.5))
        }
        KeyframeTrack(\.rootLean) {
            LinearKeyframe(0, duration: 0.8)
            CubicKeyframe(0.6, duration: 0.6, endVelocity: 0)
            Rest.breathing(0.6, duration: 0.5, drift: 0.3)
            SpringKeyframe(-0.4, duration: 0.2, spring: .init(response: 0.2, dampingRatio: 0.5))
            CubicKeyframe(0, duration: 0.22, endVelocity: 0)
            Rest.moving(0, duration: 0.48, drift: 0.3)
        }
        KeyframeTrack(\.pupilDrop) {
            LinearKeyframe(0, duration: 0.8)
            CubicKeyframe(1.4, duration: 0.15, endVelocity: 0)
            Rest.moving(1.4, duration: 0.95, drift: 0.1)
            CubicKeyframe(-0.4, duration: 0.1, startVelocity: 0)
            CubicKeyframe(0, duration: 0.8, endVelocity: 0)
        }
    }

    // MARK: - longBreak: "Victory cry" (3.2s)
    //
    // 0.00-0.35 rise  0.35-0.55 crouch  0.55-0.95 one jump (24 units), blade thrust
    // straight up, off fist to the hip  0.95-1.15 land wide  1.15-2.20 kiai hold
    // 2.20-2.70 deep bow, blade lowers  2.70-3.20 sink

    /// A fast rise, a crouch, one jump with the blade thrust straight up, a wide
    /// landing and a held kiai. Then the blade comes down, he bows deeply and sinks.
    @KeyframesBuilder<SamuraiPose>
    public static var triumph: some Keyframes<SamuraiPose> {
        KeyframeTrack(\.swordArmUpper) {
            CubicKeyframe(0, duration: 0.35)
            CubicKeyframe(-26.92, duration: 0.2)
            SpringKeyframe(-130.44, duration: 0.25, spring: .init(response: 0.26, dampingRatio: 0.55))
            Rest.moving(-130.44, duration: 0.15, drift: 0.6)
            Rest.moving(-130.44, duration: 0.2, drift: 0.6)
            Rest.breathing(-130.44, duration: 1.05, drift: 1.2)
            CubicKeyframe(-7.76, duration: 0.4, startVelocity: 0, endVelocity: 0)
            Rest.moving(-7.76, duration: 0.1, drift: 0.4)
            Rest.moving(-7.76, duration: 0.5, drift: 0.4)
        }
        KeyframeTrack(\.swordFore) {
            CubicKeyframe(0, duration: 0.35)
            CubicKeyframe(107.87, duration: 0.2)
            SpringKeyframe(-39.9, duration: 0.25, spring: .init(response: 0.26, dampingRatio: 0.55))
            Rest.moving(-39.9, duration: 0.15, drift: 0.6)
            Rest.moving(-39.9, duration: 0.2, drift: 0.6)
            Rest.breathing(-39.9, duration: 1.05, drift: 1.2)
            CubicKeyframe(54.42, duration: 0.4, startVelocity: 0, endVelocity: 0)
            Rest.moving(54.42, duration: 0.1, drift: 0.4)
            Rest.moving(54.42, duration: 0.5, drift: 0.4)
        }
        KeyframeTrack(\.katana) {
            CubicKeyframe(0, duration: 0.35)
            CubicKeyframe(-85.07, duration: 0.2)
            SpringKeyframe(-213.78, duration: 0.25, spring: .init(response: 0.26, dampingRatio: 0.55))
            CubicKeyframe(-213.78, duration: 0.15)
            CubicKeyframe(-207.78, duration: 0.1)
            SpringKeyframe(-213.78, duration: 0.2, spring: .init(response: 0.25, dampingRatio: 0.45))
            Rest.moving(-213.78, duration: 0.95, drift: 1.2)
            CubicKeyframe(-260.78, duration: 0.4, startVelocity: 0, endVelocity: 0)
            Rest.moving(-260.78, duration: 0.1, drift: 0.4)
            Rest.moving(-260.78, duration: 0.5, drift: 0.4)
        }
        KeyframeTrack(\.offArmUpper) {
            CubicKeyframe(0, duration: 0.35)
            CubicKeyframe(28.12, duration: 0.2)
            SpringKeyframe(28.77, duration: 0.25, spring: .init(response: 0.26, dampingRatio: 0.55))
            Rest.moving(28.77, duration: 0.15, drift: 0.6)
            Rest.moving(28.77, duration: 0.2, drift: 0.6)
            Rest.breathing(28.77, duration: 1.05, drift: 1.2)
            CubicKeyframe(0, duration: 0.4, startVelocity: 0, endVelocity: 0)
            Rest.moving(0, duration: 0.1, drift: 0.4)
            Rest.moving(0, duration: 0.5, drift: 0.4)
        }
        KeyframeTrack(\.offArmFore) {
            CubicKeyframe(0, duration: 0.35)
            CubicKeyframe(-85.22, duration: 0.2)
            SpringKeyframe(-78.51, duration: 0.25, spring: .init(response: 0.26, dampingRatio: 0.55))
            Rest.moving(-78.51, duration: 0.15, drift: 0.6)
            Rest.moving(-78.51, duration: 0.2, drift: 0.6)
            Rest.breathing(-78.51, duration: 1.05, drift: 1.2)
            CubicKeyframe(0, duration: 0.4, startVelocity: 0, endVelocity: 0)
            Rest.moving(0, duration: 0.1, drift: 0.4)
            Rest.moving(0, duration: 0.5, drift: 0.4)
        }
        KeyframeTrack(\.legL) {
            LinearKeyframe(0, duration: 0.35)
            CubicKeyframe(12, duration: 0.2)
            CubicKeyframe(3, duration: 0.2)
            CubicKeyframe(14, duration: 0.2)
            SpringKeyframe(12, duration: 0.2, spring: .init(response: 0.3, dampingRatio: 0.5))
            Rest.breathing(12, duration: 1.05, drift: 0.4)
            CubicKeyframe(4, duration: 0.25)
            CubicKeyframe(0, duration: 0.25, endVelocity: 0)
            Rest.moving(0, duration: 0.5, drift: 0.4)
        }
        KeyframeTrack(\.shinL) {
            LinearKeyframe(0, duration: 0.35)
            CubicKeyframe(-29.04, duration: 0.2)
            CubicKeyframe(-7.23, duration: 0.2)
            CubicKeyframe(-33.93, duration: 0.2)
            SpringKeyframe(-29.04, duration: 0.2, spring: .init(response: 0.3, dampingRatio: 0.5))
            Rest.breathing(-29.04, duration: 1.05, drift: 0.4)
            CubicKeyframe(-9.64, duration: 0.25)
            CubicKeyframe(0, duration: 0.25, endVelocity: 0)
            Rest.moving(0, duration: 0.5, drift: 0.4)
        }
        KeyframeTrack(\.legR) {
            LinearKeyframe(0, duration: 0.35)
            CubicKeyframe(-12, duration: 0.2)
            CubicKeyframe(-3, duration: 0.2)
            CubicKeyframe(-14, duration: 0.2)
            SpringKeyframe(-12, duration: 0.2, spring: .init(response: 0.3, dampingRatio: 0.5))
            Rest.breathing(-12, duration: 1.05, drift: 0.4)
            CubicKeyframe(-4, duration: 0.25)
            CubicKeyframe(0, duration: 0.25, endVelocity: 0)
            Rest.moving(0, duration: 0.5, drift: 0.4)
        }
        KeyframeTrack(\.shinR) {
            LinearKeyframe(0, duration: 0.35)
            CubicKeyframe(29.04, duration: 0.2)
            CubicKeyframe(7.23, duration: 0.2)
            CubicKeyframe(33.93, duration: 0.2)
            SpringKeyframe(29.04, duration: 0.2, spring: .init(response: 0.3, dampingRatio: 0.5))
            Rest.breathing(29.04, duration: 1.05, drift: 0.4)
            CubicKeyframe(9.64, duration: 0.25)
            CubicKeyframe(0, duration: 0.25, endVelocity: 0)
            Rest.moving(0, duration: 0.5, drift: 0.4)
        }
        KeyframeTrack(\.emergence) {
            CubicKeyframe(-6, duration: 0.35, startVelocity: -900, endVelocity: 0)
            CubicKeyframe(0, duration: 0.2)
            CubicKeyframe(-12.5, duration: 0.2, startVelocity: -260, endVelocity: 0)
            CubicKeyframe(0, duration: 0.2, startVelocity: 0, endVelocity: 520)
            Rest.breathing(0, duration: 1.75, drift: 0.8)
            CubicKeyframe(200, duration: 0.5, startVelocity: 0, endVelocity: 900)
        }
        KeyframeTrack(\.rootScaleY) {
            CubicKeyframe(1.05, duration: 0.35)
            CubicKeyframe(0.9, duration: 0.2)
            CubicKeyframe(1.06, duration: 0.2)
            CubicKeyframe(0.92, duration: 0.2)
            SpringKeyframe(1, duration: 0.2, spring: .init(response: 0.3, dampingRatio: 0.5))
            Rest.breathing(1, duration: 1.05, drift: 0.01)
            CubicKeyframe(0.95, duration: 0.25, startVelocity: 0)
            LinearKeyframe(0.95, duration: 0.25)
            CubicKeyframe(1.04, duration: 0.5, endVelocity: 0)
        }
        KeyframeTrack(\.rootLean) {
            Rest.breathing(0, duration: 1.15, drift: 0.4)
            CubicKeyframe(-0.8, duration: 0.35)
            CubicKeyframe(0.6, duration: 0.4)
            CubicKeyframe(0, duration: 0.3)
            Rest.moving(0, duration: 1, drift: 0.4)
        }
        KeyframeTrack(\.torso) {
            Rest.breathing(0, duration: 1.15, drift: 0.4)
            Rest.breathing(0, duration: 1.05, drift: 0.8)
            LinearKeyframe(0, duration: 0.25)
            Rest.moving(0, duration: 0.75, drift: 0.3)
        }
        KeyframeTrack(\.torsoScaleY) {
            CubicKeyframe(0.95, duration: 0.55)
            CubicKeyframe(1.03, duration: 0.2)
            CubicKeyframe(0.96, duration: 0.2)
            SpringKeyframe(1, duration: 0.2, spring: .init(response: 0.3, dampingRatio: 0.5))
            Rest.breathing(1, duration: 1.05, drift: 0.012)
            CubicKeyframe(0.9, duration: 0.25, startVelocity: 0)
            LinearKeyframe(0.9, duration: 0.25)
            CubicKeyframe(1, duration: 0.5, endVelocity: 0)
        }
        KeyframeTrack(\.head) {
            LinearKeyframe(0, duration: 0.55)
            CubicKeyframe(-6, duration: 0.2)
            CubicKeyframe(-8, duration: 0.2)
            CubicKeyframe(-14, duration: 0.2, endVelocity: 0)
            Rest.breathing(-14, duration: 1.05, drift: 1.0)
            CubicKeyframe(2, duration: 0.25, startVelocity: 0)
            LinearKeyframe(2, duration: 0.25)
            CubicKeyframe(0, duration: 0.5, endVelocity: 0)
        }
        KeyframeTrack(\.headScale) {
            LinearKeyframe(1, duration: 2.2)
            CubicKeyframe(0.93, duration: 0.25)
            LinearKeyframe(0.93, duration: 0.25)
            CubicKeyframe(1, duration: 0.5, endVelocity: 0)
        }
        KeyframeTrack(\.kabutoLift) {
            Rest.moving(0, duration: 0.95, drift: 0.4)
            CubicKeyframe(-4, duration: 0.07)
            SpringKeyframe(0, duration: 0.23, spring: .init(response: 0.3, dampingRatio: 0.45))
            Rest.breathing(0, duration: 1.95, drift: 0.4)
        }
        KeyframeTrack(\.kabuto) {
            Rest.breathing(0, duration: 2.2, drift: 0.4)
            CubicKeyframe(4, duration: 0.25)
            LinearKeyframe(4, duration: 0.25)
            CubicKeyframe(0, duration: 0.5, endVelocity: 0)
        }
        KeyframeTrack(\.maedate) {
            CubicKeyframe(8, duration: 0.35)
            CubicKeyframe(-4, duration: 0.2)
            CubicKeyframe(12, duration: 0.2)
            CubicKeyframe(-14, duration: 0.2)
            SpringKeyframe(8, duration: 0.2, spring: .init(response: 0.4, dampingRatio: 0.3))
            SpringKeyframe(-3, duration: 0.3, spring: .init(response: 0.4, dampingRatio: 0.35))
            SpringKeyframe(0, duration: 0.3, spring: .init(response: 0.45, dampingRatio: 0.4))
            Rest.moving(0, duration: 0.45, drift: 0.8)
            CubicKeyframe(6, duration: 0.25, startVelocity: 0)
            LinearKeyframe(6, duration: 0.25)
            CubicKeyframe(0, duration: 0.5, endVelocity: 0)
        }
        KeyframeTrack(\.sodeL) {
            LinearKeyframe(0, duration: 0.55)
            CubicKeyframe(-8, duration: 0.2)
            CubicKeyframe(12, duration: 0.2)
            SpringKeyframe(-4, duration: 0.2, spring: .init(response: 0.3, dampingRatio: 0.4))
            SpringKeyframe(0, duration: 0.3, spring: .init(response: 0.4, dampingRatio: 0.45))
            Rest.breathing(0, duration: 1.75, drift: 0.5)
        }
        KeyframeTrack(\.sodeR) {
            LinearKeyframe(0, duration: 0.55)
            CubicKeyframe(8, duration: 0.2)
            CubicKeyframe(-12, duration: 0.2)
            SpringKeyframe(4, duration: 0.2, spring: .init(response: 0.3, dampingRatio: 0.4))
            SpringKeyframe(0, duration: 0.3, spring: .init(response: 0.4, dampingRatio: 0.45))
            Rest.breathing(0, duration: 1.75, drift: 0.5)
        }
        KeyframeTrack(\.kusazuriL) {
            CubicKeyframe(-12, duration: 0.35)
            SpringKeyframe(0, duration: 0.2, spring: .init(response: 0.3, dampingRatio: 0.5))
            CubicKeyframe(10, duration: 0.2)
            CubicKeyframe(-14, duration: 0.2)
            SpringKeyframe(6, duration: 0.2, spring: .init(response: 0.3, dampingRatio: 0.4))
            SpringKeyframe(0, duration: 0.35, spring: .init(response: 0.4, dampingRatio: 0.45))
            Rest.breathing(0, duration: 1.7, drift: 0.6)
        }
        KeyframeTrack(\.kusazuriFL) {
            CubicKeyframe(-8.4, duration: 0.35)
            SpringKeyframe(0, duration: 0.2, spring: .init(response: 0.3, dampingRatio: 0.5))
            CubicKeyframe(7, duration: 0.2)
            CubicKeyframe(-9.8, duration: 0.2)
            SpringKeyframe(4.2, duration: 0.2, spring: .init(response: 0.3, dampingRatio: 0.4))
            SpringKeyframe(0, duration: 0.35, spring: .init(response: 0.4, dampingRatio: 0.45))
            Rest.breathing(0, duration: 1.7, drift: 0.6)
        }
        KeyframeTrack(\.kusazuriFR) {
            CubicKeyframe(8.4, duration: 0.35)
            SpringKeyframe(0, duration: 0.2, spring: .init(response: 0.3, dampingRatio: 0.5))
            CubicKeyframe(-7, duration: 0.2)
            CubicKeyframe(9.8, duration: 0.2)
            SpringKeyframe(-4.2, duration: 0.2, spring: .init(response: 0.3, dampingRatio: 0.4))
            SpringKeyframe(0, duration: 0.35, spring: .init(response: 0.4, dampingRatio: 0.45))
            Rest.breathing(0, duration: 1.7, drift: 0.6)
        }
        KeyframeTrack(\.kusazuriR) {
            CubicKeyframe(12, duration: 0.35)
            SpringKeyframe(0, duration: 0.2, spring: .init(response: 0.3, dampingRatio: 0.5))
            CubicKeyframe(-10, duration: 0.2)
            CubicKeyframe(14, duration: 0.2)
            SpringKeyframe(-6, duration: 0.2, spring: .init(response: 0.3, dampingRatio: 0.4))
            SpringKeyframe(0, duration: 0.35, spring: .init(response: 0.4, dampingRatio: 0.45))
            Rest.breathing(0, duration: 1.7, drift: 0.6)
        }
        KeyframeTrack(\.sashTailL) {
            CubicKeyframe(-20, duration: 0.35)
            SpringKeyframe(0, duration: 0.2, spring: .init(response: 0.3, dampingRatio: 0.5))
            CubicKeyframe(-16, duration: 0.2)
            SpringKeyframe(24, duration: 0.2, spring: .init(response: 0.28, dampingRatio: 0.4))
            SpringKeyframe(-14, duration: 0.2, spring: .init(response: 0.3, dampingRatio: 0.38))
            SpringKeyframe(8, duration: 0.25, spring: .init(response: 0.3, dampingRatio: 0.4))
            SpringKeyframe(0, duration: 0.3, spring: .init(response: 0.4, dampingRatio: 0.45))
            Rest.moving(0, duration: 0.5, drift: 1.0)
            CubicKeyframe(-6, duration: 0.25, startVelocity: 0)
            LinearKeyframe(-6, duration: 0.25)
            CubicKeyframe(0, duration: 0.5, endVelocity: 0)
        }
        KeyframeTrack(\.sashTailR) {
            CubicKeyframe(20, duration: 0.35)
            SpringKeyframe(0, duration: 0.2, spring: .init(response: 0.3, dampingRatio: 0.5))
            CubicKeyframe(16, duration: 0.2)
            SpringKeyframe(-24, duration: 0.2, spring: .init(response: 0.28, dampingRatio: 0.4))
            SpringKeyframe(14, duration: 0.2, spring: .init(response: 0.3, dampingRatio: 0.38))
            SpringKeyframe(-8, duration: 0.25, spring: .init(response: 0.3, dampingRatio: 0.4))
            SpringKeyframe(0, duration: 0.3, spring: .init(response: 0.4, dampingRatio: 0.45))
            Rest.moving(0, duration: 0.5, drift: 1.0)
            CubicKeyframe(6, duration: 0.25, startVelocity: 0)
            LinearKeyframe(6, duration: 0.25)
            CubicKeyframe(0, duration: 0.5, endVelocity: 0)
        }
        KeyframeTrack(\.chestCord) {
            LinearKeyframe(0, duration: 0.75)
            CubicKeyframe(8, duration: 0.2)
            SpringKeyframe(-6, duration: 0.25, spring: .init(response: 0.3, dampingRatio: 0.4))
            SpringKeyframe(0, duration: 0.4, spring: .init(response: 0.4, dampingRatio: 0.5))
            Rest.breathing(0, duration: 1.6, drift: 0.6)
        }
        KeyframeTrack(\.scabbard) {
            LinearKeyframe(0, duration: 0.55)
            CubicKeyframe(5, duration: 0.2)
            CubicKeyframe(-6, duration: 0.2)
            SpringKeyframe(4, duration: 0.2, spring: .init(response: 0.3, dampingRatio: 0.4))
            SpringKeyframe(0, duration: 0.35, spring: .init(response: 0.4, dampingRatio: 0.45))
            Rest.breathing(0, duration: 1.7, drift: 0.5)
        }
        KeyframeTrack(\.eyeOpacity) {
            LinearKeyframe(1, duration: 0.52)
            LinearKeyframe(0, duration: 0.04)
            LinearKeyframe(0, duration: 2.64)
        }
        KeyframeTrack(\.fierceOpacity) {
            LinearKeyframe(1, duration: 0.52)
            LinearKeyframe(0, duration: 0.04)
            LinearKeyframe(0, duration: 2.64)
        }
        KeyframeTrack(\.triumphOpacity) {
            LinearKeyframe(0, duration: 0.52)
            LinearKeyframe(1, duration: 0.04)
            LinearKeyframe(1, duration: 2.64)
        }
        KeyframeTrack(\.kiai) {
            LinearKeyframe(0, duration: 0.9)
            LinearKeyframe(1, duration: 0.1)
            LinearKeyframe(1, duration: 1.15)
            LinearKeyframe(0, duration: 0.1)
            LinearKeyframe(0, duration: 0.95)
        }
    }
}

/// Holds that start and end at rest. `Hold.moving` leaves the incoming velocity to
/// the spline, which carries the previous move straight through the hold and
/// overshoots it; these pin both ends so a hold stays a hold.
private enum Rest {
    @KeyframeTrackContentBuilder<Double>
    static func moving(_ value: Double, duration: Double, drift: Double)
        -> some KeyframeTrackContent<Double> {
        CubicKeyframe(value + drift, duration: duration * 0.58, startVelocity: 0, endVelocity: 0)
        CubicKeyframe(value, duration: duration * 0.42, startVelocity: 0, endVelocity: 0)
    }

    @KeyframeTrackContentBuilder<Double>
    static func breathing(_ value: Double, duration: Double, drift: Double)
        -> some KeyframeTrackContent<Double> {
        CubicKeyframe(value + drift, duration: duration * 0.34, startVelocity: 0, endVelocity: 0)
        CubicKeyframe(value - drift * 0.55, duration: duration * 0.30, startVelocity: 0, endVelocity: 0)
        CubicKeyframe(value + drift * 0.35, duration: duration * 0.22, startVelocity: 0, endVelocity: 0)
        CubicKeyframe(value, duration: duration * 0.14, startVelocity: 0, endVelocity: 0)
    }
}
