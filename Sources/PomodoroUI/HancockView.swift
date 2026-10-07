import CoreGraphics
import PomodoroCore
import SwiftUI

/// The animatable state of Boa Hancock's rig.
///
/// Sign conventions (SwiftUI rotation: positive is clockwise on screen):
/// - Left arm (screen left): `armL` positive swings the arm out, away from the
///   body; negative brings it across the body and up. `armR` mirrors it:
///   negative is out. Raising an arm overhead is about +150 on `armL`.
/// - Elbows: `armL_fore` negative bends the forearm in toward the body (the
///   natural way); keep it within -150...+10. `armR_fore` mirrors: +150...-10.
/// - Wrists: `handL`/`handR` within about ±60.
/// - Legs: `legL` positive swings the left leg out to the side; `shinL` negative
///   kicks the foot back inward. Knees bend within -10...+40 of the thigh on
///   either side; in this front view a "step" is a small outward leg swing plus a
///   bent knee.
/// - `hips` positive raises the left hip (weight on her left leg). `chest` is a
///   child of `hips`, so set it opposite for contrapposto.
/// - `skirtPanel` positive swings the slit flap out to the left, baring the left
///   leg from mid-thigh. 0...25.
/// - Capes: `capeL` positive flares out to the left, `capeR` negative to the right.
/// - Hair: `hairBase`, `hairMid`, `hairTip` add up down the chain; drive the mid
///   and tip a few frames late for follow-through. Positive swings the hair's
///   bottom to the left.
public struct HancockPose: Equatable, Sendable {

    /// Design units behind the pill edge. 200 hidden, 0 risen.
    public var emergence: Double = 200

    public var figureRotation: Double = 0
    public var figureScale: Double = 1
    public var figureLift: Double = 0

    // Contrapposto rest: weight on her left leg, that hip high, shoulders
    // tilted the other way, head tipped back toward the high hip.
    public var hips: Double = 2.5
    public var chest: Double = -5
    public var head: Double = 4

    public var legL: Double = -3
    public var shinL: Double = 0
    public var legR: Double = -1
    public var shinR: Double = 2
    public var skirtPanel: Double = 0

    public var armL: Double = 12
    public var armL_fore: Double = -5
    public var handL: Double = 0
    public var armR: Double = -10
    public var armR_fore: Double = 5
    public var handR: Double = 0

    public var capeL: Double = 0
    public var capeR: Double = 0

    public var hairBase: Double = -2
    public var hairMid: Double = 0
    public var hairTip: Double = 0
    public var sideLockL: Double = -3
    public var sideLockR: Double = -3
    public var earringL: Double = -3
    public var earringR: Double = -3

    /// Bust follow-through. Lift is design units (negative is up), safe -3...+3.
    /// Scales are about the upper chest, safe 0.94...1.06; keep them volume
    /// preserving (scaleX ≈ 1 / scaleY) so it reads as weight, not inflation.
    public var bustLift: Double = 0
    public var bustScaleX: Double = 1
    public var bustScaleY: Double = 1

    /// Face sets, 0...1 each. With all at 0 she wears the haughty default.
    public var smugOpacity: Double = 0
    public var flusteredOpacity: Double = 0
    public var winkOpacity: Double = 0
    public var laughOpacity: Double = 0

    /// Hand shapes, 0...1, over the relaxed open hand.
    public var hipL: Double = 0
    public var hipR: Double = 0
    public var pointL: Double = 0
    public var pointR: Double = 0
    public var mouthL: Double = 0
    public var mouthR: Double = 0

    /// The love-struck heart above her head.
    public var heartOpacity: Double = 0
    public var heartScale: Double = 1
    /// Design units, negative is up.
    public var heartLift: Double = 0

    public init() {}

    func rotation(of part: HancockArt.Part) -> Double {
        switch part {
        case .figure: figureRotation
        case .hips: hips
        case .chest: chest
        case .head: head
        case .legL: legL
        case .shinL: shinL
        case .legR: legR
        case .shinR: shinR
        case .skirtPanel: skirtPanel
        case .armL: armL
        case .armL_fore: armL_fore
        case .handL: handL
        case .armR: armR
        case .armR_fore: armR_fore
        case .handR: handR
        case .capeL: capeL
        case .capeR: capeR
        case .hairBase: hairBase
        case .hairMid: hairMid
        case .hairTip: hairTip
        case .sideLockL: sideLockL
        case .sideLockR: sideLockR
        case .earringL: earringL
        case .earringR: earringR
        case .root, .heart, .bust: 0
        }
    }

