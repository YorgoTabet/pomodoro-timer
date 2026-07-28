import PomodoroCore
import SwiftUI

/// The anime girl's three performances.
///
/// The ahoge does the emotional work: it snaps rigid when she is determined,
/// droops when she relaxes, and whips hardest coming out of the twirl. It lags
/// everything else by design.
public enum AnimeGirlPerformance {

    public static func preferredEdge(for cue: CharacterCue) -> StageEdge { .top }

    public static func comesForward(for cue: CharacterCue) -> Bool {
        cue == .focusStart
    }

    public static func duration(for cue: CharacterCue) -> Double {
        switch cue {
        case .focusStart: 2.60
        case .breakStart: 3.00
        case .longBreak: 3.40
        }
    }

    // MARK: - focusStart · "Ganbatte" (2.6s)

    /// Determined face, then a fist pumped overhead while she steps toward you.
    @KeyframesBuilder<AnimeGirlPose>
    public static var fistPump: some Keyframes<AnimeGirlPose> {
        KeyframeTrack(\.emergence) {
            CubicKeyframe(0, duration: 0.45)
            Hold.moving(0, duration: 1.75, drift: 1.4)
            CubicKeyframe(200, duration: 0.40)
        }
        KeyframeTrack(\.figureScaleY) {
            LinearKeyframe(1.06, duration: 0.05)
            CubicKeyframe(1.0, duration: 0.40)
            Hold.moving(1.0, duration: 2.15, drift: 0.014)
        }
        KeyframeTrack(\.figureScale) {
            LinearKeyframe(1, duration: 0.55)
            SpringKeyframe(1.12, duration: 0.40, spring: .init(response: 0.4, dampingRatio: 0.65))
            Hold.moving(1.12, duration: 0.95, drift: 0.014)
            CubicKeyframe(1.0, duration: 0.25)
            LinearKeyframe(1.0, duration: 0.45)
        }
        KeyframeTrack(\.figureLift) {
            LinearKeyframe(0, duration: 0.55)
            CubicKeyframe(6, duration: 0.40)
            Hold.moving(6, duration: 0.95, drift: 0.5)
            CubicKeyframe(0, duration: 0.25)
            LinearKeyframe(0, duration: 0.45)
        }
        KeyframeTrack(\.determinedOpacity) {
            LinearKeyframe(0, duration: 0.30)
            LinearKeyframe(1, duration: 0.12)
            LinearKeyframe(1, duration: 1.73)
            LinearKeyframe(0, duration: 0.10)
            LinearKeyframe(0, duration: 0.35)
        }
        KeyframeTrack(\.ahogeScaleY) {
            LinearKeyframe(1, duration: 0.30)
            SpringKeyframe(1.3, duration: 0.25, spring: .init(response: 0.3, dampingRatio: 0.5))
            Hold.moving(1.3, duration: 1.6, drift: 0.014)
            CubicKeyframe(1.0, duration: 0.45)
        }
        // The pump: up fast, a bounce at the top, then held.
        KeyframeTrack(\.armR) {
            LinearKeyframe(0, duration: 0.60)
            CubicKeyframe(-150, duration: 0.25)
            SpringKeyframe(-125, duration: 0.25, spring: .init(response: 0.26, dampingRatio: 0.45))
            CubicKeyframe(-150, duration: 0.25)
            LinearKeyframe(-150, duration: 0.55)
            CubicKeyframe(0, duration: 0.25)
            LinearKeyframe(0, duration: 0.45)
        }
        // A fist pump is mostly elbow. The shoulder sets the arm's direction; the
        // forearm is what actually pumps, and it bounces harder and later than the
        // shoulder — which is the whole reason the gesture reads as energetic.
        KeyframeTrack(\.armR_fore) {
            LinearKeyframe(0, duration: 0.64)
            CubicKeyframe(-62, duration: 0.25)
            SpringKeyframe(-30, duration: 0.25, spring: .init(response: 0.22, dampingRatio: 0.38))
            CubicKeyframe(-58, duration: 0.25)
            Hold.moving(-58, duration: 0.51, drift: 3.0)
            CubicKeyframe(0, duration: 0.25)
            LinearKeyframe(0, duration: 0.45)
        }
        // The other arm was entirely static. It braces down and back as a counter
        // to the pump, then settles.
        KeyframeTrack(\.armL) {
            LinearKeyframe(0, duration: 0.60)
            CubicKeyframe(17, duration: 0.28)
            SpringKeyframe(9, duration: 0.24, spring: .init(response: 0.34, dampingRatio: 0.55))
            Hold.breathing(9, duration: 0.78, drift: 2.0)
            CubicKeyframe(0, duration: 0.25)
            LinearKeyframe(0, duration: 0.45)
        }
        KeyframeTrack(\.armL_fore) {
            LinearKeyframe(0, duration: 0.64)
            CubicKeyframe(26, duration: 0.28)
            SpringKeyframe(15, duration: 0.24, spring: .init(response: 0.38, dampingRatio: 0.52))
            Hold.breathing(15, duration: 0.74, drift: 2.4)
            CubicKeyframe(0, duration: 0.25)
            LinearKeyframe(0, duration: 0.45)
        }
        KeyframeTrack(\.head) {
            LinearKeyframe(0, duration: 0.60)
            CubicKeyframe(-6, duration: 0.20)
            Hold.breathing(-6, duration: 1.3, drift: 1.8)
            CubicKeyframe(0, duration: 0.25)
            LinearKeyframe(0, duration: 0.25)
        }
        KeyframeTrack(\.eyesScale) {
            LinearKeyframe(1, duration: 0.30)
            CubicKeyframe(0.92, duration: 0.12)
            Hold.moving(0.92, duration: 1.73, drift: 0.014)
            CubicKeyframe(1.0, duration: 0.45)
        }
        // The ahoge quivers through the held pose.
        KeyframeTrack(\.ahoge) {
            LinearKeyframe(0, duration: 0.85)
            SpringKeyframe(-14, duration: 0.25, spring: .init(response: 0.35, dampingRatio: 0.35))
            CubicKeyframe(8, duration: 0.25)
            CubicKeyframe(-8, duration: 0.25)
            CubicKeyframe(0, duration: 0.30)
            LinearKeyframe(0, duration: 0.70)
        }
        KeyframeTrack(\.tailL_base) {
            LinearKeyframe(0, duration: 0.68)
            SpringKeyframe(-16, duration: 0.25, spring: .init(response: 0.35, dampingRatio: 0.55))
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.35, dampingRatio: 0.55))
            Hold.moving(0, duration: 1.27, drift: 1.8)
        }
        KeyframeTrack(\.tailR_base) {
            LinearKeyframe(0, duration: 0.68)
            SpringKeyframe(16, duration: 0.25, spring: .init(response: 0.35, dampingRatio: 0.55))
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.35, dampingRatio: 0.55))
            Hold.moving(0, duration: 1.27, drift: 1.8)
        }
        KeyframeTrack(\.tailL_tip) {
            LinearKeyframe(0, duration: 0.80)
            SpringKeyframe(-26, duration: 0.28, spring: .init(response: 0.40, dampingRatio: 0.42))
            SpringKeyframe(0, duration: 0.45, spring: .init(response: 0.40, dampingRatio: 0.42))
            Hold.moving(0, duration: 1.07, drift: 1.8)
        }
        KeyframeTrack(\.tailR_tip) {
            LinearKeyframe(0, duration: 0.80)
            SpringKeyframe(26, duration: 0.28, spring: .init(response: 0.40, dampingRatio: 0.42))
            SpringKeyframe(0, duration: 0.45, spring: .init(response: 0.40, dampingRatio: 0.42))
            Hold.moving(0, duration: 1.07, drift: 1.8)
        }
    }

    // MARK: - breakStart · "Happy sway" (3.0s)

    /// Eyes close into ∩ arcs and she sways, everything counter-phasing.
    @KeyframesBuilder<AnimeGirlPose>
    public static var happySway: some Keyframes<AnimeGirlPose> {
        KeyframeTrack(\.emergence) {
            CubicKeyframe(-10, duration: 0.60)
            SpringKeyframe(0, duration: 0.20, spring: .init(response: 0.35, dampingRatio: 0.60))
            Hold.moving(0, duration: 1.7, drift: 1.4)
            CubicKeyframe(200, duration: 0.50)
        }
        KeyframeTrack(\.happyOpacity) {
            LinearKeyframe(0, duration: 0.50)
            LinearKeyframe(1, duration: 0.12)
            LinearKeyframe(1, duration: 1.68)
            LinearKeyframe(0, duration: 0.12)
            LinearKeyframe(0, duration: 0.58)
        }
        KeyframeTrack(\.hips) {
            LinearKeyframe(0, duration: 0.80)
            CubicKeyframe(-5, duration: 0.35)
            CubicKeyframe(5, duration: 0.70)
            CubicKeyframe(-5, duration: 0.70)
            CubicKeyframe(0, duration: 0.20)
            LinearKeyframe(0, duration: 0.25)
        }
        // Counter-phase so she reads as swaying, not toppling.
        KeyframeTrack(\.head) {
            LinearKeyframe(0, duration: 0.80)
            CubicKeyframe(3, duration: 0.35)
            CubicKeyframe(-3, duration: 0.70)
            CubicKeyframe(3, duration: 0.70)
            CubicKeyframe(0, duration: 0.20)
            LinearKeyframe(0, duration: 0.25)
        }
        KeyframeTrack(\.armL) {
            LinearKeyframe(0, duration: 0.80)
            CubicKeyframe(8, duration: 0.35)
            CubicKeyframe(-8, duration: 0.70)
            CubicKeyframe(8, duration: 0.70)
            CubicKeyframe(0, duration: 0.45)
        }
        KeyframeTrack(\.armR) {
            LinearKeyframe(0, duration: 0.80)
            CubicKeyframe(-8, duration: 0.35)
            CubicKeyframe(8, duration: 0.70)
            CubicKeyframe(-8, duration: 0.70)
            CubicKeyframe(0, duration: 0.45)
        }
        // Elbows swing a beat behind the shoulders and a touch wider, so the sway
        // travels down each arm instead of the whole limb tilting as a unit.
        KeyframeTrack(\.armL_fore) {
            Hold.moving(0, duration: 0.92, drift: 1.8)
            CubicKeyframe(12, duration: 0.35)
            CubicKeyframe(-12, duration: 0.70)
            CubicKeyframe(11, duration: 0.65)
            CubicKeyframe(0, duration: 0.38)
        }
        KeyframeTrack(\.armR_fore) {
            Hold.moving(0, duration: 0.92, drift: 1.8)
            CubicKeyframe(-12, duration: 0.35)
            CubicKeyframe(12, duration: 0.70)
            CubicKeyframe(-11, duration: 0.65)
            CubicKeyframe(0, duration: 0.38)
        }
        // Tails lag the sway; the ahoge lags the tails.
        KeyframeTrack(\.tailL_base) {
            LinearKeyframe(0, duration: 0.88)
            SpringKeyframe(9, duration: 0.35, spring: .init(response: 0.45, dampingRatio: 0.50))
            SpringKeyframe(-9, duration: 0.70, spring: .init(response: 0.45, dampingRatio: 0.50))
            SpringKeyframe(0, duration: 0.60, spring: .init(response: 0.45, dampingRatio: 0.50))
            LinearKeyframe(0, duration: 0.47)
        }
        KeyframeTrack(\.tailR_base) {
            LinearKeyframe(0, duration: 0.88)
            SpringKeyframe(-9, duration: 0.35, spring: .init(response: 0.45, dampingRatio: 0.50))
            SpringKeyframe(9, duration: 0.70, spring: .init(response: 0.45, dampingRatio: 0.50))
            SpringKeyframe(0, duration: 0.60, spring: .init(response: 0.45, dampingRatio: 0.50))
            LinearKeyframe(0, duration: 0.47)
        }
        KeyframeTrack(\.ahoge) {
            Hold.moving(0, duration: 0.95, drift: 1.8)
            SpringKeyframe(14, duration: 0.35, spring: .init(response: 0.50, dampingRatio: 0.38))
            SpringKeyframe(-14, duration: 0.70, spring: .init(response: 0.50, dampingRatio: 0.38))
            SpringKeyframe(0, duration: 0.60, spring: .init(response: 0.50, dampingRatio: 0.38))
            LinearKeyframe(0, duration: 0.40)
        }
        KeyframeTrack(\.ahogeScaleY) {
            LinearKeyframe(1, duration: 0.50)
            CubicKeyframe(0.75, duration: 0.30)       // droops as she relaxes
            Hold.moving(0.75, duration: 1.7, drift: 0.014)
            CubicKeyframe(1.0, duration: 0.50)
        }
    }

    // MARK: - longBreak · "Twirl" (3.4s)

    /// A full clockwise turn with the profile thinning mid-spin, then sparkles.
    @KeyframesBuilder<AnimeGirlPose>
    public static var twirl: some Keyframes<AnimeGirlPose> {
        KeyframeTrack(\.emergence) {
            CubicKeyframe(-16, duration: 0.50)
            SpringKeyframe(0, duration: 0.20, spring: .init(response: 0.4, dampingRatio: 0.60))
            Hold.moving(0, duration: 2.1, drift: 1.4)
            CubicKeyframe(200, duration: 0.60)
        }
        KeyframeTrack(\.happyOpacity) {
            LinearKeyframe(0, duration: 0.60)
            LinearKeyframe(1, duration: 0.12)
            LinearKeyframe(1, duration: 1.83)
            LinearKeyframe(0, duration: 0.12)
            LinearKeyframe(0, duration: 0.73)
        }
        // Arms and head through the turn, none of which moved before — the twirl was
        // the whole figure rotating as one flat board.
        //
        // Both arms come out and up into the spin and are pulled back in as it
        // stops; the head leads the turn and settles last. That ordering is what
        // separates a person turning from a sprite being rotated.
        KeyframeTrack(\.armL) {
            LinearKeyframe(0, duration: 0.80)
            CubicKeyframe(14, duration: 0.20)         // opens with the anticipation
            CubicKeyframe(-34, duration: 0.70)        // out and up through the turn
            SpringKeyframe(-12, duration: 0.35, spring: .init(response: 0.42, dampingRatio: 0.50))
            Hold.breathing(-12, duration: 0.95, drift: 2.2)
            CubicKeyframe(0, duration: 0.40)
        }
        KeyframeTrack(\.armL_fore) {
            LinearKeyframe(0, duration: 0.86)
            CubicKeyframe(20, duration: 0.20)
            CubicKeyframe(-46, duration: 0.68)
            SpringKeyframe(-16, duration: 0.36, spring: .init(response: 0.46, dampingRatio: 0.44))
            Hold.breathing(-16, duration: 0.90, drift: 2.8)
            CubicKeyframe(0, duration: 0.40)
        }
        KeyframeTrack(\.armR) {
            LinearKeyframe(0, duration: 0.80)
            CubicKeyframe(-14, duration: 0.20)
            CubicKeyframe(34, duration: 0.70)
            SpringKeyframe(12, duration: 0.35, spring: .init(response: 0.42, dampingRatio: 0.50))
            Hold.breathing(12, duration: 0.95, drift: 2.2)
            CubicKeyframe(0, duration: 0.40)
        }
        KeyframeTrack(\.armR_fore) {
            LinearKeyframe(0, duration: 0.86)
            CubicKeyframe(-20, duration: 0.20)
            CubicKeyframe(46, duration: 0.68)
            SpringKeyframe(16, duration: 0.36, spring: .init(response: 0.46, dampingRatio: 0.44))
            Hold.breathing(16, duration: 0.90, drift: 2.8)
            CubicKeyframe(0, duration: 0.40)
        }
        KeyframeTrack(\.head) {
            LinearKeyframe(0, duration: 0.80)
            CubicKeyframe(9, duration: 0.20)          // head leads into the turn
            CubicKeyframe(-11, duration: 0.70)
            SpringKeyframe(0, duration: 0.35, spring: .init(response: 0.44, dampingRatio: 0.42))
            Hold.breathing(0, duration: 0.95, drift: 2.0)
            CubicKeyframe(0, duration: 0.40)
        }
        KeyframeTrack(\.figureRotation) {
            LinearKeyframe(0, duration: 0.80)
            CubicKeyframe(-20, duration: 0.20)        // anticipation
            CubicKeyframe(340, duration: 0.70)        // the turn
            SpringKeyframe(360, duration: 0.35, spring: .init(response: 0.4, dampingRatio: 0.60))
            Hold.moving(360, duration: 1.35, drift: 1.8)
        }
        // Profile thins through the spin, which is what sells it as a rotation
        // rather than a flat pinwheel.
        KeyframeTrack(\.figureScaleX) {
            LinearKeyframe(1, duration: 0.80)
            CubicKeyframe(0.94, duration: 0.20)
            CubicKeyframe(0.86, duration: 0.45)
            CubicKeyframe(1.0, duration: 0.25)
            Hold.moving(1.0, duration: 1.7, drift: 0.014)
        }
        KeyframeTrack(\.sparkleOpacity) {
            LinearKeyframe(0, duration: 1.00)
            CubicKeyframe(1, duration: 0.30)
            LinearKeyframe(1, duration: 0.30)
            CubicKeyframe(0, duration: 0.60)
            LinearKeyframe(0, duration: 1.20)
        }
        KeyframeTrack(\.sparkleScale) {
            Hold.moving(0.4, duration: 1.0, drift: 0.014)
            CubicKeyframe(1.1, duration: 0.30)
            Hold.moving(1.1, duration: 0.9, drift: 0.014)
            Hold.moving(1.1, duration: 1.2, drift: 0.014)
        }
        KeyframeTrack(\.sparkleRotation) {
            Hold.moving(0, duration: 1.0, drift: 1.8)
            LinearKeyframe(90, duration: 0.60)
            Hold.moving(90, duration: 1.8, drift: 1.8)
        }
        // Everything catches up late and overshoots hard.
        KeyframeTrack(\.tailL_base) {
            Hold.moving(0, duration: 1.0, drift: 1.8)
            CubicKeyframe(-30, duration: 0.70)
            SpringKeyframe(0, duration: 0.80, spring: .init(response: 0.35, dampingRatio: 0.42))
            Hold.moving(0, duration: 0.9, drift: 1.8)
        }
        KeyframeTrack(\.tailR_base) {
            Hold.moving(0, duration: 1.0, drift: 1.8)
            CubicKeyframe(30, duration: 0.70)
            SpringKeyframe(0, duration: 0.80, spring: .init(response: 0.35, dampingRatio: 0.42))
            Hold.moving(0, duration: 0.9, drift: 1.8)
        }
        KeyframeTrack(\.tailL_tip) {
            Hold.moving(0, duration: 1.1, drift: 1.8)
            CubicKeyframe(-40, duration: 0.70)
            SpringKeyframe(0, duration: 0.90, spring: .init(response: 0.40, dampingRatio: 0.38))
            LinearKeyframe(0, duration: 0.70)
        }
        KeyframeTrack(\.tailR_tip) {
            Hold.moving(0, duration: 1.1, drift: 1.8)
            CubicKeyframe(40, duration: 0.70)
            SpringKeyframe(0, duration: 0.90, spring: .init(response: 0.40, dampingRatio: 0.38))
            LinearKeyframe(0, duration: 0.70)
        }
        KeyframeTrack(\.ahoge) {
            Hold.moving(0, duration: 1.1, drift: 1.8)
            CubicKeyframe(-42, duration: 0.70)
            SpringKeyframe(18, duration: 0.35, spring: .init(response: 0.40, dampingRatio: 0.32))
            SpringKeyframe(0, duration: 0.55, spring: .init(response: 0.40, dampingRatio: 0.32))
            LinearKeyframe(0, duration: 0.70)
        }
    }
}
