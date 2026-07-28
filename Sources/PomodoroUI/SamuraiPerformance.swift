import PomodoroCore
import SwiftUI

/// The samurai's three performances, transcribed from the art-direction spec.
///
/// Each is a `KeyframeTrack` set over `SamuraiPose`; a timeline row in the spec maps
/// to one keyframe here, so the two can be diffed by eye.
///
/// Convention: positive rotation is clockwise on screen, `emergence` counts design
/// units *behind* the pill edge (200 = hidden, 0 = risen, negative = overshoot).
public enum SamuraiPerformance {

    /// Preferred emergence edge per cue. The stage flips these when the pill is too
    /// close to a screen edge.
    /// Everything reveals from the top. Emerging sideways read as a different
    /// character each time; rising from behind the pill is the one gesture that
    /// makes the pill feel like the thing he lives in.
    public static func preferredEdge(for cue: CharacterCue) -> StageEdge { .top }

    /// Whether he comes *in front of* the pill rather than staying behind it.
    /// Only the back-to-work cue does — stepping into the foreground and aiming at
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

    // MARK: - focusStart · "Get back to work" (2.4s)

    /// He vaults from behind the pill into the foreground, plants, and levels the
    /// blade at you. The scale-up is what sells "stepped toward the viewer" — a
    /// flat puppet cannot foreshorten, so proximity has to be read as size.
    @KeyframesBuilder<SamuraiPose>
    public static var snapToGuard: some Keyframes<SamuraiPose> {
        KeyframeTrack(\.emergence) {
            CubicKeyframe(150, duration: 0.10)            // helmet crest peeks
            SpringKeyframe(-18, duration: 0.30, spring: .init(response: 0.30, dampingRatio: 0.55))
            SpringKeyframe(0, duration: 0.20, spring: .init(response: 0.30, dampingRatio: 0.62))
            Hold.moving(0, duration: 1.42, drift: 1.4)
            CubicKeyframe(-6, duration: 0.10)
            CubicKeyframe(200, duration: 0.28)
        }
        // Grows as he lands in front of the pill, then holds his ground.
        KeyframeTrack(\.rootScale) {
            LinearKeyframe(0.86, duration: 0.10)
            SpringKeyframe(1.12, duration: 0.30, spring: .init(response: 0.30, dampingRatio: 0.55))
            SpringKeyframe(1.06, duration: 0.20, spring: .init(response: 0.30, dampingRatio: 0.62))
            Hold.moving(1.06, duration: 1.42, drift: 0.014)
            CubicKeyframe(0.9, duration: 0.38)
        }
        KeyframeTrack(\.rootScaleY) {
            LinearKeyframe(0.92, duration: 0.10)          // launch squash
            SpringKeyframe(1.06, duration: 0.20, spring: .init(response: 0.30, dampingRatio: 0.50))
            SpringKeyframe(0.94, duration: 0.12, spring: .init(response: 0.28, dampingRatio: 0.50))
            SpringKeyframe(1.0, duration: 0.18, spring: .init(response: 0.30, dampingRatio: 0.60))
            Hold.moving(1.0, duration: 1.8, drift: 0.014)
        }
        // The point: blade swings down and levels straight at the viewer.
        KeyframeTrack(\.swordArmUpper) {
            LinearKeyframe(0, duration: 0.40)
            CubicKeyframe(-38, duration: 0.14)            // cocks back
            SpringKeyframe(30, duration: 0.16, spring: .init(response: 0.26, dampingRatio: 0.55))
            SpringKeyframe(24, duration: 0.14, spring: .init(response: 0.26, dampingRatio: 0.62))
            Hold.moving(24, duration: 1.14, drift: 1.8)            // held, aimed at you
            CubicKeyframe(0, duration: 0.42)
        }
        KeyframeTrack(\.swordFore) {
            LinearKeyframe(0, duration: 0.40)
            CubicKeyframe(-14, duration: 0.14)
            SpringKeyframe(52, duration: 0.30, spring: .init(response: 0.26, dampingRatio: 0.58))
            Hold.moving(52, duration: 1.14, drift: 1.8)
            CubicKeyframe(0, duration: 0.42)
        }
        KeyframeTrack(\.katana) {
            LinearKeyframe(0, duration: 0.46)
            SpringKeyframe(-18, duration: 0.34, spring: .init(response: 0.30, dampingRatio: 0.50))
            Hold.moving(-18, duration: 1.18, drift: 1.8)
            CubicKeyframe(0, duration: 0.42)
        }
        KeyframeTrack(\.torso) {
            LinearKeyframe(0, duration: 0.40)
            SpringKeyframe(-6, duration: 0.30, spring: .init(response: 0.30, dampingRatio: 0.60))
            Hold.moving(-6, duration: 1.28, drift: 1.8)            // leans in behind the point
            CubicKeyframe(0, duration: 0.42)
        }
        KeyframeTrack(\.head) {
            LinearKeyframe(0, duration: 0.54)
            CubicKeyframe(4, duration: 0.16)              // chin down, eyes on you
            Hold.moving(4, duration: 1.28, drift: 1.8)
            CubicKeyframe(0, duration: 0.42)
        }
        KeyframeTrack(\.maedate) {
            LinearKeyframe(12, duration: 0.24)
            SpringKeyframe(-6, duration: 0.14, spring: .init(response: 0.50, dampingRatio: 0.35))
            SpringKeyframe(0, duration: 0.18, spring: .init(response: 0.50, dampingRatio: 0.35))
            Hold.moving(0, duration: 1.56, drift: 1.8)
            CubicKeyframe(-12, duration: 0.28)
        }
        KeyframeTrack(\.kusazuriL) {
            LinearKeyframe(-16, duration: 0.20)
            SpringKeyframe(0, duration: 0.34, spring: .init(response: 0.48, dampingRatio: 0.40))
            Hold.moving(0, duration: 1.86, drift: 1.8)
        }
        KeyframeTrack(\.kusazuriFL) {
            LinearKeyframe(-9, duration: 0.26)
            SpringKeyframe(0, duration: 0.34, spring: .init(response: 0.48, dampingRatio: 0.40))
            Hold.moving(0, duration: 1.8, drift: 1.8)
        }
        KeyframeTrack(\.kusazuriFR) {
            LinearKeyframe(9, duration: 0.32)
            SpringKeyframe(0, duration: 0.34, spring: .init(response: 0.48, dampingRatio: 0.40))
            Hold.moving(0, duration: 1.74, drift: 1.8)
        }
        KeyframeTrack(\.kusazuriR) {
            LinearKeyframe(16, duration: 0.38)
            SpringKeyframe(0, duration: 0.34, spring: .init(response: 0.48, dampingRatio: 0.40))
            Hold.moving(0, duration: 1.68, drift: 1.8)
        }
        KeyframeTrack(\.sodeL) {
            LinearKeyframe(-16, duration: 0.22)
            SpringKeyframe(0, duration: 0.36, spring: .init(response: 0.50, dampingRatio: 0.48))
            Hold.moving(0, duration: 1.82, drift: 1.8)
        }
        KeyframeTrack(\.sodeR) {
            LinearKeyframe(16, duration: 0.22)
            SpringKeyframe(-10, duration: 0.24, spring: .init(response: 0.45, dampingRatio: 0.45))
            SpringKeyframe(0, duration: 0.24, spring: .init(response: 0.45, dampingRatio: 0.45))
            Hold.moving(0, duration: 1.7, drift: 1.8)
        }
        // The free arm, which did nothing at all here until now.
        //
        // A two-handed guard is a whole-body shape: the off hand comes across to
        // brace, and it arrives *before* the blade settles, because it is what the
        // blade settles against. Leaving it hanging made the stance read as a
        // one-armed pose with a spare limb attached.
        KeyframeTrack(\.offArmUpper) {
            LinearKeyframe(0, duration: 0.34)
            CubicKeyframe(-16, duration: 0.16)            // opens away as he cocks back
            SpringKeyframe(26, duration: 0.20, spring: .init(response: 0.26, dampingRatio: 0.56))
            Hold.moving(26, duration: 1.28, drift: 1.6)
            CubicKeyframe(0, duration: 0.42)
        }
        KeyframeTrack(\.offArmFore) {
            LinearKeyframe(0, duration: 0.34)
            CubicKeyframe(-8, duration: 0.18)
            SpringKeyframe(44, duration: 0.24, spring: .init(response: 0.26, dampingRatio: 0.52))
            Hold.moving(44, duration: 1.22, drift: 2.0)
            CubicKeyframe(0, duration: 0.42)
        }
        KeyframeTrack(\.pupilDrop) {
            LinearKeyframe(0, duration: 0.54)
            CubicKeyframe(-0.9, duration: 0.16)
            Hold.moving(-0.9, duration: 1.7, drift: 0.12)
        }
    }

