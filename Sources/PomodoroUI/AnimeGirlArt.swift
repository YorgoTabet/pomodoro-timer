import CoreGraphics
import SwiftUI

/// Path data and rig for the anime girl — adult proportions, idol stagewear.
///
/// Head *count* was never what made the earlier drafts read as a child (5.5 heads
/// is already adult-range). Five other ratios were: shoulders the same width as
/// the head, no waist taper, short legs, a round face and moe-sized eyes. The
/// figure is authored against adult targets on all of them:
///
/// | ratio                  | before | now  | adult F |
/// |------------------------|--------|------|---------|
/// | shoulders / head width | 1.03   | 1.63 | ~1.6    |
/// | waist / shoulders      | 0.97   | 0.66 | ~0.70   |
/// | leg fraction of height | 0.42   | 0.48 | ~0.47   |
/// | face width : height    | 0.81   | 0.74 | ~0.72   |
/// | eye height / face      | 0.21   | 0.16 | ~0.13   |
///
/// Vertical landmarks, in canvas units: skull 26.5, eye line 44, chin 62.8,
/// shoulder 76, bust 93, waist 119, hip break 136, boot top 170, sole 239.
/// The silhouette is natural and understated — the taper is anatomy, not
/// emphasis, and that restraint is deliberate.
///
/// Outfit is vocaloid-*inspired*, not a copy: white crop top with a teal tie,
/// blue pleated mini skirt, detached navy forearm sleeves, over-knee boots. The
/// hair stays lavender and there is no headset, so she remains our character.
///
/// Geometry contracts the rest of the app relies on:
/// - The occluding edge is y=196. Masked cues show her from the crown to the
///   knee; only the unmasked cues reveal the boots' feet at 239.
/// - Two-segment limbs (elbows, both twin tails) use the rabbit's construction:
///   the parent is cut flat just past the pivot and the child's rounded proximal
///   cap is centred on the pivot and drawn over it, so no gap opens at any angle.
/// - Arms draw *behind* the head, so any gesture aimed "beside the head" must
///   clear the skull silhouette — see the -155° cap in `fistPump`.
/// - Layer names in the expression cluster (mouths, brows, eye parts, sparkles)
///   are matched by string in `AnimeGirlPose.opacity(of:)` — rename them there
///   too or the cross-fades silently stop.
public enum AnimeGirlArt {

    public static let canvas = CGSize(width: 200, height: 260)

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

