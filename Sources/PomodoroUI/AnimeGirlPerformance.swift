import PomodoroCore
import SwiftUI

/// Power's three performances (the type keeps its old name).
///
/// Loud, arrogant, gremlin energy: snappy moves with clear holds. Her two long
/// back hair masses lag the body by two or three frames; the face swaps are fast
/// crossfades so two faces are never half-blended for long.
public enum AnimeGirlPerformance {

    public static func preferredEdge(for cue: CharacterCue) -> StageEdge { .top }

    public static func comesForward(for cue: CharacterCue) -> Bool {
        // The yawn rests her arms on the bar edge, so she has to stay behind it.
        // The shout leans over the bar and points down at you, so it comes forward.
        cue == .focusStart
    }

    public static func duration(for cue: CharacterCue) -> Double {
        switch cue {
        case .focusStart: 2.60
        case .breakStart: 3.00
        case .longBreak: 3.40
        }
    }

    // MARK: - focusStart · "Grovel, human!" (2.6s)

    /// Bursts up, leans over the bar and points down with a claw, shouting. Recoils,
    /// crosses her arms, smug. One foot tap, a hair flick, then she ducks out.
    @KeyframesBuilder<AnimeGirlPose>
    public static var fistPump: some Keyframes<AnimeGirlPose> {
        fistPumpPart1
        fistPumpPart2
        fistPumpPart3
        fistPumpPart4
    }

    /// fistPump: one group of tracks, split out to keep each builder small.
    @KeyframesBuilder<AnimeGirlPose>
    static var fistPumpPart1: some Keyframes<AnimeGirlPose> {
        KeyframeTrack(\.emergence) {
            CubicKeyframe(-8, duration: 0.22)
            CubicKeyframe(0, duration: 0.08)
            Hold.moving(0, duration: 0.15, drift: 0.8)
            CubicKeyframe(-5, duration: 0.14)
            CubicKeyframe(-3, duration: 0.16)
            Hold.moving(-4, duration: 0.35, drift: 1.0)
            CubicKeyframe(0, duration: 0.3)
            Hold.breathing(0, duration: 0.65, drift: 1.2)
            Hold.moving(0, duration: 0.25, drift: 0.8)
            CubicKeyframe(-3, duration: 0.05)
            CubicKeyframe(200, duration: 0.25)
        }
        KeyframeTrack(\.figureScale) {
            Hold.moving(1, duration: 0.3, drift: 0.01)
            CubicKeyframe(0.97, duration: 0.15)
            SpringKeyframe(1.17, duration: 0.3, spring: .init(response: 0.32, dampingRatio: 0.55))
            Hold.moving(1.17, duration: 0.35, drift: 0.012)
            CubicKeyframe(1.0, duration: 0.3)
            Hold.breathing(1.0, duration: 0.65, drift: 0.012)
            Hold.moving(1.0, duration: 0.25, drift: 0.01)
            CubicKeyframe(0.97, duration: 0.05)
            CubicKeyframe(1.0, duration: 0.25)
        }
        KeyframeTrack(\.figureLift) {
            Hold.moving(0, duration: 0.3, drift: 0.4)
            CubicKeyframe(-2, duration: 0.15)
            CubicKeyframe(5, duration: 0.3)
            Hold.moving(5, duration: 0.35, drift: 0.6)
            CubicKeyframe(0, duration: 0.3)
            Hold.moving(0, duration: 0.25, drift: 0.5)
            CubicKeyframe(2, duration: 0.06)
            CubicKeyframe(0, duration: 0.08)
            Hold.moving(0, duration: 0.26, drift: 0.5)
            Hold.moving(0, duration: 0.25, drift: 0.5)
            Hold.moving(0, duration: 0.3, drift: 0.4)
        }
        KeyframeTrack(\.torso) {
            Hold.moving(0, duration: 0.3, drift: 0.8)
            CubicKeyframe(-4, duration: 0.15)
            CubicKeyframe(3, duration: 0.3)
            Hold.breathing(3, duration: 0.35, drift: 0.8)
            CubicKeyframe(-2, duration: 0.15)
            SpringKeyframe(0, duration: 0.15, spring: .init(response: 0.32, dampingRatio: 0.55))
            Hold.breathing(0, duration: 0.65, drift: 1.0)
            CubicKeyframe(-3, duration: 0.25)
            CubicKeyframe(0, duration: 0.3)
        }
        KeyframeTrack(\.hips) {
            Hold.moving(0, duration: 0.3, drift: 0.6)
            CubicKeyframe(1.5, duration: 0.15)
            CubicKeyframe(-2, duration: 0.3)
            Hold.moving(-2, duration: 0.35, drift: 0.6)
            SpringKeyframe(0, duration: 0.3, spring: .init(response: 0.32, dampingRatio: 0.55))
            Hold.breathing(0, duration: 0.65, drift: 0.8)
            Hold.moving(0, duration: 0.25, drift: 0.6)
            Hold.moving(0, duration: 0.3, drift: 0.5)
        }
        KeyframeTrack(\.head) {
            Hold.moving(0, duration: 0.3, drift: 1.0)
            CubicKeyframe(3, duration: 0.15)
            CubicKeyframe(-4, duration: 0.3)
            Hold.moving(-4, duration: 0.35, drift: 1.0)
            CubicKeyframe(-8, duration: 0.3)
            Hold.breathing(-8, duration: 0.65, drift: 1.0)
            CubicKeyframe(9, duration: 0.25)
            CubicKeyframe(0, duration: 0.3)
        }
    }

