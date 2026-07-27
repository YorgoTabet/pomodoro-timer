import CoreGraphics
import SwiftUI

/// The anime schoolgirl's artwork and rig.
///
/// She is the one character whose eyes carry the identity, so they are large,
/// glossy and drawn *over* the bangs — the classic anime convention — rather than
/// tucked under them. Her ahoge, the single cowlick curling off the crown, is an
/// emotional seismograph: it lags the head by 100ms and overshoots everything.
public enum AnimeGirlArt {

    public static let canvas = CGSize(width: 200, height: 260)

    public enum Ink {
        public static let outline = Color(hex: 0x2B2333)
        public static let ink = Color(hex: 0x2B2333)
        public static let hair = Color(hex: 0xC9A6F2)
        public static let hairShadow = Color(hex: 0xA57FD6)
        public static let hairShine = Color(hex: 0xE9DBFC)
        public static let blazer = Color(hex: 0x3F4C8F)
        public static let blazerShadow = Color(hex: 0x2F3A73)
        public static let rose = Color(hex: 0xF06292)
        public static let roseDeep = Color(hex: 0xB3486B)
        public static let skin = Color(hex: 0xFFE3D0)
        public static let blush = Color(hex: 0xFFADC0)
        public static let iris = Color(hex: 0x7C4DD4)
        public static let white = Color.white
        /// Stroke-only paths: the ahoge, the brows, and the closed-eye arcs.
        public static let clear = Color.clear
    }

    public enum Part: String, CaseIterable, RigPart {
        public static var canvas: CGSize { AnimeGirlArt.canvas }

        case root, sparkles, figure, hips, legL, legR, torso
        case armL, armR, head, eyes, ahoge
        case tailL_base, tailL_tip, tailR_base, tailR_tip

        public var parent: Part? {
            switch self {
            case .root: nil
            case .sparkles, .figure: .root
            case .hips: .figure
            case .legL, .legR, .torso: .hips
            case .armL, .armR, .head: .torso
            case .eyes, .ahoge, .tailL_base, .tailR_base: .head
            case .tailL_tip: .tailL_base
            case .tailR_tip: .tailR_base
            }
        }

        public var pivot: CGPoint {
            switch self {
            case .root: CGPoint(x: 100, y: 196)
            case .sparkles: CGPoint(x: 100, y: 100)
            case .figure: CGPoint(x: 100, y: 196)
            case .hips: CGPoint(x: 100, y: 165)
            case .legL: CGPoint(x: 91, y: 189)
            case .legR: CGPoint(x: 109, y: 189)
            case .torso: CGPoint(x: 100, y: 164)
            case .armL: CGPoint(x: 77, y: 122)
            case .armR: CGPoint(x: 123, y: 122)
            case .head: CGPoint(x: 100, y: 118)
            case .eyes: CGPoint(x: 100, y: 83)
            case .ahoge: CGPoint(x: 98, y: 22)
            case .tailL_base: CGPoint(x: 55, y: 48)
            case .tailL_tip: CGPoint(x: 52, y: 128)
            case .tailR_base: CGPoint(x: 145, y: 48)
            case .tailR_tip: CGPoint(x: 148, y: 128)
            }
        }
    }

    public typealias Layer = RigLayer<Part>

