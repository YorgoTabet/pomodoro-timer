import AppKit
import os
import PomodoroCore
import SwiftUI

/// Runs a character's performance beside the pill.
///
/// Owns *when and where*: which edge to emerge from, how to mask the hidden body,
/// and driving the clock. It knows nothing about what any particular character looks
/// like — that lives in the character views.
public struct CharacterStage: View {

    /// Target on-screen height. The art carries far more detail than the old
    /// 44pt chibi could, and needs room for it.
    /// Sized against the 46pt pill, not against the artwork's own detail. At 150pt
    /// he dwarfed the widget; at 96 he reads as standing on it.
    public static let displayHeight: Double = 96

    /// Scale from the 200×260 design space to `displayHeight`.
    public static var scale: Double { displayHeight / SamuraiArt.canvas.height }

    public static var displaySize: CGSize {
        CGSize(width: SamuraiArt.canvas.width * scale, height: displayHeight)
    }

    /// Where the character's feet are, measured from the top of its box.
    ///
    /// The art is authored with the occluding edge at design y=196, not at the
    /// bottom of the 260-unit canvas — the last 64 units are body that is meant to
    /// be hidden. Aligning this line to the pill's edge is what makes him stand on
    /// it rather than float above it.
    public static var groundInset: Double { 196 * scale }

    /// How far the character must travel to be completely out of sight past a given
    /// edge. Authored `emergence` is a 0…200 scale, so it is mapped onto this.
    static func hideDistance(for edge: StageEdge) -> Double {
        switch edge {
        case .top: groundInset
        case .bottom: displaySize.height
        case .leading, .trailing: displaySize.width
        }
    }

    /// Transparent room on every side of the pill: enough for the character plus
    /// the pill's own 15% growth.
    public static let margin: Double = 110

    let character: PomodoroCharacter
    let cue: CharacterCue
    /// Changes once per performance; the animator plays when it does.
    let generation: Int
    /// Drawn in front of the pill instead of behind it, and unmasked.
    let foreground: Bool
    let edge: StageEdge
    /// The pill's frame inside the panel's coordinate space.
    let pillFrame: CGRect

    public init(character: PomodoroCharacter, cue: CharacterCue, generation: Int,
                foreground: Bool, edge: StageEdge, pillFrame: CGRect) {
        self.character = character
        self.cue = cue
        self.generation = generation
        self.foreground = foreground
        self.edge = edge
        self.pillFrame = pillFrame
    }

