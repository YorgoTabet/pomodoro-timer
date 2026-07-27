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
        public static let iron = Color(hex: 0x3B322E)
        public static let indigo = Color(hex: 0x33475E)
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

        case root, legL, legR, torso, head, kabuto, maedate
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
            case .torso: CGPoint(x: 100, y: 163)
            case .head: CGPoint(x: 100, y: 113)
            case .kabuto: CGPoint(x: 100, y: 80)
            case .maedate: CGPoint(x: 100, y: 64)
            case .sodeL: CGPoint(x: 70, y: 117)
            case .sodeR: CGPoint(x: 130, y: 117)
            case .offArmUpper: CGPoint(x: 76, y: 124)
            case .offArmFore: CGPoint(x: 64, y: 147)
            case .swordArmUpper: CGPoint(x: 122, y: 124)
            case .swordFore: CGPoint(x: 135, y: 151)
            case .katana: CGPoint(x: 150, y: 164.5)
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
              "M 81.5 195.0 L 98.5 196.0 L 97.0 227.0 L 83.5 227.0 Z"),
        .init(5, "shinL", .legL, Ink.red, stroke: 3.0,
              "M 84.0 227.0 L 96.5 227.0 L 96.0 249.0 L 85.0 249.0 Z"),
        .init(6, "footL", .legL, Ink.leather, stroke: 3.0,
              "M 81.0 249.0 L 98.0 249.0 Q 101.0 252.0 97.5 255.0 L 82.0 255.0 Q 78.5 252.0 81.0 249.0 Z"),
        .init(7, "legUpperR", .legR, Ink.indigo, stroke: 3.0,
              "M 101.5 196.0 L 118.5 195.0 L 116.5 227.0 L 103.0 227.0 Z"),
        .init(8, "shinR", .legR, Ink.red, stroke: 3.0,
              "M 103.5 227.0 L 116.0 227.0 L 115.0 249.0 L 104.0 249.0 Z"),
        .init(9, "footR", .legR, Ink.leather, stroke: 3.0,
              "M 102.0 249.0 L 119.0 249.0 Q 121.5 252.0 118.0 255.0 L 102.5 255.0 Q 99.0 252.0 102.0 249.0 Z"),
        .init(10, "kusazuriPlateL", .kusazuriL, Ink.red, stroke: 3.0,
              "M 62.5 167.5 L 85.5 168.5 L 82.5 199.5 L 55.5 196.5 Z"),
        .init(11, "kusazuriHemL", .kusazuriL, Ink.gold, stroke: 1.8,
              "M 56.0 191.7 L 83.0 194.6 L 82.5 199.5 L 55.5 196.5 Z"),
        .init(12, "kusazuriPlateR", .kusazuriR, Ink.red, stroke: 3.0,
              "M 114.5 168.5 L 137.5 167.5 L 144.5 196.5 L 117.5 199.5 Z"),
        .init(13, "kusazuriHemR", .kusazuriR, Ink.gold, stroke: 1.8,
              "M 117.0 194.6 L 144.0 191.7 L 144.5 196.5 L 117.5 199.5 Z"),
        .init(14, "kusazuriPlateFL", .kusazuriFL, Ink.red, stroke: 3.0,
              "M 84.0 168.0 L 101.0 168.0 L 100.5 202.0 L 79.0 200.5 Z"),
        .init(15, "kusazuriHemFL", .kusazuriFL, Ink.gold, stroke: 1.8,
              "M 79.4 195.6 L 100.6 196.9 L 100.5 202.0 L 79.0 200.5 Z"),
        .init(16, "kusazuriPlateFR", .kusazuriFR, Ink.red, stroke: 3.0,
              "M 99.0 168.0 L 116.0 168.0 L 121.0 200.5 L 99.5 202.0 Z"),
        .init(17, "kusazuriHemFR", .kusazuriFR, Ink.gold, stroke: 1.8,
              "M 99.4 196.9 L 120.3 195.6 L 121.0 200.5 L 99.5 202.0 Z"),
        .init(18, "neck", .torso, Ink.skinShade, stroke: nil,
              "M 92.5 105.0 L 107.5 105.0 L 107.5 116.0 L 92.5 116.0 Z"),
        .init(19, "doPlate", .torso, Ink.red, stroke: 3.0,
              "M 74.0 121.0 C 74.0 116.0 83.0 112.5 100.0 112.5 C 117.0 112.5 126.0 116.0 126.0 121.0 L 128.5 158.0 L 71.5 158.0 Z"),
        .init(20, "doShadePlane", .torso, Ink.redShade, stroke: nil,
              "M 113.0 113.5 C 121.0 115.0 126.0 117.5 126.0 121.0 L 128.5 158.0 L 117.0 158.0 C 121.5 143.0 119.5 127.0 113.0 113.5 Z"),
        .init(21, "doLamePair", .torso, Ink.redShade, stroke: nil,
              "M 73.2 135.0 Q 100.0 139.5 126.8 135.0 L 127.0 138.2 Q 100.0 142.7 73.0 138.2 Z M 73.6 146.0 Q 100.0 150.5 126.4 146.0 L 126.7 149.2 Q 100.0 153.7 73.4 149.2 Z"),
        .init(22, "muneita", .torso, Ink.gold, stroke: 1.8,
              "M 76.5 118.5 C 84.0 114.8 116.0 114.8 123.5 118.5 L 123.8 124.0 C 116.0 120.5 84.0 120.5 76.2 124.0 Z"),
        .init(23, "chestCordTails", .chestCord, Ink.gold, stroke: 1.8,
              "M 96.5 136.0 Q 93.0 144.0 95.0 151.5 L 98.2 150.7 Q 96.6 144.5 99.6 137.5 Z M 103.5 136.0 Q 107.0 144.0 105.0 151.5 L 101.8 150.7 Q 103.4 144.5 100.4 137.5 Z"),
        .init(24, "chestCordKnot", .chestCord, Ink.gold, stroke: 1.8,
              "M 100.0 126.5 L 105.5 132.0 L 100.0 137.5 L 94.5 132.0 Z"),
        .init(25, "obiBand", .torso, Ink.iron, stroke: 3.0,
              "M 71.5 157.0 L 128.5 157.0 L 129.5 168.5 L 70.5 168.5 Z"),
        .init(26, "obiKnot", .torso, Ink.gold, stroke: 1.8,
              "M 93.0 158.5 L 107.0 158.5 L 109.0 170.0 L 91.0 170.0 Z"),
        .init(27, "sashTailL", .sashTailL, Ink.gold, stroke: 1.8,
              "M 94.5 169.0 Q 90.5 178.0 92.5 188.5 L 97.5 187.8 Q 96.0 178.5 99.5 169.5 Z"),
        .init(28, "sashTailR", .sashTailR, Ink.gold, stroke: 1.8,
              "M 105.5 169.0 Q 109.5 178.0 107.5 188.5 L 102.5 187.8 Q 104.0 178.5 100.5 169.5 Z"),
        .init(29, "offArmUpper", .offArmUpper, Ink.indigo, stroke: 3.0,
              "M 71.0 119.5 Q 61.5 128.0 59.0 145.0 L 69.5 148.5 Q 72.5 133.5 81.0 125.0 Z"),
        .init(30, "offArmForearm", .offArmFore, Ink.red, stroke: 3.0,
              "M 59.0 145.0 L 69.5 148.5 Q 69.0 158.5 72.5 166.5 L 62.0 170.5 Q 57.5 158.5 59.0 145.0 Z"),
        .init(31, "offArmFist", .offArmFore, Ink.skin, stroke: 3.0,
              "M 63.5 166.5 C 60.5 169.5 60.0 175.5 63.5 178.5 C 67.5 181.5 74.0 180.0 75.5 175.0 C 76.8 170.5 73.5 166.0 68.5 166.0 Z"),
        .init(32, "sodeL", .sodeL, Ink.red, stroke: 3.0,
              "M 58.5 119.0 Q 68.0 113.5 81.0 116.0 L 83.5 141.0 Q 71.0 148.5 57.0 142.5 Z"),
        .init(33, "sodeLCap", .sodeL, Ink.gold, stroke: 1.8,
              "M 58.5 119.0 Q 68.0 113.5 81.0 116.0 L 81.6 121.5 Q 69.0 119.0 59.3 124.0 Z"),
        .init(34, "sodeR", .sodeR, Ink.red, stroke: 3.0,
              "M 141.5 119.0 Q 132.0 113.5 119.0 116.0 L 116.5 141.0 Q 129.0 148.5 143.0 142.5 Z"),
        .init(35, "sodeRCap", .sodeR, Ink.gold, stroke: 1.8,
              "M 141.5 119.0 Q 132.0 113.5 119.0 116.0 L 118.4 121.5 Q 131.0 119.0 140.7 124.0 Z"),
        .init(36, "face", .head, Ink.skin, stroke: 3.0,
              "M 80.0 74.0 L 120.0 74.0 L 120.0 96.0 C 120.0 106.5 112.0 113.0 100.0 113.0 C 88.0 113.0 80.0 106.5 80.0 96.0 Z"),
        .init(37, "menpoMask", .head, Ink.iron, stroke: 3.0,
              "M 80.0 92.5 L 120.0 92.5 L 120.0 96.0 C 120.0 106.5 112.0 113.5 100.0 113.5 C 88.0 113.5 80.0 106.5 80.0 96.0 Z"),
        .init(38, "menpoMouthSlit", .head, Ink.outline, stroke: nil,
              "M 89.5 101.5 Q 100.0 106.5 110.5 101.5 L 109.3 105.2 Q 100.0 109.7 90.7 105.2 Z"),
        .init(39, "eyeWhites", .head, Ink.steelHilite, stroke: 1.8,
              "M 85.5 86.0 L 95.5 88.5 L 95.0 92.5 L 86.0 91.0 Z M 114.5 86.0 L 104.5 88.5 L 105.0 92.5 L 114.0 91.0 Z"),
        .init(40, "pupilPair", .head, Ink.outline, stroke: nil,
              path: VectorPath.combined([
                  VectorPath.circle(91.5, 89.5, 1.9),
                  VectorPath.circle(108.5, 89.5, 1.9),
              ])),
        .init(41, "browsFierce", .head, Ink.outline, stroke: nil,
              "M 84.0 81.0 L 96.5 84.5 L 95.5 87.5 L 83.5 84.0 Z M 116.0 81.0 L 103.5 84.5 L 104.5 87.5 L 116.5 84.0 Z"),
        .init(42, "browsEase", .head, Ink.outline, stroke: nil,
              "M 84.5 80.0 Q 90.0 78.0 96.0 79.5 L 96.0 82.5 Q 90.5 81.0 85.0 83.0 Z M 115.5 80.0 Q 110.0 78.0 104.0 79.5 L 104.0 82.5 Q 109.5 81.0 115.0 83.0 Z",
              restOpacity: 0),
        .init(43, "eyesTriumph", .head, Ink.outline, stroke: nil,
              "M 85.5 90.5 Q 90.5 84.5 95.5 90.5 L 92.8 90.5 Q 90.5 87.5 88.2 90.5 Z M 114.5 90.5 Q 109.5 84.5 104.5 90.5 L 107.2 90.5 Q 109.5 87.5 111.8 90.5 Z",
              restOpacity: 0),
        .init(44, "kabutoBowl", .kabuto, Ink.red, stroke: 3.0,
              "M 72.0 78.0 C 72.0 54.0 83.0 42.0 100.0 42.0 C 117.0 42.0 128.0 54.0 128.0 78.0 L 128.0 79.0 L 72.0 79.0 Z"),
        .init(45, "kabutoBowlShade", .kabuto, Ink.redShade, stroke: nil,
              "M 72.0 78.0 C 72.0 54.0 83.0 42.0 100.0 42.0 C 90.0 47.0 84.5 58.0 84.0 79.0 L 72.0 79.0 Z"),
        .init(46, "mabizashi", .kabuto, Ink.iron, stroke: 3.0,
              "M 69.0 75.0 L 131.0 75.0 Q 134.0 77.5 131.5 81.0 Q 116.0 78.5 100.0 78.5 Q 84.0 78.5 68.5 81.0 Q 66.0 77.5 69.0 75.0 Z"),
        .init(47, "fukigaeshiL", .kabuto, Ink.red, stroke: 3.0,
              "M 73.0 75.5 Q 60.0 73.5 55.5 82.0 Q 52.5 90.5 62.0 94.0 Q 70.0 96.5 76.5 90.0 L 74.5 80.0 Z"),
        .init(48, "fukigaeshiR", .kabuto, Ink.red, stroke: 3.0,
              "M 127.0 75.5 Q 140.0 73.5 144.5 82.0 Q 147.5 90.5 138.0 94.0 Q 130.0 96.5 123.5 90.0 L 125.5 80.0 Z"),
        .init(49, "fukiRivetPair", .kabuto, Ink.gold, stroke: 1.8,
              path: VectorPath.combined([
                  VectorPath.circle(64.5, 85.5, 2.0),
                  VectorPath.circle(135.5, 85.5, 2.0),
              ])),
        .init(50, "tehenCap", .kabuto, Ink.gold, stroke: 1.8,
              path: VectorPath.circle(100.0, 42.5, 3.0)),
        .init(51, "maedateBase", .maedate, Ink.gold, stroke: 1.8,
              "M 93.5 60.0 L 106.5 60.0 L 104.5 71.0 L 95.5 71.0 Z"),
        .init(52, "maedateCrescent", .maedate, Ink.gold, stroke: 3.0,
              "M 100.0 58.5 C 84.0 57.0 73.0 44.0 74.5 24.0 C 81.5 38.5 89.5 46.5 100.0 48.5 C 110.5 46.5 118.5 38.5 125.5 24.0 C 127.0 44.0 116.0 57.0 100.0 58.5 Z"),
        .init(53, "swordArmUpper", .swordArmUpper, Ink.indigo, stroke: 3.0,
              "M 117.5 120.5 Q 128.0 124.5 134.0 136.5 L 139.5 149.0 L 129.5 153.5 L 124.5 141.0 Q 120.0 131.0 112.5 125.5 Z"),
        .init(54, "swordForearm", .swordFore, Ink.red, stroke: 3.0,
              "M 129.5 153.5 L 139.5 149.0 Q 147.5 152.5 152.5 159.0 L 145.5 167.5 Q 138.5 159.5 129.5 153.5 Z"),
        .init(55, "swordFist", .swordFore, Ink.skin, stroke: 3.0,
              "M 144.5 158.0 C 141.5 160.5 140.8 166.0 144.0 169.5 C 147.5 173.0 154.0 172.0 156.0 167.5 C 157.8 163.5 155.0 158.5 150.5 158.0 Z"),
        .init(56, "katanaTsuka", .katana, Ink.iron, stroke: 1.8,
              "M 144.7 176.0 L 153.7 155.9 L 158.3 158.0 L 149.3 178.1 Z"),
        .init(57, "tsukaWrapPair", .katana, Ink.goldShade, stroke: nil,
              "M 151.1 168.1 L 151.7 170.8 L 149.3 172.1 L 148.7 169.4 Z M 153.8 162.1 L 154.4 164.8 L 152.0 166.1 L 151.4 163.4 Z"),
        .init(58, "tsuba", .katana, Ink.gold, stroke: 1.8,
              path: VectorPath.circle(156.4, 154.5, 4.3)),
        .init(59, "katanaBlade", .katana, Ink.steel, stroke: 1.8,
              "M 154.5 150.4 L 188.0 80.0 L 191.3 81.3 L 159.1 152.5 Z"),
        .init(60, "bladeHamon", .katana, Ink.steelHilite, stroke: nil,
              "M 157.6 151.8 L 190.5 81.0 L 191.3 81.3 L 159.1 152.5 Z"),
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
