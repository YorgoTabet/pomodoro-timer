import CoreGraphics
import SwiftUI

/// The General's artwork and rig.
///
/// A cartoon blowhard and nothing more. Identity comes only from a comically tall
/// peaked cap, saucer-sized aviators, a walrus moustache that hides his mouth
/// entirely, five plain brass discs, and olive drab. Deliberately no insignia, no
/// symbols, no nation: the cap button is a blank disc, the medals are blank discs,
/// the buckle is a blank rectangle. The brass is duller and greener than the
/// samurai's gold and appears only as small circles, so the two never read alike.
public enum GeneralArt {

    public static let canvas = CGSize(width: 200, height: 260)

    public enum Ink {
        public static let outline = Color(hex: 0x2A2620)
        public static let coat = Color(hex: 0x6E7345)
        public static let coatShade = Color(hex: 0x565A31)
        public static let khaki = Color(hex: 0xC9B98A)
        public static let brass = Color(hex: 0xC29B3C)
        public static let leather = Color(hex: 0x3A2E24)
        public static let skin = Color(hex: 0xE8A87C)
        public static let ruddy = Color(hex: 0xD97B5F)
        public static let moustache = Color(hex: 0xE8E4DA)
        public static let moustacheShade = Color(hex: 0xCFC9BB)
        public static let lens = Color(hex: 0x35404D)
        public static let lensShine = Color(hex: 0x5C7086)
    }

    public enum Part: String, CaseIterable, RigPart {
        public static var canvas: CGSize { GeneralArt.canvas }

        case root, figure, torso, head, cap, shades, stache, medals
        case armNear, foreNear, stick, armFar, foreFar
        case legNear, bootNear, legFar, bootFar

        public var parent: Part? {
            switch self {
            case .root: nil
            case .figure: .root
            case .torso, .legNear, .legFar: .figure
            case .head, .medals, .armNear, .armFar: .torso
            case .cap, .shades, .stache: .head
            case .foreNear: .armNear
            case .stick: .foreNear
            case .foreFar: .armFar
            case .bootNear: .legNear
            case .bootFar: .legFar
            }
        }

        public var pivot: CGPoint {
            switch self {
            case .root: CGPoint(x: 100, y: 196)
            case .figure: CGPoint(x: 100, y: 132)
            case .torso: CGPoint(x: 100, y: 150)
            case .head: CGPoint(x: 100, y: 96)
            case .cap: CGPoint(x: 100, y: 38)
            case .shades: CGPoint(x: 100, y: 52)
            case .stache: CGPoint(x: 100, y: 74)
            case .medals: CGPoint(x: 79, y: 127)
            case .armNear: CGPoint(x: 66, y: 104)
            case .foreNear: CGPoint(x: 56, y: 134)
            case .stick: CGPoint(x: 50, y: 160)
            case .armFar: CGPoint(x: 134, y: 104)
            case .foreFar: CGPoint(x: 144, y: 134)
            case .legNear: CGPoint(x: 82, y: 174)
            case .bootNear: CGPoint(x: 81, y: 209)
            case .legFar: CGPoint(x: 118, y: 174)
            case .bootFar: CGPoint(x: 119, y: 209)
            }
        }
    }

    public typealias Layer = RigLayer<Part>