    public var body: some View {
        // Mounted whenever a character is chosen, not only during a performance:
        // the animator has to exist *before* the trigger changes. At rest its
        // initial pose is fully hidden behind the pill, so nothing is drawn.
        // No `generation > 0` gate. KeyframeAnimator only animates when its trigger
        // *changes*, so it must already be mounted when the cue fires — gating on
        // generation meant it appeared with the trigger final and sat at its initial
        // pose forever. At rest that pose is fully hidden, so mounting costs nothing.
        if character != .none, character.isImplemented {
            performance(cue)
                // Purely decorative: the stage must never intercept a click meant
                // for whatever is behind the transparent panel.
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func performance(_ cue: CharacterCue) -> some View {
        switch character {
        case .samurai:
            samurai(cue)
        case .ninja:
            ninja(cue)
        case .general:
            general(cue)
        default:
            // Declared in the roster but not drawn yet.
            EmptyView()
        }
    }

    // MARK: - General

    @ViewBuilder
    private func general(_ cue: CharacterCue) -> some View {
        if reduceMotion {
            GeneralView(pose: generalRestingPose)
                .scaleEffect(CharacterStage.scale, anchor: .topLeading)
                .frame(width: CharacterStage.displaySize.width,
                       height: CharacterStage.displaySize.height,
                       alignment: .topLeading)
                .modifier(StagePlacement(edge: edge, pillFrame: pillFrame,
                                         box: CharacterStage.displaySize, masked: !foreground))
                .transition(.opacity.animation(.easeInOut(duration: 0.4)))
        } else {
            switch cue {
            case .focusStart: generalAnimator { GeneralPerformance.backToTheFront }
            case .breakStart: generalAnimator { GeneralPerformance.atEase }
            case .longBreak: generalAnimator { GeneralPerformance.paradeOfOne }
            }
        }
    }

    private func generalAnimator<K: Keyframes<GeneralPose>>(
        @KeyframesBuilder<GeneralPose> _ track: @escaping () -> K
    ) -> some View {
        KeyframeAnimator(initialValue: GeneralPose(), trigger: generation) { pose in
            GeneralView(pose: pose)
                .opacity(pose.emergence >= 185 ? 0 : 1)
                .scaleEffect(CharacterStage.scale, anchor: .topLeading)
                .frame(width: CharacterStage.displaySize.width,
                       height: CharacterStage.displaySize.height,
                       alignment: .topLeading)
                .offset(
                    x: -hidden(pose.emergence) * edge.inwardNormal.x,
                    y: -hidden(pose.emergence) * edge.inwardNormal.y
                )
                .modifier(StagePlacement(edge: edge, pillFrame: pillFrame,
                                         box: CharacterStage.displaySize, masked: !foreground))
        } keyframes: { _ in
            track()
        }
    }

    private var generalRestingPose: GeneralPose {
        var pose = GeneralPose()
        pose.emergence = 0
        return pose
    }

    // MARK: - Ninja

    @ViewBuilder
    private func ninja(_ cue: CharacterCue) -> some View {
        if reduceMotion {
            NinjaView(pose: ninjaRestingPose)
                .scaleEffect(CharacterStage.scale, anchor: .topLeading)
                .frame(width: CharacterStage.displaySize.width,
                       height: CharacterStage.displaySize.height,
                       alignment: .topLeading)
                .modifier(StagePlacement(edge: edge, pillFrame: pillFrame,
                                         box: CharacterStage.displaySize, masked: !foreground))
                .transition(.opacity.animation(.easeInOut(duration: 0.4)))
        } else if let held = ProcessInfo.processInfo.environment["POMODORO_HOLD"] {
            NinjaView(pose: ninjaHeldPose(named: held))
                .scaleEffect(CharacterStage.scale, anchor: .topLeading)
                .frame(width: CharacterStage.displaySize.width,
                       height: CharacterStage.displaySize.height,
                       alignment: .topLeading)
                .modifier(StagePlacement(edge: edge, pillFrame: pillFrame,
                                         box: CharacterStage.displaySize, masked: !foreground))
        } else {
            switch cue {
            case .focusStart: ninjaAnimator { NinjaPerformance.shurikenThrow }
            case .breakStart: ninjaAnimator { NinjaPerformance.perch }
            case .longBreak: ninjaAnimator { NinjaPerformance.backflip }
            }
        }
    }

    private func ninjaAnimator<K: Keyframes<NinjaPose>>(
        @KeyframesBuilder<NinjaPose> _ track: @escaping () -> K
    ) -> some View {
        KeyframeAnimator(initialValue: NinjaPose(), trigger: generation) { pose in
            NinjaView(pose: pose)
                .opacity(pose.emergence >= 185 ? 0 : 1)
                .scaleEffect(CharacterStage.scale, anchor: .topLeading)
                .frame(width: CharacterStage.displaySize.width,
                       height: CharacterStage.displaySize.height,
                       alignment: .topLeading)
                .offset(
                    x: -hidden(pose.emergence) * edge.inwardNormal.x,
                    y: -hidden(pose.emergence) * edge.inwardNormal.y
                )
                .modifier(StagePlacement(edge: edge, pillFrame: pillFrame,
                                         box: CharacterStage.displaySize, masked: !foreground))
        } keyframes: { _ in
            track()
        }
    }

    /// Development aid, matching `heldPose` — a representative frame per cue.
    private func ninjaHeldPose(named name: String) -> NinjaPose {
        var pose = NinjaPose()
        pose.emergence = 0
        switch name {
        case "breakStart":
            pose.emergence = 52
            pose.torso = 9
            pose.head = -13
            pose.alertOpacity = 0
            pose.contentOpacity = 1
            pose.throwArmUpper = -10
            pose.throwForearm = -16
            pose.offArmUpper = 12
        case "longBreak":
            pose.emergence = -58
            pose.figureRotation = -240
            pose.legFrontThigh = -62
            pose.legFrontShin = 74
            pose.legBackThigh = -48
            pose.legBackShin = 62
            pose.throwArmUpper = -54
            pose.offArmUpper = 48
            pose.eyesScaleY = 0.55
            pose.sparkOpacity = 1
        default:                       // focusStart
            pose.throwArmUpper = 38
            pose.throwForearm = 58
            pose.torso = -10
            pose.head = 5
            pose.eyesScaleY = 0.62
            pose.shurikenOpacity = 0
        }
        return pose
    }

    private var ninjaRestingPose: NinjaPose {
        var pose = NinjaPose()
        pose.emergence = 0
        return pose
    }

    // MARK: - Samurai

    @ViewBuilder
    private func samurai(_ cue: CharacterCue) -> some View {
        if reduceMotion {
            // Reduce Motion: no leaping, spinning, or bouncing. The character simply
            // appears at its risen pose, holds, and fades.
            SamuraiView(pose: restingPose)
                .scaleEffect(CharacterStage.scale, anchor: .topLeading)
                .frame(width: CharacterStage.displaySize.width, height: CharacterStage.displaySize.height, alignment: .topLeading)
                .modifier(StagePlacement(edge: edge, pillFrame: pillFrame, box: CharacterStage.displaySize, masked: !foreground))
                .transition(.opacity.animation(.easeInOut(duration: 0.4)))
        } else if let held = ProcessInfo.processInfo.environment["POMODORO_HOLD"] {
            // Development aid: hold a pose instead of animating, so placement and
            // scale can be judged from a single screenshot rather than by trying
            // to catch a 2.5-second performance mid-flight.
            SamuraiView(pose: heldPose(named: held))
                .scaleEffect(CharacterStage.scale, anchor: .topLeading)
                .frame(width: CharacterStage.displaySize.width,
                       height: CharacterStage.displaySize.height,
                       alignment: .topLeading)
                .modifier(StagePlacement(edge: edge, pillFrame: pillFrame,
                                         box: CharacterStage.displaySize, masked: !foreground))
        } else {
            // Each performance is its own opaque `Keyframes` type, so the switch
            // happens here in a ViewBuilder — which can unify branches — rather than
            // inside a `@KeyframesBuilder`, which cannot.
            switch cue {
            case .focusStart: samuraiAnimator(cue) { SamuraiPerformance.snapToGuard }
            case .breakStart: samuraiAnimator(cue) { SamuraiPerformance.exhale }
            case .longBreak: samuraiAnimator(cue) { SamuraiPerformance.triumph }
            }
        }
    }

    private func samuraiAnimator<K: Keyframes<SamuraiPose>>(
        _ cue: CharacterCue,
        generation _: Int = 0,
        @KeyframesBuilder<SamuraiPose> _ track: @escaping () -> K
    ) -> some View {
        KeyframeAnimator(initialValue: SamuraiPose(), trigger: generation) { pose in
            SamuraiView(pose: pose)
                // Invisible at both ends of every timeline. The mask cannot be
                // relied on for this: cues that step in front of the pill run
                // unmasked, which left the resting pose parked in plain sight below
                // the widget. Opacity works for masked and unmasked alike.
                .opacity(pose.emergence >= 185 ? 0 : 1)
                // `scaleEffect` does not change reported layout size, so the frame
                // needs .topLeading or the still-200x260 content gets centred and
                // shifted out of the mask.
                .scaleEffect(CharacterStage.scale, anchor: .topLeading)
                .frame(width: CharacterStage.displaySize.width,
                       height: CharacterStage.displaySize.height,
                       alignment: .topLeading)
                // `emergence` is authored as "how far behind the pill" on a 0…200
                // scale, mapped onto the distance this edge actually needs.
                .offset(
                    x: -hidden(pose.emergence) * edge.inwardNormal.x,
                    y: -hidden(pose.emergence) * edge.inwardNormal.y
                )
                .modifier(StagePlacement(edge: edge, pillFrame: pillFrame,
                                         box: CharacterStage.displaySize, masked: !foreground))
        } keyframes: { _ in
            track()
        }
    }

    /// Maps the authored 0…200 emergence scale onto the real distance this edge
    /// needs, so "hidden" means hidden on every side.
    private func hidden(_ emergence: Double) -> Double {
        emergence / 200 * hideDistance
    }

    /// Far enough that the resting pose clears the mask entirely.
    ///
    /// Using just the character's height left his head inside the pill, where the
    /// translucent glass showed him faintly at rest. The pill's own depth has to be
    /// included because the mask cuts at its far edge, not its near one.
    private var hideDistance: Double {
        switch edge {
        case .top, .bottom: CharacterStage.displaySize.height + pillFrame.height
        case .leading, .trailing: CharacterStage.displaySize.width + pillFrame.width
        }
    }

    /// Key poses from the three timelines, for the hold aid above.
    private func heldPose(named name: String) -> SamuraiPose {
        var p = SamuraiPose()
        p.emergence = 0
        switch name {
        case "focusStart":
            p.rootScale = 1.06; p.swordArmUpper = 24; p.swordFore = 52
            p.katana = -18; p.torso = -6; p.head = 4; p.pupilDrop = -0.9
        case "breakStart":
            p.emergence = 38; p.rootLean = 7; p.head = 11; p.kabuto = 5
            p.swordArmUpper = 22; p.swordFore = 10; p.katana = -16
            p.torsoScaleY = 0.96; p.sodeL = 8; p.sodeR = -8
            p.fierceOpacity = 0; p.easeOpacity = 1; p.pupilDrop = 1.4
        case "longBreak":
            p.emergence = -8; p.swordArmUpper = -55; p.swordFore = -14; p.katana = 16
            p.offArmUpper = -68; p.offArmFore = -46; p.head = -11
            p.fierceOpacity = 0; p.triumphOpacity = 1
        default: break
        }
        return p
    }

    private var restingPose: SamuraiPose {
        var pose = SamuraiPose()
        pose.emergence = 0
        return pose
    }

    private var reduceMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }
}

/// Positions and masks the character relative to the pill.
///
/// The mask matters: the pill is Liquid Glass, so it is translucent. Without
/// clipping, the character's hidden lower body would ghost faintly through it
/// instead of looking like it is behind a solid object.
struct StagePlacement: ViewModifier {
    let edge: StageEdge
    let pillFrame: CGRect
    let box: CGSize
    /// Clipped to the region beyond the pill's edge. Off when the character has
    /// stepped in front of the pill, where the whole body should be visible.
    let masked: Bool

