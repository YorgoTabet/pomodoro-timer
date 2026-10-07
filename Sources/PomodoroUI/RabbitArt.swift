import CoreGraphics
import SwiftUI

/// The rabbit-costume guy's artwork and rig.
///
/// The joke is that it reads as a *costume*, not a rabbit. The mascot head carries
/// its own huge permanently-delighted eyes high on the dome; below them an oval
/// opening frames a human face that is dead flat and stays that way. One ear is
/// half-upright, the other has given up entirely and drapes down the right side.
/// A zipper pull dangles at the neck seam.
///
/// The costume is thrilled to be here. The occupant is not. Every animation keys
/// the costume and leaves the face alone — that contrast is the whole character.
public enum RabbitArt {

    public static let canvas = CGSize(width: 200, height: 260)

    public enum Ink {
        public static let outline = Color(hex: 0x45322A)
        public static let outlineCocoa = Color(hex: 0x45322A)
        public static let creamBase = Color(hex: 0xF6EAD7)
        public static let creamShade = Color(hex: 0xD1BEA1)
        public static let bellyCream = Color(hex: 0xFBF4E6)
        public static let pinkInner = Color(hex: 0xF5A8B8)
        public static let skinTone = Color(hex: 0xEFC9A8)
        public static let hairUmber = Color(hex: 0x6B4A38)
        public static let openingShadow = Color(hex: 0x33251D)
        public static let white = Color.white
        public static let zincMetal = Color(hex: 0xB0A79B)
        /// Stroke-only paths — whiskers, stitching, the zipper track, and every
        /// line of the human's face. They carry no fill at all.
        public static let clear = Color.clear
    }

    public enum Part: String, CaseIterable, RigPart {
        public static var canvas: CGSize { RabbitArt.canvas }

        case root, figure, torso, legs, tail, armL, armR, zipperPull
        case armL_fore, armR_fore
        case head, earL_base, earL_tip, earR_base, earR_tip, face

        public var parent: Part? {
            switch self {
            case .root: nil
            case .figure: .root
            case .torso: .figure
            case .legs, .tail, .armL, .armR, .zipperPull, .head: .torso
            case .armL_fore: .armL
            case .armR_fore: .armR
            case .earL_base, .earR_base, .face: .head
            case .earL_tip: .earL_base
            case .earR_tip: .earR_base
            }
        }

        public var pivot: CGPoint {
            switch self {
            case .root: CGPoint(x: 100, y: 196)
            case .figure: CGPoint(x: 100, y: 150)
            case .torso: CGPoint(x: 100, y: 196)
            case .legs: CGPoint(x: 100, y: 200)
            case .tail: CGPoint(x: 61, y: 181)
            case .armL: CGPoint(x: 70, y: 120)
            case .armR: CGPoint(x: 130, y: 120)
            // Elbows, level with each other and set where the sleeve's curve turns
            // from heading outward to heading down.
            case .armL_fore: CGPoint(x: 62, y: 140.5)
            case .armR_fore: CGPoint(x: 138, y: 140.5)
            case .zipperPull: CGPoint(x: 100, y: 141.5)
            case .head: CGPoint(x: 100, y: 112)
            case .earL_base: CGPoint(x: 78, y: 33)
            case .earL_tip: CGPoint(x: 67, y: 19)
            case .earR_base: CGPoint(x: 124, y: 28)
            case .earR_tip: CGPoint(x: 136, y: 17)
            case .face: CGPoint(x: 100, y: 86)
            }
        }
    }

    public typealias Layer = RigLayer<Part>

