import CoreGraphics
import SwiftUI

/// The ninja's artwork and rig, transcribed from the v2 art-direction spec.
///
/// Same conventions as `SamuraiArt`: one flat 200×260 design space, origin
/// top-left, +y down, absolute `Path` data only. The ninja is the dark, fast,
/// asymmetric counterpart to the samurai's heavy red-and-gold — jade and charcoal,
/// a coiled diagonal stance, ribbon tails and a shuriken.
public enum NinjaArt {

    public static let canvas = CGSize(width: 200, height: 260)

    public enum Ink {
        public static let outline = Color(hex: 0x2A1A16)
        public static let suit = Color(hex: 0x2F3850)
        public static let suitShade = Color(hex: 0x171C26)
        public static let hood = Color(hex: 0x3A4660)
        public static let wrap = Color(hex: 0x4A5468)
        public static let sash = Color(hex: 0x4E8578)
        public static let sashDeep = Color(hex: 0x3A665C)
        public static let skin = Color(hex: 0xF0C49A)
        public static let steel = Color(hex: 0xC9D2D8)
        public static let iron = Color(hex: 0x3B322E)
        public static let eyeWhite = Color(hex: 0xF4F1E8)
        public static let smoke = Color(hex: 0xB7BEC6)
        /// Cool rim light on the lit (left) side, so the dark suit holds against a dark pill.
        public static let rim = Color(hex: 0x56637C)
    }

    /// A jointed part. `figure` wraps the whole body between `root` (which owns the
    /// emergence offset) and everything else, so full-body flips don't fight it.
    public enum Part: String, CaseIterable, RigPart {
        public static var canvas: CGSize { NinjaArt.canvas }

        case root, figure, torso, head, eyes, ribbonNear, ribbonFar, smokeB, smokeC
        case throwArmUpper, throwForearm, shuriken
        case offArmUpper, offForearm, ninjato, sashTail
        case legFrontThigh, legFrontShin, legBackThigh, legBackShin, smoke

        public var parent: Part? {
            switch self {
            case .root: nil
            case .figure, .smoke, .smokeB, .smokeC: .root
            case .torso, .legFrontThigh, .legBackThigh: .figure
            case .head, .throwArmUpper, .offArmUpper, .ninjato, .sashTail: .torso
            case .eyes, .ribbonNear, .ribbonFar: .head
            case .throwForearm: .throwArmUpper
            case .shuriken: .throwForearm
            case .offForearm: .offArmUpper
            case .legFrontShin: .legFrontThigh
            case .legBackShin: .legBackThigh
            }
        }

        public var pivot: CGPoint {
            switch self {
            case .root: CGPoint(x: 100, y: 196)
            case .figure: CGPoint(x: 100, y: 132)
            case .torso: CGPoint(x: 101, y: 150)
            case .head: CGPoint(x: 92, y: 76)
            case .eyes: CGPoint(x: 92, y: 51)
            case .ribbonNear: CGPoint(x: 111, y: 46)
            case .ribbonFar: CGPoint(x: 112, y: 43)
            case .throwArmUpper: CGPoint(x: 79, y: 87)
            case .throwForearm: CGPoint(x: 71, y: 111)
            case .shuriken: CGPoint(x: 77, y: 142)
            case .offArmUpper: CGPoint(x: 117, y: 87)
            case .offForearm: CGPoint(x: 126, y: 111)
            case .ninjato: CGPoint(x: 114, y: 70)
            case .sashTail: CGPoint(x: 111, y: 146)
            case .legFrontThigh: CGPoint(x: 94, y: 153)
            case .legFrontShin: CGPoint(x: 84, y: 190)
            case .legBackThigh: CGPoint(x: 112, y: 153)
            case .legBackShin: CGPoint(x: 113, y: 194)
            case .smoke: CGPoint(x: 100, y: 160)
            case .smokeB: CGPoint(x: 74, y: 146)
            case .smokeC: CGPoint(x: 128, y: 128)
            }
        }

    }

    public typealias Layer = RigLayer<Part>