    /// Back to front. Twin tails and back-hair behind the head; the ahoge in front
    /// of the crown so it always reads; brows and closed-eye arcs after the bangs.
    public static let layers: [Layer] = [
        .init(1, "backHair", .head, Ink.hairShadow, stroke: 3.0, "M 62.0 44.0 Q 54.0 78.0 66.0 108.0 L 134.0 108.0 Q 146.0 78.0 138.0 44.0 Q 100.0 30.0 62.0 44.0 Z"),
        .init(2, "tailL_base", .tailL_base, Ink.hair, stroke: 3.0, "M 57.0 46.0 Q 44.0 52.0 39.0 70.0 Q 34.0 92.0 38.0 114.0 Q 40.0 124.0 44.0 130.0 L 66.0 126.0 Q 70.0 100.0 68.0 76.0 Q 66.0 56.0 57.0 46.0 Z"),
        .init(3, "tailL_tip", .tailL_tip, Ink.hair, stroke: 3.0, "M 44.0 130.0 Q 48.0 146.0 44.0 160.0 Q 40.0 172.0 31.0 180.0 Q 45.0 181.0 54.0 170.0 Q 63.0 156.0 66.0 126.0 Z"),
        .init(4, "tailR_base", .tailR_base, Ink.hair, stroke: 3.0, "M 143.0 46.0 Q 156.0 52.0 161.0 70.0 Q 166.0 92.0 162.0 114.0 Q 160.0 124.0 156.0 130.0 L 134.0 126.0 Q 130.0 100.0 132.0 76.0 Q 134.0 56.0 143.0 46.0 Z"),
        .init(5, "tailR_tip", .tailR_tip, Ink.hair, stroke: 3.0, "M 156.0 130.0 Q 152.0 146.0 156.0 160.0 Q 160.0 172.0 169.0 180.0 Q 155.0 181.0 146.0 170.0 Q 137.0 156.0 134.0 126.0 Z"),
        .init(6, "scrunchieL", .tailL_base, Ink.rose, stroke: 1.8, path: VectorPath.circle(55.0, 48.0, 6.0)),
        .init(7, "scrunchieR", .tailR_base, Ink.rose, stroke: 1.8, path: VectorPath.circle(145.0, 48.0, 6.0)),
        .init(8, "legL", .legL, Ink.skin, stroke: 3.0, "M 87.0 187.0 L 85.0 213.0 L 95.0 213.0 L 96.0 187.0 Z"),
        .init(9, "sockL", .legL, Ink.white, stroke: 1.8, "M 85.0 211.0 L 84.0 228.0 L 96.0 228.0 L 95.0 211.0 Z"),
        .init(10, "shoeL", .legL, Ink.roseDeep, stroke: 3.0, "M 84.0 226.0 Q 79.0 234.0 81.0 240.0 L 96.0 240.0 Q 97.0 232.0 96.0 226.0 Z"),
        .init(11, "legR", .legR, Ink.skin, stroke: 3.0, "M 104.0 187.0 L 105.0 213.0 L 115.0 213.0 L 113.0 187.0 Z"),
        .init(12, "sockR", .legR, Ink.white, stroke: 1.8, "M 105.0 211.0 L 104.0 228.0 L 116.0 228.0 L 115.0 211.0 Z"),
        .init(13, "shoeR", .legR, Ink.roseDeep, stroke: 3.0, "M 104.0 226.0 Q 103.0 232.0 104.0 240.0 L 119.0 240.0 Q 121.0 234.0 116.0 226.0 Z"),
        .init(14, "skirt", .hips, Ink.blazer, stroke: 3.0, "M 77.0 163.0 L 123.0 163.0 L 133.0 189.0 L 124.0 186.5 L 116.0 190.0 L 108.0 186.5 L 100.0 190.0 L 92.0 186.5 L 84.0 190.0 L 76.0 186.5 L 67.0 189.0 Z"),
        .init(15, "skirtShade", .hips, Ink.blazerShadow, stroke: nil, "M 110.0 163.0 L 123.0 163.0 L 133.0 189.0 L 124.0 186.5 L 116.0 190.0 Z"),
        .init(16, "armL_sleeve", .armL, Ink.blazer, stroke: 3.0, "M 76.0 118.0 Q 66.0 124.0 63.0 138.0 L 60.0 150.0 Q 65.0 155.0 72.0 153.0 L 76.0 138.0 Q 79.0 127.0 76.0 118.0 Z"),
        .init(17, "handL", .armL, Ink.skin, stroke: 1.8, path: VectorPath.circle(65.0, 159.0, 5.5)),
        .init(18, "torsoBlazer", .torso, Ink.blazer, stroke: 3.0, "M 74.0 126.0 Q 78.0 118.0 88.0 116.0 L 112.0 116.0 Q 122.0 118.0 126.0 126.0 L 131.0 150.0 Q 132.0 162.0 123.0 165.0 L 77.0 165.0 Q 68.0 162.0 69.0 150.0 Z"),
        .init(19, "blazerShade", .torso, Ink.blazerShadow, stroke: nil, "M 112.0 117.0 Q 121.0 119.0 125.0 127.0 L 129.0 150.0 Q 130.0 160.0 122.0 163.0 L 112.0 163.0 Z"),
        .init(20, "shirtV", .torso, Ink.white, stroke: 1.8, "M 91.0 116.0 L 100.0 132.0 L 109.0 116.0 Z"),
        .init(21, "lapels", .torso, Ink.blazerShadow, stroke: 1.8, "M 91.0 116.0 L 86.0 129.0 L 94.0 125.0 Z M 109.0 116.0 L 114.0 129.0 L 106.0 125.0 Z"),
        .init(22, "bowLoops", .torso, Ink.rose, stroke: 1.8, "M 100.0 129.0 Q 89.0 121.0 85.0 128.0 Q 82.0 136.0 92.0 137.0 Q 98.0 136.0 100.0 129.0 Z M 100.0 129.0 Q 111.0 121.0 115.0 128.0 Q 118.0 136.0 108.0 137.0 Q 102.0 136.0 100.0 129.0 Z"),
        .init(23, "bowKnot", .torso, Ink.roseDeep, stroke: 1.8, path: VectorPath.circle(100.0, 130.0, 3.5)),
        .init(24, "armR_sleeve", .armR, Ink.blazer, stroke: 3.0, "M 124.0 118.0 Q 134.0 124.0 137.0 138.0 L 140.0 150.0 Q 135.0 155.0 128.0 153.0 L 124.0 138.0 Q 121.0 127.0 124.0 118.0 Z"),
        .init(25, "handR", .armR, Ink.skin, stroke: 1.8, path: VectorPath.circle(135.0, 159.0, 5.5)),
        .init(26, "neck", .torso, Ink.skin, stroke: nil, "M 93.0 106.0 L 92.0 122.0 L 108.0 122.0 L 107.0 106.0 Z"),
        .init(27, "headBase", .head, Ink.skin, stroke: 3.0, "M 62.0 66.0 Q 62.0 40.0 80.0 31.0 Q 100.0 23.0 120.0 31.0 Q 138.0 40.0 138.0 66.0 Q 138.0 86.0 126.0 100.0 Q 114.0 113.0 100.0 115.0 Q 86.0 113.0 74.0 100.0 Q 62.0 86.0 62.0 66.0 Z"),
        .init(28, "blush", .head, Ink.blush, stroke: nil, "M 65.0 96.0 Q 71.0 91.5 77.0 96.0 Q 71.0 100.0 65.0 96.0 Z M 123.0 96.0 Q 129.0 91.5 135.0 96.0 Q 129.0 100.0 123.0 96.0 Z"),
        .init(29, "mouthDefault", .head, Ink.clear, stroke: 1.8, "M 94.0 104.0 Q 100.0 108.5 106.0 104.0"),
        .init(30, "mouthHappy", .head, Ink.roseDeep, stroke: 1.8, "M 91.0 102.0 L 109.0 102.0 Q 106.0 112.0 100.0 112.0 Q 94.0 112.0 91.0 102.0 Z", restOpacity: 0),
        .init(31, "mouthDetermined", .head, Ink.white, stroke: 1.8, "M 93.0 102.0 L 107.0 102.0 Q 106.0 108.0 100.0 108.0 Q 94.0 108.0 93.0 102.0 Z", restOpacity: 0),
        .init(32, "eyeWhiteL", .head, Ink.white, stroke: 1.8, "M 72.0 82.0 Q 72.0 70.0 82.0 70.0 Q 92.0 70.0 92.0 83.0 Q 92.0 96.0 82.0 96.0 Q 72.0 96.0 72.0 82.0 Z"),
        .init(33, "eyeWhiteR", .head, Ink.white, stroke: 1.8, "M 108.0 82.0 Q 108.0 70.0 118.0 70.0 Q 128.0 70.0 128.0 83.0 Q 128.0 96.0 118.0 96.0 Q 108.0 96.0 108.0 82.0 Z"),
        .init(34, "irisL", .eyes, Ink.iris, stroke: nil, "M 76.0 82.0 Q 76.0 73.0 82.0 73.0 Q 88.0 73.0 88.0 83.0 Q 88.0 93.0 82.0 93.0 Q 76.0 93.0 76.0 82.0 Z"),
        .init(35, "irisR", .eyes, Ink.iris, stroke: nil, "M 112.0 82.0 Q 112.0 73.0 118.0 73.0 Q 124.0 73.0 124.0 83.0 Q 124.0 93.0 118.0 93.0 Q 112.0 93.0 112.0 82.0 Z"),
        .init(36, "pupilL", .eyes, Ink.ink, stroke: nil, "M 79.0 83.0 Q 79.0 78.0 82.0 78.0 Q 85.0 78.0 85.0 84.0 Q 85.0 90.0 82.0 90.0 Q 79.0 90.0 79.0 83.0 Z"),
        .init(37, "pupilR", .eyes, Ink.ink, stroke: nil, "M 115.0 83.0 Q 115.0 78.0 118.0 78.0 Q 121.0 78.0 121.0 84.0 Q 121.0 90.0 118.0 90.0 Q 115.0 90.0 115.0 83.0 Z"),
        .init(38, "hiBigL", .eyes, Ink.white, stroke: nil, path: VectorPath.circle(79.0, 77.0, 2.8)),
        .init(39, "hiBigR", .eyes, Ink.white, stroke: nil, path: VectorPath.circle(115.0, 77.0, 2.8)),
        .init(40, "hiSmallL", .eyes, Ink.white, stroke: nil, path: VectorPath.circle(85.5, 89.0, 1.5)),
        .init(41, "hiSmallR", .eyes, Ink.white, stroke: nil, path: VectorPath.circle(121.5, 89.0, 1.5)),
        .init(42, "lashL", .head, Ink.ink, stroke: nil, "M 70.0 78.0 Q 70.0 66.0 82.0 65.0 Q 92.0 64.0 94.0 75.0 L 92.0 76.0 Q 89.0 69.0 82.0 69.0 Q 74.0 69.0 72.0 79.0 Z"),
        .init(43, "lashR", .head, Ink.ink, stroke: nil, "M 130.0 78.0 Q 130.0 66.0 118.0 65.0 Q 108.0 64.0 106.0 75.0 L 108.0 76.0 Q 111.0 69.0 118.0 69.0 Q 126.0 69.0 128.0 79.0 Z"),
        .init(44, "hairCrown", .head, Ink.hair, stroke: 3.0, "M 54.0 76.0 Q 50.0 38.0 76.0 24.0 Q 100.0 12.0 124.0 24.0 Q 150.0 38.0 146.0 76.0 Q 140.0 66.0 137.0 56.0 Q 119.0 44.0 100.0 44.0 Q 81.0 44.0 63.0 56.0 Q 60.0 66.0 54.0 76.0 Z"),
        .init(45, "sideLockL", .head, Ink.hair, stroke: 3.0, "M 56.0 58.0 Q 49.0 82.0 54.0 106.0 Q 57.0 118.0 64.0 124.0 Q 69.0 112.0 67.0 92.0 Q 65.0 72.0 61.0 56.0 Z"),
        .init(46, "sideLockR", .head, Ink.hair, stroke: 3.0, "M 144.0 58.0 Q 151.0 82.0 146.0 106.0 Q 143.0 118.0 136.0 124.0 Q 131.0 112.0 133.0 92.0 Q 135.0 72.0 139.0 56.0 Z"),
        .init(47, "bangs", .head, Ink.hair, stroke: 3.0, "M 58.0 62.0 Q 56.0 44.0 68.0 34.0 Q 66.0 52.0 74.0 66.0 Q 79.0 54.0 86.0 46.0 Q 86.0 60.0 94.0 70.0 Q 100.0 58.0 104.0 46.0 Q 108.0 60.0 116.0 68.0 Q 120.0 54.0 127.0 47.0 Q 128.0 60.0 136.0 64.0 Q 144.0 52.0 138.0 38.0 Q 124.0 24.0 100.0 24.0 Q 76.0 24.0 62.0 40.0 Q 57.0 50.0 58.0 62.0 Z"),
        .init(48, "hairShine", .head, Ink.hairShine, stroke: nil, "M 74.0 32.0 Q 94.0 22.0 116.0 27.0 Q 122.0 29.0 126.0 33.0 Q 104.0 28.0 82.0 36.0 Q 77.0 34.0 74.0 32.0 Z"),
        .init(49, "browsDefault", .head, Ink.clear, stroke: 1.8, "M 72.0 63.0 Q 80.0 59.0 90.0 62.0 M 110.0 62.0 Q 120.0 59.0 128.0 63.0"),
        .init(50, "browsDetermined", .head, Ink.clear, stroke: 1.8, "M 73.0 59.0 L 90.0 66.0 M 110.0 66.0 L 127.0 59.0", restOpacity: 0),
        .init(51, "closedEyesHappy", .head, Ink.clear, stroke: 3.0, "M 71.0 85.0 Q 82.0 74.0 93.0 85.0 M 107.0 85.0 Q 118.0 74.0 129.0 85.0", restOpacity: 0),
        .init(52, "ahoge", .ahoge, Ink.clear, stroke: 3.0, "M 98.0 22.0 C 92.0 10.0 100.0 2.0 110.0 5.0 C 119.0 7.7 115.0 17.0 106.0 14.0"),
        .init(53, "sparkleA", .sparkles, Ink.white, stroke: nil, "M 42.0 52.0 L 45.0 61.0 L 54.0 64.0 L 45.0 67.0 L 42.0 76.0 L 39.0 67.0 L 30.0 64.0 L 39.0 61.0 Z", restOpacity: 0),
        .init(54, "sparkleB", .sparkles, Ink.rose, stroke: nil, "M 158.0 78.0 L 160.5 85.5 L 168.0 88.0 L 160.5 90.5 L 158.0 98.0 L 155.5 90.5 L 148.0 88.0 L 155.5 85.5 Z", restOpacity: 0),
        .init(55, "sparkleC", .sparkles, Ink.white, stroke: nil, "M 150.0 18.0 L 152.0 24.0 L 158.0 26.0 L 152.0 28.0 L 150.0 34.0 L 148.0 28.0 L 142.0 26.0 L 148.0 24.0 Z", restOpacity: 0),
    ]
}
