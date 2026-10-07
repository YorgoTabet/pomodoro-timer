import CoreGraphics
import PomodoroCore
import SwiftUI

/// The animatable state of the General's rig.
///
/// His soul is entirely in the lagged secondaries — cap, moustache, aviators and
/// medals all trail the parts they hang off. Key the parents and let the springs
/// sell it.
public struct GeneralPose: Equatable, Sendable {

    /// Design units behind the pill edge. 200 hidden, 0 risen, negative overshoot.
    public var emergence: Double = 200

    public var figureRotation: Double = 0
    public var figureScale: Double = 1
    public var figureScaleY: Double = 1

    public var torso: Double = 0
    /// The chest puff, anchored at the belt.
    public var torsoScaleY: Double = 1
    public var head: Double = 0

    public var cap: Double = 0
    /// The cap pops off his head on an outburst.
    public var capLift: Double = 0
    public var shades: Double = 0
    /// Aviators sliding down his nose — the "at ease" tell.
    public var shadesSlide: Double = 0
    public var stache: Double = 0
    public var stacheLift: Double = 0
    public var stacheScaleY: Double = 1
    public var medals: Double = 0
    public var medalsLift: Double = 0

    public var armNear: Double = 0
    public var foreNear: Double = 0
    public var stick: Double = 0
    public var armFar: Double = 0
    public var foreFar: Double = 0

    public var legNear: Double = 0
    public var bootNear: Double = 0
    public var legFar: Double = 0
    public var bootFar: Double = 0
    /// How far each leg lifts into the coat skirt on a march step (design units, up is negative).
    public var legNearLift: Double = 0
    public var legFarLift: Double = 0
    /// A raised knee is shown as a shortened thigh (the leg points at you), not a
    /// sideways swing. 1 = full length.
    public var legNearScaleY: Double = 1
    public var legFarScaleY: Double = 1
    /// How far each boot rises on its own, on top of the leg (design units, up is negative).
    public var bootNearLift: Double = 0
    public var bootFarLift: Double = 0

    /// The stick shortened along its length, for pointing it straight at the viewer.
    public var stickLength: Double = 1

    /// 0 = forearm and hand drawn in front of the body, 1 = tucked behind his back.
    public var nearBehind: Double = 0
    public var farBehind: Double = 0
    /// The swagger stick. It can be put away entirely (behind his back, out of sight).
    public var stickOpacity: Double = 1

    /// Expression cross-fades. The aviators and moustache *are* the default face,
    /// so the alternates only ever add a mouth.
    public var shoutOpacity: Double = 0
    public var grinOpacity: Double = 0
    public var sweatOpacity: Double = 0

    public init() {}

    func rotation(of part: GeneralArt.Part) -> Double {
        switch part {
        case .figure: figureRotation
        case .torso: torso
        case .head: head
        case .cap: cap
        case .shades: shades
        case .stache: stache
        case .medals: medals
        case .armNear: armNear
        case .foreNear: foreNear
        case .stick: stick
        case .armFar: armFar
        case .foreFar: foreFar
        case .legNear: legNear
        case .bootNear: bootNear
        case .legFar: legFar
        case .bootFar: bootFar
        case .root: 0
        }
    }

    func opacity(of layer: GeneralArt.Layer) -> Double {
        switch layer.name {
        case "shoutMouth": shoutOpacity
        case "grinTeeth": grinOpacity
        case "sweatDrop": sweatOpacity
        case "foreFarB", "cuffFarB", "handFarB": farBehind
        case "foreFar", "cuffFar", "handFar": 1 - farBehind
        case "foreNearB", "cuffNearB", "handNearB": nearBehind
        case "foreNear", "cuffNear", "handNear": 1 - nearBehind
        case "stickRodB", "stickTipB": nearBehind * stickOpacity
        case "stickRod", "stickTip": (1 - nearBehind) * stickOpacity
        default: layer.restOpacity
        }
    }
}

/// The General, drawn from `GeneralArt`'s path data.
public struct GeneralView: View {

    public static let canvas = GeneralArt.canvas

    let pose: GeneralPose

    public init(pose: GeneralPose) { self.pose = pose }

    public var body: some View {
        RigView(
            layers: GeneralArt.layers,
            pose: pose,
            outline: GeneralArt.Ink.outline,
            rotation: { $0.rotation(of: $1) },
            opacity: { $0.opacity(of: $1) },
            extras: { view, part, pose in
                AnyView(view.modifier(GeneralPartExtras(part: part, pose: pose)))
            }
        )
        .scaleEffect(y: pose.figureScaleY, anchor: .bottom)
        .scaleEffect(pose.figureScale, anchor: .bottom)
    }
}

/// Parts that move by more than a rotation.
///
/// Internal rather than private so render tests can compose a single rig part.
struct GeneralPartExtras: ViewModifier {
    let part: GeneralArt.Part
    let pose: GeneralPose

    private static let hip = UnitPoint(x: 0.5, y: 174.0 / 260.0)
    private static let ankle = UnitPoint(x: 0.5, y: 209.0 / 260.0)
    /// The rod runs from the hand toward (-24, -36): 36.4 degrees left of straight up.
    private static let rodTilt = 36.4

    func body(content: Content) -> some View {
        switch part {
        case .torso:
            // Anchored at the belt so the puff pushes the chest up, not the boots down.
            content.scaleEffect(y: pose.torsoScaleY, anchor: UnitPoint(x: 0.5, y: 153.0 / 260.0))
        case .cap:
            content.offset(y: pose.capLift)
        case .shades:
            content.offset(y: pose.shadesSlide)
        case .stache:
            content
                .scaleEffect(y: pose.stacheScaleY, anchor: GeneralArt.Part.stache.anchor)
                .offset(y: pose.stacheLift)
        case .medals:
            content.offset(y: pose.medalsLift)
        case .legNear:
            content
                .scaleEffect(y: pose.legNearScaleY, anchor: Self.hip)
                .offset(y: pose.legNearLift)
        case .legFar:
            content
                .scaleEffect(y: pose.legFarScaleY, anchor: Self.hip)
                .offset(y: pose.legFarLift)
        case .bootNear:
            // Undo the thigh's squash so the boot keeps its shape, then lift it.
            content
                .scaleEffect(y: 1 / pose.legNearScaleY, anchor: Self.ankle)
                .offset(y: pose.bootNearLift)
        case .bootFar:
            content
                .scaleEffect(y: 1 / pose.legFarScaleY, anchor: Self.ankle)
                .offset(y: pose.bootFarLift)
        case .stick:
            // Shorten along the rod, not along the screen: turn it upright, squash,
            // turn it back. The rod is drawn up and to the left of the hand.
            let anchor = GeneralArt.Part.stick.anchor
            content
                .rotationEffect(.degrees(-pose.stick), anchor: anchor)
                .rotationEffect(.degrees(Self.rodTilt), anchor: anchor)
                .scaleEffect(x: 1 + (1 - pose.stickLength) * 0.8, y: pose.stickLength, anchor: anchor)
                .rotationEffect(.degrees(-Self.rodTilt), anchor: anchor)
                .rotationEffect(.degrees(pose.stick), anchor: anchor)
        default:
            content
        }
    }
}