        public var pivot: CGPoint {
            switch self {
            case .root: CGPoint(x: 100, y: 196)
            case .sparkles: CGPoint(x: 100, y: 80)
            case .figure: CGPoint(x: 100, y: 196)
            case .hips: CGPoint(x: 100, y: 122)
            case .legL: CGPoint(x: 94, y: 138)
            case .legR: CGPoint(x: 106, y: 138)
            case .torso: CGPoint(x: 100, y: 119)
            // Shoulder joints sit at the deltoid, now 22 units off centre rather
            // than 20 — the widened shoulder line is most of the adult read.
            case .armL: CGPoint(x: 81, y: 80)
            case .armR: CGPoint(x: 119, y: 80)
            case .armL_fore: CGPoint(x: 81, y: 112)
            case .armR_fore: CGPoint(x: 119, y: 112)
            // Base of the skull, so a head turn pivots on the neck.
            case .head: CGPoint(x: 100, y: 61)
            case .eyes: CGPoint(x: 100, y: 45.8)
            case .ahoge: CGPoint(x: 97, y: 17)
            case .tailL_base: CGPoint(x: 86, y: 32)
            case .tailL_tip: CGPoint(x: 78.5, y: 96)
            case .tailR_base: CGPoint(x: 114, y: 32)
            case .tailR_tip: CGPoint(x: 121.5, y: 96)
            }
        }
    }

    public typealias Layer = RigLayer<Part>

    /// Back to front. Hair curtain and both tails behind the body; legs behind
    /// the skirt; bare torso behind the crop top; arms in front of the top but
    /// behind the head; hair ties on the finished crown; sparkles last.
    public static let layers: [Layer] = [
        .init(1, "backHair", .head, Ink.hairShadow, stroke: 3.0, "M 87.0 40.0 Q 83.5 60.0 84.0 86.0 Q 84.5 108.0 87.0 126.0 Q 93.0 131.0 100.0 129.0 Q 107.0 131.0 113.0 126.0 Q 115.5 108.0 116.0 86.0 Q 116.5 60.0 113.0 40.0 Q 100.0 30.0 87.0 40.0 Z"),
        // Tails sweep out from the root, carry their weight low, and taper to a
        // point. The previous pass made them the right *width* but drew them as
        // parallel straight tubes, which read as curtains hung beside her head —
        // correct measurement, no drawing.
        .init(2, "tailL_base", .tailL_base, Ink.hair, stroke: 3.0, "M 88.0 28.0 Q 79.0 33.0 75.0 48.0 Q 71.5 63.0 72.0 82.0 Q 72.3 91.0 73.5 96.5 L 84.0 96.0 Q 84.5 76.0 85.0 58.0 Q 85.5 41.0 88.0 28.0 Z"),
        .init(3, "tailL_tip", .tailL_tip, Ink.hair, stroke: 3.0, "M 73.5 96.0 Q 73.5 90.5 78.5 90.5 Q 83.5 90.5 83.5 96.0 Q 84.5 118.0 81.5 140.0 Q 79.0 156.0 74.0 166.0 Q 69.5 154.0 69.5 133.0 Q 69.5 112.0 73.5 96.0 Z"),
        .init(6, "tailShineL", .tailL_base, Ink.hairShine, stroke: nil, "M 78.0 44.0 Q 74.5 60.0 75.0 80.0 L 78.0 80.0 Q 78.0 60.0 80.5 44.0 Z"),
        .init(4, "tailR_base", .tailR_base, Ink.hair, stroke: 3.0, "M 112.0 28.0 Q 121.0 33.0 125.0 48.0 Q 128.5 63.0 128.0 82.0 Q 127.7 91.0 126.5 96.5 L 116.0 96.0 Q 115.5 76.0 115.0 58.0 Q 114.5 41.0 112.0 28.0 Z"),
        .init(5, "tailR_tip", .tailR_tip, Ink.hair, stroke: 3.0, "M 126.5 96.0 Q 126.5 90.5 121.5 90.5 Q 116.5 90.5 116.5 96.0 Q 115.5 118.0 118.5 140.0 Q 121.0 156.0 126.0 166.0 Q 130.5 154.0 130.5 133.0 Q 130.5 112.0 126.5 96.0 Z"),
        .init(7, "tailShineR", .tailR_base, Ink.hairShine, stroke: nil, "M 122.0 44.0 Q 125.5 60.0 125.0 80.0 L 122.0 80.0 Q 122.0 60.0 119.5 44.0 Z"),
        // Thighs taper 10 → 8.3; the hip break at 136 is what buys the adult leg
        // fraction (0.48 of total height, up from 0.42).
        .init(8, "thighL", .legL, Ink.skin, stroke: 3.0, "M 87.5 134.0 L 97.5 134.0 L 96.8 176.0 L 88.5 176.0 Z"),
        .init(9, "bootL", .legL, Ink.navy, stroke: 3.0, "M 87.4 170.0 L 86.9 202.0 Q 87.4 216.0 88.6 226.0 Q 88.2 233.0 86.6 236.5 Q 86.0 239.0 88.4 239.0 L 97.6 239.0 Q 98.8 234.0 98.4 226.0 Q 98.2 214.0 98.0 202.0 L 97.6 170.0 Q 92.5 167.5 87.4 170.0 Z"),
        .init(10, "bootTrimL", .legL, Ink.teal, stroke: nil, "M 87.45 170.5 L 97.55 170.5 L 97.5 174.0 L 87.4 174.0 Z"),
        .init(11, "thighR", .legR, Ink.skin, stroke: 3.0, "M 102.5 134.0 L 112.5 134.0 L 111.5 176.0 L 103.2 176.0 Z"),
        .init(12, "bootR", .legR, Ink.navy, stroke: 3.0, "M 102.4 170.0 L 102.0 202.0 Q 101.8 214.0 101.6 226.0 Q 101.2 234.0 102.4 239.0 L 111.6 239.0 Q 114.0 239.0 113.4 236.5 Q 111.8 233.0 111.4 226.0 Q 112.6 216.0 113.1 202.0 L 112.6 170.0 Q 107.5 167.5 102.4 170.0 Z"),
        .init(13, "bootTrimR", .legR, Ink.teal, stroke: nil, "M 102.45 170.5 L 112.55 170.5 L 112.6 174.0 L 102.5 174.0 Z"),
        .init(14, "skirt", .hips, Ink.blue, stroke: 3.0, "M 85.0 120.0 L 115.0 120.0 Q 118.5 136.0 121.5 150.0 Q 122.0 154.0 121.5 157.0 L 114.0 153.5 L 107.0 158.0 L 100.0 153.5 L 93.0 158.0 L 86.0 153.5 L 78.5 157.0 Q 78.0 154.0 78.5 150.0 Q 81.5 136.0 85.0 120.0 Z"),
        .init(15, "skirtShade", .hips, Ink.blueDeep, stroke: nil, "M 109.0 120.0 L 115.0 120.0 Q 118.5 136.0 121.5 150.0 Q 122.0 154.0 121.5 157.0 L 114.0 153.5 L 112.0 150.0 Z M 93.0 158.0 L 90.5 154.0 L 96.0 154.2 Z M 107.0 158.0 L 104.0 154.0 L 109.5 154.2 Z"),
        .init(64, "skirtBand", .hips, Ink.blueDeep, stroke: nil, "M 85.3 116.0 L 114.7 116.0 L 115.2 122.0 L 84.8 122.0 Z"),
        // Bare torso: shoulders above the neckline and the midriff band below the
        // hem. Widest at the ribcage (37), narrowest at the waist (28.4).
        .init(63, "torsoSkin", .torso, Ink.skin, stroke: 3.0, "M 85.0 78.0 Q 92.0 73.5 100.0 73.0 Q 108.0 73.5 115.0 78.0 Q 118.5 84.0 118.5 93.0 Q 118.0 102.0 116.6 110.0 Q 115.9 115.0 115.5 119.5 L 84.5 119.5 Q 84.1 115.0 83.4 110.0 Q 82.0 102.0 81.5 93.0 Q 81.5 84.0 85.0 78.0 Z"),
        .init(66, "waistShade", .torso, Ink.skinShade, stroke: nil, "M 113.0 110.0 Q 114.2 115.0 114.8 119.5 L 109.0 119.5 Q 109.8 115.0 110.5 110.0 Z"),
        .init(20, "cropTop", .torso, Ink.white, stroke: 3.0, "M 86.0 77.0 Q 92.0 82.5 100.0 82.5 Q 108.0 82.5 114.0 77.0 Q 116.5 76.5 117.5 79.0 Q 119.5 85.0 119.3 94.0 Q 118.8 102.0 117.2 108.5 L 82.8 108.5 Q 81.2 102.0 80.7 94.0 Q 80.5 85.0 82.5 79.0 Q 83.5 76.5 86.0 77.0 Z"),
        .init(65, "topShade", .torso, Ink.cloth, stroke: nil, "M 110.0 80.5 Q 115.5 81.0 117.0 84.0 Q 119.4 90.0 119.3 96.0 Q 118.9 103.0 117.2 108.5 L 110.5 108.5 Q 111.5 95.0 110.0 80.5 Z"),
        .init(62, "topHem", .torso, Ink.teal, stroke: nil, "M 82.9 105.8 L 117.1 105.8 L 117.2 108.5 L 82.8 108.5 Z"),
        .init(21, "tie", .torso, Ink.teal, stroke: 1.8, "M 97.5 84.0 L 102.5 84.0 L 101.6 87.5 L 98.4 87.5 Z M 98.4 87.5 L 101.6 87.5 Q 102.8 94.0 100.0 99.0 Q 97.2 94.0 98.4 87.5 Z"),
        // Upper arms taper 7.6 → 6.7 and carry the deltoid out to x=78/122, which
        // is the single biggest change: shoulders now 1.63 head-widths, not 1.03.
        .init(16, "armL_skin", .armL, Ink.skin, stroke: 3.0, "M 85.5 76.0 Q 79.8 78.0 78.1 86.0 Q 77.0 94.0 77.5 112.0 L 85.0 112.0 Q 85.4 96.0 86.4 84.0 Q 86.9 78.5 85.5 76.0 Z"),
        .init(56, "foreSleeveL", .armL_fore, Ink.navy, stroke: 3.0, "M 77.0 112.0 Q 77.0 106.8 81.0 106.8 Q 85.0 106.8 85.0 112.0 L 84.7 134.0 Q 85.8 139.0 84.2 141.0 L 77.8 141.0 Q 76.2 139.0 77.3 134.0 Z"),
        .init(17, "handL", .armL_fore, Ink.skin, stroke: 1.8, "M 78.0 140.0 Q 76.8 145.8 78.3 150.5 Q 81.0 152.6 83.9 150.5 Q 85.4 145.8 84.2 140.0 Q 81.0 138.2 78.0 140.0 Z"),
        .init(24, "armR_skin", .armR, Ink.skin, stroke: 3.0, "M 114.5 76.0 Q 120.2 78.0 121.9 86.0 Q 123.0 94.0 122.5 112.0 L 115.0 112.0 Q 114.6 96.0 113.6 84.0 Q 113.1 78.5 114.5 76.0 Z"),
        .init(57, "foreSleeveR", .armR_fore, Ink.navy, stroke: 3.0, "M 123.0 112.0 Q 123.0 106.8 119.0 106.8 Q 115.0 106.8 115.0 112.0 L 115.3 134.0 Q 114.2 139.0 115.8 141.0 L 122.2 141.0 Q 123.8 139.0 122.7 134.0 Z"),
        .init(25, "handR", .armR_fore, Ink.skin, stroke: 1.8, "M 122.0 140.0 Q 123.2 145.8 121.7 150.5 Q 119.0 152.6 116.1 150.5 Q 114.6 145.8 115.8 140.0 Q 119.0 138.2 122.0 140.0 Z"),
        .init(26, "neck", .torso, Ink.skin, stroke: nil, "M 95.6 60.0 L 94.8 76.0 L 105.2 76.0 L 104.4 60.0 Z"),
        // Face 28 × 37.5 (w:h 0.75). The jaw curves into a soft chin rather than
        // the spike the previous pass drew — 0.74 measured fine and looked gaunt.
        .init(27, "headBase", .head, Ink.skin, stroke: 3.0, "M 86.0 43.5 Q 86.0 27.0 100.0 26.0 Q 114.0 27.0 114.0 43.5 Q 114.0 52.0 110.5 57.5 Q 106.5 62.5 100.0 63.5 Q 93.5 62.5 89.5 57.5 Q 86.0 52.0 86.0 43.5 Z"),
        .init(28, "blush", .head, Ink.blush, stroke: nil, "M 88.0 53.5 Q 90.8 52.1 93.6 53.5 Q 90.8 54.8 88.0 53.5 Z M 106.4 53.5 Q 109.2 52.1 112.0 53.5 Q 109.2 54.8 106.4 53.5 Z"),
        .init(59, "nose", .head, Ink.clear, stroke: 1.2, "M 99.5 54.0 Q 100.8 54.7 100.2 56.0"),
        .init(29, "mouthDefault", .head, Ink.clear, stroke: 1.6, "M 97.2 58.6 Q 100.0 60.2 102.8 58.6"),
        .init(30, "mouthHappy", .head, Ink.mouthDeep, stroke: 1.6, "M 96.4 57.8 L 103.6 57.8 Q 102.4 61.4 100.0 61.4 Q 97.6 61.4 96.4 57.8 Z", restOpacity: 0),
        .init(31, "mouthDetermined", .head, Ink.white, stroke: 1.6, "M 96.9 58.1 L 103.1 58.1 Q 102.4 60.1 100.0 60.1 Q 97.6 60.1 96.9 58.1 Z", restOpacity: 0),
        // 7.3 tall on a 37.5 face — 0.195. The 0.16 of the last pass was an
        // overcorrection: small eyes on a long face read gaunt, not adult. Adult
        // anime leads sit near 0.20; what ages a face is the jaw and the lid
        // line, not shrinking the eye.
        .init(32, "eyeWhiteL", .head, Ink.white, stroke: 1.2, "M 87.6 45.8 Q 88.2 42.4 92.2 42.2 Q 96.4 42.4 97.0 45.6 Q 96.4 49.4 92.3 49.5 Q 88.2 49.4 87.6 45.8 Z"),
        .init(33, "eyeWhiteR", .head, Ink.white, stroke: 1.2, "M 112.4 45.8 Q 111.8 42.4 107.8 42.2 Q 103.6 42.4 103.0 45.6 Q 103.6 49.4 107.7 49.5 Q 111.8 49.4 112.4 45.8 Z"),
        .init(34, "irisL", .eyes, Ink.iris, stroke: nil, "M 89.6 45.8 Q 89.6 42.5 92.3 42.5 Q 95.0 42.5 95.0 46.0 Q 95.0 49.3 92.3 49.3 Q 89.6 49.3 89.6 45.8 Z"),
        .init(35, "irisR", .eyes, Ink.iris, stroke: nil, "M 105.0 45.8 Q 105.0 42.5 107.7 42.5 Q 110.4 42.5 110.4 46.0 Q 110.4 49.3 107.7 49.3 Q 105.0 49.3 105.0 45.8 Z"),
        .init(36, "pupilL", .eyes, Ink.ink, stroke: nil, "M 91.1 45.9 Q 91.1 43.9 92.3 43.9 Q 93.5 43.9 93.5 46.1 Q 93.5 48.2 92.3 48.2 Q 91.1 48.2 91.1 45.9 Z"),
        .init(37, "pupilR", .eyes, Ink.ink, stroke: nil, "M 106.5 45.9 Q 106.5 43.9 107.7 43.9 Q 108.9 43.9 108.9 46.1 Q 108.9 48.2 107.7 48.2 Q 106.5 48.2 106.5 45.9 Z"),
        .init(38, "hiBigL", .eyes, Ink.white, stroke: nil, path: VectorPath.circle(90.9, 43.9, 1.1)),
        .init(39, "hiBigR", .eyes, Ink.white, stroke: nil, path: VectorPath.circle(106.3, 43.9, 1.1)),
        .init(40, "hiSmallL", .eyes, Ink.white, stroke: nil, path: VectorPath.circle(93.8, 48.4, 0.6)),
        .init(41, "hiSmallR", .eyes, Ink.white, stroke: nil, path: VectorPath.circle(109.2, 48.4, 0.6)),
        // Heavy upper lid with an outer flick — this is what does the aging work.
        .init(42, "lashL", .head, Ink.ink, stroke: nil, "M 86.3 44.6 Q 87.0 41.0 92.2 40.7 Q 96.8 40.8 97.6 44.4 L 96.5 45.0 Q 95.4 42.4 92.2 42.6 Q 89.0 42.8 88.0 46.0 Z"),
        .init(43, "lashR", .head, Ink.ink, stroke: nil, "M 113.7 44.6 Q 113.0 41.0 107.8 40.7 Q 103.2 40.8 102.4 44.4 L 103.5 45.0 Q 104.6 42.4 107.8 42.6 Q 111.0 42.8 112.0 46.0 Z"),
        // A domed crown with real volume. The old one arced from 84.5 to 19.5
        // through flat control points and rendered as a bowl-cut cap.
        .init(44, "hairCrown", .head, Ink.hair, stroke: 3.0, "M 83.5 46.0 Q 79.5 28.0 90.5 20.0 Q 100.0 14.0 110.5 19.0 Q 120.0 24.5 118.0 46.0 Q 116.5 36.0 112.5 31.0 Q 100.0 25.0 88.0 31.0 Q 84.5 36.0 83.5 46.0 Z"),
        // Short, swept, tapering to a point at the jaw — framing the face rather
        // than hanging past it like a drape and splitting the face in three.
        .init(45, "sideLockL", .head, Ink.hair, stroke: 2.2, "M 86.0 34.0 Q 81.5 46.0 82.2 58.0 Q 82.8 67.0 85.5 72.0 Q 88.8 64.0 88.4 52.0 Q 88.2 43.0 88.8 35.5 Z"),
        .init(46, "sideLockR", .head, Ink.hair, stroke: 2.2, "M 114.0 34.0 Q 118.5 46.0 117.8 58.0 Q 117.2 67.0 114.5 72.0 Q 111.2 64.0 111.6 52.0 Q 111.8 43.0 111.2 35.5 Z"),
        // One smooth swept curve. Cutting the hem into four lock tips rendered as
        // a sawtooth band across her forehead — at this scale a 3pt stroke turns
        // every interior point into a spike, so the fringe gets its shape from
        // the sweep, not from notches. Clears the brows: an exposed forehead ages
        // a face up, blunt bangs to the eyes read young.
        .init(47, "bangs", .head, Ink.hair, stroke: 3.0, "M 83.5 45.0 Q 79.5 27.0 91.0 19.5 Q 101.0 13.5 111.0 18.5 Q 120.0 24.0 118.0 45.0 Q 116.0 32.0 111.0 28.5 Q 100.0 36.0 90.0 29.5 Q 85.5 33.0 83.5 45.0 Z"),
        .init(48, "hairShine", .head, Ink.hairShine, stroke: nil, "M 88.0 26.0 Q 98.0 19.5 108.5 22.5 Q 113.0 24.5 115.0 27.5 Q 104.0 22.5 91.5 28.5 Q 89.0 27.5 88.0 26.0 Z"),
        .init(49, "browsDefault", .head, Ink.clear, stroke: 1.5, "M 87.5 38.4 Q 91.5 36.4 95.8 37.8 M 104.2 37.8 Q 108.5 36.4 112.5 38.4"),
        .init(50, "browsDetermined", .head, Ink.clear, stroke: 1.5, "M 88.0 36.4 Q 92.0 37.2 95.9 39.4 M 104.1 39.4 Q 108.0 37.2 112.0 36.4", restOpacity: 0),
        .init(51, "closedEyesHappy", .head, Ink.clear, stroke: 1.8, "M 87.6 47.4 Q 92.3 42.8 97.0 47.4 M 103.0 47.4 Q 107.7 42.8 112.4 47.4", restOpacity: 0),
        // Small and subtle. A tall bouncing ahoge is a genki-kid signal; it still
        // has to exist because the performances drive it as the emotional lag.
        .init(52, "ahoge", .ahoge, Ink.clear, stroke: 2.2, "M 97.0 17.0 C 94.8 11.5 98.8 7.5 103.4 9.0 C 106.6 10.0 104.6 14.0 100.8 12.6"),
        .init(60, "tieHairL", .tailL_base, Ink.teal, stroke: 1.6, path: VectorPath.circle(86.0, 32.0, 2.6)),
        .init(61, "tieHairR", .tailR_base, Ink.teal, stroke: 1.6, path: VectorPath.circle(114.0, 32.0, 2.6)),
        // All three start upper-left/upper-right so the twirl's 90° orbit about
        // (100, 80) — cubic overshoot included — never sweeps across the body.
        .init(53, "sparkleA", .sparkles, Ink.white, stroke: nil, "M 42.0 30.0 L 44.2 35.8 L 50.0 38.0 L 44.2 40.2 L 42.0 46.0 L 39.8 40.2 L 34.0 38.0 L 39.8 35.8 Z", restOpacity: 0),
        .init(54, "sparkleB", .sparkles, Ink.teal, stroke: nil, "M 56.0 14.0 L 57.7 18.3 L 62.0 20.0 L 57.7 21.7 L 56.0 26.0 L 54.3 21.7 L 50.0 20.0 L 54.3 18.3 Z", restOpacity: 0),
        .init(55, "sparkleC", .sparkles, Ink.white, stroke: nil, "M 150.0 21.0 L 151.4 24.6 L 155.0 26.0 L 151.4 27.4 L 150.0 31.0 L 148.6 27.4 L 145.0 26.0 L 148.6 24.6 Z", restOpacity: 0),
    ]
}