    func body(content: Content) -> some View {
        content
            .frame(width: box.width, height: box.height)
            .position(x: origin.x, y: origin.y)
            .mask(alignment: .topLeading) {
                if masked { maskShape } else { Rectangle() }
            }
    }

    /// Centre of the character's box, in panel coordinates, when fully risen.
    private var origin: CGPoint {
        switch edge {
        case .top:
            // Feet on the pill's top edge; the unused lower body falls past it and
            // is masked away.
            CGPoint(x: pillFrame.midX, y: pillFrame.minY - CharacterStage.groundInset + box.height / 2)
        case .bottom:
            CGPoint(x: pillFrame.midX, y: pillFrame.maxY + box.height / 2)
        case .leading:
            CGPoint(x: pillFrame.minX - box.width / 2, y: pillFrame.maxY - CharacterStage.groundInset + box.height / 2)
        case .trailing:
            CGPoint(x: pillFrame.maxX + box.width / 2, y: pillFrame.maxY - CharacterStage.groundInset + box.height / 2)
        }
    }

    /// Everything beyond the pill's edge on the emergence side, and nothing on the
    /// pill itself.
    ///
    /// Built from aligned frames rather than a `GeometryReader` drawing a `Path`.
    /// The previous version masked the character away entirely: a mask must cover
    /// the content it masks, and a path drawn in a reader's own coordinate space
    /// did not line up with the positioned content it was applied to.
    @ViewBuilder
    private var maskShape: some View {
        switch edge {
        case .top:
            // Cut at the pill's *bottom* edge rather than its top.
            //
            // Cutting at the top edge is geometrically ideal but unforgiving: the
            // character passes through that line during the rise, so any error in
            // placement or timing removes him entirely rather than partially — which
            // is exactly what happened. Cutting lower still kills the real artifact
            // (a body dangling below the widget) while tolerating both.
            Rectangle()
                .frame(height: max(pillFrame.maxY, 0))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        case .bottom:
            Rectangle()
                .padding(.top, max(pillFrame.maxY, 0))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        case .leading:
            Rectangle()
                .frame(width: max(pillFrame.minX, 0))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        case .trailing:
            Rectangle()
                .padding(.leading, max(pillFrame.maxX, 0))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        }
    }

}