    // MARK: - breakStart · "Doze off" (2.8s)

    /// He rises just far enough to lean on the pill, lets the blade drop, closes
    /// his eyes and nods off — head sinking in slow breaths, jerking up once when
    /// he nearly falls asleep, then settling.
    @KeyframesBuilder<SamuraiPose>
    public static var exhale: some Keyframes<SamuraiPose> {
        KeyframeTrack(\.emergence) {
            // Only comes up two-thirds — he is leaning on the pill, not standing
            // to attention behind it.
            SpringKeyframe(38, duration: 0.40, spring: .init(response: 0.50, dampingRatio: 0.85))
            Hold.moving(38, duration: 2.1, drift: 1.4)
            CubicKeyframe(200, duration: 0.30)
        }
        KeyframeTrack(\.rootLean) {
            LinearKeyframe(0, duration: 0.40)
            CubicKeyframe(7, duration: 0.35)             // slumps sideways
            Hold.moving(7, duration: 1.75, drift: 1.8)
            CubicKeyframe(0, duration: 0.30)
        }
        KeyframeTrack(\.torsoScaleY) {
            LinearKeyframe(1.0, duration: 0.40)
            CubicKeyframe(0.95, duration: 0.30)          // the exhale
            LinearKeyframe(0.95, duration: 0.50)
            CubicKeyframe(0.98, duration: 0.45)          // slow sleeping breaths
            CubicKeyframe(0.95, duration: 0.45)
            CubicKeyframe(0.98, duration: 0.40)
            LinearKeyframe(0.98, duration: 0.30)
        }
        // The head nod: sinks, jerks awake once, sinks again.
        KeyframeTrack(\.head) {
            LinearKeyframe(0, duration: 0.45)
            CubicKeyframe(13, duration: 0.45)            // chin drops to the chest
            LinearKeyframe(13, duration: 0.35)
            SpringKeyframe(-4, duration: 0.16, spring: .init(response: 0.24, dampingRatio: 0.5))
            SpringKeyframe(11, duration: 0.55, spring: .init(response: 0.60, dampingRatio: 0.85))
            LinearKeyframe(11, duration: 0.54)
            CubicKeyframe(0, duration: 0.30)
        }
        KeyframeTrack(\.kabuto) {
            LinearKeyframe(0, duration: 0.55)
            CubicKeyframe(5, duration: 0.45)             // helmet tips over the eyes
            Hold.moving(5, duration: 1.5, drift: 1.8)
            CubicKeyframe(0, duration: 0.30)
        }
        KeyframeTrack(\.maedate) {
            LinearKeyframe(10, duration: 0.24)
            SpringKeyframe(0, duration: 0.30, spring: .init(response: 0.55, dampingRatio: 0.40))
            LinearKeyframe(0, duration: 0.72)
            SpringKeyframe(-7, duration: 0.20, spring: .init(response: 0.50, dampingRatio: 0.35))
            SpringKeyframe(0, duration: 0.54, spring: .init(response: 0.50, dampingRatio: 0.45))
            LinearKeyframe(0, duration: 0.80)
        }
        // Sword arm goes slack and hangs.
        KeyframeTrack(\.swordArmUpper) {
            LinearKeyframe(0, duration: 0.40)
            CubicKeyframe(22, duration: 0.45)
            Hold.moving(22, duration: 1.65, drift: 1.8)
            CubicKeyframe(0, duration: 0.30)
        }
        KeyframeTrack(\.swordFore) {
            LinearKeyframe(0, duration: 0.40)
            CubicKeyframe(10, duration: 0.45)
            Hold.moving(10, duration: 1.65, drift: 1.8)
            CubicKeyframe(0, duration: 0.30)
        }
        KeyframeTrack(\.katana) {
            LinearKeyframe(0, duration: 0.40)
            SpringKeyframe(-16, duration: 0.50, spring: .init(response: 0.55, dampingRatio: 0.55))
            Hold.moving(-16, duration: 1.6, drift: 1.8)
            CubicKeyframe(0, duration: 0.30)
        }
        KeyframeTrack(\.sodeL) {
            LinearKeyframe(0, duration: 0.40)
            SpringKeyframe(8, duration: 0.35, spring: .init(response: 0.60, dampingRatio: 0.70))
            Hold.moving(8, duration: 2.05, drift: 1.8)
        }
        KeyframeTrack(\.sodeR) {
            LinearKeyframe(0, duration: 0.40)
            SpringKeyframe(-8, duration: 0.35, spring: .init(response: 0.60, dampingRatio: 0.70))
            Hold.moving(-8, duration: 2.05, drift: 1.8)
        }
        // The off arm gives up first. It is the limb with nothing to hold, so it is
        // the one that shows he has stopped being on duty — and it was static here.
        KeyframeTrack(\.offArmUpper) {
            LinearKeyframe(0, duration: 0.44)
            SpringKeyframe(-9, duration: 0.50, spring: .init(response: 0.72, dampingRatio: 0.78))
            Hold.breathing(-9, duration: 1.56, drift: 1.7)
            CubicKeyframe(0, duration: 0.30)
        }
        KeyframeTrack(\.offArmFore) {
            LinearKeyframe(0, duration: 0.50)
            SpringKeyframe(-19, duration: 0.54, spring: .init(response: 0.78, dampingRatio: 0.74))
            Hold.breathing(-19, duration: 1.46, drift: 2.2)
            CubicKeyframe(0, duration: 0.30)
        }
        // Torso breathing: the one track that makes a sleeping figure look asleep
        // rather than paused. Slower and deeper than the drift on any other joint.
        KeyframeTrack(\.torso) {
            LinearKeyframe(0, duration: 0.44)
            CubicKeyframe(4, duration: 0.46)
            Hold.breathing(4, duration: 1.60, drift: 3.0)
            CubicKeyframe(0, duration: 0.30)
        }
        KeyframeTrack(\.kusazuriL) {
            LinearKeyframe(-6, duration: 0.16)
            SpringKeyframe(4, duration: 0.40, spring: .init(response: 0.55, dampingRatio: 0.50))
            Hold.moving(4, duration: 2.24, drift: 1.8)
        }
        KeyframeTrack(\.kusazuriR) {
            LinearKeyframe(6, duration: 0.22)
            SpringKeyframe(-4, duration: 0.40, spring: .init(response: 0.55, dampingRatio: 0.50))
            Hold.moving(-4, duration: 2.18, drift: 1.8)
        }
        // Eyes close and stay closed — the whole point of the beat.
        KeyframeTrack(\.fierceOpacity) {
            LinearKeyframe(1, duration: 0.45)
            LinearKeyframe(0, duration: 0.25)
            LinearKeyframe(0, duration: 2.10)
        }
        KeyframeTrack(\.easeOpacity) {
            LinearKeyframe(0, duration: 0.45)
            LinearKeyframe(1, duration: 0.25)
            LinearKeyframe(1, duration: 2.10)
        }
        KeyframeTrack(\.pupilDrop) {
            LinearKeyframe(0, duration: 0.45)
            CubicKeyframe(1.4, duration: 0.25)
            Hold.moving(1.4, duration: 2.1, drift: 0.12)
        }
    }

