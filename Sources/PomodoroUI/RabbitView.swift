import CoreGraphics
import PomodoroCore
import SwiftUI

/// The animatable state of the rabbit costume's rig.
///
/// Note what is missing: there is no field for a facial expression beyond a blink
/// and a single frown. That is deliberate. The costume hops and its ears flap; the
/// human inside contributes one blink per performance and nothing else.
public struct RabbitPose: Equatable, Sendable {

    /// Design units behind the pill edge. 200 hidden, 0 risen, negative overshoot.
    public var emergence: Double = 200
    public var rootScale: Double = 1

    public var figureRotation: Double = 0
    public var figureScaleY: Double = 1
    /// Hops are on `figure` so they do not fight the emergence offset on `root`.
    public var figureLift: Double = 0

    public var torso: Double = 0
    public var legs: Double = 0
    public var tail: Double = 0
    public var armL: Double = 0
    public var armR: Double = 0
    public var zipperPull: Double = 0

    public var head: Double = 0
    public var earL_base: Double = 0
    public var earL_tip: Double = 0
    public var earR_base: Double = 0
    public var earR_tip: Double = 0

    /// The human's entire emotional range.
    public var blinkOpacity: Double = 0
    public var sighOpacity: Double = 0

    public init() {}

    func rotation(of part: RabbitArt.Part) -> Double {
        switch part {
        case .figure: figureRotation
        case .torso: torso
        case .legs: legs
        case .tail: tail
        case .armL: armL
        case .armR: armR
        case .zipperPull: zipperPull
        case .head: head
        case .earL_base: earL_base
        case .earL_tip: earL_tip
        case .earR_base: earR_base
        case .earR_tip: earR_tip
        case .root, .face: 0
        }
    }

    func opacity(of layer: RabbitArt.Layer) -> Double {
        switch layer.name {
        case "alt_blink": blinkOpacity
        case "alt_sigh": sighOpacity
        // The default eyes and mouth yield to their alternates.
        case "eyes_flat", "eyeDotL", "eyeDotR": 1 - blinkOpacity
        case "mouth_flat": 1 - sighOpacity
        default: layer.restOpacity
        }
    }
}

/// The rabbit-costume guy, drawn from `RabbitArt`'s path data.
public struct RabbitView: View {

    public static let canvas = RabbitArt.canvas

    let pose: RabbitPose

    public init(pose: RabbitPose) { self.pose = pose }

    public var body: some View {
        RigView(
            layers: RabbitArt.layers,
            pose: pose,
            outline: RabbitArt.Ink.outline,
            rotation: { $0.rotation(of: $1) },
            opacity: { $0.opacity(of: $1) },
            extras: { view, part, pose in
                AnyView(view.modifier(RabbitPartExtras(part: part, pose: pose)))
            }
        )
        .scaleEffect(pose.rootScale, anchor: .bottom)
    }
}

/// Parts that move by more than a rotation.
///
/// Internal rather than private so render tests can compose a single rig part.
struct RabbitPartExtras: ViewModifier {
    let part: RabbitArt.Part
    let pose: RabbitPose

    func body(content: Content) -> some View {
        switch part {
        case .figure:
            content
                .scaleEffect(y: pose.figureScaleY, anchor: .bottom)
                .offset(y: pose.figureLift)
        default:
            content
        }
    }
}
