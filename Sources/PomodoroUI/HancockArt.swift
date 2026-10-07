import CoreGraphics
import SwiftUI

/// Boa Hancock, the Pirate Empress: palette, skeleton and the assembled layers.
///
/// The shapes live in `HancockParts`, built from the landmarks in
/// `HancockParts.Mark`. This file says what she is made of, in what order it
/// draws, and where the joints are.
///
/// Geometry contracts the rest of the app relies on:
/// - The occluding edge is y=196 (her knees). Masked cues show her from the hair
///   down to the knee; the unmasked ones reveal the hem and the heels at y=251.
/// - She stands about 6.3 heads tall (crown 24, chin 60, sole 251): adult
///   proportions with the head biased a little large so the face reads at 70pt.
/// - Face, hand and heart layers are matched by name in `HancockPose.opacity(of:)`.
public enum HancockArt {

    public static let canvas = CGSize(width: 200, height: 260)

    public enum Ink {
        public static let outline = Color(hex: 0x2A1620)
        /// Blue-black hair, a cool rim so it holds on a dark bar, and a gloss band.
        public static let hair = Color(hex: 0x1D1D2B)
        public static let hairRim = Color(hex: 0x4F5B82)
        public static let hairShine = Color(hex: 0x8C9AC4)
        public static let skin = Color(hex: 0xFFE2CF)
        public static let skinShade = Color(hex: 0xF0BFA6)
        /// The fitted top and the skirt.
        public static let red = Color(hex: 0xB8263A)
        public static let redShade = Color(hex: 0x8E1B2C)
        /// A lighter red catching the light on the bust.
        public static let redSheen = Color(hex: 0xD04256)
        /// Inside of the skirt, seen through the slit and at the hem: blue, as
        /// in the manga colour art.
        public static let lining = Color(hex: 0x3D5BA6)
        public static let liningShade = Color(hex: 0x2C4485)
        /// The cape's inner side, which faces us beside her body.
        public static let capeInner = Color(hex: 0x2B3470)
        public static let capeInnerShade = Color(hex: 0x1F2758)
        /// A small glint on the skin.
        public static let skinLight = Color(hex: 0xFFF3EA)
        public static let heelShade = Color(hex: 0x8E1B2C)
        public static let pink = Color(hex: 0xE58FA6)
        public static let pinkShade = Color(hex: 0xC96F88)
        public static let gold = Color(hex: 0xD9A441)
        public static let goldShade = Color(hex: 0xA97A26)
        public static let green = Color(hex: 0x6BAA4F)
        public static let cape = Color(hex: 0xF4F1EC)
        public static let capeShade = Color(hex: 0xD9D4CC)
        public static let iris = Color(hex: 0x262B4E)
        public static let irisLight = Color(hex: 0x4B5A92)
        public static let lash = Color(hex: 0x15101A)
        public static let lips = Color(hex: 0xD3253D)
        public static let mouthDeep = Color(hex: 0x5C1222)
        public static let blush = Color(hex: 0xF4889F)
        public static let heart = Color(hex: 0xEC4A72)
        public static let heels = Color(hex: 0xC4213A)
        public static let white = Color.white
        public static let clear = Color.clear
    }

    public enum Part: String, CaseIterable, RigPart {
        public static var canvas: CGSize { HancockArt.canvas }

        case root, heart, figure
        /// Lower body: skirt, sash and legs. Tilts about the waist.
        case hips
        /// Upper body. A child of `hips` with the same pivot, so the chest can
        /// counter-tilt for contrapposto.
        case chest
        /// Bust volume, for follow-through. Scales and lifts (see the pose). It
        /// carries only interior marks under the static neckline, so it never tears.
        case bust
        case legL, shinL, legR, shinR
        /// The skirt's left front panel, hinged at the outer hip. Swinging it
        /// outward (positive) opens the slit over the left leg.
        case skirtPanel
        /// The low sash's long loose end, hinged at the knot on her left hip.
        /// Positive swings its bottom to the left.
        case sashTail
        case capeL, capeR
        case armL, armL_fore, handL
        case armR, armR_fore, handR
        case head
        /// The long back hair in three links: base at the head, mid at the
        /// shoulder blades, tip at the hips.
        case hairBase, hairMid, hairTip
        case sideLockL, sideLockR
        case earringL, earringR