    /// Back to front. The half-upright ear draws behind the head; the flopped one
    /// draws in front, draped over the head's right edge.
    public static let layers: [Layer] = [
        .init(1, "earL_base_seg", .earL_base, Ink.creamBase, stroke: 3.0, "M 84.5 34.0 C 82.0 27.0 78.0 20.0 72.0 16.0 C 68.0 13.5 63.0 15.0 63.5 20.0 C 64.0 25.0 68.0 31.0 73.0 35.5 Q 79.0 39.0 84.5 34.0 Z"),
        .init(2, "earL_tip_seg", .earL_tip, Ink.creamBase, stroke: 3.0, "M 74.0 21.0 C 71.0 14.0 66.0 6.5 60.0 3.5 C 55.0 1.2 51.0 4.0 52.5 9.0 C 54.0 14.5 58.0 20.0 63.0 23.5 Q 69.0 26.5 74.0 21.0 Z"),
        .init(3, "earL_inner", .earL_tip, Ink.pinkInner, stroke: nil, "M 68.5 18.0 C 66.0 12.5 62.0 7.5 58.5 6.0 C 56.0 5.0 54.5 6.6 55.5 9.5 C 56.8 13.0 59.5 17.0 62.5 19.5 Q 66.0 22.0 68.5 18.0 Z"),
        .init(4, "legL", .legs, Ink.creamBase, stroke: 3.0, "M 72.0 200.0 C 70.5 210.0 70.5 222.0 72.5 231.0 L 91.0 231.0 C 92.5 221.0 92.5 209.0 91.5 200.0 Z"),
        .init(5, "legR", .legs, Ink.creamBase, stroke: 3.0, "M 109.0 200.0 C 107.5 209.0 107.5 221.0 109.0 231.0 L 127.5 231.0 C 129.5 222.0 129.5 210.0 128.0 200.0 Z"),
        .init(6, "footL", .legs, Ink.bellyCream, stroke: 3.0, "M 56.0 242.0 C 56.0 235.4 65.0 230.5 76.0 230.5 C 87.0 230.5 96.0 235.4 96.0 242.0 C 96.0 248.6 87.0 253.5 76.0 253.5 C 65.0 253.5 56.0 248.6 56.0 242.0 Z"),
        .init(7, "footR", .legs, Ink.bellyCream, stroke: 3.0, "M 104.0 242.0 C 104.0 235.4 113.0 230.5 124.0 230.5 C 135.0 230.5 144.0 235.4 144.0 242.0 C 144.0 248.6 135.0 253.5 124.0 253.5 C 113.0 253.5 104.0 248.6 104.0 242.0 Z"),
        .init(8, "tail_pouf", .tail, Ink.bellyCream, stroke: 3.0, path: VectorPath.circle(61.0, 181.0, 11.0)),
        // The left arm, split at the elbow. It was one rigid tube from shoulder to
        // paw, which is why it swung like a broom handle.
        //
        // The upper arm's distal end is cut flat *below* the elbow pivot and the
        // forearm's proximal end is a cap centred *on* that pivot, drawn over it.
        // Because the cap's every point is equidistant from the centre of rotation,
        // the joint's silhouette stays a circle at any angle and the flat cut can
        // never be exposed — the standard cutout-rig trick for hiding a seam without
        // mesh deformation.
        .init(9, "armL_upper", .armL, Ink.creamBase, stroke: 3.0, "M 80.0 112.0 C 68.0 114.0 58.5 125.0 55.0 144.0 L 68.5 144.5 C 68.5 136.5 71.0 129.5 74.5 125.5 C 77.0 122.0 80.5 119.5 83.5 117.5 Q 84.0 112.5 80.0 112.0 Z"),
        .init(50, "armL_fore", .armL_fore, Ink.creamBase, stroke: 3.0, "M 54.5 140.5 Q 55.0 132.5 62.0 132.5 Q 69.2 132.5 69.5 140.5 C 66.0 148.5 64.0 157.5 67.0 166.5 C 65.0 170.5 59.0 170.5 57.0 166.5 C 53.5 159.0 52.8 149.5 54.5 140.5 Z"),
        .init(10, "armL_paw", .armL_fore, Ink.creamBase, stroke: 3.0, "M 50.0 172.0 C 50.0 165.5 55.0 161.5 61.5 162.0 C 68.5 162.5 72.5 167.0 72.0 174.0 C 71.5 181.0 66.5 185.0 60.5 184.5 C 54.0 184.0 50.0 179.0 50.0 172.0 Z"),
        .init(11, "torso_body", .torso, Ink.creamBase, stroke: 3.6, "M 100.0 107.0 C 122.0 107.5 136.5 120.0 140.5 143.0 C 143.8 163.0 141.0 185.0 137.0 204.0 L 63.0 204.0 C 59.0 185.0 56.2 163.0 59.5 143.0 C 63.5 120.0 78.0 107.5 100.0 107.0 Z"),
        .init(12, "torso_shade", .torso, Ink.creamShade, stroke: nil, "M 128.0 122.0 C 136.0 132.0 139.8 148.0 140.5 162.0 C 141.3 178.0 139.5 192.0 137.0 202.0 L 129.0 202.0 C 132.5 188.0 134.5 170.0 132.5 152.0 C 131.0 138.0 129.0 128.0 124.0 120.0 Z"),
        .init(13, "belly_patch", .torso, Ink.bellyCream, stroke: 1.8, "M 100.0 130.0 C 114.5 130.0 125.0 141.8 125.0 158.0 C 125.0 174.2 114.5 186.0 100.0 186.0 C 85.5 186.0 75.0 174.2 75.0 158.0 C 75.0 141.8 85.5 130.0 100.0 130.0 Z"),
        .init(14, "seam_stitches", .torso, Ink.clear, stroke: 1.8, "M 65.5 166.0 L 70.5 165.0 M 64.8 174.0 L 69.8 173.2 M 64.5 182.0 L 69.5 181.4"),
        .init(15, "neck_seam_band", .torso, Ink.creamShade, stroke: 1.8, "M 74.0 112.0 Q 100.0 122.5 126.0 112.0 Q 126.8 116.5 126.0 117.0 Q 100.0 127.5 74.0 117.0 Q 73.2 116.5 74.0 112.0 Z"),
        .init(16, "zipper_track", .torso, Ink.clear, stroke: 1.8, "M 100.0 122.0 L 100.0 137.0 M 97.5 125.5 L 102.5 125.5 M 97.5 130.0 L 102.5 130.0 M 97.5 134.5 L 102.5 134.5"),
        .init(17, "zipper_slider", .torso, Ink.zincMetal, stroke: 1.8, "M 96.8 136.5 L 103.2 136.5 L 102.4 141.5 L 97.6 141.5 Z"),
        .init(18, "zipper_pull", .zipperPull, Ink.zincMetal, stroke: 1.8, "M 98.6 141.5 L 101.4 141.5 L 102.2 149.0 C 102.4 151.8 101.2 153.2 100.0 153.2 C 98.8 153.2 97.6 151.8 97.8 149.0 Z"),
        .init(19, "head_fill", .head, Ink.creamBase, stroke: 3.6, "M 100.0 22.0 C 129.0 22.0 147.5 40.0 149.8 67.0 C 151.6 91.0 138.5 109.5 100.0 111.5 C 61.5 109.5 48.4 91.0 50.2 67.0 C 52.5 40.0 71.0 22.0 100.0 22.0 Z"),
        .init(20, "head_shade", .head, Ink.creamShade, stroke: nil, "M 131.0 33.5 C 143.0 43.0 148.6 56.0 149.3 68.0 C 150.2 86.0 142.0 101.5 124.0 108.5 C 138.0 99.0 143.5 84.0 142.3 66.5 C 141.3 52.5 137.0 41.5 131.0 33.5 Z"),
        .init(21, "blushL", .head, Ink.pinkInner, stroke: nil, path: VectorPath.circle(63.5, 71.0, 5.0)),
        .init(22, "blushR", .head, Ink.pinkInner, stroke: nil, path: VectorPath.circle(136.5, 71.0, 5.0)),
        .init(23, "whiskersL", .head, Ink.clear, stroke: 1.8, "M 57.0 82.0 L 43.0 78.5 M 57.5 90.0 L 43.5 90.0 M 57.0 98.0 L 44.0 102.0"),
        .init(24, "whiskersR", .head, Ink.clear, stroke: 1.8, "M 143.0 82.0 L 157.0 78.5 M 142.5 90.0 L 156.5 90.0 M 143.0 98.0 L 156.0 102.0"),
        .init(25, "eyeWhiteL", .head, Ink.white, stroke: 1.8, "M 68.5 50.0 C 68.5 43.1 72.8 37.5 78.0 37.5 C 83.2 37.5 87.5 43.1 87.5 50.0 C 87.5 56.9 83.2 62.5 78.0 62.5 C 72.8 62.5 68.5 56.9 68.5 50.0 Z"),
        .init(26, "eyeWhiteR", .head, Ink.white, stroke: 1.8, "M 112.5 50.0 C 112.5 43.1 116.8 37.5 122.0 37.5 C 127.2 37.5 131.5 43.1 131.5 50.0 C 131.5 56.9 127.2 62.5 122.0 62.5 C 116.8 62.5 112.5 56.9 112.5 50.0 Z"),
        .init(27, "pupilL", .head, Ink.outlineCocoa, stroke: nil, path: VectorPath.circle(79.5, 52.5, 4.5)),
        .init(28, "pupilR", .head, Ink.outlineCocoa, stroke: nil, path: VectorPath.circle(120.5, 52.5, 4.5)),
        .init(29, "shineL", .head, Ink.white, stroke: nil, path: VectorPath.circle(81.3, 50.6, 1.5)),
        .init(30, "shineR", .head, Ink.white, stroke: nil, path: VectorPath.circle(122.3, 50.6, 1.5)),
        .init(31, "opening_dark", .head, Ink.openingShadow, stroke: 3.0, "M 100.0 63.5 C 114.9 63.5 126.0 72.9 126.0 85.0 C 126.0 97.1 114.9 106.5 100.0 106.5 C 85.1 106.5 74.0 97.1 74.0 85.0 C 74.0 72.9 85.1 63.5 100.0 63.5 Z"),
        .init(32, "face_skin", .face, Ink.skinTone, stroke: nil, "M 100.0 68.0 C 112.5 68.0 122.0 75.5 122.0 86.0 C 122.0 96.5 112.5 104.0 100.0 104.0 C 87.5 104.0 78.0 96.5 78.0 86.0 C 78.0 75.5 87.5 68.0 100.0 68.0 Z"),
        .init(33, "hair_fringe", .face, Ink.hairUmber, stroke: nil, "M 80.0 79.0 C 82.0 70.5 90.0 66.0 100.0 66.0 C 110.0 66.0 118.0 70.5 120.0 79.0 C 116.0 75.5 112.0 77.5 108.5 74.5 C 104.5 78.0 100.5 74.0 96.5 77.5 C 92.0 74.5 88.0 77.5 84.0 75.0 Q 82.0 77.0 80.0 79.0 Z"),
        .init(34, "brows_flat", .face, Ink.clear, stroke: 1.8, "M 86.0 81.5 L 95.5 81.5 M 104.5 81.5 L 114.0 81.5"),
        .init(35, "eyes_flat", .face, Ink.clear, stroke: 1.8, "M 87.0 88.0 L 95.5 88.0 M 104.5 88.0 L 113.0 88.0"),
        .init(36, "eyeDotL", .face, Ink.outlineCocoa, stroke: nil, path: VectorPath.circle(91.0, 90.3, 2.0)),
        .init(37, "eyeDotR", .face, Ink.outlineCocoa, stroke: nil, path: VectorPath.circle(108.8, 90.3, 2.0)),
        .init(38, "mouth_flat", .face, Ink.clear, stroke: 1.8, "M 93.0 98.5 L 107.0 98.5"),
        .init(39, "alt_blink", .face, Ink.clear, stroke: 1.8, "M 87.0 89.5 Q 91.3 91.5 95.5 89.5 M 104.5 89.5 Q 108.8 91.5 113.0 89.5", restOpacity: 0),
        .init(40, "alt_sigh", .face, Ink.clear, stroke: 1.8, "M 93.0 99.5 Q 100.0 96.5 107.0 99.5", restOpacity: 0),
        .init(41, "nose", .head, Ink.pinkInner, stroke: 1.8, "M 93.5 58.5 Q 100.0 55.5 106.5 58.5 Q 104.5 66.0 100.0 66.5 Q 95.5 66.0 93.5 58.5 Z"),
        .init(42, "buck_teeth", .head, Ink.white, stroke: 1.8, "M 94.5 66.0 L 94.5 75.5 Q 94.5 78.0 97.0 78.0 L 99.2 78.0 L 99.2 66.0 Z M 100.8 66.0 L 100.8 78.0 L 103.0 78.0 Q 105.5 78.0 105.5 75.5 L 105.5 66.0 Z"),
        .init(43, "earR_base_seg", .earR_base, Ink.creamBase, stroke: 3.0, "M 116.0 30.0 C 116.5 22.0 121.0 14.5 128.0 13.0 C 133.0 12.0 138.0 14.0 139.5 19.0 C 140.5 23.5 137.0 27.5 131.0 30.0 Q 122.5 33.0 116.0 30.0 Z"),
        .init(44, "earR_tip_seg", .earR_tip, Ink.creamBase, stroke: 3.0, "M 130.0 15.0 C 138.0 10.0 146.0 12.0 150.5 20.0 C 155.5 29.5 158.0 44.0 156.5 56.0 C 155.5 63.5 150.5 66.5 146.5 61.5 C 142.5 56.5 143.5 42.0 140.0 31.0 C 137.5 23.0 133.0 19.0 130.0 15.0 Z"),
        .init(45, "earR_inner", .earR_tip, Ink.pinkInner, stroke: nil, "M 146.0 22.0 C 150.0 28.0 152.5 40.0 151.5 51.0 C 151.0 57.0 148.0 58.5 146.0 54.5 C 144.0 50.5 144.8 39.0 142.5 30.0 Q 141.0 24.0 146.0 22.0 Z"),
        // Mirror of the left arm, about x = 100.
        .init(46, "armR_upper", .armR, Ink.creamBase, stroke: 3.0, "M 120.0 112.0 C 132.0 114.0 141.5 125.0 145.0 144.0 L 131.5 144.5 C 131.5 136.5 129.0 129.5 125.5 125.5 C 123.0 122.0 119.5 119.5 116.5 117.5 Q 116.0 112.5 120.0 112.0 Z"),
        .init(51, "armR_fore", .armR_fore, Ink.creamBase, stroke: 3.0, "M 145.5 140.5 Q 145.0 132.5 138.0 132.5 Q 130.8 132.5 130.5 140.5 C 134.0 148.5 136.0 157.5 133.0 166.5 C 135.0 170.5 141.0 170.5 143.0 166.5 C 146.5 159.0 147.2 149.5 145.5 140.5 Z"),
        .init(47, "armR_paw", .armR_fore, Ink.creamBase, stroke: 3.0, "M 128.0 174.0 C 128.0 167.0 132.0 162.5 138.5 162.0 C 145.0 161.5 150.0 165.5 150.0 172.0 C 150.0 179.0 146.0 184.0 139.5 184.5 C 133.5 185.0 128.0 181.0 128.0 174.0 Z"),
        .init(48, "armR_cuff", .armR_fore, Ink.clear, stroke: 1.8, "M 132.0 165.0 Q 139.0 169.0 146.0 164.5"),
    ]
}