    /// fistPump: one group of tracks, split out to keep each builder small.
    @KeyframesBuilder<AnimeGirlPose>
    static var fistPumpPart2: some Keyframes<AnimeGirlPose> {
        // Face drops toward you on the point, the lean the front view cannot rotate.
        KeyframeTrack(\.eyesLift) {
            LinearKeyframe(0, duration: 0.3)
            CubicKeyframe(3, duration: 0.3)
            Hold.moving(3, duration: 0.5, drift: 0.3)
            CubicKeyframe(-1.5, duration: 0.3)
            LinearKeyframe(-1.5, duration: 0.95)
            CubicKeyframe(0, duration: 0.25)
        }
        // Face and hand swaps are steps (one 0.01s switch), never a blend.
        KeyframeTrack(\.shoutOpacity) {
            LinearKeyframe(0, duration: 0.45)
            LinearKeyframe(1, duration: 0.01)
            LinearKeyframe(1, duration: 0.64)
            LinearKeyframe(0, duration: 0.01)
            LinearKeyframe(0, duration: 1.49)
        }
        KeyframeTrack(\.smugOpacity) {
            LinearKeyframe(0, duration: 1.1)
            LinearKeyframe(1, duration: 0.01)
            LinearKeyframe(1, duration: 1.49)
        }
        KeyframeTrack(\.armR) {
            Hold.moving(0, duration: 0.3, drift: 1.0)
            CubicKeyframe(10, duration: 0.15)
            CubicKeyframe(-26, duration: 0.3)
            Hold.moving(-26, duration: 0.35, drift: 1.5)
            CubicKeyframe(-22, duration: 0.3)
            Hold.breathing(-22, duration: 0.65, drift: 1.5)
            CubicKeyframe(-78, duration: 0.25)
            CubicKeyframe(0, duration: 0.3)
        }
        KeyframeTrack(\.armR_fore) {
            Hold.moving(0, duration: 0.45, drift: 0.8)
            CubicKeyframe(84, duration: 0.3)
            Hold.moving(84, duration: 0.35, drift: 2.0)
            CubicKeyframe(108, duration: 0.3)
            Hold.breathing(108, duration: 0.65, drift: 1.5)
            CubicKeyframe(-125, duration: 0.25)
            CubicKeyframe(0, duration: 0.3)
        }
        KeyframeTrack(\.armL) {
            Hold.moving(0, duration: 0.3, drift: 0.8)
            CubicKeyframe(12, duration: 0.15)
            CubicKeyframe(36, duration: 0.3)
            Hold.breathing(36, duration: 0.35, drift: 1.2)
            CubicKeyframe(22, duration: 0.3)
            Hold.breathing(22, duration: 0.65, drift: 1.2)
            Hold.moving(22, duration: 0.25, drift: 1.0)
            CubicKeyframe(0, duration: 0.3)
        }
    }

    /// fistPump: one group of tracks, split out to keep each builder small.
    @KeyframesBuilder<AnimeGirlPose>
    static var fistPumpPart3: some Keyframes<AnimeGirlPose> {
        KeyframeTrack(\.armL_fore) {
            Hold.moving(0, duration: 0.45, drift: 0.8)
            CubicKeyframe(-58, duration: 0.3)
            Hold.moving(-58, duration: 0.35, drift: 2.0)
            CubicKeyframe(-108, duration: 0.3)
            Hold.breathing(-108, duration: 0.65, drift: 1.5)
            Hold.moving(-108, duration: 0.25, drift: 1.5)
            CubicKeyframe(0, duration: 0.3)
        }
        KeyframeTrack(\.clawR) {
            LinearKeyframe(0, duration: 0.45)
            LinearKeyframe(1, duration: 0.01)
            LinearKeyframe(1, duration: 0.64)
            LinearKeyframe(0, duration: 0.01)
            LinearKeyframe(0, duration: 1.49)
        }
        KeyframeTrack(\.tailL_base) {
            CubicKeyframe(4.5, duration: 0.3)
            CubicKeyframe(1.8, duration: 0.15)
            SpringKeyframe(7.2, duration: 0.4, spring: .init(response: 0.40, dampingRatio: 0.40))
            CubicKeyframe(3.6, duration: 0.25)
            CubicKeyframe(-2.7, duration: 0.3)
            SpringKeyframe(0.0, duration: 0.3, spring: .init(response: 0.32, dampingRatio: 0.55))
            Hold.moving(0.0, duration: 0.35, drift: 0.68)
            CubicKeyframe(4.5, duration: 0.25)
            SpringKeyframe(0.0, duration: 0.3, spring: .init(response: 0.40, dampingRatio: 0.40))
        }
        KeyframeTrack(\.tailR_base) {
            CubicKeyframe(-4.5, duration: 0.3)
            CubicKeyframe(-1.8, duration: 0.15)
            SpringKeyframe(-7.2, duration: 0.4, spring: .init(response: 0.40, dampingRatio: 0.40))
            CubicKeyframe(-3.6, duration: 0.25)
            CubicKeyframe(2.7, duration: 0.3)
            SpringKeyframe(0.0, duration: 0.3, spring: .init(response: 0.32, dampingRatio: 0.55))
            Hold.moving(0.0, duration: 0.35, drift: -0.68)
            CubicKeyframe(-4.5, duration: 0.25)
            SpringKeyframe(0.0, duration: 0.3, spring: .init(response: 0.40, dampingRatio: 0.40))
        }
        KeyframeTrack(\.tailL_tip) {
            CubicKeyframe(5.4, duration: 0.37)
            CubicKeyframe(2.25, duration: 0.15)
            SpringKeyframe(9.9, duration: 0.4, spring: .init(response: 0.40, dampingRatio: 0.40))
            CubicKeyframe(4.5, duration: 0.25)
            CubicKeyframe(-4.05, duration: 0.3)
            SpringKeyframe(0.0, duration: 0.3, spring: .init(response: 0.40, dampingRatio: 0.40))
            Hold.moving(0.0, duration: 0.35, drift: 0.9)
            CubicKeyframe(6.3, duration: 0.25)
            SpringKeyframe(0.0, duration: 0.23, spring: .init(response: 0.40, dampingRatio: 0.40))
        }
        KeyframeTrack(\.tailR_tip) {
            CubicKeyframe(-5.4, duration: 0.37)
            CubicKeyframe(-2.25, duration: 0.15)
            SpringKeyframe(-9.9, duration: 0.4, spring: .init(response: 0.40, dampingRatio: 0.40))
            CubicKeyframe(-4.5, duration: 0.25)
            CubicKeyframe(4.05, duration: 0.3)
            SpringKeyframe(0.0, duration: 0.3, spring: .init(response: 0.40, dampingRatio: 0.40))
            Hold.moving(0.0, duration: 0.35, drift: -0.9)
            CubicKeyframe(-6.3, duration: 0.25)
            SpringKeyframe(0.0, duration: 0.23, spring: .init(response: 0.40, dampingRatio: 0.40))
        }
    }

