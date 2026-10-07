import CoreGraphics
import PomodoroCore
import SwiftUI

/// The animatable state of Power's rig (the type keeps its old name).
public struct AnimeGirlPose: Equatable, Sendable {

    /// Design units behind the pill edge. 200 hidden, 0 risen, negative overshoot.
    public var emergence: Double = 200

    public var figureRotation: Double = 0
    public var figureScale: Double = 1
    public var figureScaleX: Double = 1
    public var figureScaleY: Double = 1
    public var figureLift: Double = 0

    public var hips: Double = 0
    public var torso: Double = 0
    public var legL: Double = 0
    public var legR: Double = 0
    public var armL: Double = 0
    public var armR: Double = 0
    /// Elbows. Positive bends the hand away from the body.
    public var armL_fore: Double = 0
    public var armR_fore: Double = 0
    public var head: Double = 0

    public var eyesScale: Double = 1
    public var eyesLift: Double = 0
    /// The emotional seismograph — lags the head and overshoots everything.
    public var ahoge: Double = 0
    public var ahogeScaleY: Double = 1

    public var tailL_base: Double = 0
    public var tailL_tip: Double = 0
    public var tailR_base: Double = 0
    public var tailR_tip: Double = 0

    /// Knees. Rotate the lower leg about the knee; in this front view that
    /// swings the shin sideways (wide stance, knock-kneed squash).
    public var shinL: Double = 0
    public var shinR: Double = 0

    /// Face sets, each 0…1. With all of them at 0 she wears her default: an open,
    /// fanged grin with open cross-pupil eyes. Fade one up to replace it.
    /// - shout: mouth wide with teeth top and bottom, angry brows.
    /// - smug: half-lidded eyes, closed smirk with one fang over the lip.
    /// - yawn: eyes squeezed into > <, tall open mouth with fangs, raised brows.
    /// - laugh: eyes closed in upward arcs, wide open mouth, raised brows.
    /// - doze: eyes closed and relaxed, small closed smile.
    public var shoutOpacity: Double = 0
    public var smugOpacity: Double = 0
    public var yawnOpacity: Double = 0
    public var laughOpacity: Double = 0
    public var dozeOpacity: Double = 0

    /// Hands, each 0…1 over the relaxed open hand. Claw is fingers spread and
    /// hooked; fist is clenched. If both are up on one hand, fist wins.
    public var clawL: Double = 0
    public var clawR: Double = 0
    public var fistL: Double = 0
    /// The right hand's fist.
    public var fist: Double = 0

    public var sparkleOpacity: Double = 0
    public var sparkleScale: Double = 0.4
    public var sparkleRotation: Double = 0

    public init() {}

    func rotation(of part: AnimeGirlArt.Part) -> Double {
        switch part {
        case .figure: figureRotation
        case .hips: hips
        case .torso: torso
        case .legL: legL
        case .legR: legR
        case .armL: armL
        case .armR: armR
        case .armL_fore: armL_fore
        case .armR_fore: armR_fore
        case .shinL: shinL
        case .shinR: shinR
        case .head: head
        case .ahoge: ahoge
        case .tailL_base: tailL_base
        case .tailL_tip: tailL_tip
        case .tailR_base: tailR_base
        case .tailR_tip: tailR_tip
        case .sparkles: sparkleRotation
        case .root, .eyes: 0
        }
    }

    func opacity(of layer: AnimeGirlArt.Layer) -> Double {
        switch AnimeGirlLayerRole.of(layer.name) {
        case let .face(set): faceOpacity(set)
        case let .brow(shape): browOpacity(shape)
        case let .hand(kind, left): handOpacity(kind, left: left)
        case .sparkle: sparkleOpacity
        case .plain: layer.restOpacity
        }
    }

    private func faceOpacity(_ set: AnimeGirlLayerRole.FaceSet) -> Double {
        let shout = clamp(shoutOpacity), smug = clamp(smugOpacity)
        let yawn = clamp(yawnOpacity), laugh = clamp(laughOpacity), doze = clamp(dozeOpacity)
        // Every alternate covers the default grin; only the ones that close her
        // eyes cover the open-eye cluster.
        return switch set {
        case .grin: 1 - max(shout, smug, yawn, laugh, doze)
        case .open: 1 - max(yawn, laugh, doze)
        case .shout: shout
        case .smug: smug
        case .yawn: yawn
        case .laugh: laugh
        case .doze: doze
        }
    }

