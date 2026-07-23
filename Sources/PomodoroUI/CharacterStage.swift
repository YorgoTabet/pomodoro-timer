import AppKit
import PomodoroCore
import SwiftUI

/// Runs a character's performance beside the pill.
///
/// Owns *when and where*: which edge to emerge from, how to mask the hidden body,
/// and driving the clock. It knows nothing about what any particular character looks
/// like — that lives in the character views.
public struct CharacterStage: View {

    public static let margin: Double = 64

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
                .modifier(StagePlacement(edge: edge, pillFrame: pillFrame, box: SamuraiView.boxSize))
                .transition(.opacity.animation(.easeInOut(duration: 0.4)))
        } else {
            // Each performance is its own opaque `Keyframes` type, so the switch
            // happens here in a ViewBuilder — which can unify branches — rather than
            // inside a `@KeyframesBuilder`, which cannot.
            switch cue {
            case .focusStart: samuraiAnimator(cue) { SamuraiPerformance.iaiDraw }
            case .breakStart: samuraiAnimator(cue) { SamuraiPerformance.sheatheAndExhale }
            case .longBreak: samuraiAnimator(cue) { SamuraiPerformance.bladeToTheSky }
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
                .modifier(StagePlacement(edge: edge, pillFrame: pillFrame, box: SamuraiView.boxSize))
        } keyframes: { _ in
            track()
        }
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
            CGPoint(x: pillFrame.midX, y: pillFrame.minY - box.height / 2)
        case .bottom:
            CGPoint(x: pillFrame.midX, y: pillFrame.maxY + box.height / 2)
        case .leading:
            CGPoint(x: pillFrame.minX - box.width / 2, y: pillFrame.midY)
        case .trailing:
            CGPoint(x: pillFrame.maxX + box.width / 2, y: pillFrame.midY)
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