        public var parent: Part? {
            switch self {
            case .root: nil
            case .heart, .figure: .root
            case .hips: .figure
            case .chest, .legL, .legR, .skirtPanel, .sashTail: .hips
            case .shinL: .legL
            case .shinR: .legR
            case .bust, .capeL, .capeR, .armL, .armR, .head: .chest
            case .armL_fore: .armL
            case .armR_fore: .armR
            case .handL: .armL_fore
            case .handR: .armR_fore
            case .hairBase, .sideLockL, .sideLockR, .earringL, .earringR: .head
            case .hairMid: .hairBase
            case .hairTip: .hairMid
            }
        }

        public var pivot: CGPoint {
            typealias M = HancockParts.Mark
            let mid = HancockParts.cx
            func mirror(_ point: CGPoint) -> CGPoint { CGPoint(x: mid * 2 - point.x, y: point.y) }
            let shoulder = CGPoint(x: M.shoulderX, y: M.shoulderY)
            let elbow = CGPoint(x: M.shoulderX, y: M.elbow)
            let wrist = CGPoint(x: M.shoulderX, y: M.wrist)
            let hip = CGPoint(x: M.legX, y: M.legTop)
            let knee = CGPoint(x: M.legX, y: M.knee)
            let cape = CGPoint(x: 80, y: 68)
            let lock = CGPoint(x: 85, y: 35)
            let lobe = CGPoint(x: 85.4, y: 53)
            return switch self {
            case .root, .figure: CGPoint(x: mid, y: 196)
            case .heart: CGPoint(x: 130, y: 16)
            case .hips, .chest: CGPoint(x: mid, y: M.waist)
            case .bust: CGPoint(x: mid, y: 80)
            case .legL: hip
            case .legR: mirror(hip)
            case .shinL: knee
            case .shinR: mirror(knee)
            case .skirtPanel: CGPoint(x: 72.6, y: 150)
            case .sashTail: CGPoint(x: HancockParts.Top.knot.0, y: HancockParts.Top.knot.1)
            case .capeL: cape
            case .capeR: mirror(cape)
            case .armL: shoulder
            case .armR: mirror(shoulder)
            case .armL_fore: elbow
            case .armR_fore: mirror(elbow)
            case .handL: wrist
            case .handR: mirror(wrist)
            case .head: CGPoint(x: mid, y: M.chin - 2)
            case .hairBase: CGPoint(x: mid, y: 34)
            case .hairMid: CGPoint(x: mid, y: 100)
            case .hairTip: CGPoint(x: mid, y: 152)
            case .sideLockL: lock
            case .sideLockR: mirror(lock)
            case .earringL: lobe
            case .earringR: mirror(lobe)
            }
        }
    }

    public typealias Layer = RigLayer<Part>

    /// Back to front: cape, back hair, skirt lining, legs, skirt and slit
    /// panel, lower midriff, low sash with its knot and loose end, neck, upper
    /// midriff, top, waist belt, the V, bust, frill, arms, epaulettes, head and
    /// face, front hair, side locks, earrings, heart.
    public static let layers: [Layer] = {
        let assembled: [Layer] =
            HancockParts.Cape.layers()
            + HancockParts.Hair.back()
            + HancockParts.Skirt.lining()
            + HancockParts.Legs.layers()
            + HancockParts.Skirt.main()
            + HancockParts.Skirt.panel()
            + HancockParts.Top.lowerMidriff()
            + HancockParts.Top.sash()
            + HancockParts.Top.sashTail()
            + HancockParts.Top.sashKnot()
            + HancockParts.Top.neck()
            + HancockParts.Top.upperMidriff()
            + HancockParts.Top.chest()
            + HancockParts.Top.belt()
            + HancockParts.Top.neckline()
            + HancockParts.Top.bust()
            + HancockParts.Top.frill()
            + HancockParts.Arms.layers()
            + HancockParts.Top.epaulettes()
            + HancockParts.Face.head()
            + HancockParts.Face.sets()
            + HancockParts.Hair.front()
            + HancockParts.Hair.sideLocks()
            + HancockParts.Hair.earrings()
            + HancockParts.Props.heart()
        // Ids assigned after concatenation so ForEach always gets unique ones.
        return assembled.enumerated().map { index, layer in
            Layer(index + 1, layer.name, layer.part, layer.fill,
                  stroke: layer.stroke, path: layer.path, restOpacity: layer.restOpacity)
        }
    }()
}
