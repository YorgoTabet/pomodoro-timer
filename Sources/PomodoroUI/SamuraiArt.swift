import CoreGraphics
import SwiftUI

/// The samurai's artwork and rig, transcribed from the art-direction spec.
///
/// Everything lives in one flat 200×260 design space, origin top-left, +y down.
/// Absolute `Path` data only — no `.position` modifiers. That is not a style
/// preference: an earlier version built from `.position` inside nested
/// `.frame`-constrained stacks blanked the entire hosting view at runtime while
/// rendering fine offscreen.
public enum SamuraiArt {

    public static let canvas = CGSize(width: 200, height: 260)

    // MARK: - Palette

    public enum Ink {
        public static let outline = Color(hex: 0x2A1A16)
        public static let red = Color(hex: 0xC13327)
        public static let redShade = Color(hex: 0x8E2018)
        public static let gold = Color(hex: 0xF0B84B)
        public static let goldShade = Color(hex: 0xC08A2A)
        public static let iron = Color(hex: 0x54453E)
        public static let indigo = Color(hex: 0x4C6B8E)
        public static let skin = Color(hex: 0xF0C49A)
        public static let skinShade = Color(hex: 0xCE9E72)
        public static let steel = Color(hex: 0xC9D2D8)
        public static let steelHilite = Color(hex: 0xF4F8FA)
        public static let leather = Color(hex: 0x7A4E2C)
    }

    // MARK: - Rig

    /// A jointed part. `parent` gives the transform chain; `pivot` is in design units.
    public enum Part: String, CaseIterable, RigPart {
        public static var canvas: CGSize { SamuraiArt.canvas }

        case root, legL, legR, shinL, shinR, footL, footR, torso, head, kabuto, maedate
        case sodeL, sodeR, offArmUpper, offArmFore
        case swordArmUpper, swordFore, katana
        case chestCord, sashTailL, sashTailR
        case kusazuriL, kusazuriFL, kusazuriFR, kusazuriR
        case scabbard

        public var parent: Part? {
            switch self {
            case .root: nil
            case .legL, .legR, .torso: .root
            case .head, .sodeL, .sodeR, .offArmUpper, .swordArmUpper,
                 .chestCord, .sashTailL, .sashTailR,
                 .kusazuriL, .kusazuriFL, .kusazuriFR, .kusazuriR, .scabbard: .torso
            case .kabuto: .head
            case .shinL: .legL
            case .shinR: .legR
            case .footL: .shinL
            case .footR: .shinR
            case .maedate: .kabuto
            case .offArmFore: .offArmUpper
            case .swordFore: .swordArmUpper
            case .katana: .swordFore
            }
        }

        /// Rotation pivot in design units, straight from the rig table.
        public var pivot: CGPoint {
            switch self {
            case .root: CGPoint(x: 100, y: 260)
            case .legL: CGPoint(x: 90, y: 196)
            case .legR: CGPoint(x: 110, y: 196)
            case .shinL: CGPoint(x: 90, y: 227)
            case .shinR: CGPoint(x: 110, y: 227)
            case .footL: CGPoint(x: 90, y: 249)
            case .footR: CGPoint(x: 110, y: 249)
            case .torso: CGPoint(x: 100, y: 163)
            case .head: CGPoint(x: 100, y: 113)
            case .kabuto: CGPoint(x: 100, y: 80)
            case .maedate: CGPoint(x: 100, y: 64)
            case .sodeL: CGPoint(x: 70, y: 117)
            case .sodeR: CGPoint(x: 130, y: 117)
            case .offArmUpper: CGPoint(x: 76, y: 124)
            case .offArmFore: CGPoint(x: 70.18, y: 151.39)
            case .swordArmUpper: CGPoint(x: 124, y: 124)
            case .swordFore: CGPoint(x: 129.82, y: 151.39)
            case .katana: CGPoint(x: 130.59, y: 173.37)
            case .chestCord: CGPoint(x: 100, y: 128)
            case .sashTailL: CGPoint(x: 97, y: 169)
            case .sashTailR: CGPoint(x: 103, y: 169)
            case .kusazuriL: CGPoint(x: 74, y: 168)
            case .kusazuriFL: CGPoint(x: 92, y: 168)
            case .kusazuriFR: CGPoint(x: 108, y: 168)
            case .kusazuriR: CGPoint(x: 126, y: 168)
            case .scabbard: CGPoint(x: 80, y: 163)
            }
        }

    }