    // MARK: - longBreak · "Cheer" (3.2s)

    /// Four sessions done. He springs up higher than the other two, throws both
    /// arms overhead and cheers, bouncing on the spot.
    @KeyframesBuilder<SamuraiPose>
    public static var triumph: some Keyframes<SamuraiPose> {
        KeyframeTrack(\.emergence) {
            CubicKeyframe(170, duration: 0.10)           // crest peeks — a beat
            LinearKeyframe(170, duration: 0.10)
            SpringKeyframe(-26, duration: 0.28, spring: .init(response: 0.32, dampingRatio: 0.48))
            SpringKeyframe(-8, duration: 0.18, spring: .init(response: 0.32, dampingRatio: 0.55))
            // Three cheering bounces on the spot.
            CubicKeyframe(-22, duration: 0.22)
            CubicKeyframe(-8, duration: 0.22)
            CubicKeyframe(-20, duration: 0.22)
            CubicKeyframe(-8, duration: 0.22)
            CubicKeyframe(-18, duration: 0.22)
            CubicKeyframe(-8, duration: 0.22)
            LinearKeyframe(-8, duration: 0.62)
            CubicKeyframe(200, duration: 0.30)
        }
        KeyframeTrack(\.rootScaleY) {
            LinearKeyframe(0.90, duration: 0.20)         // crouch, then launch
            SpringKeyframe(1.08, duration: 0.28, spring: .init(response: 0.32, dampingRatio: 0.48))
            SpringKeyframe(1.0, duration: 0.18, spring: .init(response: 0.32, dampingRatio: 0.55))
            Hold.moving(1.0, duration: 2.24, drift: 0.014)
            CubicKeyframe(1.04, duration: 0.30)
        }
        // Both arms punch overhead — the cheer.
        KeyframeTrack(\.swordArmUpper) {
            LinearKeyframe(0, duration: 0.28)
            SpringKeyframe(-62, duration: 0.28, spring: .init(response: 0.30, dampingRatio: 0.48))
            SpringKeyframe(-55, duration: 0.16, spring: .init(response: 0.30, dampingRatio: 0.55))
            Hold.moving(-55, duration: 1.98, drift: 1.8)
            CubicKeyframe(-10, duration: 0.30)
            LinearKeyframe(-10, duration: 0.20)
        }
        KeyframeTrack(\.swordFore) {
            LinearKeyframe(0, duration: 0.28)
            SpringKeyframe(-14, duration: 0.44, spring: .init(response: 0.30, dampingRatio: 0.50))
            Hold.moving(-14, duration: 1.98, drift: 1.8)
            CubicKeyframe(0, duration: 0.50)
        }
        KeyframeTrack(\.katana) {
            LinearKeyframe(0, duration: 0.34)
            SpringKeyframe(16, duration: 0.40, spring: .init(response: 0.35, dampingRatio: 0.45))
            Hold.moving(16, duration: 1.96, drift: 1.8)
            CubicKeyframe(0, duration: 0.50)
        }
        KeyframeTrack(\.offArmUpper) {
            LinearKeyframe(0, duration: 0.34)
            SpringKeyframe(-78, duration: 0.26, spring: .init(response: 0.32, dampingRatio: 0.48))
            SpringKeyframe(-68, duration: 0.16, spring: .init(response: 0.32, dampingRatio: 0.55))
            Hold.moving(-68, duration: 1.94, drift: 1.8)
            CubicKeyframe(0, duration: 0.50)
        }
        KeyframeTrack(\.offArmFore) {
            LinearKeyframe(0, duration: 0.34)
            SpringKeyframe(-46, duration: 0.42, spring: .init(response: 0.32, dampingRatio: 0.50))
            Hold.moving(-46, duration: 1.94, drift: 1.8)
            CubicKeyframe(0, duration: 0.50)
        }
        KeyframeTrack(\.head) {
            LinearKeyframe(0, duration: 0.34)
            CubicKeyframe(-11, duration: 0.24)           // chin up, looking skyward
            Hold.breathing(-11, duration: 2.12, drift: 1.8)
            CubicKeyframe(0, duration: 0.50)
        }
        KeyframeTrack(\.kabutoLift) {
            LinearKeyframe(0, duration: 0.56)
            SpringKeyframe(-4, duration: 0.18, spring: .init(response: 0.35, dampingRatio: 0.42))
            SpringKeyframe(0, duration: 0.24, spring: .init(response: 0.35, dampingRatio: 0.45))
            Hold.moving(0, duration: 1.92, drift: 0.5)
            CubicKeyframe(-3, duration: 0.30)
        }
        KeyframeTrack(\.maedate) {
            LinearKeyframe(0, duration: 0.62)
            SpringKeyframe(15, duration: 0.16, spring: .init(response: 0.50, dampingRatio: 0.28))
            SpringKeyframe(-11, duration: 0.16, spring: .init(response: 0.50, dampingRatio: 0.28))
            SpringKeyframe(0, duration: 0.16, spring: .init(response: 0.50, dampingRatio: 0.30))
            // Wobbles again on every bounce.
            CubicKeyframe(9, duration: 0.22)
            CubicKeyframe(0, duration: 0.22)
            CubicKeyframe(8, duration: 0.22)
            CubicKeyframe(0, duration: 0.22)
            Hold.moving(0, duration: 0.92, drift: 1.8)
            CubicKeyframe(-12, duration: 0.30)
        }
        KeyframeTrack(\.rootLean) {
            Hold.moving(0, duration: 0.9, drift: 1.8)
            CubicKeyframe(-4, duration: 0.30)
            CubicKeyframe(4, duration: 0.44)
            CubicKeyframe(-3, duration: 0.44)
            CubicKeyframe(0, duration: 0.42)
            LinearKeyframe(0, duration: 0.70)
        }
        KeyframeTrack(\.kusazuriL) {
            LinearKeyframe(-15, duration: 0.30)
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.50, dampingRatio: 0.38))
            Hold.moving(0, duration: 2.5, drift: 1.8)
        }
        KeyframeTrack(\.kusazuriFL) {
            LinearKeyframe(-10, duration: 0.36)
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.50, dampingRatio: 0.38))
            Hold.moving(0, duration: 2.44, drift: 1.8)
        }
        KeyframeTrack(\.kusazuriFR) {
            LinearKeyframe(10, duration: 0.42)
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.50, dampingRatio: 0.38))
            Hold.moving(0, duration: 2.38, drift: 1.8)
        }
        KeyframeTrack(\.kusazuriR) {
            LinearKeyframe(15, duration: 0.48)
            SpringKeyframe(0, duration: 0.40, spring: .init(response: 0.50, dampingRatio: 0.38))
            Hold.moving(0, duration: 2.32, drift: 1.8)
        }
        KeyframeTrack(\.sashTailL) {
            LinearKeyframe(-24, duration: 0.32)
            SpringKeyframe(0, duration: 0.44, spring: .init(response: 0.60, dampingRatio: 0.32))
            Hold.moving(0, duration: 2.44, drift: 1.8)
        }
        KeyframeTrack(\.sashTailR) {
            LinearKeyframe(24, duration: 0.32)
            SpringKeyframe(0, duration: 0.44, spring: .init(response: 0.60, dampingRatio: 0.32))
            Hold.moving(0, duration: 2.44, drift: 1.8)
        }
        KeyframeTrack(\.fierceOpacity) {
            LinearKeyframe(1, duration: 0.50)
            LinearKeyframe(0, duration: 0.14)
            LinearKeyframe(0, duration: 2.56)
        }
        KeyframeTrack(\.triumphOpacity) {
            LinearKeyframe(0, duration: 0.50)
            LinearKeyframe(1, duration: 0.14)
            LinearKeyframe(1, duration: 2.56)
        }
    }
}