    /// fistPump: one group of tracks, split out to keep each builder small.
    @KeyframesBuilder<AnimeGirlPose>
    static var fistPumpPart4: some Keyframes<AnimeGirlPose> {
        KeyframeTrack(\.ahoge) {
            CubicKeyframe(-3.6, duration: 0.4)
            SpringKeyframe(4.5, duration: 0.5, spring: .init(response: 0.40, dampingRatio: 0.40))
            CubicKeyframe(-2.7, duration: 0.3)
            SpringKeyframe(0.0, duration: 0.5, spring: .init(response: 0.40, dampingRatio: 0.40))
            Hold.moving(0.0, duration: 0.55, drift: 0.68)
            SpringKeyframe(3.6, duration: 0.35, spring: .init(response: 0.40, dampingRatio: 0.40))
        }
        KeyframeTrack(\.legR) {
            Hold.moving(0, duration: 1.6, drift: 0.8)
            CubicKeyframe(-5, duration: 0.07)
            CubicKeyframe(0, duration: 0.08)
            Hold.moving(0, duration: 0.85, drift: 0.8)
        }
        KeyframeTrack(\.shinR) {
            Hold.moving(0, duration: 1.6, drift: 0.8)
            CubicKeyframe(4, duration: 0.07)
            CubicKeyframe(0, duration: 0.08)
            Hold.moving(0, duration: 0.85, drift: 0.8)
        }
    }

    // MARK: - breakStart · "Big yawn" (3.0s)

    /// A slow rise into a huge stretching yawn on tiptoe, then she flops onto the bar
    /// edge, folds her arms and rests her chin on them, eyes closed, and slides out.
    @KeyframesBuilder<AnimeGirlPose>
    public static var perchWave: some Keyframes<AnimeGirlPose> {
        perchWavePart1
        perchWavePart2
        perchWavePart3
        perchWavePart4
    }

    /// perchWave: one group of tracks, split out to keep each builder small.
    @KeyframesBuilder<AnimeGirlPose>
    static var perchWavePart1: some Keyframes<AnimeGirlPose> {
        KeyframeTrack(\.emergence) {
            CubicKeyframe(0, duration: 0.45)
            CubicKeyframe(-6, duration: 0.3)
            Hold.moving(-6, duration: 0.35, drift: 1.0)
            SpringKeyframe(20, duration: 0.3, spring: .init(response: 0.32, dampingRatio: 0.6))
            Hold.breathing(20, duration: 1.0, drift: 1.2)
            CubicKeyframe(16, duration: 0.08)
            CubicKeyframe(200, duration: 0.52)
        }
        KeyframeTrack(\.figureScaleY) {
            Hold.moving(1, duration: 0.45, drift: 0.01)
            CubicKeyframe(1.05, duration: 0.3)
            Hold.moving(1.05, duration: 0.35, drift: 0.008)
            SpringKeyframe(0.9, duration: 0.3, spring: .init(response: 0.32, dampingRatio: 0.55))
            Hold.breathing(0.9, duration: 1.0, drift: 0.015)
            Hold.moving(0.9, duration: 0.6, drift: 0.01)
        }
        KeyframeTrack(\.figureLift) {
            Hold.moving(0, duration: 0.45, drift: 0.4)
            CubicKeyframe(-5, duration: 0.3)
            Hold.moving(-5, duration: 0.35, drift: 0.5)
            CubicKeyframe(2, duration: 0.3)
            Hold.breathing(2, duration: 1.0, drift: 0.6)
            CubicKeyframe(0, duration: 0.6)
        }
        KeyframeTrack(\.torso) {
            Hold.moving(0, duration: 0.45, drift: 0.8)
            CubicKeyframe(-2, duration: 0.3)
            Hold.breathing(-2, duration: 0.35, drift: 1.0)
            CubicKeyframe(0, duration: 0.3)
            Hold.breathing(0, duration: 1.0, drift: 0.8)
            CubicKeyframe(0, duration: 0.6)
        }
        KeyframeTrack(\.hips) {
            Hold.moving(0, duration: 0.45, drift: 0.6)
            CubicKeyframe(-1.5, duration: 0.3)
            Hold.moving(-1.5, duration: 0.35, drift: 0.6)
            CubicKeyframe(2, duration: 0.3)
            Hold.breathing(2, duration: 1.0, drift: 0.5)
            CubicKeyframe(0, duration: 0.6)
        }
        KeyframeTrack(\.head) {
            CubicKeyframe(5, duration: 0.45)
            CubicKeyframe(-12, duration: 0.3)
            Hold.moving(-12, duration: 0.35, drift: 1.5)
            CubicKeyframe(10, duration: 0.3)
            Hold.breathing(10, duration: 1.0, drift: 1.0)
            CubicKeyframe(8, duration: 0.3)
            Hold.moving(8, duration: 0.3, drift: 0.8)
        }
    }

