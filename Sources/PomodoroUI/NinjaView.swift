import CoreGraphics
import PomodoroCore
import SwiftUI

/// The animatable state of the ninja rig.
///
/// Parallels `SamuraiPose`: one field per joint the timelines move, plus the
/// figure-level transforms the backflip needs (`figureRotation`, `figureScaleY`).
public struct NinjaPose: Equatable, Sendable {

    /// Design units behind the pill edge. 200 = hidden, 0 = risen.
    public var emergence: Double = 200

    /// Whole-body transforms, applied at the `figure` wrapper so the emergence
    /// offset (on `root`) is not dragged into the flip.
    public var figureRotation: Double = 0
    public var figureScaleY: Double = 1

    public var torso: Double = 0
    public var head: Double = 0
    public var eyesScaleY: Double = 1
    public var eyesOffsetX: Double = 0
    public var ribbonNear: Double = 0
    public var ribbonFar: Double = 0

    public var throwArmUpper: Double = 0
    public var throwForearm: Double = 0
    public var shuriken: Double = 0
    public var shurikenOpacity: Double = 1
    public var offArmUpper: Double = 0
    public var offForearm: Double = 0
    public var ninjato: Double = 0
    public var sashTail: Double = 0

    public var legFrontThigh: Double = 0
    public var legFrontShin: Double = 0
    public var legBackThigh: Double = 0
    public var legBackShin: Double = 0

    /// Expression cross-fades. The eye slit does all the acting.
    public var alertOpacity: Double = 1     // whites + pupils + lids
    public var contentOpacity: Double = 0   // ∩ crescents
    public var sparkOpacity: Double = 0

    /// The smoke-bomb burst.
    public var smokeOpacity: Double = 0
    public var smokeScale: Double = 0.5

    public init() {}

    func rotation(of part: NinjaArt.Part) -> Double {
        switch part {
        case .figure: figureRotation
        case .torso: torso
        case .head: head
        case .ribbonNear: ribbonNear
        case .ribbonFar: ribbonFar
        case .throwArmUpper: throwArmUpper
        case .throwForearm: throwForearm
        case .shuriken: shuriken
        case .offArmUpper: offArmUpper
        case .offForearm: offForearm
        case .ninjato: ninjato
        case .sashTail: sashTail
        case .legFrontThigh: legFrontThigh
        case .legFrontShin: legFrontShin
        case .legBackThigh: legBackThigh
        case .legBackShin: legBackShin
        case .root, .eyes, .smoke: 0
        }
    }

    func opacity(of layer: NinjaArt.Layer) -> Double {
        switch layer.name {
        case "eyeWhiteL", "eyeWhiteR", "pupilL", "pupilR", "lidL", "lidR": alertOpacity
        case "contentEyeL", "contentEyeR": contentOpacity
        case "sparkL", "sparkR": sparkOpacity
        case "shurikenStar", "shurikenHole": shurikenOpacity
        case "puffA", "puffB", "puffC": smokeOpacity
        default: layer.restOpacity
        }
    }
}

/// The ninja, drawn from `NinjaArt`'s path data. Structure mirrors `SamuraiView`.
public struct NinjaView: View {

    public static let canvas = NinjaArt.canvas

    let pose: NinjaPose

    public init(pose: NinjaPose) { self.pose = pose }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(NinjaArt.layers) { layer in
                rigged(layer)
            }
        }
        .frame(width: Self.canvas.width, height: Self.canvas.height, alignment: .topLeading)
    }

    @ViewBuilder
    private func rigged(_ layer: NinjaArt.Layer) -> some View {
        // `root` carries nothing here — emergence is applied by the stage — so it is
        // dropped from the chain like it is for the samurai.
        let chain = layer.part.chain.filter { $0 != .root }.reversed()
        let opacity = pose.opacity(of: layer)

        if opacity > 0 {
            // Leaf-first, root-last. SwiftUI applies modifiers bottom-up, so the
            // ancestor's rotation must wrap the child's — otherwise the child's
            // anchor is evaluated against already-rotated content and the part
            // flies off its joint. Small angles hid this; a full backflip did not.
            chain.reduce(AnyView(shape(layer))) { view, part in
                AnyView(
                    view
                        .rotationEffect(.degrees(pose.rotation(of: part)), anchor: part.anchor)
                        .modifier(NinjaPartExtras(part: part, pose: pose))
                )
            }
            .opacity(opacity)
        }
    }

    private func shape(_ layer: NinjaArt.Layer) -> some View {
        ZStack(alignment: .topLeading) {
            layer.path.fill(layer.fill)
            if let width = layer.stroke {
                layer.path.stroke(
                    NinjaArt.Ink.outline,
                    style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .frame(width: Self.canvas.width, height: Self.canvas.height, alignment: .topLeading)
    }
}

/// Parts that move by more than a rotation.
private struct NinjaPartExtras: ViewModifier {
    let part: NinjaArt.Part
    let pose: NinjaPose

    func body(content: Content) -> some View {
        switch part {
        case .figure:
            content.scaleEffect(y: pose.figureScaleY, anchor: NinjaArt.Part.figure.anchor)
        case .eyes:
            content
                .scaleEffect(y: pose.eyesScaleY, anchor: NinjaArt.Part.eyes.anchor)
                .offset(x: pose.eyesOffsetX)
        case .smoke:
            content.scaleEffect(pose.smokeScale, anchor: NinjaArt.Part.smoke.anchor)
        default:
            content
        }
    }
}