    func opacity(of layer: HancockArt.Layer) -> Double {
        switch HancockLayerRole.of(layer.name) {
        case let .face(set): faceOpacity(set)
        case let .hand(kind, left): handOpacity(kind, left: left)
        case .heart: clamp(heartOpacity)
        case .plain: layer.restOpacity
        }
    }

    private func faceOpacity(_ set: HancockLayerRole.FaceSet) -> Double {
        let smug = clamp(smugOpacity), flustered = clamp(flusteredOpacity)
        let wink = clamp(winkOpacity), laugh = clamp(laughOpacity)
        return switch set {
        case .haughty: 1 - max(smug, flustered, wink, laugh)
        case .smug: smug
        case .flustered: flustered
        case .wink: wink
        case .laugh: laugh
        }
    }

    private func handOpacity(_ kind: HancockLayerRole.HandKind, left: Bool) -> Double {
        let hip = clamp(left ? hipL : hipR)
        let point = clamp(left ? pointL : pointR)
        let mouth = clamp(left ? mouthL : mouthR)
        return switch kind {
        case .open: 1 - max(hip, point, mouth)
        case .hip: hip
        case .point: point
        case .mouth: mouth
        }
    }

    private func clamp(_ value: Double) -> Double { min(max(value, 0), 1) }
}

/// What a layer's name says it is, parsed once per name and cached.
enum HancockLayerRole: Equatable, Sendable {
    enum FaceSet: String, Sendable { case haughty, smug, flustered, wink, laugh }
    enum HandKind: String, Sendable { case open, hip, point, mouth }

    case face(FaceSet)
    case hand(HandKind, left: Bool)
    case heart
    case plain

    private static let cache: [String: HancockLayerRole] = Dictionary(
        HancockArt.layers.map { ($0.name, parse($0.name)) },
        uniquingKeysWith: { first, _ in first }
    )

    static func of(_ name: String) -> HancockLayerRole {
        cache[name] ?? parse(name)
    }

    static func parse(_ name: String) -> HancockLayerRole {
        let bits = name.split(separator: ".").map(String.init)
        switch bits.first {
        case "face" where bits.count >= 2:
            return FaceSet(rawValue: bits[1]).map(HancockLayerRole.face) ?? .plain
        case "hand" where bits.count >= 3:
            guard let kind = HandKind(rawValue: bits[1]) else { return .plain }
            return .hand(kind, left: bits[2] == "L")
        case "heart":
            return .heart
        default:
            return .plain
        }
    }
}

/// Boa Hancock, drawn from `HancockArt`.
public struct HancockView: View {

    public static let canvas = HancockArt.canvas

    let pose: HancockPose

    public init(pose: HancockPose) {
        self.pose = pose
    }

    public var body: some View {
        RigView(
            layers: HancockArt.layers,
            pose: pose,
            outline: HancockArt.Ink.outline,
            rotation: { $0.rotation(of: $1) },
            opacity: { $0.opacity(of: $1) },
            extras: { view, part, pose in
                AnyView(view.modifier(HancockPartExtras(part: part, pose: pose)))
            }
        )
    }
}

/// Parts that move by more than a rotation.
struct HancockPartExtras: ViewModifier {
    let part: HancockArt.Part
    let pose: HancockPose

    func body(content: Content) -> some View {
        switch part {
        case .figure:
            content
                .scaleEffect(pose.figureScale, anchor: .bottom)
                .offset(y: pose.figureLift)
        case .bust:
            content
                .scaleEffect(x: pose.bustScaleX, y: pose.bustScaleY,
                             anchor: HancockArt.Part.bust.anchor)
                .offset(y: pose.bustLift)
        case .heart:
            content
                .scaleEffect(pose.heartScale, anchor: HancockArt.Part.heart.anchor)
                .offset(y: pose.heartLift)
        default:
            content
        }
    }
}
