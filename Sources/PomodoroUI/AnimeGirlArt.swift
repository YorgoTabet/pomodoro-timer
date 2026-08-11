import CoreGraphics
import SwiftUI

/// The anime girl: palette, skeleton, and the assembled layer table.
///
/// The shapes themselves live in `AnimeGirlParts`, generated from the named
/// numbers in `AnimeGirlProportions`. This file only says what she is made of,
/// in what order it draws, and where the joints are — all three derived from the
/// same `shape` value, so moving a landmark moves its pivot with it. That was
/// the bug waiting to happen in the old hand-authored table: pivots were
/// literals that had to be remembered separately from the art.
///
/// Geometry contracts the rest of the app relies on:
/// - The occluding edge is y=196. Masked cues show her from the crown to the
///   knee; only the unmasked cues reveal the boots' feet at `sole`.
/// - Arms draw *behind* the head, so any gesture aimed "beside the head" must
///   clear the skull — see the -155° cap in `fistPump`.
/// - Layer names in the expression cluster (mouths, brows, eye parts, sparkles)
///   are matched by string in `AnimeGirlPose.opacity(of:)` — rename them there
///   too or the cross-fades silently stop.
public enum AnimeGirlArt {

    public static let canvas = CGSize(width: 200, height: 260)

    /// The dimensions every part and pivot is generated from. Swap this for a
    /// different `AnimeGirlProportions` to reshape the whole character.
    public static let shape = AnimeGirlProportions.standard

    public enum Ink {
        public static let outline = Color(hex: 0x2B2333)
        public static let ink = Color(hex: 0x2B2333)
        public static let hair = Color(hex: 0xB49AE8)
        public static let hairShadow = Color(hex: 0x8E74C4)
        public static let hairShine = Color(hex: 0xE2D4F8)
        /// Skirt blue and its pleat shadow.
        public static let blue = Color(hex: 0x3F6ED8)
        public static let blueDeep = Color(hex: 0x2B4DA6)
        /// Boots and detached sleeves.
        public static let navy = Color(hex: 0x27355C)
        /// The vocaloid nod: tie, hem stripe, boot trim, hair ties.
        public static let teal = Color(hex: 0x3BBFC9)
        /// Form shading on the white top — light enough to read as fold, not dirt.
        public static let cloth = Color(hex: 0xE4DFEE)
        public static let skin = Color(hex: 0xFFE3D0)
        public static let skinShade = Color(hex: 0xF2C9B4)
        public static let blush = Color(hex: 0xF4B9C6)
        public static let iris = Color(hex: 0x5C4699)
        public static let white = Color.white
        /// Open-mouth interior for the happy expression.
        public static let mouthDeep = Color(hex: 0x8E3A50)

        public static let clear = Color.clear
    }

    public enum Part: String, CaseIterable, RigPart {
        public static var canvas: CGSize { AnimeGirlArt.canvas }

        case root, sparkles, figure, hips, legL, legR, torso
        case armL, armR, head, eyes, ahoge
        case armL_fore, armR_fore
        case tailL_base, tailL_tip, tailR_base, tailR_tip

        public var parent: Part? {
            switch self {
            case .root: nil
            case .sparkles, .figure: .root
            case .hips: .figure
            case .legL, .legR, .torso: .hips
            case .armL, .armR, .head: .torso
            case .armL_fore: .armL
            case .armR_fore: .armR
            case .eyes, .ahoge, .tailL_base, .tailR_base: .head
            case .tailL_tip: .tailL_base
            case .tailR_tip: .tailR_base
            }
        }

        /// Every joint is read off the same proportions the art is drawn from,
        /// so a landmark and its pivot can never drift apart.
        public var pivot: CGPoint {
            let p = AnimeGirlArt.shape
            let mid = AnimeGirlParts.cx
            func flip(_ point: (x: Double, y: Double)) -> CGPoint {
                CGPoint(x: mid * 2 - point.x, y: point.y)
            }
            // Explicit `return`: the helpers above make this a multi-statement
            // body, so the switch is not an implicit return.
            return switch self {
            case .root, .figure: CGPoint(x: mid, y: 196)
            case .sparkles: CGPoint(x: mid, y: 80)
            case .hips: CGPoint(x: mid, y: p.waist + 3)
            case .legL: CGPoint(x: AnimeGirlParts.Limbs.legCentre(p), y: p.hip + 2)
            case .legR: CGPoint(x: mid * 2 - AnimeGirlParts.Limbs.legCentre(p), y: p.hip + 2)
            case .torso: CGPoint(x: mid, y: p.waist)
            case .armL: CGPoint(x: AnimeGirlParts.Limbs.shoulder(p).x, y: p.shoulder + 4)
            case .armR: CGPoint(x: mid * 2 - AnimeGirlParts.Limbs.shoulder(p).x, y: p.shoulder + 4)
            case .armL_fore: CGPoint(x: AnimeGirlParts.Limbs.shoulder(p).x, y: p.elbow)
            case .armR_fore: CGPoint(x: mid * 2 - AnimeGirlParts.Limbs.shoulder(p).x, y: p.elbow)
            case .head: CGPoint(x: mid, y: p.chin - 2.5)
            case .eyes: CGPoint(x: mid, y: p.eyeLine)
            case .ahoge: CGPoint(x: AnimeGirlParts.Hair.ahogeRoot(p).x,
                                 y: AnimeGirlParts.Hair.ahogeRoot(p).y)
            case .tailL_base: CGPoint(x: AnimeGirlParts.Hair.tailRoot(p).x,
                                      y: AnimeGirlParts.Hair.tailRoot(p).y)
            case .tailR_base: flip(AnimeGirlParts.Hair.tailRoot(p))
            case .tailL_tip: CGPoint(x: AnimeGirlParts.Hair.tailPivot(p).x,
                                     y: AnimeGirlParts.Hair.tailPivot(p).y)
            case .tailR_tip: flip(AnimeGirlParts.Hair.tailPivot(p))
            }
        }
    }

    public typealias Layer = RigLayer<Part>

    /// Back to front: hair curtain and tails behind everything, legs behind the
    /// skirt, bare torso behind the top, arms in front of the top but behind the
    /// head, hair over the finished face, sparkles last.
    public static let layers: [Layer] = build(shape)

    /// Composes the figure. A pure function of `p`, so a tool can call it with
    /// different proportions for a live preview without touching anything here.
    public static func build(_ p: AnimeGirlProportions) -> [Layer] {
        let hair = AnimeGirlParts.Hair.layers(p)
        let assembled =
            hair.back
            + AnimeGirlParts.Limbs.legs(p)
            + AnimeGirlParts.Outfit.skirt(p)
            + AnimeGirlParts.Torso.layers(p)
            + AnimeGirlParts.Outfit.top(p)
            + AnimeGirlParts.Limbs.arm(p)
            + AnimeGirlParts.Head.neck(p)
            + AnimeGirlParts.Head.layers(p)
            + AnimeGirlParts.Eyes.layers(p)
            + hair.front
            + AnimeGirlParts.Hair.ahogeLayer(p)
            + AnimeGirlParts.Hair.ties(p)
            + AnimeGirlParts.Sparkles.layers(p)

        // Ids are assigned here rather than by the parts, so a part never has to
        // know where it lands in the draw order — and `ForEach` still gets the
        // unique ids it needs to avoid silently dropping a layer.
        return assembled.enumerated().map { index, layer in
            Layer(index + 1, layer.name, layer.part, layer.fill,
                  stroke: layer.stroke, path: layer.path, restOpacity: layer.restOpacity)
        }
    }
}