    /// perchWave: one group of tracks, split out to keep each builder small.
    @KeyframesBuilder<AnimeGirlPose>
    static var perchWavePart2: some Keyframes<AnimeGirlPose> {
        // Steps again: the yawn face on when the arms go up, doze when they come down.
        KeyframeTrack(\.dozeOpacity) {
            LinearKeyframe(1, duration: 0.45)
            LinearKeyframe(0, duration: 0.01)
            LinearKeyframe(0, duration: 0.64)
            LinearKeyframe(1, duration: 0.01)
            LinearKeyframe(1, duration: 1.89)
        }
        KeyframeTrack(\.yawnOpacity) {
            LinearKeyframe(0, duration: 0.45)
            LinearKeyframe(1, duration: 0.01)
            LinearKeyframe(1, duration: 0.64)
            LinearKeyframe(0, duration: 0.01)
            LinearKeyframe(0, duration: 1.89)
        }
        KeyframeTrack(\.clawL) {
            LinearKeyframe(0, duration: 0.57)
            LinearKeyframe(1, duration: 0.01)
            LinearKeyframe(1, duration: 0.55)
            LinearKeyframe(0, duration: 0.01)
            LinearKeyframe(0, duration: 1.86)
        }
        KeyframeTrack(\.clawR) {
            LinearKeyframe(0, duration: 0.57)
            LinearKeyframe(1, duration: 0.01)
            LinearKeyframe(1, duration: 0.55)
            LinearKeyframe(0, duration: 0.01)
            LinearKeyframe(0, duration: 1.86)
        }
        KeyframeTrack(\.armL) {
            Hold.moving(0, duration: 0.45, drift: 1.0)
            CubicKeyframe(-8, duration: 0.12)
            CubicKeyframe(158, duration: 0.28)
            Hold.moving(158, duration: 0.25, drift: -3.0)
            CubicKeyframe(52, duration: 0.3)
            Hold.breathing(52, duration: 1.0, drift: 1.0)
            Hold.moving(52, duration: 0.6, drift: 1.0)
        }
        KeyframeTrack(\.armL_fore) {
            Hold.moving(0, duration: 0.45, drift: 0.8)
            CubicKeyframe(4, duration: 0.12)
            CubicKeyframe(14, duration: 0.28)
            Hold.moving(14, duration: 0.25, drift: 2.0)
            CubicKeyframe(-142, duration: 0.3)
            Hold.breathing(-142, duration: 1.0, drift: 1.5)
            Hold.moving(-142, duration: 0.6, drift: 1.0)
        }
    }

    /// perchWave: one group of tracks, split out to keep each builder small.
    @KeyframesBuilder<AnimeGirlPose>
    static var perchWavePart3: some Keyframes<AnimeGirlPose> {
        KeyframeTrack(\.armR) {
            Hold.moving(0, duration: 0.45, drift: -1.0)
            CubicKeyframe(8, duration: 0.12)
            CubicKeyframe(-158, duration: 0.28)
            Hold.moving(-158, duration: 0.25, drift: 3.0)
            CubicKeyframe(-52, duration: 0.3)
            Hold.breathing(-52, duration: 1.0, drift: -1.0)
            Hold.moving(-52, duration: 0.6, drift: -1.0)
        }
        KeyframeTrack(\.armR_fore) {
            Hold.moving(0, duration: 0.45, drift: -0.8)
            CubicKeyframe(-4, duration: 0.12)
            CubicKeyframe(-14, duration: 0.28)
            Hold.moving(-14, duration: 0.25, drift: -2.0)
            CubicKeyframe(142, duration: 0.3)
            Hold.breathing(142, duration: 1.0, drift: -1.5)
            Hold.moving(142, duration: 0.6, drift: -1.0)
        }
        KeyframeTrack(\.tailL_base) {
            Hold.moving(0.0, duration: 1.1, drift: 0.68)
            SpringKeyframe(5.4, duration: 0.3, spring: .init(response: 0.32, dampingRatio: 0.55))
            SpringKeyframe(-1.8, duration: 0.4, spring: .init(response: 0.32, dampingRatio: 0.55))
            Hold.moving(-1.8, duration: 0.6, drift: 0.54)
            CubicKeyframe(0.0, duration: 0.6)
        }
        KeyframeTrack(\.tailR_base) {
            Hold.moving(0.0, duration: 1.1, drift: -0.68)
            SpringKeyframe(-5.4, duration: 0.3, spring: .init(response: 0.32, dampingRatio: 0.55))
            SpringKeyframe(1.8, duration: 0.4, spring: .init(response: 0.32, dampingRatio: 0.55))
            Hold.moving(1.8, duration: 0.6, drift: -0.54)
            CubicKeyframe(0.0, duration: 0.6)
        }
        KeyframeTrack(\.tailL_tip) {
            Hold.moving(0.0, duration: 1.17, drift: 0.9)
            SpringKeyframe(7.2, duration: 0.3, spring: .init(response: 0.40, dampingRatio: 0.40))
            SpringKeyframe(-2.7, duration: 0.45, spring: .init(response: 0.40, dampingRatio: 0.40))
            Hold.moving(-2.7, duration: 0.48, drift: 0.45)
            CubicKeyframe(0.0, duration: 0.6)
        }
        KeyframeTrack(\.tailR_tip) {
            Hold.moving(0.0, duration: 1.17, drift: -0.9)
            SpringKeyframe(-7.2, duration: 0.3, spring: .init(response: 0.40, dampingRatio: 0.40))
            SpringKeyframe(2.7, duration: 0.45, spring: .init(response: 0.40, dampingRatio: 0.40))
            Hold.moving(2.7, duration: 0.48, drift: -0.45)
            CubicKeyframe(0.0, duration: 0.6)
        }
    }

