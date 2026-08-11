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
        // The break perch needs the mask off: she sits on the pill's top edge with
        // her boots dangling over the glass, which only reads drawn in front of it.
        cue == .focusStart || cue == .breakStart
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
        // The pump: up fast, a bounce at the top, then held. -155° puts the fist at
        // roughly (148, 20) — clear of the narrowed skull, which matters because
        // arms draw behind the head. The earlier -115° cap was sized for the old
        // wide face and now reads as a shrug rather than a punch.
        KeyframeTrack(\.armR) {
            LinearKeyframe(0, duration: 0.60)
            CubicKeyframe(-155, duration: 0.25)
            SpringKeyframe(-132, duration: 0.25, spring: .init(response: 0.26, dampingRatio: 0.45))
            CubicKeyframe(-155, duration: 0.25)
            LinearKeyframe(-155, duration: 0.55)
            CubicKeyframe(0, duration: 0.25)
            LinearKeyframe(0, duration: 0.45)
        }
        // A fist pump is mostly elbow. The shoulder sets the arm's direction; the
        // forearm is what actually pumps, and it bounces harder and later than the
        // shoulder — which is the whole reason the gesture reads as energetic.
        // Elbow angles are *relative to the shoulder*, so they compound. With the
        // shoulder at -155 a -54 elbow totals -209° and folds the fist back over
        // her head — the pose that read as a head-scratch. -20 keeps the fist out
        // at x≈136, clear of the skull, and the bounce toward -4 straightens the
        // arm, which is what drives the fist upward on the pump.
        KeyframeTrack(\.armR_fore) {
            LinearKeyframe(0, duration: 0.64)
            CubicKeyframe(-20, duration: 0.25)
            SpringKeyframe(-4, duration: 0.25, spring: .init(response: 0.22, dampingRatio: 0.38))
            CubicKeyframe(-20, duration: 0.25)
            Hold.moving(-20, duration: 0.51, drift: 3.0)
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

    // MARK: - breakStart · "Perch & wave" (3.0s)

    /// She pops up in front of the pill, sits down on its top edge — boots
    /// dangling over the glass — and waves with her eyes closed happy.
    ///
    /// Sitting is sold by three cues, none of which is a knee joint (the legs are
    /// single segments): the figure settles ~45 design units lower than standing,
    /// so her seat lands on the occluding edge; a small squash absorbs the
    /// sit-down; and the legs kick alternately from the hip like anyone perched on
    /// a ledge. Emergence 23 ≈ that 45-unit drop through the top edge's mapping.
    @KeyframesBuilder<AnimeGirlPose>
    public static var perchWave: some Keyframes<AnimeGirlPose> {
        KeyframeTrack(\.emergence) {
            CubicKeyframe(14, duration: 0.50)         // rises a touch high…
            SpringKeyframe(23, duration: 0.25, spring: .init(response: 0.35, dampingRatio: 0.60))
            Hold.moving(23, duration: 1.75, drift: 1.2)   // …and sits into the hold
            CubicKeyframe(200, duration: 0.50)
        }
        // The sit-down lands with a small squash, like the fist pump's entry.
        KeyframeTrack(\.figureScaleY) {
            LinearKeyframe(1, duration: 0.62)
            CubicKeyframe(0.955, duration: 0.13)
            SpringKeyframe(1.0, duration: 0.30, spring: .init(response: 0.30, dampingRatio: 0.55))
            Hold.moving(1.0, duration: 1.95, drift: 0.014)
        }
        KeyframeTrack(\.happyOpacity) {
            LinearKeyframe(0, duration: 0.45)
            LinearKeyframe(1, duration: 0.12)
            LinearKeyframe(1, duration: 1.86)
            LinearKeyframe(0, duration: 0.12)
            LinearKeyframe(0, duration: 0.45)
        }
        // Perched-on-a-ledge kicks: whole legs from the hip, counter-phased and
        // slightly uneven so they read as idle swinging, not a metronome.
        KeyframeTrack(\.legL) {
            LinearKeyframe(0, duration: 0.70)
            CubicKeyframe(-9, duration: 0.30)
            CubicKeyframe(7, duration: 0.45)
            CubicKeyframe(-8, duration: 0.45)
            CubicKeyframe(6, duration: 0.40)
            CubicKeyframe(0, duration: 0.30)
            LinearKeyframe(0, duration: 0.40)
        }
        KeyframeTrack(\.legR) {
            LinearKeyframe(0, duration: 0.85)
            CubicKeyframe(8, duration: 0.30)
            CubicKeyframe(-7, duration: 0.45)
            CubicKeyframe(8, duration: 0.45)
            CubicKeyframe(-5, duration: 0.35)
            CubicKeyframe(0, duration: 0.30)
            LinearKeyframe(0, duration: 0.30)
        }
        // The wave: the shoulder raises the arm beside her head and holds with a
        // breath; the forearm does the actual waving, three wags from the elbow.
        KeyframeTrack(\.armR) {
            LinearKeyframe(0, duration: 0.55)
            CubicKeyframe(-145, duration: 0.30)
            Hold.breathing(-145, duration: 1.35, drift: 3.0)
            CubicKeyframe(0, duration: 0.40)
            LinearKeyframe(0, duration: 0.40)
        }
        KeyframeTrack(\.armR_fore) {
            LinearKeyframe(0, duration: 0.60)
            CubicKeyframe(-38, duration: 0.25)
            CubicKeyframe(-8, duration: 0.30)
            CubicKeyframe(-42, duration: 0.30)
            CubicKeyframe(-8, duration: 0.30)
            CubicKeyframe(-38, duration: 0.25)
            CubicKeyframe(0, duration: 0.45)
            LinearKeyframe(0, duration: 0.55)
        }
        // The other hand props against the pill's edge beside her hip.
        KeyframeTrack(\.armL) {
            LinearKeyframe(0, duration: 0.58)
            CubicKeyframe(14, duration: 0.30)
            SpringKeyframe(9, duration: 0.30, spring: .init(response: 0.34, dampingRatio: 0.55))
            Hold.breathing(9, duration: 1.02, drift: 2.0)
            CubicKeyframe(0, duration: 0.35)
            LinearKeyframe(0, duration: 0.45)
        }
        KeyframeTrack(\.armL_fore) {
            LinearKeyframe(0, duration: 0.62)
            CubicKeyframe(20, duration: 0.30)
            SpringKeyframe(13, duration: 0.28, spring: .init(response: 0.38, dampingRatio: 0.52))
            Hold.breathing(13, duration: 0.95, drift: 2.2)
            CubicKeyframe(0, duration: 0.40)
            LinearKeyframe(0, duration: 0.45)
        }
        // A small lean toward the waving side.
        KeyframeTrack(\.head) {
            LinearKeyframe(0, duration: 0.70)
            CubicKeyframe(-4, duration: 0.30)
            Hold.breathing(-4, duration: 1.20, drift: 1.5)
            CubicKeyframe(0, duration: 0.35)
            LinearKeyframe(0, duration: 0.45)
        }
        // Tails settle from the drop, then idle; tips lag their bases.
        KeyframeTrack(\.tailL_base) {
            LinearKeyframe(0, duration: 0.75)
            SpringKeyframe(-8, duration: 0.30, spring: .init(response: 0.45, dampingRatio: 0.50))
            SpringKeyframe(5, duration: 0.55, spring: .init(response: 0.45, dampingRatio: 0.50))
            SpringKeyframe(-4, duration: 0.55, spring: .init(response: 0.45, dampingRatio: 0.50))
            SpringKeyframe(0, duration: 0.45, spring: .init(response: 0.45, dampingRatio: 0.50))
            LinearKeyframe(0, duration: 0.40)
        }
        KeyframeTrack(\.tailR_base) {
            LinearKeyframe(0, duration: 0.75)
            SpringKeyframe(8, duration: 0.30, spring: .init(response: 0.45, dampingRatio: 0.50))
            SpringKeyframe(-5, duration: 0.55, spring: .init(response: 0.45, dampingRatio: 0.50))
            SpringKeyframe(4, duration: 0.55, spring: .init(response: 0.45, dampingRatio: 0.50))
            SpringKeyframe(0, duration: 0.45, spring: .init(response: 0.45, dampingRatio: 0.50))
            LinearKeyframe(0, duration: 0.40)
        }
        KeyframeTrack(\.tailL_tip) {
            Hold.moving(0, duration: 0.90, drift: 1.8)
            SpringKeyframe(-12, duration: 0.35, spring: .init(response: 0.40, dampingRatio: 0.38))
            SpringKeyframe(8, duration: 0.60, spring: .init(response: 0.40, dampingRatio: 0.38))
            SpringKeyframe(-6, duration: 0.55, spring: .init(response: 0.40, dampingRatio: 0.38))
            SpringKeyframe(0, duration: 0.60, spring: .init(response: 0.40, dampingRatio: 0.38))
        }
        KeyframeTrack(\.tailR_tip) {
            Hold.moving(0, duration: 0.90, drift: 1.8)
            SpringKeyframe(12, duration: 0.35, spring: .init(response: 0.40, dampingRatio: 0.38))
            SpringKeyframe(-8, duration: 0.60, spring: .init(response: 0.40, dampingRatio: 0.38))
            SpringKeyframe(6, duration: 0.55, spring: .init(response: 0.40, dampingRatio: 0.38))
            SpringKeyframe(0, duration: 0.60, spring: .init(response: 0.40, dampingRatio: 0.38))
        }
        KeyframeTrack(\.ahoge) {
            Hold.moving(0, duration: 0.80, drift: 1.8)
            SpringKeyframe(10, duration: 0.35, spring: .init(response: 0.50, dampingRatio: 0.38))
            SpringKeyframe(-10, duration: 0.60, spring: .init(response: 0.50, dampingRatio: 0.38))
            SpringKeyframe(6, duration: 0.50, spring: .init(response: 0.50, dampingRatio: 0.38))
            SpringKeyframe(0, duration: 0.45, spring: .init(response: 0.50, dampingRatio: 0.38))
            LinearKeyframe(0, duration: 0.30)
        }
        KeyframeTrack(\.ahogeScaleY) {
            LinearKeyframe(1, duration: 0.55)
            CubicKeyframe(0.8, duration: 0.30)        // droops as she relaxes
            Hold.moving(0.8, duration: 1.65, drift: 0.014)
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