    /// A thin open stroke turned into a fillable sliver (rim light).
    static func rimPath(_ data: String) -> Path {
        VectorPath.parse(data).strokedPath(StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
    }

    /// Back to front. Draw order is the spec's numeric order and independent of the
    /// rig hierarchy.
    public static let layers: [Layer] = [
        .init(1, "ribbonFar", .ribbonFar, Ink.sashDeep, stroke: 3.0, "M 112.0 42.0 C 124.0 35.5 136.0 45.0 149.0 37.5 C 153.5 35.0 157.0 40.0 153.0 43.0 C 141.0 51.5 127.0 42.5 114.5 49.0 Z"),
        .init(2, "ribbonNear", .ribbonNear, Ink.sash, stroke: 3.0, "M 111.5 45.5 C 122.0 49.0 132.0 58.0 144.0 55.0 C 149.0 53.8 151.0 59.5 146.0 61.5 C 133.0 66.5 119.0 55.5 110.5 52.5 Z"),
        .init(3, "scabbard", .ninjato, Ink.iron, stroke: 3.0, "M 117.0 71.8 L 69.0 149.8 Q 65.0 152.0 63.0 146.2 L 111.0 68.2 Z"),
        .init(4, "tsuba", .ninjato, Ink.iron, stroke: 1.8, "M 109.0 66.0 L 119.5 66.5 L 119.0 74.0 L 108.5 73.5 Z"),
        .init(5, "grip", .ninjato, Ink.suitShade, stroke: 3.0, "M 116.6 71.5 L 130.6 48.0 Q 132.4 44.0 128.4 42.0 Q 124.8 40.4 123.0 44.5 L 111.4 68.5 Z"),
        .init(6, "gripWrap", .ninjato, Ink.wrap, stroke: nil, "M 118.0 63.5 L 123.6 59.8 L 125.2 62.4 L 119.6 66.1 Z"),
        .init(7, "offUpperArm", .offArmUpper, Ink.suit, stroke: 3.0, "M 113.0 84.0 Q 122.0 86.0 126.0 96.0 L 130.5 110.0 L 121.0 115.0 L 114.5 98.0 Q 112.0 90.0 113.0 84.0 Z"),
        .init(8, "offForearm", .offForearm, Ink.wrap, stroke: 3.0, "M 121.5 111.0 L 130.5 108.5 Q 129.0 122.0 122.5 131.5 L 114.0 127.0 Q 119.5 120.0 121.5 111.0 Z"),
        .init(9, "offWrapA", .offForearm, Ink.suitShade, stroke: nil, "M 121.0 115.5 L 129.6 113.0 L 129.0 117.3 L 120.2 119.6 Z"),
        .init(10, "offWrapB", .offForearm, Ink.suitShade, stroke: nil, "M 118.8 122.5 L 127.2 120.2 L 126.2 124.4 L 117.6 126.5 Z"),
        .init(11, "offHand", .offForearm, Ink.suitShade, stroke: 1.8, "M 114.5 126.5 Q 109.5 128.0 110.0 133.0 Q 110.5 137.5 116.0 137.0 Q 121.0 136.5 120.5 131.0 Q 120.0 127.0 114.5 126.5 Z"),
        .init(12, "backThigh", .legBackThigh, Ink.suit, stroke: 3.0, "M 103.0 152.0 Q 98.5 172.0 105.5 194.0 L 122.5 195.0 Q 126.0 172.0 121.0 152.0 Z"),
        .init(13, "backShin", .legBackShin, Ink.wrap, stroke: 3.0, "M 107.0 193.0 Q 105.0 216.0 106.5 238.0 L 119.5 238.5 Q 121.5 216.0 121.5 194.0 Z"),
        .init(14, "backWrapA", .legBackShin, Ink.suitShade, stroke: nil, "M 106.3 202.0 L 120.9 199.0 L 121.0 203.5 L 106.2 206.5 Z"),
        .init(15, "backWrapB", .legBackShin, Ink.suitShade, stroke: nil, "M 106.0 216.0 L 120.6 213.0 L 120.7 217.5 L 105.9 220.5 Z"),
        .init(16, "backFoot", .legBackShin, Ink.suitShade, stroke: 3.0, "M 106.5 238.0 L 96.0 240.0 Q 92.0 241.0 92.5 244.5 Q 93.0 247.5 98.0 247.5 L 119.0 247.0 Q 121.5 246.5 121.0 242.5 L 119.5 238.5 Z"),
        .init(17, "frontThigh", .legFrontThigh, Ink.suit, stroke: 3.0, "M 88.0 152.0 Q 78.0 168.0 76.5 188.0 L 92.0 194.0 Q 96.0 172.0 100.0 153.0 Z"),
        .init(60, "rimFrontThigh", .legFrontThigh, Ink.rim, stroke: nil, path: rimPath("M 90.0 156.0 Q 81.5 169.0 80.0 186.0")),
        .init(18, "frontShin", .legFrontShin, Ink.wrap, stroke: 3.0, "M 77.0 187.0 Q 79.0 208.0 84.5 226.0 L 95.5 223.5 Q 92.5 206.0 91.5 190.5 Z"),
        .init(19, "frontWrapA", .legFrontShin, Ink.suitShade, stroke: nil, "M 79.2 197.0 L 92.2 194.5 L 92.7 199.0 L 79.9 201.5 Z"),
        .init(20, "frontWrapB", .legFrontShin, Ink.suitShade, stroke: nil, "M 81.5 210.0 L 93.6 207.5 L 94.1 212.0 L 82.2 214.5 Z"),
        .init(21, "frontFoot", .legFrontShin, Ink.suitShade, stroke: 3.0, "M 84.5 225.5 Q 78.0 234.0 76.5 244.0 Q 76.0 247.5 80.5 247.0 Q 86.0 246.0 89.0 238.0 Q 93.0 230.0 95.5 224.0 Z"),
        .init(22, "torso", .torso, Ink.suit, stroke: 3.0, "M 76.0 86.0 C 71.5 91.0 72.5 97.0 74.5 103.0 L 82.5 130.0 Q 85.0 144.0 85.0 158.0 L 118.5 158.5 Q 119.5 144.0 118.0 130.0 L 122.5 95.0 Q 123.5 86.5 119.5 83.5 Q 106.0 75.5 92.0 77.5 Q 81.5 79.5 76.0 86.0 Z"),
        .init(23, "torsoShade", .torso, Ink.suitShade, stroke: nil, "M 113.0 87.0 Q 116.5 92.0 115.5 100.0 L 111.5 131.0 Q 112.5 145.0 112.0 158.0 L 118.5 158.3 Q 119.5 144.0 118.0 130.0 L 122.5 95.0 Q 123.3 87.0 119.5 83.8 Z"),
        .init(59, "rimTorso", .torso, Ink.rim, stroke: nil, path: rimPath("M 79.0 89.5 C 77.0 93.0 77.2 98.0 77.4 103.0 L 85.4 130.0 Q 88.0 144.0 88.0 156.0")),
        .init(24, "collarV", .torso, Ink.suitShade, stroke: 1.8, "M 90.0 79.0 L 101.0 97.0 L 112.5 81.0 L 106.5 78.0 L 101.0 88.5 L 96.0 77.5 Z"),
        .init(25, "chestStrap", .torso, Ink.iron, stroke: 1.8, "M 114.0 82.0 L 88.0 128.0 L 93.5 130.5 L 119.0 85.0 Z"),
        .init(26, "hemFlapL", .torso, Ink.suit, stroke: 3.0, "M 85.0 158.0 L 84.0 168.0 Q 88.0 172.0 94.0 169.0 L 96.0 158.2 Z"),
        .init(27, "hemFlapR", .torso, Ink.suit, stroke: 3.0, "M 104.0 158.3 L 106.5 170.0 Q 112.0 172.5 117.0 168.5 L 118.5 158.5 Z"),
        .init(28, "sash", .torso, Ink.sash, stroke: 3.0, "M 82.0 128.5 Q 100.0 132.5 118.5 130.5 L 117.5 140.5 Q 100.0 142.5 83.5 138.5 Z"),
        .init(29, "sashKnot", .sashTail, Ink.sash, stroke: 1.8, "M 110.0 139.5 Q 105.8 141.0 106.5 145.5 Q 107.2 149.5 112.5 149.0 Q 117.0 148.5 116.4 144.0 Q 115.8 140.0 110.0 139.5 Z"),
        .init(30, "sashTailPath", .sashTail, Ink.sash, stroke: 3.0, "M 108.5 148.0 Q 105.0 158.0 107.5 168.0 Q 108.5 172.0 103.5 172.5 Q 99.5 172.5 100.5 167.0 Q 102.0 155.5 105.5 147.0 Z"),
        .init(31, "neck", .torso, Ink.hood, stroke: 3.0, "M 86.0 69.0 L 85.5 79.5 Q 92.0 82.5 98.5 79.0 L 98.0 68.5 Q 92.0 72.5 86.0 69.0 Z"),
        .init(32, "headBase", .head, Ink.hood, stroke: 3.0, "M 74.0 58.0 C 72.0 40.0 80.0 29.0 94.0 29.0 C 106.0 29.0 113.0 38.0 113.5 52.0 C 114.0 62.0 108.0 71.5 96.0 72.5 C 86.0 73.0 76.0 68.0 74.0 58.0 Z"),
        .init(58, "rimHead", .head, Ink.rim, stroke: nil, path: rimPath("M 77.5 58.0 C 75.8 43.0 82.0 32.4 94.0 32.3 C 100.0 32.3 104.0 34.5 107.0 38.0")),
        .init(33, "eyeSlit", .head, Ink.skin, stroke: 1.8, "M 75.0 47.5 Q 92.0 44.5 110.5 47.0 L 111.0 55.5 Q 92.0 58.5 75.5 56.0 Z"),
        .init(34, "browBand", .head, Ink.wrap, stroke: nil, "M 75.0 44.5 Q 92.0 40.5 111.0 43.5 L 110.8 46.8 Q 92.0 43.8 75.2 47.8 Z"),
        .init(35, "eyeWhiteL", .eyes, Ink.eyeWhite, stroke: 1.8, "M 78.5 47.8 Q 83.5 45.8 88.5 47.5 Q 89.5 51.5 88.0 53.8 Q 83.0 55.2 79.0 53.8 Q 77.8 50.8 78.5 47.8 Z"),
        .init(36, "eyeWhiteR", .eyes, Ink.eyeWhite, stroke: 1.8, "M 95.5 47.3 Q 100.0 45.4 104.5 47.0 Q 105.4 50.8 104.2 53.2 Q 99.8 54.6 96.0 53.3 Q 94.9 50.2 95.5 47.3 Z"),
        .init(37, "pupilL", .eyes, Ink.outline, stroke: nil, path: VectorPath.circle(82.8, 51.0, 1.7)),
        .init(38, "pupilR", .eyes, Ink.outline, stroke: nil, path: VectorPath.circle(98.8, 50.6, 1.7)),
        .init(39, "lidL", .eyes, Ink.hood, stroke: nil, "M 78.3 47.6 Q 83.5 45.6 88.7 47.3 L 88.7 50.0 Q 83.5 48.6 78.5 50.4 Z"),
        .init(40, "lidR", .eyes, Ink.hood, stroke: nil, "M 95.3 47.1 Q 100.0 45.2 104.7 46.8 L 104.7 49.4 Q 100.0 48.0 95.5 49.8 Z"),
        .init(41, "contentEyeL", .eyes, Ink.outline, stroke: nil, "M 78.0 52.5 Q 83.5 46.5 89.0 52.5 Q 83.5 49.5 78.0 52.5 Z", restOpacity: 0),
        .init(42, "contentEyeR", .eyes, Ink.outline, stroke: nil, "M 95.0 52.0 Q 100.0 46.0 105.0 52.0 Q 100.0 49.0 95.0 52.0 Z", restOpacity: 0),
        .init(43, "sparkL", .eyes, Ink.eyeWhite, stroke: nil, path: VectorPath.circle(83.6, 50.2, 0.7), restOpacity: 0),
        .init(44, "sparkR", .eyes, Ink.eyeWhite, stroke: nil, path: VectorPath.circle(99.6, 49.8, 0.7), restOpacity: 0),
        .init(45, "hoodKnot", .head, Ink.sash, stroke: 1.8, "M 109.0 40.0 Q 116.0 37.0 118.0 43.0 Q 119.5 48.5 112.5 49.5 Q 107.5 50.0 107.0 45.0 Q 106.8 41.2 109.0 40.0 Z"),
        .init(46, "throwUpperArm", .throwArmUpper, Ink.suit, stroke: 3.0, "M 81.0 84.5 Q 72.5 87.0 69.5 97.0 L 66.5 110.0 L 76.0 114.0 L 79.5 100.0 Q 81.5 91.5 81.0 84.5 Z"),
        .init(56, "rimThrowUpper", .throwArmUpper, Ink.rim, stroke: nil, path: rimPath("M 76.5 88.5 Q 73.0 91.0 72.3 97.0 L 69.8 108.5")),
        .init(47, "throwForearmPath", .throwForearm, Ink.wrap, stroke: 3.0, "M 66.5 108.5 L 76.0 112.0 Q 77.5 124.0 83.0 132.0 L 74.5 137.5 Q 67.0 125.0 66.5 108.5 Z"),
        .init(48, "throwWrapA", .throwForearm, Ink.suitShade, stroke: nil, "M 68.2 114.5 L 76.6 116.8 L 76.0 121.0 L 67.9 118.8 Z"),
        .init(49, "throwWrapB", .throwForearm, Ink.suitShade, stroke: nil, "M 69.8 123.0 L 78.4 125.0 L 77.6 129.2 L 69.2 127.2 Z"),
        .init(57, "rimThrowForearm", .throwForearm, Ink.rim, stroke: nil, path: rimPath("M 69.8 112.0 Q 69.6 124.0 75.0 133.0")),
        .init(50, "throwHand", .throwForearm, Ink.suitShade, stroke: 1.8, "M 76.0 131.0 Q 71.5 133.5 73.0 138.5 Q 74.5 143.0 80.0 141.0 Q 84.5 139.0 82.5 134.0 Q 81.0 130.0 76.0 131.0 Z"),
        .init(51, "shurikenStar", .shuriken, Ink.steel, stroke: 1.8, "M 77.0 134.0 L 79.0 140.0 L 85.0 142.0 L 79.0 144.0 L 77.0 150.0 L 75.0 144.0 L 69.0 142.0 L 75.0 140.0 Z"),
        .init(52, "shurikenHole", .shuriken, Ink.iron, stroke: nil, path: VectorPath.circle(77.0, 142.0, 1.5)),
        .init(53, "puffA", .smoke, Ink.smoke, stroke: 3.0, "M 74.0 176.0 Q 70.0 160.0 84.0 156.0 Q 88.0 144.0 102.0 146.0 Q 116.0 142.0 122.0 154.0 Q 136.0 156.0 132.0 170.0 Q 140.0 182.0 126.0 188.0 Q 122.0 198.0 106.0 196.0 Q 92.0 200.0 86.0 190.0 Q 72.0 188.0 74.0 176.0 Z", restOpacity: 0),
        .init(54, "puffB", .smokeB, Ink.smoke, stroke: 3.0, "M 62.0 150.0 Q 60.0 141.0 69.0 140.0 Q 72.0 133.0 80.0 136.0 Q 87.0 135.0 87.0 143.0 Q 91.0 150.0 82.0 153.0 Q 76.0 157.0 70.0 153.0 Q 63.0 155.0 62.0 150.0 Z", restOpacity: 0),
        .init(55, "puffC", .smokeC, Ink.smoke, stroke: 3.0, "M 116.0 134.0 Q 114.0 125.0 123.0 124.0 Q 126.0 117.0 134.0 120.0 Q 141.0 119.0 141.0 127.0 Q 145.0 134.0 136.0 137.0 Q 130.0 141.0 124.0 137.0 Q 117.0 139.0 116.0 134.0 Z", restOpacity: 0),
    ]
}