    /// perchWave: one group of tracks, split out to keep each builder small.
    @KeyframesBuilder<AnimeGirlPose>
    static var perchWavePart4: some Keyframes<AnimeGirlPose> {
        KeyframeTrack(\.legL) {
            Hold.moving(0, duration: 0.45, drift: 0.5)
            CubicKeyframe(3, duration: 0.3)
            Hold.moving(3, duration: 0.35, drift: 0.5)
            CubicKeyframe(0, duration: 0.3)
            Hold.moving(0, duration: 1.6, drift: 0.5)
        }
        KeyframeTrack(\.legR) {
            Hold.moving(0, duration: 0.45, drift: -0.5)
            CubicKeyframe(-3, duration: 0.3)
            Hold.moving(-3, duration: 0.35, drift: -0.5)
            CubicKeyframe(0, duration: 0.3)
            Hold.moving(0, duration: 1.6, drift: -0.5)
        }
        KeyframeTrack(\.ahoge) {
            Hold.moving(0.0, duration: 0.45, drift: 0.68)
            CubicKeyframe(2.7, duration: 0.65)
            SpringKeyframe(-4.5, duration: 0.4, spring: .init(response: 0.40, dampingRatio: 0.40))
            Hold.moving(-4.5, duration: 0.9, drift: 0.68)
            CubicKeyframe(0.0, duration: 0.6)
        }
    }

    // MARK: - longBreak · "Hey hey hey!" (3.4s)

    /// Crouch, jump with both fists up, land in a wide stance and hit her signature
    /// pose: one claw high beside her face, one low, head back, laughing.
    @KeyframesBuilder<AnimeGirlPose>
    public static var twirl: some Keyframes<AnimeGirlPose> {
        twirlPart1
        twirlPart2
        twirlPart3
        twirlPart4
        twirlPart5
    }