    /// Brows have three shapes shared between the face sets: angry for the
    /// shout, raised for the laugh and the yawn, default otherwise.
    private func browOpacity(_ shape: AnimeGirlLayerRole.BrowShape) -> Double {
        let angry = clamp(shoutOpacity)
        let raised = clamp(max(laughOpacity, yawnOpacity))
        return switch shape {
        case .angry: angry
        case .raised: raised * (1 - angry)
        case .normal: 1 - max(angry, raised)
        }
    }

    private func handOpacity(_ kind: AnimeGirlLayerRole.HandKind, left: Bool) -> Double {
        let claw = clamp(left ? clawL : clawR)
        let fist = clamp(left ? fistL : self.fist)
        return switch kind {
        case .fist: fist
        case .claw: claw * (1 - fist)
        case .open: 1 - max(claw, fist)
        }
    }

    private func clamp(_ value: Double) -> Double { min(max(value, 0), 1) }
}

/// What a layer's name says it is, parsed once per name and cached, so the
/// per-frame opacity lookup is a dictionary hit rather than string splitting.
///
/// Names follow `AnimeGirlParts`: `face.<set>.<piece>`, `face.brows.<shape>`,
/// `hand.<kind>.<L|R>[.<piece>]`.
enum AnimeGirlLayerRole: Equatable, Sendable {
    enum FaceSet: String, Sendable { case grin, open, shout, smug, yawn, laugh, doze }
    enum BrowShape: String, Sendable { case normal = "default", angry, raised }
    enum HandKind: String, Sendable { case open, claw, fist }

    case face(FaceSet)
    case brow(BrowShape)
    case hand(HandKind, left: Bool)
    case sparkle
    case plain

    private static let cache: [String: AnimeGirlLayerRole] = Dictionary(
        AnimeGirlArt.layers.map { ($0.name, parse($0.name)) },
        uniquingKeysWith: { first, _ in first }
    )

    static func of(_ name: String) -> AnimeGirlLayerRole {
        cache[name] ?? parse(name)
    }

    static func parse(_ name: String) -> AnimeGirlLayerRole {
        let bits = name.split(separator: ".").map(String.init)
        switch bits.first {
        case "face" where bits.count >= 3 && bits[1] == "brows":
            return BrowShape(rawValue: bits[2]).map(AnimeGirlLayerRole.brow) ?? .plain
        case "face" where bits.count >= 2:
            return FaceSet(rawValue: bits[1]).map(AnimeGirlLayerRole.face) ?? .plain
        case "hand" where bits.count >= 3:
            guard let kind = HandKind(rawValue: bits[1]) else { return .plain }
            return .hand(kind, left: bits[2] == "L")
        default:
            return name.hasPrefix("sparkle") ? .sparkle : .plain
        }
    }
}


/// Power, drawn from `AnimeGirlArt`'s path data.
public struct AnimeGirlView: View {

    public static let canvas = AnimeGirlArt.canvas

    let pose: AnimeGirlPose
    /// Defaults to the shipped figure. Pass `AnimeGirlArt.build(other)` to draw
    /// a different set of proportions — this is the seam RigStudio's variant
    /// sheet uses, and the reason `build` is a pure function.
    let layers: [AnimeGirlArt.Layer]

    public init(pose: AnimeGirlPose, layers: [AnimeGirlArt.Layer] = AnimeGirlArt.layers) {
        self.pose = pose
        self.layers = layers
    }

    public var body: some View {
        RigView(
            layers: layers,
            pose: pose,
            outline: AnimeGirlArt.Ink.outline,
            rotation: { $0.rotation(of: $1) },
            opacity: { $0.opacity(of: $1) },
            extras: { view, part, pose in
                AnyView(view.modifier(AnimeGirlPartExtras(part: part, pose: pose)))
            }
        )
    }
}

/// Parts that move by more than a rotation.
///
/// Internal rather than private so render tests can compose a single rig part.
struct AnimeGirlPartExtras: ViewModifier {
    let part: AnimeGirlArt.Part
    let pose: AnimeGirlPose

    func body(content: Content) -> some View {
        switch part {
        case .figure:
            content
                .scaleEffect(x: pose.figureScaleX, y: pose.figureScaleY, anchor: .bottom)
                .scaleEffect(pose.figureScale, anchor: .bottom)
                .offset(y: pose.figureLift)
        case .eyes:
            content
                .scaleEffect(pose.eyesScale, anchor: AnimeGirlArt.Part.eyes.anchor)
                .offset(y: pose.eyesLift)
        case .ahoge:
            content.scaleEffect(y: pose.ahogeScaleY, anchor: AnimeGirlArt.Part.ahoge.anchor)
        case .sparkles:
            content.scaleEffect(pose.sparkleScale, anchor: AnimeGirlArt.Part.sparkles.anchor)
        default:
            content
        }
    }
}