    /// Back to front.
    public static let layers: [Layer] = [
        // Forearms, hands and stick drawn BEHIND the body, for hands-behind-the-back.
        // The front twins sit near the end; `GeneralPose` cross-fades between the two.
        .init(60, "foreFarB", .foreFar, Ink.coat, stroke: 3.0, "M 150.0 131.5 L 138.0 134.5 Q 139.0 148.0 144.5 157.5 L 155.5 153.0 Q 151.0 143.0 150.0 131.5 Z"),
        .init(61, "cuffFarB", .foreFar, Ink.leather, stroke: nil, "M 153.5 149.5 L 143.0 153.8 L 144.5 158.3 L 155.2 154.0 Z"),
        .init(62, "handFarB", .foreFar, Ink.moustache, stroke: 1.8, "M 151.0 156.0 Q 156.5 158.0 155.5 163.5 Q 154.5 168.5 148.5 167.5 Q 143.0 166.0 144.5 160.5 Q 146.0 155.5 151.0 156.0 Z"),
        .init(63, "foreNearB", .foreNear, Ink.coat, stroke: 3.0, "M 50.0 131.5 L 62.0 134.5 Q 61.0 148.0 55.5 157.5 L 44.5 153.0 Q 49.0 143.0 50.0 131.5 Z"),
        .init(64, "cuffNearB", .foreNear, Ink.leather, stroke: nil, "M 46.5 149.5 L 57.0 153.8 L 55.5 158.3 L 44.8 154.0 Z"),
        .init(65, "handNearB", .foreNear, Ink.moustache, stroke: 1.8, "M 49.0 156.0 Q 43.5 158.0 44.5 163.5 Q 45.5 168.5 51.5 167.5 Q 57.0 166.0 55.5 160.5 Q 54.0 155.5 49.0 156.0 Z"),
        .init(66, "stickRodB", .stick, Ink.leather, stroke: 1.8, "M 51.7 158.9 L 27.7 122.9 L 24.3 125.1 L 48.3 161.1 Z"),
        .init(67, "stickTipB", .stick, Ink.brass, stroke: 1.8, path: VectorPath.circle(26.0, 124.0, 2.8)),
        .init(5, "legFarThigh", .legFar, Ink.khaki, stroke: 3.0, "M 108.0 174.0 Q 105.5 192.0 108.0 210.0 L 122.0 211.0 Q 132.0 210.0 134.0 200.0 Q 136.0 186.0 130.0 172.0 Z"),
        .init(6, "bootFar", .bootFar, Ink.leather, stroke: 3.0, "M 108.5 208.5 L 107.0 242.0 Q 106.5 246.5 110.0 247.0 L 137.0 247.0 Q 141.5 246.5 140.0 243.5 Q 138.0 240.5 131.5 240.0 Q 133.5 228.0 132.0 208.0 Z"),
        .init(7, "bootFarShine", .bootFar, Ink.lensShine, stroke: nil, "M 112.0 214.5 L 116.5 214.0 L 115.5 240.0 L 111.0 239.5 Z"),
        .init(8, "legNearThigh", .legNear, Ink.khaki, stroke: 3.0, "M 70.0 172.0 Q 64.0 186.0 66.0 200.0 Q 68.0 210.0 78.0 211.0 L 92.0 210.0 Q 94.5 192.0 93.0 174.0 Z"),
        .init(9, "bootNear", .bootNear, Ink.leather, stroke: 3.0, "M 68.0 208.0 Q 66.5 228.0 68.5 240.0 Q 62.0 240.5 60.0 243.5 Q 58.5 246.5 63.0 247.0 L 90.0 247.0 Q 93.5 246.5 93.0 242.0 L 91.5 208.5 Z"),
        .init(10, "bootNearShine", .bootNear, Ink.lensShine, stroke: nil, "M 71.5 214.0 L 76.0 214.5 L 74.5 240.0 L 70.5 239.5 Z"),
        .init(11, "coatSkirt", .torso, Ink.coat, stroke: 3.0, "M 60.0 158.0 Q 58.0 168.0 60.5 176.0 L 139.5 176.0 Q 142.0 168.0 140.0 158.0 Z"),
        .init(12, "torsoBarrel", .torso, Ink.coat, stroke: 3.0, "M 64.0 98.0 Q 57.5 99.0 57.0 106.0 L 56.0 124.0 Q 56.0 142.0 60.0 160.0 L 63.0 172.0 L 137.0 172.0 L 140.0 160.0 Q 144.0 142.0 144.0 124.0 L 143.0 106.0 Q 142.5 99.0 136.0 98.0 Q 100.0 94.0 64.0 98.0 Z"),
        .init(13, "coatShadeR", .torso, Ink.coatShade, stroke: nil, "M 136.0 98.0 Q 142.5 99.0 143.0 106.0 L 144.0 124.0 Q 144.0 142.0 140.0 160.0 L 137.0 172.0 L 128.0 172.0 L 131.5 158.0 Q 135.0 142.0 134.5 124.0 Q 134.5 108.0 128.0 98.5 Z"),
        .init(14, "placket", .torso, Ink.coatShade, stroke: nil, "M 103.0 108.0 L 101.5 148.0 L 104.5 148.0 L 106.0 108.0 Z"),
        .init(15, "collar", .torso, Ink.coatShade, stroke: 1.8, "M 88.0 96.0 L 100.0 106.0 L 112.0 96.0 L 116.0 102.0 L 100.0 112.5 L 84.0 102.0 Z"),
        .init(16, "btnA", .torso, Ink.brass, stroke: 1.8, path: VectorPath.circle(106.0, 118.0, 2.6)),
        .init(17, "btnB", .torso, Ink.brass, stroke: 1.8, path: VectorPath.circle(107.5, 132.0, 2.6)),
        .init(18, "btnC", .torso, Ink.brass, stroke: 1.8, path: VectorPath.circle(108.0, 146.0, 2.6)),
        .init(19, "belt", .torso, Ink.leather, stroke: 3.0, "M 58.5 148.0 L 141.5 148.0 L 141.0 158.5 L 59.0 158.5 Z"),
        .init(20, "buckle", .torso, Ink.brass, stroke: 1.8, "M 94.0 146.5 L 106.0 146.5 L 106.0 159.5 L 94.0 159.5 Z"),
        .init(21, "medalA", .medals, Ink.brass, stroke: 1.8, path: VectorPath.circle(72.0, 114.0, 4.2)),
        .init(22, "medalB", .medals, Ink.brass, stroke: 1.8, path: VectorPath.circle(83.0, 116.5, 4.2)),
        .init(23, "medalC", .medals, Ink.brass, stroke: 1.8, path: VectorPath.circle(70.5, 126.5, 4.2)),
        .init(24, "medalD", .medals, Ink.brass, stroke: 1.8, path: VectorPath.circle(81.5, 129.0, 4.2)),
        .init(25, "medalE", .medals, Ink.brass, stroke: 1.8, path: VectorPath.circle(76.0, 140.0, 5.4)),
        .init(26, "neck", .torso, Ink.skin, stroke: 3.0, "M 90.0 90.0 L 90.0 100.0 Q 100.0 104.0 110.0 100.0 L 110.0 90.0 Z"),
        .init(27, "faceBase", .head, Ink.skin, stroke: 3.0, "M 70.0 46.0 L 70.0 66.0 Q 70.0 88.0 86.0 93.0 Q 100.0 96.5 114.0 93.0 Q 130.0 88.0 130.0 66.0 L 130.0 46.0 Z"),
        .init(28, "cheekL", .head, Ink.ruddy, stroke: nil, "M 70.5 66.0 Q 76.0 63.5 80.0 67.0 Q 80.5 71.5 76.0 73.0 Q 71.0 72.0 70.5 66.0 Z"),
        .init(29, "cheekR", .head, Ink.ruddy, stroke: nil, "M 120.0 67.0 Q 124.0 63.5 129.5 66.0 Q 129.0 72.0 124.0 73.0 Q 119.5 71.5 120.0 67.0 Z"),
        .init(30, "sweatDrop", .head, Ink.lensShine, stroke: 1.8, "M 140.0 52.0 Q 144.5 59.0 141.5 63.5 Q 138.5 66.5 135.5 63.5 Q 133.0 59.5 137.0 54.0 Q 138.5 51.5 140.0 52.0 Z", restOpacity: 0),
        .init(31, "shoutMouth", .head, Ink.leather, stroke: 1.8, "M 93.0 88.0 Q 100.0 85.5 107.0 88.0 Q 108.5 94.5 100.0 96.0 Q 91.5 94.5 93.0 88.0 Z", restOpacity: 0),
        .init(32, "grinTeeth", .head, Ink.moustache, stroke: 1.8, "M 93.5 89.0 L 106.5 89.0 Q 107.5 93.5 100.0 94.0 Q 92.5 93.5 93.5 89.0 Z", restOpacity: 0),
        .init(33, "chin", .head, Ink.skin, stroke: 1.8, "M 92.0 92.5 Q 100.0 97.5 108.0 92.5 Q 106.0 99.0 100.0 99.5 Q 94.0 99.0 92.0 92.5 Z"),
        .init(34, "stacheMain", .stache, Ink.moustache, stroke: 3.0, "M 100.0 66.0 Q 82.0 60.0 72.0 68.0 Q 63.5 75.0 68.0 86.0 Q 72.5 96.0 83.0 94.0 Q 92.0 92.0 95.0 84.0 Q 98.0 78.0 100.0 78.0 Q 102.0 78.0 105.0 84.0 Q 108.0 92.0 117.0 94.0 Q 127.5 96.0 132.0 86.0 Q 136.5 75.0 128.0 68.0 Q 118.0 60.0 100.0 66.0 Z"),
        .init(35, "stacheShade", .stache, Ink.moustacheShade, stroke: nil, "M 74.0 84.0 Q 78.0 91.0 84.0 90.5 Q 78.0 93.5 74.5 89.0 Q 72.5 86.5 74.0 84.0 Z M 126.0 84.0 Q 122.0 91.0 116.0 90.5 Q 122.0 93.5 125.5 89.0 Q 127.5 86.5 126.0 84.0 Z"),
        .init(36, "nose", .head, Ink.ruddy, stroke: 1.8, "M 92.0 56.0 Q 100.0 52.5 108.0 56.0 Q 113.5 60.0 111.0 66.0 Q 107.0 71.5 100.0 71.5 Q 93.0 71.5 89.0 66.0 Q 86.5 60.0 92.0 56.0 Z"),
        .init(70, "eyeWhiteL", .head, Ink.moustache, stroke: 1.2, "M 78.0 58.0 Q 78.0 54.2 84.0 54.2 Q 90.0 54.2 90.0 58.0 Q 90.0 61.8 84.0 61.8 Q 78.0 61.8 78.0 58.0 Z"),
        .init(71, "eyeWhiteR", .head, Ink.moustache, stroke: 1.2, "M 110.0 58.0 Q 110.0 54.2 116.0 54.2 Q 122.0 54.2 122.0 58.0 Q 122.0 61.8 116.0 61.8 Q 110.0 61.8 110.0 58.0 Z"),
        .init(53, "eyeL", .head, Ink.outline, stroke: nil, path: VectorPath.circle(85.0, 58.4, 2.8)),
        .init(54, "eyeR", .head, Ink.outline, stroke: nil, path: VectorPath.circle(117.0, 58.4, 2.8)),
        .init(55, "browL", .head, Ink.outline, stroke: nil, "M 76.0 51.0 L 91.0 52.5 L 91.0 54.0 L 76.0 52.5 Z"),
        .init(56, "browR", .head, Ink.outline, stroke: nil, "M 124.0 51.0 L 109.0 52.5 L 109.0 54.0 L 124.0 52.5 Z"),
        .init(37, "lensL", .shades, Ink.lens, stroke: 3.0, "M 68.0 44.0 L 96.0 44.0 Q 97.5 58.0 89.5 63.5 Q 79.5 68.0 72.5 60.5 Q 67.0 53.0 68.0 44.0 Z"),
        .init(38, "lensR", .shades, Ink.lens, stroke: 3.0, "M 104.0 44.0 L 132.0 44.0 Q 133.0 53.0 127.5 60.5 Q 120.5 68.0 110.5 63.5 Q 102.5 58.0 104.0 44.0 Z"),
        .init(39, "bridge", .shades, Ink.brass, stroke: 1.8, "M 95.5 44.5 L 104.5 44.5 L 104.5 47.5 L 95.5 47.5 Z"),
        .init(40, "shineL", .shades, Ink.lensShine, stroke: nil, "M 71.5 46.0 L 80.0 46.0 L 72.5 58.0 Q 69.5 53.0 71.5 46.0 Z"),
        .init(41, "shineR", .shades, Ink.lensShine, stroke: nil, "M 107.5 46.0 L 116.0 46.0 L 108.5 58.0 Q 105.5 53.0 107.5 46.0 Z"),
        .init(42, "capCrown", .cap, Ink.coat, stroke: 3.0, "M 70.0 38.0 L 62.5 12.0 Q 61.0 6.0 67.0 5.0 Q 100.0 0.5 133.0 5.0 Q 139.0 6.0 137.5 12.0 L 130.0 38.0 Z"),
        .init(43, "capShade", .cap, Ink.coatShade, stroke: nil, "M 126.0 6.0 Q 138.5 7.5 137.0 13.0 L 130.0 38.0 L 122.0 38.0 Z"),
        .init(57, "capRim", .cap, Ink.brass, stroke: nil, "M 64.0 10.0 Q 62.5 6.2 67.0 5.8 Q 100.0 1.6 133.0 5.8 Q 137.5 6.2 136.0 10.0 Q 100.0 5.4 64.0 10.0 Z"),
        .init(44, "capBand", .cap, Ink.leather, stroke: 3.0, "M 68.0 34.0 L 132.0 34.0 L 133.5 42.5 L 66.5 42.5 Z"),
        .init(45, "capVisor", .cap, Ink.leather, stroke: 3.0, "M 70.0 42.0 Q 100.0 52.0 130.0 42.0 Q 132.0 47.0 127.0 50.5 Q 100.0 58.0 73.0 50.5 Q 68.0 47.0 70.0 42.0 Z"),
        .init(46, "capButton", .cap, Ink.brass, stroke: 1.8, path: VectorPath.circle(100.0, 20.0, 5.0)),
        // Arms, drawn last so a salute or a point crosses the body and the cap.
        .init(1, "armFarUpper", .armFar, Ink.coat, stroke: 3.0, "M 143.0 105.0 Q 143.0 95.5 134.0 95.5 Q 125.0 95.5 124.5 105.0 Q 130.0 120.0 138.5 137.0 L 150.5 134.0 Q 144.5 120.0 143.0 105.0 Z"),
        .init(2, "foreFar", .foreFar, Ink.coat, stroke: 3.0, "M 150.0 131.5 L 138.0 134.5 Q 139.0 148.0 144.5 157.5 L 155.5 153.0 Q 151.0 143.0 150.0 131.5 Z"),
        .init(3, "cuffFar", .foreFar, Ink.leather, stroke: nil, "M 153.5 149.5 L 143.0 153.8 L 144.5 158.3 L 155.2 154.0 Z"),
        .init(4, "handFar", .foreFar, Ink.moustache, stroke: 1.8, "M 151.0 156.0 Q 156.5 158.0 155.5 163.5 Q 154.5 168.5 148.5 167.5 Q 143.0 166.0 144.5 160.5 Q 146.0 155.5 151.0 156.0 Z"),
        .init(80, "elbowFar", .foreFar, Ink.coat, stroke: 3.0, path: VectorPath.circle(144.0, 134.5, 7.0)),
        .init(81, "shoulderFar", .armFar, Ink.coat, stroke: 3.0, path: VectorPath.circle(134.0, 103.5, 9.5)),
        .init(47, "armNearUpper", .armNear, Ink.coat, stroke: 3.0, "M 57.0 105.0 Q 57.0 95.5 66.0 95.5 Q 75.0 95.5 75.5 105.0 Q 70.0 120.0 61.5 137.0 L 49.5 134.0 Q 55.5 120.0 57.0 105.0 Z"),
        .init(48, "foreNear", .foreNear, Ink.coat, stroke: 3.0, "M 50.0 131.5 L 62.0 134.5 Q 61.0 148.0 55.5 157.5 L 44.5 153.0 Q 49.0 143.0 50.0 131.5 Z"),
        .init(49, "cuffNear", .foreNear, Ink.leather, stroke: nil, "M 46.5 149.5 L 57.0 153.8 L 55.5 158.3 L 44.8 154.0 Z"),
        .init(50, "handNear", .foreNear, Ink.moustache, stroke: 1.8, "M 49.0 156.0 Q 43.5 158.0 44.5 163.5 Q 45.5 168.5 51.5 167.5 Q 57.0 166.0 55.5 160.5 Q 54.0 155.5 49.0 156.0 Z"),
        .init(82, "elbowNear", .foreNear, Ink.coat, stroke: 3.0, path: VectorPath.circle(56.0, 134.5, 7.0)),
        .init(83, "shoulderNear", .armNear, Ink.coat, stroke: 3.0, path: VectorPath.circle(66.0, 103.5, 9.5)),
        .init(51, "stickRod", .stick, Ink.leather, stroke: 1.8, "M 51.7 158.9 L 27.7 122.9 L 24.3 125.1 L 48.3 161.1 Z"),
        .init(52, "stickTip", .stick, Ink.brass, stroke: 1.8, path: VectorPath.circle(26.0, 124.0, 2.8)),
    ]
}
