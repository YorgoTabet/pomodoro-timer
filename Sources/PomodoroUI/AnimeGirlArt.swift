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
            case .head: CGPoint(x: 100, y: 60)
            case .eyes: CGPoint(x: 100, y: 44)
            case .ahoge: CGPoint(x: 97, y: 19)
            case .tailL_base: CGPoint(x: 86, y: 33)
            case .tailL_tip: CGPoint(x: 77.5, y: 96)
            case .tailR_base: CGPoint(x: 114, y: 33)
            case .tailR_tip: CGPoint(x: 122.5, y: 96)
            }
        }
    }

    public typealias Layer = RigLayer<Part>

    /// Back to front. Hair curtain and both tails behind the body; legs behind
    /// the skirt; bare torso behind the crop top; arms in front of the top but
    /// behind the head; hair ties on the finished crown; sparkles last.
    public static let layers: [Layer] = [
        .init(1, "backHair", .head, Ink.hairShadow, stroke: 3.0, "M 86.0 40.0 Q 82.5 60.0 83.0 88.0 Q 83.5 110.0 86.0 128.0 Q 92.5 132.0 100.0 130.0 Q 107.5 132.0 114.0 128.0 Q 116.5 110.0 117.0 88.0 Q 117.5 60.0 114.0 40.0 Q 100.0 30.0 86.0 40.0 Z"),
        // Ropes, not balloons. The whole hair silhouette is now 1.28 shoulder
        // widths (was 1.56) — an oversized hair mass reads as an oversized head,
        // which was doing as much of the "child" work as the face itself.
        .init(2, "tailL_base", .tailL_base, Ink.hair, stroke: 3.0, "M 87.0 30.0 Q 80.0 34.0 77.0 48.0 Q 74.0 64.0 74.5 82.0 Q 74.8 91.0 76.0 96.5 L 83.0 96.0 Q 83.5 78.0 84.0 60.0 Q 84.5 42.0 87.0 30.0 Z"),
        .init(3, "tailL_tip", .tailL_tip, Ink.hair, stroke: 3.0, "M 73.5 96.0 Q 73.5 91.5 77.5 91.5 Q 81.5 91.5 81.5 96.0 Q 82.0 116.0 80.0 136.0 Q 78.5 150.0 75.0 160.0 Q 71.0 150.0 70.5 132.0 Q 70.0 112.0 73.5 96.0 Z"),
        .init(6, "tailShineL", .tailL_base, Ink.hairShine, stroke: nil, "M 79.0 46.0 Q 76.5 62.0 77.0 82.0 L 79.0 82.0 Q 79.0 62.0 81.0 46.0 Z"),
        .init(4, "tailR_base", .tailR_base, Ink.hair, stroke: 3.0, "M 113.0 30.0 Q 120.0 34.0 123.0 48.0 Q 126.0 64.0 125.5 82.0 Q 125.2 91.0 124.0 96.5 L 117.0 96.0 Q 116.5 78.0 116.0 60.0 Q 115.5 42.0 113.0 30.0 Z"),
        .init(5, "tailR_tip", .tailR_tip, Ink.hair, stroke: 3.0, "M 126.5 96.0 Q 126.5 91.5 122.5 91.5 Q 118.5 91.5 118.5 96.0 Q 118.0 116.0 120.0 136.0 Q 121.5 150.0 125.0 160.0 Q 129.0 150.0 129.5 132.0 Q 130.0 112.0 126.5 96.0 Z"),
        .init(7, "tailShineR", .tailR_base, Ink.hairShine, stroke: nil, "M 121.0 46.0 Q 123.5 62.0 123.0 82.0 L 121.0 82.0 Q 121.0 62.0 119.0 46.0 Z"),
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
        // A longer neck than the chibi draft, but not a stalk — 10 wide, not 7.6.
        .init(26, "neck", .torso, Ink.skin, stroke: nil, "M 95.6 58.0 L 94.8 75.0 L 105.2 75.0 L 104.4 58.0 Z"),
        // Face 27 × 36.3 (w:h 0.74) with a real jaw taper to a 7-unit chin.
        .init(27, "headBase", .head, Ink.skin, stroke: 3.0, "M 86.5 44.0 Q 86.5 27.5 100.0 26.5 Q 113.5 27.5 113.5 44.0 Q 113.5 52.0 110.2 56.5 Q 106.2 61.5 100.0 62.8 Q 93.8 61.5 89.8 56.5 Q 86.5 52.0 86.5 44.0 Z"),
        .init(28, "blush", .head, Ink.blush, stroke: nil, "M 88.0 52.5 Q 90.5 51.2 93.0 52.5 Q 90.5 53.6 88.0 52.5 Z M 107.0 52.5 Q 109.5 51.2 112.0 52.5 Q 109.5 53.6 107.0 52.5 Z"),
        .init(59, "nose", .head, Ink.clear, stroke: 1.2, "M 99.6 52.6 Q 100.7 53.2 100.2 54.3"),
        .init(29, "mouthDefault", .head, Ink.clear, stroke: 1.6, "M 97.3 57.3 Q 100.0 58.8 102.7 57.3"),
        .init(30, "mouthHappy", .head, Ink.mouthDeep, stroke: 1.6, "M 96.6 56.6 L 103.4 56.6 Q 102.3 60.0 100.0 60.0 Q 97.7 60.0 96.6 56.6 Z", restOpacity: 0),
        .init(31, "mouthDetermined", .head, Ink.white, stroke: 1.6, "M 97.0 56.9 L 103.0 56.9 Q 102.3 58.8 100.0 58.8 Q 97.7 58.8 97.0 56.9 Z", restOpacity: 0),
        // Almond eyes, 5.7 tall on a 36.3 face (0.16) — down from the moe 0.21,
        // and set on the skull midline where an adult's sit.
        .init(32, "eyeWhiteL", .head, Ink.white, stroke: 1.2, "M 88.0 44.6 Q 89.0 41.3 92.4 41.2 Q 96.0 41.4 96.9 44.3 Q 95.2 46.9 92.3 46.9 Q 89.1 46.9 88.0 44.6 Z"),
        .init(33, "eyeWhiteR", .head, Ink.white, stroke: 1.2, "M 112.0 44.6 Q 111.0 41.3 107.6 41.2 Q 104.0 41.4 103.1 44.3 Q 104.8 46.9 107.7 46.9 Q 110.9 46.9 112.0 44.6 Z"),
        .init(34, "irisL", .eyes, Ink.iris, stroke: nil, "M 90.3 44.2 Q 90.3 41.6 92.3 41.6 Q 94.3 41.6 94.3 44.4 Q 94.3 46.9 92.3 46.9 Q 90.3 46.9 90.3 44.2 Z"),
        .init(35, "irisR", .eyes, Ink.iris, stroke: nil, "M 105.7 44.2 Q 105.7 41.6 107.7 41.6 Q 109.7 41.6 109.7 44.4 Q 109.7 46.9 107.7 46.9 Q 105.7 46.9 105.7 44.2 Z"),
        .init(36, "pupilL", .eyes, Ink.ink, stroke: nil, "M 91.5 44.3 Q 91.5 42.7 92.3 42.7 Q 93.1 42.7 93.1 44.5 Q 93.1 46.2 92.3 46.2 Q 91.5 46.2 91.5 44.3 Z"),
        .init(37, "pupilR", .eyes, Ink.ink, stroke: nil, "M 106.9 44.3 Q 106.9 42.7 107.7 42.7 Q 108.5 42.7 108.5 44.5 Q 108.5 46.2 107.7 46.2 Q 106.9 46.2 106.9 44.3 Z"),
        .init(38, "hiBigL", .eyes, Ink.white, stroke: nil, path: VectorPath.circle(91.4, 42.8, 0.75)),
        .init(39, "hiBigR", .eyes, Ink.white, stroke: nil, path: VectorPath.circle(106.8, 42.8, 0.75)),
        .init(40, "hiSmallL", .eyes, Ink.white, stroke: nil, path: VectorPath.circle(93.5, 45.9, 0.45)),
        .init(41, "hiSmallR", .eyes, Ink.white, stroke: nil, path: VectorPath.circle(108.9, 45.9, 0.45)),
        // Heavier upper lid with an outer flick — adult eye makeup reads older
        // than the big round lash cluster it replaces.
        .init(42, "lashL", .head, Ink.ink, stroke: nil, "M 86.6 43.4 Q 87.4 40.4 92.3 40.2 Q 96.5 40.2 97.4 43.4 L 96.4 43.9 Q 95.2 41.6 92.3 41.8 Q 89.4 42.0 88.4 44.8 Z"),
        .init(43, "lashR", .head, Ink.ink, stroke: nil, "M 113.4 43.4 Q 112.6 40.4 107.7 40.2 Q 103.5 40.2 102.6 43.4 L 103.6 43.9 Q 104.8 41.6 107.7 41.8 Q 110.6 42.0 111.6 44.8 Z"),
        .init(44, "hairCrown", .head, Ink.hair, stroke: 3.0, "M 84.0 45.0 Q 81.0 27.0 93.0 21.0 Q 106.5 16.5 115.5 24.5 Q 119.0 31.5 117.5 45.0 Q 115.0 35.0 111.0 31.0 Q 100.0 26.0 89.0 31.5 Q 85.5 35.5 84.0 45.0 Z"),
        // Wide enough that the 2.2 stroke leaves fill visible. At 4 units with a
        // 3.0 stroke these rendered as solid black bars down her cheeks.
        .init(45, "sideLockL", .head, Ink.hair, stroke: 2.2, "M 86.5 36.0 Q 82.0 50.0 82.8 63.0 Q 83.4 71.0 86.0 75.0 Q 90.0 67.0 89.5 55.0 Q 89.0 45.0 89.5 37.0 Z"),
        .init(46, "sideLockR", .head, Ink.hair, stroke: 2.2, "M 113.5 36.0 Q 118.0 50.0 117.2 63.0 Q 116.6 71.0 114.0 75.0 Q 110.0 67.0 110.5 55.0 Q 111.0 45.0 110.5 37.0 Z"),
        // Side-swept, parted left of centre and clearing the brow line — an
        // exposed forehead ages a face up; blunt bangs to the eyes read young.
        .init(47, "bangs", .head, Ink.hair, stroke: 3.0, "M 84.0 44.0 Q 81.0 26.5 93.5 20.5 Q 107.0 16.0 115.8 24.0 Q 119.2 31.0 117.5 44.0 Q 116.3 36.0 113.0 32.0 Q 108.5 33.8 105.0 32.2 Q 101.0 30.2 99.5 27.5 Q 96.0 31.8 92.0 32.8 Q 88.0 33.5 86.6 37.4 Q 85.3 40.0 85.0 44.0 Z"),
        .init(48, "hairShine", .head, Ink.hairShine, stroke: nil, "M 89.0 28.0 Q 98.5 22.0 108.5 24.5 Q 112.5 26.0 114.5 29.0 Q 104.0 25.0 92.0 30.5 Q 90.0 29.5 89.0 28.0 Z"),
        .init(49, "browsDefault", .head, Ink.clear, stroke: 1.5, "M 87.5 37.6 Q 91.5 35.9 95.5 37.2 M 104.5 37.2 Q 108.5 35.9 112.5 37.6"),
        .init(50, "browsDetermined", .head, Ink.clear, stroke: 1.5, "M 88.0 35.8 Q 92.0 36.6 95.6 38.6 M 104.4 38.6 Q 108.0 36.6 112.0 35.8", restOpacity: 0),
        .init(51, "closedEyesHappy", .head, Ink.clear, stroke: 1.8, "M 88.0 45.6 Q 92.3 41.8 96.6 45.6 M 103.4 45.6 Q 107.7 41.8 112.0 45.6", restOpacity: 0),
        // Small and subtle. A tall bouncing ahoge is a genki-kid signal; it still
        // has to exist because the performances drive it as the emotional lag.
        .init(52, "ahoge", .ahoge, Ink.clear, stroke: 2.2, "M 97.0 19.0 C 94.8 13.5 98.8 9.5 103.4 11.0 C 106.6 12.0 104.6 16.0 100.8 14.6"),
        .init(60, "tieHairL", .tailL_base, Ink.teal, stroke: 1.6, path: VectorPath.circle(86.0, 33.0, 2.6)),
        .init(61, "tieHairR", .tailR_base, Ink.teal, stroke: 1.6, path: VectorPath.circle(114.0, 33.0, 2.6)),
        // All three start upper-left/upper-right so the twirl's 90° orbit about
        // (100, 80) — cubic overshoot included — never sweeps across the body.
        .init(53, "sparkleA", .sparkles, Ink.white, stroke: nil, "M 42.0 30.0 L 44.2 35.8 L 50.0 38.0 L 44.2 40.2 L 42.0 46.0 L 39.8 40.2 L 34.0 38.0 L 39.8 35.8 Z", restOpacity: 0),
        .init(54, "sparkleB", .sparkles, Ink.teal, stroke: nil, "M 56.0 14.0 L 57.7 18.3 L 62.0 20.0 L 57.7 21.7 L 56.0 26.0 L 54.3 21.7 L 50.0 20.0 L 54.3 18.3 Z", restOpacity: 0),
        .init(55, "sparkleC", .sparkles, Ink.white, stroke: nil, "M 150.0 21.0 L 151.4 24.6 L 155.0 26.0 L 151.4 27.4 L 150.0 31.0 L 148.6 27.4 L 145.0 26.0 L 148.6 24.6 Z", restOpacity: 0),
    ]
}
