import CoreGraphics
import SwiftUI

/// Power (the character still called `AnimeGirl` in code): palette, skeleton,
/// and the assembled layer table.
///
/// The shapes themselves live in `AnimeGirlParts`, generated from the named
/// numbers in `AnimeGirlProportions`. This file only says what she is made of,
/// in what order it draws, and where the joints are, all three derived from the
/// same `shape` value, so moving a landmark moves its pivot with it.
///
/// Geometry contracts the rest of the app relies on:
/// - The occluding edge is y=196. Masked cues show her from the horns to just
///   below the knee; only the unmasked cues reveal the sneakers at `sole`.
/// - Arms draw *behind* the head, so any gesture aimed "beside the head" must
///   clear the skull.
/// - Expression and hand layers are matched by name in
///   `AnimeGirlPose.opacity(of:)`: rename them there too or the cross-fades
///   silently stop.
public enum AnimeGirlArt {

    public static let canvas = CGSize(width: 200, height: 260)

    /// The dimensions every part and pivot is generated from. Swap this for a
    /// different `AnimeGirlProportions` to reshape the whole character.
    public static let shape = AnimeGirlProportions.standard

    public enum Ink {
        public static let outline = Color(hex: 0x2B2128)
        public static let ink = Color(hex: 0x1E1418)
        /// Strawberry blonde, with one hard cel shadow.
        public static let hair = Color(hex: 0xF2C28B)
        public static let hairShadow = Color(hex: 0xD99A62)
        public static let hairShine = Color(hex: 0xFBE2BD)
        public static let horn = Color(hex: 0xD9473A)
        public static let hornShade = Color(hex: 0xA8302A)
        /// The suit jacket and its shade.
        public static let navy = Color(hex: 0x2F4A7A)
        public static let navyDeep = Color(hex: 0x22375C)
        public static let shirt = Color(hex: 0xEFE9D6)
        public static let shirtShade = Color(hex: 0xD8CFB4)
        public static let tie = Color(hex: 0x1E1E22)
        public static let slacks = Color(hex: 0x25262B)
        public static let slacksRoll = Color(hex: 0x34353C)
        public static let belt = Color(hex: 0x141418)
        public static let skin = Color(hex: 0xFFE3D0)
        public static let skinShade = Color(hex: 0xF0C5AE)
        /// Iris: yellow-orange ring, red core, near-black cross on top.
        public static let irisOuter = Color(hex: 0xF7B731)
        public static let irisInner = Color(hex: 0xE0452E)
        public static let pupil = Color(hex: 0x1A0E12)
        public static let white = Color.white
        public static let mouthDeep = Color(hex: 0x6E1C2A)
        public static let tongue = Color(hex: 0xE0707A)

        public static let clear = Color.clear
    }

    public enum Part: String, CaseIterable, RigPart {
        public static var canvas: CGSize { AnimeGirlArt.canvas }

        case root, sparkles, figure, hips, legL, legR, torso
        case armL, armR, head, eyes, ahoge
        case armL_fore, armR_fore
        /// Knees. The front view has no true fold, so these swing the lower leg
        /// sideways: a wide stance with flat feet, or a knock-kneed squash.
        case shinL, shinR
        /// The two long back hair masses, base and follow-through tip.
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
            case .shinL: .legL
            case .shinR: .legR
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
            case .shinL: CGPoint(x: AnimeGirlParts.Limbs.legCentre(p), y: p.knee)
            case .shinR: CGPoint(x: mid * 2 - AnimeGirlParts.Limbs.legCentre(p), y: p.knee)
            case .torso: CGPoint(x: mid, y: p.waist)
            case .armL: CGPoint(x: AnimeGirlParts.Limbs.shoulder(p).x,
                                y: AnimeGirlParts.Limbs.shoulder(p).y)
            case .armR: flip(AnimeGirlParts.Limbs.shoulder(p))
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

    /// Back to front: hair curtain and back hair masses behind everything, the
    /// jacket's back, legs, neck and shirt, the slacks' seat over the tuck, the
    /// jacket's open fronts, arms, then the head, face, front hair, horns, brows
    /// over the fringe, the top lock and sparkles last.
    public static let layers: [Layer] = build(shape)

    /// Composes the figure. A pure function of `p`, so a tool can call it with
    /// different proportions for a live preview without touching anything here.
    public static func build(_ p: AnimeGirlProportions) -> [Layer] {
        let hair = AnimeGirlParts.Hair.layers(p)
        let assembled =
            hair.back
            + AnimeGirlParts.Outfit.jacketBack(p)
            + AnimeGirlParts.Limbs.legs(p)
            + AnimeGirlParts.Head.neck(p)
            + AnimeGirlParts.Outfit.shirt(p)
            + AnimeGirlParts.Outfit.seat(p)
            + AnimeGirlParts.Outfit.jacketFront(p)
            + AnimeGirlParts.Limbs.arm(p)
            + AnimeGirlParts.Head.layers(p)
            + AnimeGirlParts.Mouth.layers(p)
            + AnimeGirlParts.Eyes.layers(p)
            + hair.front
            + AnimeGirlParts.Hair.horns(p)
            + AnimeGirlParts.Eyes.brows(p)
            + AnimeGirlParts.Hair.ahogeLayer(p)
            + AnimeGirlParts.Sparkles.layers(p)

        // Ids are assigned here rather than by the parts, so a part never has to
        // know where it lands in the draw order, and `ForEach` still gets the
        // unique ids it needs to avoid silently dropping a layer.
        return assembled.enumerated().map { index, layer in
            Layer(index + 1, layer.name, layer.part, layer.fill,
                  stroke: layer.stroke, path: layer.path, restOpacity: layer.restOpacity)
        }
    }
}