    /// twirl: one group of tracks, split out to keep each builder small.
    @KeyframesBuilder<AnimeGirlPose>
    static var twirlPart1: some Keyframes<AnimeGirlPose> {
        KeyframeTrack(\.emergence) {
            CubicKeyframe(-6, duration: 0.3)
            CubicKeyframe(0, duration: 0.1)
            CubicKeyframe(9, duration: 0.2)
            CubicKeyframe(0, duration: 0.15)
            Hold.moving(0, duration: 0.3, drift: 0.5)
            CubicKeyframe(5, duration: 0.08)
            SpringKeyframe(0, duration: 0.12, spring: .init(response: 0.32, dampingRatio: 0.55))
            Hold.moving(0, duration: 0.3, drift: 0.8)
            Hold.breathing(0, duration: 0.85, drift: 1.0)
            Hold.moving(0, duration: 0.4, drift: 0.8)
            CubicKeyframe(-3, duration: 0.1)
            CubicKeyframe(200, duration: 0.5)
        }
        KeyframeTrack(\.figureScaleY) {
            Hold.moving(1, duration: 0.4, drift: 0.01)
            CubicKeyframe(0.9, duration: 0.2)
            CubicKeyframe(1.05, duration: 0.12)
            Hold.moving(1.03, duration: 0.33, drift: 0.01)
            CubicKeyframe(0.92, duration: 0.08)
            SpringKeyframe(1.0, duration: 0.12, spring: .init(response: 0.32, dampingRatio: 0.55))
            Hold.moving(1.0, duration: 0.3, drift: 0.01)
            Hold.breathing(1.0, duration: 0.85, drift: 0.012)
            Hold.moving(1.0, duration: 0.4, drift: 0.01)
            CubicKeyframe(0.97, duration: 0.1)
            CubicKeyframe(1.0, duration: 0.5)
        }
        KeyframeTrack(\.figureLift) {
            Hold.moving(0, duration: 0.4, drift: 0.4)
            CubicKeyframe(2, duration: 0.2)
            CubicKeyframe(-28, duration: 0.22)
            CubicKeyframe(0, duration: 0.23)
            CubicKeyframe(2, duration: 0.08)
            SpringKeyframe(0, duration: 0.12, spring: .init(response: 0.32, dampingRatio: 0.55))
            Hold.moving(0, duration: 0.3, drift: 0.5)
            CubicKeyframe(-2, duration: 0.1)
            CubicKeyframe(1, duration: 0.1)
            CubicKeyframe(-1, duration: 0.1)
            CubicKeyframe(0, duration: 0.1)
            Hold.moving(0, duration: 0.45, drift: 0.5)
            Hold.moving(0, duration: 0.4, drift: 0.5)
            CubicKeyframe(1, duration: 0.1)
            CubicKeyframe(0, duration: 0.5)
        }
        KeyframeTrack(\.legL) {
            Hold.moving(0, duration: 0.4, drift: 0.8)
            CubicKeyframe(18, duration: 0.2)
            CubicKeyframe(4, duration: 0.22)
            CubicKeyframe(6, duration: 0.23)
            CubicKeyframe(18, duration: 0.08)
            SpringKeyframe(14, duration: 0.12, spring: .init(response: 0.32, dampingRatio: 0.55))
            Hold.moving(14, duration: 0.3, drift: 1.0)
            Hold.breathing(14, duration: 0.85, drift: 1.0)
            CubicKeyframe(2, duration: 0.4)
            CubicKeyframe(0, duration: 0.6)
        }
        KeyframeTrack(\.legR) {
            Hold.moving(0, duration: 0.4, drift: -0.8)
            CubicKeyframe(-18, duration: 0.2)
            CubicKeyframe(-4, duration: 0.22)
            CubicKeyframe(-6, duration: 0.23)
            CubicKeyframe(-18, duration: 0.08)
            SpringKeyframe(-14, duration: 0.12, spring: .init(response: 0.32, dampingRatio: 0.55))
            Hold.moving(-14, duration: 0.3, drift: -1.0)
            Hold.breathing(-14, duration: 0.85, drift: -1.0)
            CubicKeyframe(-2, duration: 0.4)
            CubicKeyframe(0, duration: 0.6)
        }
        KeyframeTrack(\.shinL) {
            Hold.moving(0, duration: 0.4, drift: 0.5)
            CubicKeyframe(-24, duration: 0.2)
            CubicKeyframe(-8, duration: 0.22)
            CubicKeyframe(-4, duration: 0.23)
            CubicKeyframe(-18, duration: 0.08)
            SpringKeyframe(-14, duration: 0.12, spring: .init(response: 0.32, dampingRatio: 0.55))
            Hold.moving(-14, duration: 0.3, drift: 1.0)
            Hold.breathing(-14, duration: 0.85, drift: 1.0)
            CubicKeyframe(-2, duration: 0.4)
            CubicKeyframe(0, duration: 0.6)
        }
    }

    /// twirl: one group of tracks, split out to keep each builder small.
    @KeyframesBuilder<AnimeGirlPose>
    static var twirlPart2: some Keyframes<AnimeGirlPose> {
        KeyframeTrack(\.shinR) {
            Hold.moving(0, duration: 0.4, drift: -0.5)
            CubicKeyframe(24, duration: 0.2)
            CubicKeyframe(8, duration: 0.22)
            CubicKeyframe(4, duration: 0.23)
            CubicKeyframe(18, duration: 0.08)
            SpringKeyframe(14, duration: 0.12, spring: .init(response: 0.32, dampingRatio: 0.55))
            Hold.moving(14, duration: 0.3, drift: -1.0)
            Hold.breathing(14, duration: 0.85, drift: -1.0)
            CubicKeyframe(2, duration: 0.4)
            CubicKeyframe(0, duration: 0.6)
        }
        KeyframeTrack(\.hips) {
            Hold.moving(0, duration: 0.4, drift: 0.6)
            CubicKeyframe(-2.5, duration: 0.2)
            CubicKeyframe(2, duration: 0.22)
            CubicKeyframe(-1, duration: 0.23)
            CubicKeyframe(-3, duration: 0.08)
            SpringKeyframe(0, duration: 0.12, spring: .init(response: 0.32, dampingRatio: 0.55))
            Hold.moving(0, duration: 0.3, drift: 1.0)
            Hold.breathing(0, duration: 0.85, drift: 1.2)
            Hold.moving(0, duration: 0.4, drift: 0.8)
            Hold.moving(0, duration: 0.6, drift: 0.6)
        }
        KeyframeTrack(\.torso) {
            Hold.moving(0, duration: 0.4, drift: 0.8)
            CubicKeyframe(3, duration: 0.2)
            CubicKeyframe(-4, duration: 0.2)
            CubicKeyframe(2, duration: 0.25)
            CubicKeyframe(6, duration: 0.2)
            Hold.moving(6, duration: 0.3, drift: 1.0)
            Hold.breathing(6, duration: 0.85, drift: 1.2)
            CubicKeyframe(-2, duration: 0.4)
            CubicKeyframe(0, duration: 0.6)
        }
        KeyframeTrack(\.head) {
            Hold.moving(0, duration: 0.4, drift: 1.0)
            CubicKeyframe(3, duration: 0.2)
            CubicKeyframe(-8, duration: 0.45)
            CubicKeyframe(-12, duration: 0.2)
            Hold.moving(-12, duration: 0.3, drift: 1.5)
            CubicKeyframe(-16, duration: 0.16)
            CubicKeyframe(-11, duration: 0.16)
            CubicKeyframe(-14, duration: 0.14)
            CubicKeyframe(-12, duration: 0.14)
            Hold.moving(-12, duration: 0.25, drift: 1.2)
            CubicKeyframe(5, duration: 0.4)
            CubicKeyframe(0, duration: 0.3)
            Hold.moving(0, duration: 0.3, drift: 0.8)
        }
        KeyframeTrack(\.shoutOpacity) {
            LinearKeyframe(0, duration: 0.6)
            LinearKeyframe(1, duration: 0.01)
            LinearKeyframe(1, duration: 0.64)
            LinearKeyframe(0, duration: 0.01)
            LinearKeyframe(0, duration: 2.14)
        }
        KeyframeTrack(\.laughOpacity) {
            LinearKeyframe(0, duration: 1.25)
            LinearKeyframe(1, duration: 0.01)
            LinearKeyframe(1, duration: 1.14)
            LinearKeyframe(0, duration: 0.01)
            LinearKeyframe(0, duration: 0.99)
        }
    }

