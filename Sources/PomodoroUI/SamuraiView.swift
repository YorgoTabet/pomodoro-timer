import CoreGraphics
import SwiftUI

/// The animatable state of the samurai rig.
///
/// One rotation per joint plus the handful of offsets, scales and opacities the
/// timelines actually use. Keyframe timelines interpolate this whole struct, so a
/// row in the art direction maps to a `KeyframeTrack` on one property.
public struct SamuraiPose: Equatable, Sendable {

    /// How far the character is displaced back behind the pill, in design units.
    /// 200 = fully hidden, 0 = fully risen, negative = overshoot above the edge.
    public var emergence: Double = 200
    public var rootLean: Double = 0
    public var rootScaleY: Double = 1
    /// Uniform scale — reads as stepping toward the viewer.
    public var rootScale: Double = 1

    public var torso: Double = 0
    public var torsoScaleY: Double = 1
    public var head: Double = 0
    public var headScale: Double = 1
    public var kabuto: Double = 0
    public var kabutoLift: Double = 0
    public var maedate: Double = 0

    public var sodeL: Double = 0
    public var sodeR: Double = 0
    public var offArmUpper: Double = 0
    public var offArmFore: Double = 0
    public var swordArmUpper: Double = 0
    public var swordFore: Double = 0
    public var katana: Double = 0

    public var chestCord: Double = 0
    public var sashTailL: Double = 0
    public var sashTailR: Double = 0
    public var kusazuriL: Double = 0
    public var kusazuriFL: Double = 0
    public var kusazuriFR: Double = 0
    public var kusazuriR: Double = 0
    public var scabbard: Double = 0
    public var legL: Double = 0
    public var legR: Double = 0

    /// Expression cross-fades. The menpo hides the mouth, so the brows and eyes do
    /// all the acting.
    public var fierceOpacity: Double = 1
    public var easeOpacity: Double = 0
    public var triumphOpacity: Double = 0
    public var pupilDrop: Double = 0

    public init() {}

    /// Rotation in degrees for a rig part.
    func rotation(of part: SamuraiArt.Part) -> Double {
        switch part {
        case .root: rootLean
        case .torso: torso
        case .head: head
        case .kabuto: kabuto
        case .maedate: maedate
        case .sodeL: sodeL
        case .sodeR: sodeR
        case .offArmUpper: offArmUpper
        case .offArmFore: offArmFore
        case .swordArmUpper: swordArmUpper
        case .swordFore: swordFore
        case .katana: katana
        case .chestCord: chestCord
        case .sashTailL: sashTailL
        case .sashTailR: sashTailR
        case .kusazuriL: kusazuriL
        case .kusazuriFL: kusazuriFL
        case .kusazuriFR: kusazuriFR
        case .kusazuriR: kusazuriR
        case .scabbard: scabbard
        case .legL: legL
        case .legR: legR
        }
    }

    /// Opacity override for the cross-faded expression layers.
    func opacity(of layer: SamuraiArt.Layer) -> Double {
        switch layer.name {
        case "browsFierce", "eyeWhites", "pupilPair": fierceOpacity
        case "browsEase": easeOpacity
        case "eyesTriumph": triumphOpacity
        default: layer.restOpacity
        }
    }
}

/// The samurai, drawn from `SamuraiArt`'s path data.
///
/// Draw order is global and independent of the rig, so transforms are composed per
/// layer from its ancestor chain rather than by nesting groups — `shikoro` belongs
/// to `kabuto` but must be drawn behind the body.
public struct SamuraiView: View {

    public static let canvas = SamuraiArt.canvas

    let pose: SamuraiPose

    public init(pose: SamuraiPose) {
        self.pose = pose
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(SamuraiArt.layers) { layer in
                rigged(layer)
            }
        }
        .frame(width: Self.canvas.width, height: Self.canvas.height, alignment: .topLeading)
        .scaleEffect(y: pose.rootScaleY, anchor: .bottom)
        .scaleEffect(pose.rootScale, anchor: .bottom)
        .rotationEffect(.degrees(pose.rootLean), anchor: SamuraiArt.Part.root.anchor)
    }

    /// One layer, wrapped in its ancestors' rotations from the torso down.
    ///
    /// `root` is handled once on the whole stack instead of per layer — it carries
    /// the emergence offset and the body scale, which are not per-part transforms.
    @ViewBuilder
    private func rigged(_ layer: SamuraiArt.Layer) -> some View {
        let chain = layer.part.chain.filter { $0 != .root }
        let opacity = pose.opacity(of: layer)

        if opacity > 0 {
            chain.reduce(AnyView(shape(layer))) { view, part in
                AnyView(
                    view
                        .rotationEffect(.degrees(pose.rotation(of: part)), anchor: part.anchor)
                        .modifier(PartExtras(part: part, pose: pose))
                )
            }
            .opacity(opacity)
        }
    }

    private func shape(_ layer: SamuraiArt.Layer) -> some View {
        ZStack(alignment: .topLeading) {
            layer.path.fill(layer.fill)
            if let width = layer.stroke {
                layer.path.stroke(
                    SamuraiArt.Ink.outline,
                    style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .frame(width: Self.canvas.width, height: Self.canvas.height, alignment: .topLeading)
    }
}

/// The few parts that move by more than a rotation.
private struct PartExtras: ViewModifier {
    let part: SamuraiArt.Part
    let pose: SamuraiPose

    func body(content: Content) -> some View {
        switch part {
        case .torso:
            content.scaleEffect(y: pose.torsoScaleY, anchor: UnitPoint(x: 0.5, y: 168.0 / 260.0))
        case .head:
            content.scaleEffect(pose.headScale, anchor: SamuraiArt.Part.head.anchor)
        case .kabuto:
            // "Cap pops" — the helmet lifts a beat off the head on hard accents.
            content.offset(y: pose.kabutoLift)
        default:
            content
        }
    }
}
