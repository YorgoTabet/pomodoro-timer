import CoreGraphics
import SwiftUI

/// A joint in a character's skeleton.
///
/// Conforming types are the per-character `Part` enums. Everything below the
/// protocol — anchor conversion, ancestor chains, and the draw logic in `RigView` —
/// is shared, so a fix lands once instead of once per character. The transform-order
/// bug that detached the ninja's eyes had to be fixed in two files before this
/// existed; with five characters it would have been five.
public protocol RigPart: Hashable, Sendable {
    /// The design-space canvas every part's pivot is measured in.
    static var canvas: CGSize { get }
    /// `nil` for the root.
    var parent: Self? { get }
    /// Rotation pivot in design units.
    var pivot: CGPoint { get }
}

public extension RigPart {
    /// SwiftUI rotation anchors are fractions of the view's bounds, and every layer
    /// is drawn in a full-canvas frame — so a design-space pivot converts directly.
    var anchor: UnitPoint {
        UnitPoint(x: pivot.x / Self.canvas.width, y: pivot.y / Self.canvas.height)
    }

    /// Root first, then each descendant down to this part.
    var chain: [Self] {
        var chain: [Self] = []
        var node: Self? = self
        while let current = node {
            chain.insert(current, at: 0)
            node = current.parent
        }
        return chain
    }
}

/// One drawn path and the joint that moves it.
public struct RigLayer<Part: RigPart>: Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let part: Part
    public let fill: Color
    public let stroke: CGFloat?
    public let path: Path
    /// Layers that start invisible and are cross-faded in for an expression.
    public let restOpacity: Double

    public init(_ id: Int, _ name: String, _ part: Part, _ fill: Color,
                stroke: CGFloat?, _ data: String, restOpacity: Double = 1) {
        self.init(id, name, part, fill, stroke: stroke,
                  path: VectorPath.parse(data), restOpacity: restOpacity)
    }

    public init(_ id: Int, _ name: String, _ part: Part, _ fill: Color,
                stroke: CGFloat?, path: Path, restOpacity: Double = 1) {
        self.id = id
        self.name = name
        self.part = part
        self.fill = fill
        self.stroke = stroke
        self.path = path
        self.restOpacity = restOpacity
    }
}

/// Draws a rigged character: every layer wrapped in its ancestors' transforms.
///
/// Draw order is global and independent of the rig hierarchy — the samurai's
/// `shikoro` belongs to the helmet but draws behind the body — so transforms are
/// composed per layer from its ancestor chain rather than by nesting view groups.
public struct RigView<Part: RigPart, Pose>: View {

    let layers: [RigLayer<Part>]
    let pose: Pose
    let outline: Color
    /// Degrees for a joint, given the current pose.
    let rotation: (Pose, Part) -> Double
    /// Opacity for a layer, so expression cross-fades work.
    let opacity: (Pose, RigLayer<Part>) -> Double
    /// Anything a joint does beyond rotating — scales, offsets.
    let extras: (AnyView, Part, Pose) -> AnyView

    public init(
        layers: [RigLayer<Part>],
        pose: Pose,
        outline: Color,
        rotation: @escaping (Pose, Part) -> Double,
        opacity: @escaping (Pose, RigLayer<Part>) -> Double,
        extras: @escaping (AnyView, Part, Pose) -> AnyView
    ) {
        self.layers = layers
        self.pose = pose
        self.outline = outline
        self.rotation = rotation
        self.opacity = opacity
        self.extras = extras
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(layers) { layer in
                rigged(layer)
            }
        }
        .frame(width: Part.canvas.width, height: Part.canvas.height, alignment: .topLeading)
    }

    @ViewBuilder
    private func rigged(_ layer: RigLayer<Part>) -> some View {
        // Leaf-first, root-last. SwiftUI applies modifiers bottom-up, so an
        // ancestor's rotation must wrap its child's — otherwise the child's anchor
        // is evaluated against already-rotated content and the part flies off its
        // joint. Small angles hid this; a full backflip did not.
        let chain = layer.part.chain.reversed()
        let alpha = opacity(pose, layer)

        if alpha > 0 {
            chain.reduce(AnyView(shape(layer))) { view, part in
                extras(
                    AnyView(view.rotationEffect(.degrees(rotation(pose, part)), anchor: part.anchor)),
                    part,
                    pose
                )
            }
            .opacity(alpha)
        }
    }

    private func shape(_ layer: RigLayer<Part>) -> some View {
        ZStack(alignment: .topLeading) {
            layer.path.fill(layer.fill)
            if let width = layer.stroke {
                layer.path.stroke(
                    outline,
                    style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .frame(width: Part.canvas.width, height: Part.canvas.height, alignment: .topLeading)
    }
}