    /// twirl: one group of tracks, split out to keep each builder small.
    @KeyframesBuilder<AnimeGirlPose>
    static var twirlPart3: some Keyframes<AnimeGirlPose> {
        KeyframeTrack(\.smugOpacity) {
            LinearKeyframe(0, duration: 2.4)
            LinearKeyframe(1, duration: 0.01)
            LinearKeyframe(1, duration: 0.99)
        }
        // Fists on the crouch pull (0.40) and off as the jump peaks (1.05).
        KeyframeTrack(\.fistL) {
            LinearKeyframe(0, duration: 0.4)
            LinearKeyframe(1, duration: 0.01)
            LinearKeyframe(1, duration: 0.64)
            LinearKeyframe(0, duration: 0.01)
            LinearKeyframe(0, duration: 2.34)
        }
        KeyframeTrack(\.fist) {
            LinearKeyframe(0, duration: 0.4)
            LinearKeyframe(1, duration: 0.01)
            LinearKeyframe(1, duration: 0.64)
            LinearKeyframe(0, duration: 0.01)
            LinearKeyframe(0, duration: 2.34)
        }
        // Claws on as the arms release into the pose (1.05); right claw flexes once.
        KeyframeTrack(\.clawL) {
            LinearKeyframe(0, duration: 1.05)
            LinearKeyframe(1, duration: 0.01)
            LinearKeyframe(1, duration: 1.39)
            LinearKeyframe(0, duration: 0.01)
            LinearKeyframe(0, duration: 0.94)
        }
        KeyframeTrack(\.clawR) {
            LinearKeyframe(0, duration: 1.05)
            LinearKeyframe(1, duration: 0.01)
            LinearKeyframe(1, duration: 0.54)
            LinearKeyframe(0, duration: 0.01)
            LinearKeyframe(0, duration: 0.12)
            LinearKeyframe(1, duration: 0.01)
            LinearKeyframe(1, duration: 0.71)
            LinearKeyframe(0, duration: 0.01)
            LinearKeyframe(0, duration: 0.94)
        }
        KeyframeTrack(\.armL) {
            Hold.moving(0, duration: 0.4, drift: 1.0)
            CubicKeyframe(10, duration: 0.2)
            CubicKeyframe(150, duration: 0.22)
            Hold.moving(150, duration: 0.23, drift: 3.0)
            SpringKeyframe(48, duration: 0.2, spring: .init(response: 0.32, dampingRatio: 0.55))
            Hold.moving(48, duration: 0.3, drift: 2.0)
            Hold.breathing(48, duration: 0.85, drift: 2.0)
            CubicKeyframe(14, duration: 0.4)
            CubicKeyframe(0, duration: 0.6)
        }
    }