    // MARK: - Layers

    public typealias Layer = RigLayer<Part>

    /// Back to front. Draw order is global and independent of the rig hierarchy —
    /// `shikoro` belongs to `kabuto` but is drawn third, behind almost everything.
    public static let layers: [Layer] = [
        .init(1, "scabbardBody", .scabbard, Ink.iron, stroke: 3.0,
              "M 77.6 161.2 L 82.4 164.8 L 53.4 204.8 L 48.6 201.2 Z"),
        .init(2, "scabbardKojiri", .scabbard, Ink.goldShade, stroke: 1.8,
              "M 53.4 204.8 L 48.6 201.2 Q 44.8 204.0 46.4 207.6 Q 48.6 210.6 52.0 208.6 Z"),
        .init(3, "shikoro", .kabuto, Ink.redShade, stroke: 3.0,
              "M 66.0 79.0 L 134.0 79.0 C 140.0 92.0 131.0 104.0 100.0 104.0 C 69.0 104.0 60.0 92.0 66.0 79.0 Z"),
        .init(4, "legUpperL", .legL, Ink.indigo, stroke: 3.0,
              "M 80.2 190.0 L 99.8 190.0 L 98.6 227.0 L 81.4 227.0 Z"),
        .init(5, "shinL", .shinL, Ink.red, stroke: 3.0,
              "M 82.6 227.0 L 97.4 227.0 L 96.6 249.0 L 83.4 249.0 Z"),
        .init(6, "kneeCapL", .shinL, Ink.iron, stroke: 3.0,
              path: VectorPath.circle(90.0, 227.0, 7.4)),
        .init(7, "footL", .footL, Ink.leather, stroke: 3.0,
              "M 81.5 248.0 L 98.5 248.0 Q 99.5 251.5 98.0 255.0 L 82.0 255.0 Q 78.5 251.5 81.5 248.0 Z"),
        .init(8, "legUpperR", .legR, Ink.indigo, stroke: 3.0,
              "M 100.2 190.0 L 119.8 190.0 L 118.6 227.0 L 101.4 227.0 Z"),
        .init(9, "shinR", .shinR, Ink.red, stroke: 3.0,
              "M 102.6 227.0 L 117.4 227.0 L 116.6 249.0 L 103.4 249.0 Z"),
        .init(10, "kneeCapR", .shinR, Ink.iron, stroke: 3.0,
              path: VectorPath.circle(110.0, 227.0, 7.4)),
        .init(11, "footR", .footR, Ink.leather, stroke: 3.0,
              "M 118.5 248.0 L 101.5 248.0 Q 100.5 251.5 102.0 255.0 L 118.0 255.0 Q 121.5 251.5 118.5 248.0 Z"),
        .init(12, "kusazuriPlateL", .kusazuriL, Ink.red, stroke: 3.0,
              "M 62.5 167.5 L 85.5 168.5 L 82.5 199.5 L 55.5 196.5 Z"),
        .init(13, "kusazuriHemL", .kusazuriL, Ink.gold, stroke: 1.8,
              "M 56.0 191.7 L 83.0 194.6 L 82.5 199.5 L 55.5 196.5 Z"),
        .init(14, "kusazuriPlateR", .kusazuriR, Ink.red, stroke: 3.0,
              "M 114.5 168.5 L 137.5 167.5 L 144.5 196.5 L 117.5 199.5 Z"),
        .init(15, "kusazuriHemR", .kusazuriR, Ink.gold, stroke: 1.8,
              "M 117.0 194.6 L 144.0 191.7 L 144.5 196.5 L 117.5 199.5 Z"),
        .init(16, "kusazuriPlateFL", .kusazuriFL, Ink.red, stroke: 3.0,
              "M 84.0 168.0 L 101.0 168.0 L 100.5 202.0 L 79.0 200.5 Z"),
        .init(17, "kusazuriHemFL", .kusazuriFL, Ink.gold, stroke: 1.8,
              "M 79.4 195.6 L 100.6 196.9 L 100.5 202.0 L 79.0 200.5 Z"),
        .init(18, "kusazuriPlateFR", .kusazuriFR, Ink.red, stroke: 3.0,
              "M 99.0 168.0 L 116.0 168.0 L 121.0 200.5 L 99.5 202.0 Z"),
        .init(19, "kusazuriHemFR", .kusazuriFR, Ink.gold, stroke: 1.8,
              "M 99.4 196.9 L 120.3 195.6 L 121.0 200.5 L 99.5 202.0 Z"),
        .init(20, "neck", .torso, Ink.skinShade, stroke: nil,
              "M 92.5 105.0 L 107.5 105.0 L 107.5 116.0 L 92.5 116.0 Z"),
        .init(21, "doPlate", .torso, Ink.red, stroke: 3.0,
              "M 73.5 122.0 C 73.5 116.5 83.5 112.5 100.0 112.5 C 116.5 112.5 126.5 116.5 126.5 122.0 L 124.0 158.0 L 76.0 158.0 Z"),
        .init(22, "doShadePlane", .torso, Ink.redShade, stroke: nil,
              "M 113.0 113.5 C 120.5 115.0 126.5 117.5 126.5 122.0 L 124.0 158.0 L 116.0 158.0 C 120.5 143.0 119.0 127.0 113.0 113.5 Z"),
        .init(23, "doLamePair", .torso, Ink.redShade, stroke: nil,
              "M 74.5 135.0 Q 100.0 139.5 125.5 135.0 L 125.3 138.2 Q 100.0 142.7 74.7 138.2 Z M 75.0 146.0 Q 100.0 150.5 125.0 146.0 L 124.8 149.2 Q 100.0 153.7 75.2 149.2 Z"),
        .init(24, "muneita", .torso, Ink.gold, stroke: 1.8,
              "M 77.5 118.5 C 85.0 114.8 115.0 114.8 122.5 118.5 L 122.8 124.0 C 115.0 120.5 85.0 120.5 77.2 124.0 Z"),
        .init(25, "chestCordTails", .chestCord, Ink.gold, stroke: 1.8,
              "M 96.5 136.0 Q 93.0 144.0 95.0 151.5 L 98.2 150.7 Q 96.6 144.5 99.6 137.5 Z M 103.5 136.0 Q 107.0 144.0 105.0 151.5 L 101.8 150.7 Q 103.4 144.5 100.4 137.5 Z"),
        .init(26, "chestCordKnot", .chestCord, Ink.gold, stroke: 1.8,
              "M 100.0 126.5 L 105.5 132.0 L 100.0 137.5 L 94.5 132.0 Z"),
        .init(27, "obiBand", .torso, Ink.iron, stroke: 3.0,
              "M 76.0 157.0 L 124.0 157.0 L 125.5 168.5 L 74.5 168.5 Z"),
        .init(28, "obiKnot", .torso, Ink.gold, stroke: 1.8,
              "M 93.0 158.5 L 107.0 158.5 L 109.0 170.0 L 91.0 170.0 Z"),
        .init(29, "sashTailL", .sashTailL, Ink.gold, stroke: 1.8,
              "M 94.5 169.0 Q 90.5 178.0 92.5 188.5 L 97.5 187.8 Q 96.0 178.5 99.5 169.5 Z"),
        .init(30, "sashTailR", .sashTailR, Ink.gold, stroke: 1.8,
              "M 105.5 169.0 Q 109.5 178.0 107.5 188.5 L 102.5 187.8 Q 104.0 178.5 100.5 169.5 Z"),
        .init(31, "offArmUpper", .offArmUpper, Ink.indigo, stroke: 3.0,
              "M 69.2 122.5 L 64.1 150.1 L 76.2 152.7 L 82.8 125.5 Z"),
        .init(32, "offShoulderCap", .offArmUpper, Ink.indigo, stroke: 3.0,
              path: VectorPath.circle(76.0, 124.0, 7.8)),
        .init(33, "swordArmUpper", .swordArmUpper, Ink.indigo, stroke: 3.0,
              "M 117.2 125.5 L 123.8 152.7 L 135.9 150.1 L 130.8 122.5 Z"),
        .init(34, "swordShoulderCap", .swordArmUpper, Ink.indigo, stroke: 3.0,
              path: VectorPath.circle(124.0, 124.0, 7.8)),
        .init(35, "sodeL", .sodeL, Ink.red, stroke: 3.0,
              "M 58.5 119.0 Q 68.0 113.5 81.0 116.0 L 83.5 141.0 Q 71.0 148.5 57.0 142.5 Z"),
        .init(36, "sodeLCap", .sodeL, Ink.gold, stroke: 1.8,
              "M 58.5 119.0 Q 68.0 113.5 81.0 116.0 L 81.6 121.5 Q 69.0 119.0 59.3 124.0 Z"),
        .init(37, "sodeR", .sodeR, Ink.red, stroke: 3.0,
              "M 141.5 119.0 Q 132.0 113.5 119.0 116.0 L 116.5 141.0 Q 129.0 148.5 143.0 142.5 Z"),
        .init(38, "sodeRCap", .sodeR, Ink.gold, stroke: 1.8,
              "M 141.5 119.0 Q 132.0 113.5 119.0 116.0 L 118.4 121.5 Q 131.0 119.0 140.7 124.0 Z"),
        .init(39, "face", .head, Ink.skin, stroke: 3.0,
              "M 80.0 74.0 L 120.0 74.0 L 120.0 96.0 C 120.0 106.5 112.0 113.0 100.0 113.0 C 88.0 113.0 80.0 106.5 80.0 96.0 Z"),
        .init(40, "menpoMask", .head, Ink.iron, stroke: 3.0,
              "M 80.0 92.5 L 120.0 92.5 L 120.0 96.0 C 120.0 106.5 112.0 113.5 100.0 113.5 C 88.0 113.5 80.0 106.5 80.0 96.0 Z"),
        .init(41, "menpoMouthSlit", .head, Ink.outline, stroke: nil,
              "M 89.5 101.5 Q 100.0 106.5 110.5 101.5 L 109.3 105.2 Q 100.0 109.7 90.7 105.2 Z"),
        .init(42, "menpoKiai", .head, Ink.outline, stroke: nil,
              "M 92.0 104.0 C 92.0 99.6 95.8 98.6 100.0 98.6 C 104.2 98.6 108.0 99.6 108.0 104.0 C 108.0 108.6 104.2 109.6 100.0 109.6 C 95.8 109.6 92.0 108.6 92.0 104.0 Z",
              restOpacity: 0),
        .init(43, "menpoKiaiTongue", .head, Ink.redShade, stroke: nil,
              "M 95.5 107.0 C 96.5 105.0 103.5 105.0 104.5 107.0 C 103.0 108.8 97.0 108.8 95.5 107.0 Z",
              restOpacity: 0),
        .init(44, "eyeWhites", .head, Ink.steelHilite, stroke: 1.8,
              "M 85.5 86.0 L 95.5 88.5 L 95.0 92.5 L 86.0 91.0 Z M 114.5 86.0 L 104.5 88.5 L 105.0 92.5 L 114.0 91.0 Z"),
        .init(45, "pupilPair", .head, Ink.outline, stroke: nil,
              path: VectorPath.combined([
                  VectorPath.circle(91.5, 89.5, 1.9),
                  VectorPath.circle(108.5, 89.5, 1.9),
              ])),
        .init(46, "browsFierce", .head, Ink.outline, stroke: nil,
              "M 84.0 81.0 L 96.5 84.5 L 95.5 87.5 L 83.5 84.0 Z M 116.0 81.0 L 103.5 84.5 L 104.5 87.5 L 116.5 84.0 Z"),
        .init(47, "browsEase", .head, Ink.outline, stroke: nil,
              "M 84.5 80.0 Q 90.0 78.0 96.0 79.5 L 96.0 82.5 Q 90.5 81.0 85.0 83.0 Z M 115.5 80.0 Q 110.0 78.0 104.0 79.5 L 104.0 82.5 Q 109.5 81.0 115.0 83.0 Z",
              restOpacity: 0),
        .init(48, "eyesTriumph", .head, Ink.outline, stroke: nil,
              "M 85.5 90.5 Q 90.5 84.5 95.5 90.5 L 92.8 90.5 Q 90.5 87.5 88.2 90.5 Z M 114.5 90.5 Q 109.5 84.5 104.5 90.5 L 107.2 90.5 Q 109.5 87.5 111.8 90.5 Z",
              restOpacity: 0),
        .init(49, "kabutoBowl", .kabuto, Ink.red, stroke: 3.0,
              "M 72.0 78.0 C 72.0 54.0 83.0 42.0 100.0 42.0 C 117.0 42.0 128.0 54.0 128.0 78.0 L 128.0 79.0 L 72.0 79.0 Z"),
        .init(50, "kabutoBowlShade", .kabuto, Ink.redShade, stroke: nil,
              "M 72.0 78.0 C 72.0 54.0 83.0 42.0 100.0 42.0 C 90.0 47.0 84.5 58.0 84.0 79.0 L 72.0 79.0 Z"),
        .init(51, "mabizashi", .kabuto, Ink.iron, stroke: 3.0,
              "M 69.0 75.0 L 131.0 75.0 Q 134.0 77.5 131.5 81.0 Q 116.0 78.5 100.0 78.5 Q 84.0 78.5 68.5 81.0 Q 66.0 77.5 69.0 75.0 Z"),
        .init(52, "fukigaeshiL", .kabuto, Ink.red, stroke: 3.0,
              "M 73.0 75.5 Q 60.0 73.5 55.5 82.0 Q 52.5 90.5 62.0 94.0 Q 70.0 96.5 76.5 90.0 L 74.5 80.0 Z"),
        .init(53, "fukigaeshiR", .kabuto, Ink.red, stroke: 3.0,
              "M 127.0 75.5 Q 140.0 73.5 144.5 82.0 Q 147.5 90.5 138.0 94.0 Q 130.0 96.5 123.5 90.0 L 125.5 80.0 Z"),
        .init(54, "fukiRivetPair", .kabuto, Ink.gold, stroke: 1.8,
              path: VectorPath.combined([
                  VectorPath.circle(64.5, 85.5, 2.0),
                  VectorPath.circle(135.5, 85.5, 2.0),
              ])),
        .init(55, "tehenCap", .kabuto, Ink.gold, stroke: 1.8,
              path: VectorPath.circle(100.0, 42.5, 3.0)),
        .init(56, "maedateBase", .maedate, Ink.gold, stroke: 1.8,
              "M 93.5 60.0 L 106.5 60.0 L 104.5 71.0 L 95.5 71.0 Z"),
        .init(57, "maedateCrescent", .maedate, Ink.gold, stroke: 3.0,
              "M 100.0 58.5 C 84.0 57.0 73.0 44.0 74.5 24.0 C 81.5 38.5 89.5 46.5 100.0 48.5 C 110.5 46.5 118.5 38.5 125.5 24.0 C 127.0 44.0 116.0 57.0 100.0 58.5 Z"),
        .init(58, "offArmForearm", .offArmFore, Ink.red, stroke: 3.0,
              "M 63.8 151.2 L 63.8 173.2 L 75.0 173.6 L 76.6 151.6 Z"),
        .init(59, "offElbowCap", .offArmFore, Ink.red, stroke: 3.0,
              path: VectorPath.circle(70.2, 151.4, 6.4)),
        .init(60, "swordForearm", .swordFore, Ink.red, stroke: 3.0,
              "M 123.4 151.6 L 125.0 173.6 L 136.2 173.2 L 136.2 151.2 Z"),
        .init(61, "swordElbowCap", .swordFore, Ink.red, stroke: 3.0,
              path: VectorPath.circle(129.8, 151.4, 6.4)),
        .init(62, "katanaTsuka", .katana, Ink.iron, stroke: 1.8,
              "M 125.3 184.9 L 134.3 164.8 L 138.9 166.9 L 129.9 187.0 Z"),
        .init(63, "tsukaWrapPair", .katana, Ink.goldShade, stroke: nil,
              "M 131.7 177.0 L 132.3 179.7 L 129.9 181.0 L 129.3 178.3 Z M 134.4 171.0 L 135.0 173.7 L 132.6 175.0 L 132.0 172.3 Z"),
        .init(64, "tsuba", .katana, Ink.gold, stroke: 1.8,
              path: VectorPath.circle(137.0, 163.4, 4.3)),
        .init(65, "katanaBlade", .katana, Ink.steel, stroke: 1.8,
              "M 135.1 159.3 L 168.6 88.9 L 171.9 90.2 L 139.7 161.4 Z"),
        .init(66, "bladeHamon", .katana, Ink.steelHilite, stroke: nil,
              "M 138.2 160.7 L 171.1 89.9 L 171.9 90.2 L 139.7 161.4 Z"),
        .init(67, "swordFist", .swordFore, Ink.skin, stroke: 3.0,
              path: VectorPath.circle(130.6, 173.4, 6.6)),
        .init(68, "offArmFist", .offArmFore, Ink.skin, stroke: 3.0,
              path: VectorPath.circle(69.4, 173.4, 6.6)),
    ]
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
