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
        /// Feet are their own joint so a crouch can keep them flat on the floor.
        case footFront, footBack
        /// The thrown star, once it has left his hand. A child of `root`, not of the
        /// arm, so it keeps flying while the hand recoils.
        case shurikenFlight

        public var parent: Part? {
            switch self {
            case .root: nil
            case .figure, .smoke, .smokeB, .smokeC, .shurikenFlight: .root
            case .torso, .legFrontThigh, .legBackThigh: .figure
            case .head, .throwArmUpper, .offArmUpper, .ninjato, .sashTail: .torso
            case .eyes, .ribbonNear, .ribbonFar: .head
            case .throwForearm: .throwArmUpper
            case .shuriken: .throwForearm
            case .offForearm: .offArmUpper
            case .legFrontShin: .legFrontThigh
            case .legBackShin: .legBackThigh
            case .footFront: .legFrontShin
            case .footBack: .legBackShin
            }
        }

        public var pivot: CGPoint {
            switch self {
            case .root: CGPoint(x: 100, y: 196)
            case .figure: CGPoint(x: 100, y: 132)
            case .torso: CGPoint(x: 101, y: 150)
            case .head: CGPoint(x: 92, y: 76)
            case .eyes: CGPoint(x: 92, y: 54.8)
            case .ribbonNear: CGPoint(x: 108.2, y: 50.5)
            case .ribbonFar: CGPoint(x: 109, y: 48)
            case .throwArmUpper: CGPoint(x: 76.5, y: 87)
            case .throwForearm: CGPoint(x: 68.5, y: 111)
            case .shuriken, .shurikenFlight: CGPoint(x: 74.5, y: 142)
            case .offArmUpper: CGPoint(x: 119.5, y: 87)
            case .offForearm: CGPoint(x: 128.5, y: 111)
            case .ninjato: CGPoint(x: 114, y: 70)
            case .sashTail: CGPoint(x: 111, y: 146)
            case .legFrontThigh: CGPoint(x: 94, y: 153)
            case .legFrontShin: CGPoint(x: 84, y: 186.4)
            case .legBackThigh: CGPoint(x: 112, y: 153)
            case .legBackShin: CGPoint(x: 113, y: 190)
            case .smoke: CGPoint(x: 100, y: 150)
            case .footFront: CGPoint(x: 90, y: 218.5)
            case .footBack: CGPoint(x: 113, y: 231)
            case .smokeB: CGPoint(x: 92, y: 66)
            case .smokeC: CGPoint(x: 100, y: 205)
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
    static let rawLayers: [Layer] = [
        .init(1, "ribbonFar", .ribbonFar, Ink.sashDeep, stroke: 3.0, "M 112.0 42.0 C 124.0 35.5 136.0 45.0 149.0 37.5 C 153.5 35.0 157.0 40.0 153.0 43.0 C 141.0 51.5 127.0 42.5 114.5 49.0 Z"),
        .init(2, "ribbonNear", .ribbonNear, Ink.sash, stroke: 3.0, "M 111.5 45.5 C 122.0 49.0 132.0 58.0 144.0 55.0 C 149.0 53.8 151.0 59.5 146.0 61.5 C 133.0 66.5 119.0 55.5 110.5 52.5 Z"),
        .init(3, "scabbard", .ninjato, Ink.iron, stroke: 3.0, "M 117.0 71.8 L 69.0 149.8 Q 65.0 152.0 63.0 146.2 L 111.0 68.2 Z"),
        .init(4, "tsuba", .ninjato, Ink.iron, stroke: 1.8, "M 109.0 66.0 L 119.5 66.5 L 119.0 74.0 L 108.5 73.5 Z"),
        .init(5, "grip", .ninjato, Ink.suitShade, stroke: 3.0, "M 116.6 71.5 L 130.6 48.0 Q 132.4 44.0 128.4 42.0 Q 124.8 40.4 123.0 44.5 L 111.4 68.5 Z"),
        .init(6, "gripWrap", .ninjato, Ink.wrap, stroke: nil, "M 118.0 63.5 L 123.6 59.8 L 125.2 62.4 L 119.6 66.1 Z"),
        .init(76, "capOffElbowRing", .offForearm, Ink.suit, stroke: 3.0, path: VectorPath.circle(128.5, 111, 6.6)),
        .init(77, "capOffShoulderRing", .offArmUpper, Ink.suit, stroke: 3.0, path: VectorPath.circle(119.5, 87, 5.8)),
        .init(7, "offUpperArm", .offArmUpper, Ink.suit, stroke: 3.0, "M 113.0 84.0 Q 122.0 86.0 126.0 96.0 L 130.5 110.0 L 121.0 115.0 L 114.5 98.0 Q 112.0 90.0 113.0 84.0 Z"),
        .init(78, "capOffShoulder", .offArmUpper, Ink.suit, stroke: nil, path: VectorPath.circle(119.5, 87, 4.6)),
        .init(8, "offForearm", .offForearm, Ink.wrap, stroke: 3.0, "M 121.5 111.0 L 130.5 108.5 Q 129.0 122.0 122.5 131.5 L 114.0 127.0 Q 119.5 120.0 121.5 111.0 Z"),
        .init(79, "capOffElbow", .offForearm, Ink.suit, stroke: nil, path: VectorPath.circle(128.5, 111, 5.2)),
        .init(9, "offWrapA", .offForearm, Ink.suitShade, stroke: nil, "M 121.0 115.5 L 129.6 113.0 L 129.0 117.3 L 120.2 119.6 Z"),
        .init(10, "offWrapB", .offForearm, Ink.suitShade, stroke: nil, "M 118.8 122.5 L 127.2 120.2 L 126.2 124.4 L 117.6 126.5 Z"),
        .init(11, "offHand", .offForearm, Ink.suitShade, stroke: 1.8, "M 114.5 126.5 Q 109.5 128.0 110.0 133.0 Q 110.5 137.5 116.0 137.0 Q 121.0 136.5 120.5 131.0 Q 120.0 127.0 114.5 126.5 Z"),
        .init(70, "capHipBack", .legBackThigh, Ink.suit, stroke: 3.0, path: VectorPath.circle(112, 153, 8)),
        .init(71, "capHipFront", .legFrontThigh, Ink.suit, stroke: 3.0, path: VectorPath.circle(94, 153, 7.5)),
        .init(72, "capKneeRingBack", .legBackShin, Ink.suit, stroke: 3.0, path: VectorPath.circle(113, 190, 8)),
        .init(12, "backThigh", .legBackThigh, Ink.suit, stroke: 3.0, "M 103.0 152.0 Q 98.5 172.0 105.5 194.0 L 122.5 195.0 Q 126.0 172.0 121.0 152.0 Z"),
        .init(13, "backShin", .legBackShin, Ink.wrap, stroke: 3.0, "M 107.0 193.0 Q 105.0 216.0 106.5 238.0 L 119.5 238.5 Q 121.5 216.0 121.5 194.0 Z"),
        .init(73, "capKneeBack", .legBackShin, Ink.suit, stroke: nil, path: VectorPath.circle(113, 190, 6.4)),
        .init(14, "backWrapA", .legBackShin, Ink.suitShade, stroke: nil, "M 106.3 202.0 L 120.9 199.0 L 121.0 203.5 L 106.2 206.5 Z"),
        .init(15, "backWrapB", .legBackShin, Ink.suitShade, stroke: nil, "M 106.0 216.0 L 120.6 213.0 L 120.7 217.5 L 105.9 220.5 Z"),
        .init(16, "backFoot", .footBack, Ink.suitShade, stroke: 3.0, "M 106.5 238.0 L 96.0 240.0 Q 92.0 241.0 92.5 244.5 Q 93.0 247.5 98.0 247.5 L 119.0 247.0 Q 121.5 246.5 121.0 242.5 L 119.5 238.5 Z"),
        .init(84, "rimBackFoot", .footBack, Ink.rim, stroke: nil, path: rimPath("M 105.0 241.2 L 97.5 242.6 Q 95.2 243.3 95.6 245.0 L 118.5 244.6")),
        .init(74, "capKneeRingFront", .legFrontShin, Ink.suit, stroke: 3.0, path: VectorPath.circle(84, 186.4, 7.5)),
        .init(17, "frontThigh", .legFrontThigh, Ink.suit, stroke: 3.0, "M 88.0 152.0 Q 78.0 168.0 76.5 188.0 L 92.0 194.0 Q 96.0 172.0 100.0 153.0 Z"),
        .init(60, "rimFrontThigh", .legFrontThigh, Ink.rim, stroke: nil, path: rimPath("M 90.0 156.0 Q 81.5 169.0 80.0 186.0")),
        .init(18, "frontShin", .legFrontShin, Ink.wrap, stroke: 3.0, "M 77.0 187.0 Q 79.0 208.0 84.5 226.0 L 95.5 223.5 Q 92.5 206.0 91.5 190.5 Z"),
        .init(75, "capKneeFront", .legFrontShin, Ink.suit, stroke: nil, path: VectorPath.circle(84, 186.4, 6)),
        .init(19, "frontWrapA", .legFrontShin, Ink.suitShade, stroke: nil, "M 79.2 197.0 L 92.2 194.5 L 92.7 199.0 L 79.9 201.5 Z"),
        .init(20, "frontWrapB", .legFrontShin, Ink.suitShade, stroke: nil, "M 81.5 210.0 L 93.6 207.5 L 94.1 212.0 L 82.2 214.5 Z"),
        .init(21, "frontFoot", .footFront, Ink.suitShade, stroke: 3.0, "M 84.5 225.5 Q 78.0 234.0 76.5 244.0 Q 76.0 247.5 80.5 247.0 Q 86.0 246.0 89.0 238.0 Q 93.0 230.0 95.5 224.0 Z"),
        .init(85, "rimFrontFoot", .footFront, Ink.rim, stroke: nil, path: rimPath("M 85.0 228.0 Q 80.2 235.0 79.4 242.6 Q 79.4 244.8 81.6 244.6")),
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
        .init(80, "capElbowRing", .throwForearm, Ink.suit, stroke: 3.0, path: VectorPath.circle(68.5, 111, 6.6)),
        .init(81, "capShoulderRing", .throwArmUpper, Ink.suit, stroke: 3.0, path: VectorPath.circle(76.5, 87, 5.8)),
        .init(46, "throwUpperArm", .throwArmUpper, Ink.suit, stroke: 3.0, "M 81.0 84.5 Q 72.5 87.0 69.5 97.0 L 66.5 110.0 L 76.0 114.0 L 79.5 100.0 Q 81.5 91.5 81.0 84.5 Z"),
        .init(82, "capShoulder", .throwArmUpper, Ink.suit, stroke: nil, path: VectorPath.circle(76.5, 87, 4.6)),
        .init(56, "rimThrowUpper", .throwArmUpper, Ink.rim, stroke: nil, path: rimPath("M 76.5 88.5 Q 73.0 91.0 72.3 97.0 L 69.8 108.5")),
        .init(47, "throwForearmPath", .throwForearm, Ink.wrap, stroke: 3.0, "M 66.5 108.5 L 76.0 112.0 Q 77.5 124.0 83.0 132.0 L 74.5 137.5 Q 67.0 125.0 66.5 108.5 Z"),
        .init(83, "capElbow", .throwForearm, Ink.suit, stroke: nil, path: VectorPath.circle(68.5, 111, 5.2)),
        .init(48, "throwWrapA", .throwForearm, Ink.suitShade, stroke: nil, "M 68.2 114.5 L 76.6 116.8 L 76.0 121.0 L 67.9 118.8 Z"),
        .init(49, "throwWrapB", .throwForearm, Ink.suitShade, stroke: nil, "M 69.8 123.0 L 78.4 125.0 L 77.6 129.2 L 69.2 127.2 Z"),
        .init(57, "rimThrowForearm", .throwForearm, Ink.rim, stroke: nil, path: rimPath("M 69.8 112.0 Q 69.6 124.0 75.0 133.0")),
        .init(50, "throwHand", .throwForearm, Ink.suitShade, stroke: 1.8, "M 76.0 131.0 Q 71.5 133.5 73.0 138.5 Q 74.5 143.0 80.0 141.0 Q 84.5 139.0 82.5 134.0 Q 81.0 130.0 76.0 131.0 Z"),
        .init(51, "shurikenStar", .shuriken, Ink.steel, stroke: 1.8, "M 77.0 134.0 L 79.0 140.0 L 85.0 142.0 L 79.0 144.0 L 77.0 150.0 L 75.0 144.0 L 69.0 142.0 L 75.0 140.0 Z"),
        .init(52, "shurikenHole", .shuriken, Ink.iron, stroke: nil, path: VectorPath.circle(77.0, 142.0, 1.5)),
        .init(63, "flyStar", .shurikenFlight, Ink.steel, stroke: 1.8, "M 77.0 134.0 L 79.0 140.0 L 85.0 142.0 L 79.0 144.0 L 77.0 150.0 L 75.0 144.0 L 69.0 142.0 L 75.0 140.0 Z"),
        .init(64, "flyHole", .shurikenFlight, Ink.iron, stroke: nil, path: VectorPath.circle(77.0, 142.0, 1.5)),
        .init(53, "puffA", .smoke, Ink.smoke, stroke: 3.0, "M 140.4 165.3 Q 144.9 191.8 125.3 198.1 Q 112.5 217.4 94.7 201.4 Q 74.3 211.5 65.8 188.9 Q 48.1 176.8 57.8 152.5 Q 46.2 129.6 62.8 115.4 Q 69.5 91.9 90.6 99.5 Q 107.0 81.4 121.3 99.1 Q 141.3 103.0 138.9 129.9 Q 156.3 146.6 140.4 165.3 Z", restOpacity: 0),
        .init(54, "puffB", .smokeB, Ink.smoke, stroke: 3.0, "M 124.0 81.6 Q 123.0 100.4 103.3 100.6 Q 86.7 109.9 74.5 94.6 Q 53.5 93.7 53.3 76.1 Q 42.9 61.3 60.0 50.4 Q 61.0 31.6 80.7 31.4 Q 97.3 22.1 109.5 37.4 Q 130.5 38.3 130.7 55.9 Q 141.1 70.7 124.0 81.6 Z", restOpacity: 0),
        .init(55, "puffC", .smokeC, Ink.smoke, stroke: 3.0, "M 145.8 207.9 Q 155.0 223.4 132.2 229.6 Q 118.0 242.3 95.4 233.7 Q 70.5 239.4 60.6 225.1 Q 40.3 216.3 54.2 202.1 Q 45.0 186.6 67.8 180.4 Q 82.0 167.7 104.6 176.3 Q 129.5 170.6 139.4 184.9 Q 159.7 193.7 145.8 207.9 Z", restOpacity: 0),
    ]

    // MARK: - Proportions

    /// The v3 body pass, applied to the v2 path data rather than by rewriting every
    /// coordinate: head about 15% smaller (a fifth of his height instead of a
    /// quarter), shoulders about 10% wider, shins and thighs about 10% shorter.
    /// Layers named `cap...`, `fly...` and `puff...` are authored in final space.
    public static let layers: [Layer] = rawLayers.map(fit)

    private static func fit(_ layer: Layer) -> Layer {
        let name = layer.name
        if name.hasPrefix("cap") || name.hasPrefix("puff") { return layer }
        let map: ((CGPoint) -> CGPoint)?
        switch layer.part {
        case .head, .eyes, .ribbonNear, .ribbonFar:
            map = { CGPoint(x: 92 + ($0.x - 92) * headScale, y: 76 + ($0.y - 76) * headScale) }
        case .torso where name != "neck":
            map = { point in
                let widen = 1 + 0.10 * min(max((130 - point.y) / 32, 0), 1)
                return CGPoint(x: 100 + (point.x - 100) * widen, y: point.y)
            }
        case .throwArmUpper, .throwForearm, .shuriken, .shurikenFlight:
            map = { CGPoint(x: $0.x - shoulderShift, y: $0.y) }
        case .offArmUpper, .offForearm:
            map = { CGPoint(x: $0.x + shoulderShift, y: $0.y) }
        case .legFrontThigh, .legFrontShin, .legBackThigh, .legBackShin, .footFront, .footBack:
            map = { CGPoint(x: $0.x, y: shorterLeg($0.y)) }
        default:
            map = nil
        }
        guard let map else { return layer }
        return Layer(layer.id, layer.name, layer.part, layer.fill, stroke: layer.stroke,
                     path: warped(layer.path, map), restOpacity: layer.restOpacity)
    }

    static let headScale: CGFloat = 0.85
    static let shoulderShift: CGFloat = 2.5

    /// Hip at 153, ankle line at 238: thigh 42 to 38, shin 44 to 40, feet shift up 8.
    private static func shorterLeg(_ y: CGFloat) -> CGFloat {
        if y >= 238 { return y - 8 }
        if y >= 194 { return 190 + (y - 194) * 40 / 44 }
        if y > 152 { return 152 + (y - 152) * 38 / 42 }
        return y
    }

    private static func warped(_ path: Path, _ map: (CGPoint) -> CGPoint) -> Path {
        var out = Path()
        path.forEach { element in
            switch element {
            case .move(let to): out.move(to: map(to))
            case .line(let to): out.addLine(to: map(to))
            case .quadCurve(let to, let control): out.addQuadCurve(to: map(to), control: map(control))
            case .curve(let to, let c1, let c2): out.addCurve(to: map(to), control1: map(c1), control2: map(c2))
            case .closeSubpath: out.closeSubpath()
            }
        }
        return out
    }
}