    /// twirl: one group of tracks, split out to keep each builder small.
    @KeyframesBuilder<AnimeGirlPose>
    static var twirlPart4: some Keyframes<AnimeGirlPose> {
        KeyframeTrack(\.armL_fore) {
            Hold.moving(0, duration: 0.4, drift: 1.0)
            CubicKeyframe(-35, duration: 0.2)
            CubicKeyframe(14, duration: 0.22)
            Hold.moving(14, duration: 0.23, drift: 2.5)
            CubicKeyframe(10, duration: 0.2)
            Hold.moving(10, duration: 0.3, drift: 1.5)
            Hold.breathing(10, duration: 0.85, drift: 2.0)
            CubicKeyframe(-6, duration: 0.4)
            CubicKeyframe(0, duration: 0.6)
        }
        KeyframeTrack(\.armR) {
            Hold.moving(0, duration: 0.4, drift: 1.0)
            CubicKeyframe(-8, duration: 0.2)
            CubicKeyframe(-150, duration: 0.22)
            Hold.moving(-150, duration: 0.23, drift: 3.0)
            SpringKeyframe(-145, duration: 0.2, spring: .init(response: 0.32, dampingRatio: 0.55))
            Hold.moving(-145, duration: 0.3, drift: 2.0)
            Hold.breathing(-145, duration: 0.85, drift: 2.5)
            CubicKeyframe(-78, duration: 0.4)
            CubicKeyframe(0, duration: 0.6)
        }
        KeyframeTrack(\.armR_fore) {
            Hold.moving(0, duration: 0.4, drift: 1.0)
            CubicKeyframe(35, duration: 0.2)
            CubicKeyframe(-14, duration: 0.22)
            Hold.moving(-14, duration: 0.23, drift: 2.5)
            CubicKeyframe(-18, duration: 0.2)
            Hold.moving(-18, duration: 0.3, drift: 1.5)
            Hold.breathing(-18, duration: 0.85, drift: 2.0)
            CubicKeyframe(-125, duration: 0.4)
            CubicKeyframe(0, duration: 0.6)
        }
        KeyframeTrack(\.tailL_base) {
            Hold.moving(0.0, duration: 0.4, drift: 0.68)
            CubicKeyframe(-2.7, duration: 0.2)
            CubicKeyframe(7.2, duration: 0.25)
            Hold.moving(7.2, duration: 0.2, drift: 0.9)
            CubicKeyframe(-5.4, duration: 0.1)
            SpringKeyframe(1.8, duration: 0.1, spring: .init(response: 0.40, dampingRatio: 0.40))
            SpringKeyframe(-1.35, duration: 0.3, spring: .init(response: 0.40, dampingRatio: 0.40))
            Hold.breathing(-1.35, duration: 0.85, drift: 0.9)
            CubicKeyframe(5.4, duration: 0.2)
            SpringKeyframe(0.0, duration: 0.2, spring: .init(response: 0.40, dampingRatio: 0.40))
            Hold.moving(0.0, duration: 0.6, drift: 0.68)
        }
        KeyframeTrack(\.tailR_base) {
            Hold.moving(0.0, duration: 0.4, drift: -0.68)
            CubicKeyframe(2.7, duration: 0.2)
            CubicKeyframe(-7.2, duration: 0.25)
            Hold.moving(-7.2, duration: 0.2, drift: -0.9)
            CubicKeyframe(5.4, duration: 0.1)
            SpringKeyframe(-1.8, duration: 0.1, spring: .init(response: 0.40, dampingRatio: 0.40))
            SpringKeyframe(1.35, duration: 0.3, spring: .init(response: 0.40, dampingRatio: 0.40))
            Hold.breathing(1.35, duration: 0.85, drift: -0.9)
            CubicKeyframe(-5.4, duration: 0.2)
            SpringKeyframe(0.0, duration: 0.2, spring: .init(response: 0.40, dampingRatio: 0.40))
            Hold.moving(0.0, duration: 0.6, drift: -0.68)
        }
        KeyframeTrack(\.tailL_tip) {
            Hold.moving(0.0, duration: 0.48, drift: 0.68)
            CubicKeyframe(-3.6, duration: 0.2)
            CubicKeyframe(11.7, duration: 0.28)
            CubicKeyframe(9.9, duration: 0.17)
            CubicKeyframe(-8.1, duration: 0.12)
            SpringKeyframe(2.7, duration: 0.18, spring: .init(response: 0.40, dampingRatio: 0.40))
            SpringKeyframe(-1.35, duration: 0.22, spring: .init(response: 0.40, dampingRatio: 0.40))
            Hold.breathing(-1.35, duration: 0.75, drift: 0.9)
            CubicKeyframe(7.2, duration: 0.24)
            SpringKeyframe(0.0, duration: 0.2, spring: .init(response: 0.40, dampingRatio: 0.40))
            Hold.moving(0.0, duration: 0.56, drift: 0.68)
        }
    }

    /// twirl: one group of tracks, split out to keep each builder small.
    @KeyframesBuilder<AnimeGirlPose>
    static var twirlPart5: some Keyframes<AnimeGirlPose> {
        KeyframeTrack(\.tailR_tip) {
            Hold.moving(0.0, duration: 0.48, drift: -0.68)
            CubicKeyframe(3.6, duration: 0.2)
            CubicKeyframe(-11.7, duration: 0.28)
            CubicKeyframe(-9.9, duration: 0.17)
            CubicKeyframe(8.1, duration: 0.12)
            SpringKeyframe(-2.7, duration: 0.18, spring: .init(response: 0.40, dampingRatio: 0.40))
            SpringKeyframe(1.35, duration: 0.22, spring: .init(response: 0.40, dampingRatio: 0.40))
            Hold.breathing(1.35, duration: 0.75, drift: -0.9)
            CubicKeyframe(-7.2, duration: 0.24)
            SpringKeyframe(0.0, duration: 0.2, spring: .init(response: 0.40, dampingRatio: 0.40))
            Hold.moving(0.0, duration: 0.56, drift: -0.68)
        }
        KeyframeTrack(\.ahoge) {
            Hold.moving(0.0, duration: 0.6, drift: 0.9)
            CubicKeyframe(-5.4, duration: 0.25)
            CubicKeyframe(-2.7, duration: 0.2)
            SpringKeyframe(6.3, duration: 0.25, spring: .init(response: 0.40, dampingRatio: 0.40))
            SpringKeyframe(-1.8, duration: 0.3, spring: .init(response: 0.40, dampingRatio: 0.40))
            SpringKeyframe(0.0, duration: 0.4, spring: .init(response: 0.40, dampingRatio: 0.40))
            Hold.moving(0.0, duration: 0.4, drift: 0.9)
            CubicKeyframe(4.5, duration: 0.4)
            SpringKeyframe(0.0, duration: 0.6, spring: .init(response: 0.40, dampingRatio: 0.40))
        }
    }
}
