import AppKit
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
    public static let displayHeight: Double = 150

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
    public static let margin: Double = 168

    let character: PomodoroCharacter
    let cue: CharacterCue?
    let edge: StageEdge
    /// The pill's frame inside the panel's coordinate space.
    let pillFrame: CGRect

    public init(character: PomodoroCharacter, cue: CharacterCue?, edge: StageEdge, pillFrame: CGRect) {
        self.character = character
        self.cue = cue
        self.edge = edge
        self.pillFrame = pillFrame
    }

    public var body: some View {
        if let cue, character != .none {
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
        default:
            // Declared in the roster but not drawn yet.
            EmptyView()
        }
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
                .modifier(StagePlacement(edge: edge, pillFrame: pillFrame, box: CharacterStage.displaySize))
                .transition(.opacity.animation(.easeInOut(duration: 0.4)))
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
        @KeyframesBuilder<SamuraiPose> _ track: @escaping () -> K
    ) -> some View {
        KeyframeAnimator(initialValue: SamuraiPose(), trigger: cue) { pose in
            SamuraiView(pose: pose)
                // `emergence` is authored as "how far behind the pill", so it moves
                // against the inward normal.
                .offset(
                    x: -pose.emergence * edge.inwardNormal.x,
                    y: -pose.emergence * edge.inwardNormal.y
                )
                .modifier(StagePlacement(edge: edge, pillFrame: pillFrame, box: SamuraiView.canvas))
        } keyframes: { _ in
            track()
        }
    }

    /// Maps the authored 0…200 emergence scale onto the real distance this edge
    /// needs, so "hidden" means hidden on every side.
    private func hidden(_ emergence: Double) -> Double {
        emergence / 200 * CharacterStage.hideDistance(for: edge)
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

    func body(content: Content) -> some View {
        content
            .frame(width: box.width, height: box.height)
            .position(x: origin.x, y: origin.y)
            .mask(alignment: .topLeading) {
                maskShape
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
    private var maskShape: some View {
        GeometryReader { geometry in
            let full = CGRect(origin: .zero, size: geometry.size)
            Rectangle()
                .path(in: visibleRegion(in: full))
                .fill(Color.black)
        }
    }

    private func visibleRegion(in full: CGRect) -> CGRect {
        switch edge {
        case .top:
            CGRect(x: full.minX, y: full.minY, width: full.width, height: pillFrame.minY - full.minY)
        case .bottom:
            CGRect(x: full.minX, y: pillFrame.maxY, width: full.width, height: full.maxY - pillFrame.maxY)
        case .leading:
            CGRect(x: full.minX, y: full.minY, width: pillFrame.minX - full.minX, height: full.height)
        case .trailing:
            CGRect(x: pillFrame.maxX, y: full.minY, width: full.maxX - pillFrame.maxX, height: full.height)
        }
    }
}
