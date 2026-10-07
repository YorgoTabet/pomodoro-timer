import CoreGraphics
import SwiftUI

/// Boa Hancock's shapes.
///
/// Paired parts are authored once on the left (screen left) and mirrored about
/// the midline. Every limb segment has a round top centred on its pivot, plus a
/// fill-only cap over the joint, so a bend never opens a gap or a notch.
///
/// Layer names that `HancockPose.opacity(of:)` reads:
/// `face.<set>.<piece>`, `hand.<kind>.<L|R>.<piece>`, `heart.<piece>`.
enum HancockParts {

    static let cx: Double = 100

    typealias Layer = HancockArt.Layer
    typealias Part = HancockArt.Part
    typealias Ink = HancockArt.Ink

    /// Body landmarks in canvas units. 6.3 heads crown to sole.
    enum Mark {
        static let crown = 24.0
        static let chin = 61.4
        static let headHalf = 13.6
        static let eyeY = 44.6
        static let mouthY = 54.8
        static let shoulderX = 79.0
        static let shoulderY = 73.0
        static let elbow = 114.0
        static let wrist = 147.0
        static let waist = 118.0
        static let legX = 89.0
        static let legTop = 150.0
        static let knee = 196.0
        static let ankle = 240.0
        static let sole = 251.0
    }

    // MARK: - Helpers

    static func m(_ x: Double) -> Double { 2 * cx - x }

    static func both(_ segments: [Sketch]) -> Path {
        var path = segments.path()
        path.addPath(segments.path(mirrorAbout: cx))
        return path
    }

    /// A closed shape symmetric about the midline, from its left half.
    ///
    /// `start` and the last segment's end must both lie on the midline. Each
    /// segment is a quadratic (control x, y, end x, y).
    static func symmetric(_ start: (Double, Double),
                          _ segments: [(Double, Double, Double, Double)]) -> [Sketch] {
        var sketch: [Sketch] = [.move(start.0, start.1)]
        for s in segments { sketch.append(.quad(s.0, s.1, s.2, s.3)) }
        // Walk back up the right side: each quad reversed and mirrored.
        var ends: [(Double, Double)] = [start]
        for s in segments { ends.append((s.2, s.3)) }
        for index in stride(from: segments.count - 1, through: 0, by: -1) {
            let s = segments[index]
            let back = ends[index]
            sketch.append(.quad(m(s.0), s.1, m(back.0), back.1))
        }
        sketch.append(.close)
        return sketch
    }

    /// A limb segment whose top is a true semicircle centred on (`x`, `top`).
    static func capsule(_ x: Double, _ top: Double, _ bottom: Double,
                        _ topWidth: Double, _ bottomWidth: Double,
                        bow: Double = 0) -> [Sketch] {
        let a = topWidth / 2, b = bottomWidth / 2
        let k = 0.552
        let mid = (top + bottom) / 2
        return [
            .move(x - a, top),
            .quad(x - (a + b) / 2 - bow, mid, x - b, bottom),
            .quad(x, bottom + b * 0.9, x + b, bottom),
            .quad(x + (a + b) / 2 + bow, mid, x + a, top),
            .curve(x + a, top - a * k, x + a * k, top - a, x, top - a),
            .curve(x - a * k, top - a, x - a, top - a * k, x - a, top),
            .close,
        ]
    }

    static func circle(_ x: Double, _ y: Double, _ r: Double, clockwise: Bool = true) -> [Sketch] {
        let k = 0.552 * r
        if clockwise {
            return [
                .move(x + r, y),
                .curve(x + r, y + k, x + k, y + r, x, y + r),
                .curve(x - k, y + r, x - r, y + k, x - r, y),
                .curve(x - r, y - k, x - k, y - r, x, y - r),
                .curve(x + k, y - r, x + r, y - k, x + r, y),
                .close,
            ]
        }
        return [
            .move(x + r, y),
            .curve(x + r, y - k, x + k, y - r, x, y - r),
            .curve(x - k, y - r, x - r, y - k, x - r, y),
            .curve(x - r, y + k, x - k, y + r, x, y + r),
            .curve(x + k, y + r, x + r, y + k, x + r, y),
            .close,
        ]
    }

    static func point(onQuad a: (Double, Double), _ c: (Double, Double), _ b: (Double, Double),
                      _ t: Double) -> (Double, Double) {
        let u = 1 - t
        return (u * u * a.0 + 2 * u * t * c.0 + t * t * b.0,
                u * u * a.1 + 2 * u * t * c.1 + t * t * b.1)
    }

    /// A thick spiral band, the skirt's swirl motif.
    static func swirl(_ x: Double, _ y: Double, radius: Double, thickness: Double,
                      turns: Double = 1.45, start: Double = 0, flip: Bool = false) -> Path {
        let steps = 48
        var outer: [CGPoint] = [], inner: [CGPoint] = []
        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let angle = (flip ? -1.0 : 1.0) * (start + t * turns * 2 * .pi)
            let r = radius * (0.12 + 0.88 * t)
            let w = thickness * (0.3 + 0.7 * t) / 2
            outer.append(CGPoint(x: x + (r + w) * cos(angle), y: y + (r + w) * sin(angle)))
            inner.append(CGPoint(x: x + max(r - w, 0) * cos(angle), y: y + max(r - w, 0) * sin(angle)))
        }
        var path = Path()
        path.addLines(outer)
        for p in inner.reversed() { path.addLine(to: p) }
        path.closeSubpath()
        return path
    }

    // MARK: - Cape

    enum Cape {
        static func layers() -> [Layer] {
            let cape: [Sketch] = [
                .move(92, 65.4),
                .quad(81, 65.6, 73.6, 68.6),
                .quad(66.4, 72, 64.4, 86),
                .quad(57, 160, 47, 249),
                .quad(72, 253.5, 99, 250.6),
                .line(99, 72),
                .close,
            ]
            // The white outside turns back along the outer edge; the rest of
            // what faces us is the blue inner side.
            let outside: [Sketch] = [
                .move(73.6, 68.6),
                .quad(66.4, 72, 64.4, 86),
                .quad(57, 160, 47, 249),
                .quad(51.6, 250.4, 56.4, 251.2),
                .quad(64.6, 170, 69.8, 92),
                .quad(71.2, 77, 76.4, 70.4),
                .close,
            ]
            let fold: [Sketch] = [
                .move(74.8, 100),
                .quad(70.4, 172, 68.4, 251.4),
                .quad(72.4, 252.4, 76.6, 252.4),
                .quad(76.4, 172, 77.6, 100),
                .close,
            ]
            return [
                Layer(0, "capeL", .capeL, Ink.capeInner, stroke: 2.4, path: cape.path()),
                Layer(0, "capeFoldL", .capeL, Ink.capeInnerShade, stroke: nil, path: fold.path()),
                Layer(0, "capeOutsideL", .capeL, Ink.cape, stroke: 1.0, path: outside.path()),
                Layer(0, "capeR", .capeR, Ink.capeInner, stroke: 2.4, path: cape.path(mirrorAbout: cx)),
                Layer(0, "capeFoldR", .capeR, Ink.capeInnerShade, stroke: nil,
                      path: fold.path(mirrorAbout: cx)),
                Layer(0, "capeOutsideR", .capeR, Ink.cape, stroke: 1.0,
                      path: outside.path(mirrorAbout: cx)),
            ]
        }
    }

    // MARK: - Hair

    enum Hair {

        /// One link of the back hair: a straight sheet from `top` to `bottom`,
        /// widening from `topHalf` to `bottomHalf`, with a rounded top.
        static func sheet(_ top: Double, _ bottom: Double, _ topHalf: Double,
                          _ bottomHalf: Double, ends: Bool) -> [Sketch] {
            let mid = (top + bottom) / 2
            var s: [Sketch] = [
                .move(cx - topHalf, top),
                .quad(cx - (topHalf + bottomHalf) / 2 - 0.4, mid, cx - bottomHalf, bottom),
            ]
            if ends {
                // Blunt cut with a few shallow points.
                let w = bottomHalf
                s += [
                    .line(cx - w * 0.62, bottom + 2.6),
                    .line(cx - w * 0.3, bottom + 0.8),
                    .line(cx, bottom + 3.0),
                    .line(cx + w * 0.3, bottom + 0.8),
                    .line(cx + w * 0.62, bottom + 2.6),
                    .line(cx + w, bottom),
                ]
            } else {
                s.append(.quad(cx, bottom + 3, cx + bottomHalf, bottom))
            }
            s += [
                .quad(cx + (topHalf + bottomHalf) / 2 + 0.4, mid, cx + topHalf, top),
                .quad(cx, top - 4, cx - topHalf, top),
                .close,
            ]
            return s
        }

        /// A light strip inside each outer edge, so the black reads on a dark bar.
        static func rim(_ top: Double, _ bottom: Double, _ topHalf: Double,
                        _ bottomHalf: Double) -> Path {
            let mid = (top + bottom) / 2
            let inset = 1.3, width = 1.5
            return both([
                .move(cx - topHalf + inset, top + 2),
                .quad(cx - (topHalf + bottomHalf) / 2 + inset - 0.4, mid,
                      cx - bottomHalf + inset, bottom - 1),
                .line(cx - bottomHalf + inset + width, bottom - 1.6),
                .quad(cx - (topHalf + bottomHalf) / 2 + inset + width - 0.4, mid,
                      cx - topHalf + inset + width, top + 2),
                .close,
            ])
        }

        static func back() -> [Layer] {
            let base: [Sketch] = [
                .move(cx, 16.6),
                .quad(81.6, 17.2, 80.8, 38),
                .quad(81.4, 72, 82.6, 106),
                .quad(cx, 109, m(82.6), 106),
                .quad(m(81.4), 72, m(80.8), 38),
                .quad(m(81.6), 17.2, cx, 16.6),
                .close,
            ]
            return [
                Layer(0, "hairBase", .hairBase, Ink.hair, stroke: 2.4, path: base.path()),
                Layer(0, "hairBaseRim", .hairBase, Ink.hairRim, stroke: nil,
                      path: rim(40, 104, 19.0, 17.4)),
                Layer(0, "hairMid", .hairMid, Ink.hair, stroke: 2.4,
                      path: sheet(98, 156, 17.4, 17.8, ends: false).path()),
                Layer(0, "hairMidRim", .hairMid, Ink.hairRim, stroke: nil,
                      path: rim(100, 155, 17.4, 17.8)),
                Layer(0, "hairTip", .hairTip, Ink.hair, stroke: 2.4,
                      path: sheet(150, 190, 17.8, 18.4, ends: true).path()),
                Layer(0, "hairTipRim", .hairTip, Ink.hairRim, stroke: nil,
                      path: rim(152, 189, 17.8, 18.4)),
            ]
        }

        /// Crown and blunt hime bangs, one shape covering the forehead and the
        /// temples down past the ears.
        static func front() -> [Layer] {
            let bangY = 38.8
            let crown: [Sketch] = [
                .move(cx, 18.6),
                .quad(83.4, 18.8, 82.8, 36),
                .line(83.2, 53),
                .line(86.4, 53),
                .line(86.2, bangY - 0.4),
                .quad(93, bangY + 0.5, cx, bangY + 0.4),
                .quad(m(93), bangY + 0.5, m(86.2), bangY - 0.4),
                .line(m(86.4), 53),
                .line(m(83.2), 53),
                .line(m(82.8), 36),
                .quad(m(83.4), 18.8, cx, 18.6),
                .close,
            ]
            let strands: [Sketch] = [
                .move(93.2, 31.5), .line(92.6, bangY + 0.3),
                .move(100.6, 30.5), .line(100.4, bangY + 0.4),
                .move(m(93.2) + 0.6, 32), .line(m(92.6) + 0.4, bangY + 0.3),
            ]
            // The gloss ring across the crown, broken in two.
            // Gloss: a few short glints along the crown's curve, not a band.
            let shine: [Sketch] = [
                .move(88.6, 28.6), .quad(90.2, 25.6, 92.8, 24.2),
                .line(93.4, 25.4), .quad(91.2, 26.8, 90.0, 29.4), .close,
                .move(96.2, 23.0), .line(99.6, 22.6), .line(99.6, 23.9), .line(96.6, 24.3), .close,
                .move(103.0, 22.8), .quad(106.6, 23.2, 108.8, 24.8),
                .line(108.0, 25.8), .quad(105.8, 24.6, 103.0, 24.2), .close,
            ]
            return [
                Layer(0, "hairCrown", .head, Ink.hair, stroke: 2.4, path: crown.path()),
                // A thin cool rim just inside the crown's outline, so the head
                // keeps its shape against a dark bar.
                Layer(0, "hairCrownRim", .head, Ink.hairRim, stroke: nil, path: both([
                    .move(84.3, 35), .quad(84.6, 20.8, cx, 20.3),
                    .line(cx, 21.4), .quad(85.7, 21.8, 85.4, 35), .close,
                ])),
                Layer(0, "hairShine", .head, Ink.hairShine, stroke: nil, path: shine.path()),
                Layer(0, "bangStrands", .head, Ink.clear, stroke: 0.8, path: strands.path()),
            ]
        }

        static func sideLocks() -> [Layer] {
            let lock: [Sketch] = [
                .move(82.4, 33.5),
                .quad(81.4, 60, 81.2, 85.0),
                .line(83.8, 88.0),
                .line(86.8, 85.2),
                .quad(87.4, 62, 87.0, 48),
                .quad(86.6, 38, 86.0, 33.5),
                .close,
            ]
            let lockRim: [Sketch] = [
                .move(83.3, 44),
                .quad(82.6, 64, 82.4, 83.0),
                .line(83.3, 83.8),
                .quad(83.6, 64, 84.2, 44),
                .close,
            ]
            return [
                Layer(0, "sideLockL", .sideLockL, Ink.hair, stroke: 2.0, path: lock.path()),
                Layer(0, "sideLockRimL", .sideLockL, Ink.hairRim, stroke: nil, path: lockRim.path()),
                Layer(0, "sideLockR", .sideLockR, Ink.hair, stroke: 2.0,
                      path: lock.path(mirrorAbout: cx)),
                Layer(0, "sideLockRimR", .sideLockR, Ink.hairRim, stroke: nil,
                      path: lockRim.path(mirrorAbout: cx)),
            ]
        }

        /// Gold snake hoops: a ring with a small head at the top.
        static func earrings() -> [Layer] {
            let x = 85.2, y = 57.2
            var ring = circle(x, y, 3.0).path()
            ring.addPath(circle(x, y, 1.8, clockwise: false).path())
            let head: [Sketch] = [
                .move(x - 0.6, y - 2.6), .quad(x + 1.6, y - 4.8, x + 2.4, y - 2.4),
                .quad(x + 1.2, y - 1.8, x - 0.6, y - 2.6), .close,
            ]
            var hoop = ring
            hoop.addPath(head.path())
            var mirrored = Path()
            mirrored.addPath(hoop, transform: CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: 2 * cx, ty: 0))
            return [
                Layer(0, "earringL", .earringL, Ink.gold, stroke: 0.9, path: hoop),
                Layer(0, "earringR", .earringR, Ink.gold, stroke: 0.9, path: mirrored),
            ]
        }
    }

    // MARK: - Skirt

    /// Long red skirt hung from the low sash, slit to the hip over the left leg.
    ///
    /// At rest the left leg is bare from the hip: the main piece ends at the
    /// slit along the inner thigh, and the loose front panel hangs outside the
    /// leg. Blue lining shows in the gaps beside the leg and at the hem. Fills
    /// carry no stroke; the visible edges are separate open outlines, so seams
    /// under the sash never draw.
    enum Skirt {
        static let topY = 140.0
        /// The slit's apex at the hip, tucked under the sash.
        static let apex = (85.0, 143.0)

        static func lining() -> [Layer] {
            let lining: [Sketch] = [
                .move(cx, topY),
                .line(75.4, topY + 1.4),
                .quad(67.8, 146, 67.8, 158),
                .quad(68.6, 200, 65.4, 246.4),
                .quad(84, 251.6, cx, 250.2),
                .quad(m(88), 250.4, m(72.6), 248.4),
                .quad(m(78.6), 228, m(77.4), 206),
                .quad(m(70.0), 184, m(68.6), 158),
                .quad(m(68.0), 146, m(75.4), topY + 1.4),
                .close,
            ]
            // A darker fold down the back, so the gap beside the leg has depth.
            let fold: [Sketch] = [
                .move(79.4, 156), .quad(79.6, 204, 80.6, 250.0),
                .line(85.4, 250.6), .quad(84.6, 204, 83.6, 156), .close,
            ]
            return [
                Layer(0, "skirtLining", .hips, Ink.lining, stroke: 2.0, path: lining.path()),
                Layer(0, "skirtLiningFold", .hips, Ink.liningShade, stroke: nil, path: fold.path()),
            ]
        }

        static func mainShape() -> [Sketch] {
            [
                .move(apex.0 - 2, topY),
                .line(cx, topY),
                .quad(m(86), topY, m(75.4), topY + 1.4),
                .quad(m(68.0), 146, m(68.6), 158),
                .quad(m(70.0), 184, m(77.4), 206),
                .quad(m(78.6), 228, m(72.6), 248.0),
                .quad(112, 249.8, 99.6, 249.0),
                // The slit edge, up the inner side of the bare leg to the hip.
                .quad(100.2, 205, 98.8, 172),
                .quad(96.6, 153, apex.0, apex.1),
                .line(apex.0 - 2, topY),
                .close,
            ]
        }

        static func mainOutline() -> [Sketch] {
            [
                .move(apex.0 + 0.4, apex.1 + 0.6),
                .quad(96.6, 153, 98.8, 172),
                .quad(100.2, 205, 99.6, 249.0),
                .quad(112, 249.8, m(72.6), 248.0),
                .quad(m(78.6), 228, m(77.4), 206),
                .quad(m(70.0), 184, m(68.6), 158),
                .quad(m(68.0), 146, m(75.4), topY + 1.4),
            ]
        }

        /// The loose front flap outside the left leg, hinged at the outer hip.
        /// Its top tucks under the sash, and the inner edge runs from the slit's
        /// apex diagonally out, covering where the thigh meets the hip.
        static func panelShape() -> [Sketch] {
            [
                .move(74.0, topY + 0.6),
                .line(apex.0 + 1.0, topY + 0.6),
                .line(apex.0 + 0.6, apex.1),
                .quad(81.0, 151, 77.8, 163),
                .quad(74.6, 206, 75.6, 247.8),
                .quad(70.6, 249.0, 65.4, 246.2),
                .quad(68.8, 200, 68.0, 158),
                .quad(67.8, 146, 74.0, topY + 0.6),
                .close,
            ]
        }

        static func panelOutline() -> [Sketch] {
            [
                .move(apex.0 + 0.6, apex.1),
                .quad(81.0, 151, 77.8, 163),
                .quad(74.6, 206, 75.6, 247.8),
                .quad(70.6, 249.0, 65.4, 246.2),
                .quad(68.8, 200, 68.0, 158),
                .quad(67.8, 148, 71.4, 143.0),
            ]
        }

        /// A small five-petal flower, the white motif between the swirls.
        static func flower(_ x: Double, _ y: Double, _ r: Double) -> Path {
            var path = Path()
            for i in 0..<5 {
                let a = Double(i) * 2 * .pi / 5 - .pi / 2
                path.addPath(Path.oval(x + cos(a) * r * 0.62, y + sin(a) * r * 0.62, r * 0.46, r * 0.46))
            }
            return path
        }

        static func main() -> [Layer] {
            let region = mainShape().path()
            let green = VectorPath.combined([
                swirl(116, 166, radius: 10.5, thickness: 5.0, start: 0.6),
                swirl(110, 222, radius: 10.0, thickness: 4.8, start: 3.2, flip: true),
                swirl(104, 151, radius: 6.0, thickness: 3.4, start: 2.0, flip: true),
            ]).intersection(region)
            let white = VectorPath.combined([
                flower(107, 192, 3.4),
                flower(121, 238, 2.8),
                flower(121, 146, 2.6),
            ]).intersection(region)
            let shade: [Sketch] = [
                .move(m(75.0), 150),
                .quad(m(75.6), 176, m(83.0), 204),
                .quad(m(82.4), 226, m(76.8), 247.4),
                .line(m(72.6) + 0.4, 247.8),
                .quad(m(79.0), 226, m(78.0), 204),
                .quad(m(71.4), 180, m(70.4), 150),
                .close,
            ]
            return [
                Layer(0, "skirtMain", .hips, Ink.red, stroke: nil, path: region),
                Layer(0, "skirtShade", .hips, Ink.redShade, stroke: nil, path: shade.path()),
                Layer(0, "skirtSwirlGreen", .hips, Ink.green, stroke: 0.7, path: green),
                Layer(0, "skirtFlowerWhite", .hips, Ink.white, stroke: 0.6, path: white),
                Layer(0, "skirtOutline", .hips, Ink.clear, stroke: 2.4, path: mainOutline().path()),
            ]
        }

        static func panel() -> [Layer] {
            let region = panelShape().path()
            let green = swirl(73.2, 206, radius: 6.4, thickness: 3.6, start: 1.4).intersection(region)
            let white = flower(73.4, 176, 2.6).intersection(region)
            return [
                Layer(0, "skirtPanel", .skirtPanel, Ink.red, stroke: nil, path: region),
                Layer(0, "skirtPanelSwirlGreen", .skirtPanel, Ink.green, stroke: 0.7, path: green),
                Layer(0, "skirtPanelFlowerWhite", .skirtPanel, Ink.white, stroke: 0.6, path: white),
                Layer(0, "skirtPanelOutline", .skirtPanel, Ink.clear, stroke: 2.4,
                      path: panelOutline().path()),
            ]
        }
    }

    // MARK: - Legs

    /// Long adult legs: a full outer thigh tapering to a slim knee, a calf that
    /// swells on the outside, a fine ankle, and red pumps with a pointed toe
    /// that carry the line on past the ankle.
    enum Legs {
        static func thigh() -> [Sketch] {
            let x = Mark.legX, top = Mark.legTop
            let r = 9.6
            let k = 0.552 * r
            return [
                .move(x - r, top - 2),
                .quad(x - 11.8, top + 12, x - 9.0, top + 28),
                .quad(x - 6.4, top + 40, x - 4.6, Mark.knee + 1),
                .quad(x, Mark.knee + 4.4, x + 4.6, Mark.knee + 1),
                .quad(x + 6.8, top + 32, x + 9.0, top + 18),
                .quad(x + r + 0.2, top + 8, x + r, top - 2),
                .curve(x + r, top - 2 - k, x + k, top - 2 - r, x, top - 2 - r),
                .curve(x - k, top - 2 - r, x - r, top - 2 - k, x - r, top - 2),
                .close,
            ]
        }

        static func shin() -> [Sketch] {
            let x = Mark.legX, top = Mark.knee
            let r = 4.8
            let k = 0.552 * r
            return [
                .move(x - r, top),
                .quad(x - 7.6, top + 9, x - 5.2, top + 20),
                .quad(x - 2.6, top + 33, x - 2.0, Mark.ankle),
                .quad(x, Mark.ankle + 1.6, x + 2.1, Mark.ankle),
                .quad(x + 3.0, top + 31, x + 4.6, top + 18),
                .quad(x + 5.8, top + 8, x + r, top),
                .curve(x + r, top - k, x + k, top - r, x, top - r),
                .curve(x - k, top - r, x - r, top - k, x - r, top),
                .close,
            ]
        }

        static func layers() -> [Layer] {
            let x = Mark.legX
            let thigh = thigh(), shin = shin()
            let thighShade: [Sketch] = [
                .move(x + 5.4, 158), .quad(x + 6.6, 176, x + 3.6, Mark.knee - 1),
                .line(x + 2.0, Mark.knee - 1.6), .quad(x + 4.6, 176, x + 3.6, 158), .close,
            ]
            let calfShade: [Sketch] = [
                .move(x + 3.0, Mark.knee + 6), .quad(x + 4.4, Mark.knee + 18, x + 1.6, Mark.ankle - 3),
                .line(x + 0.8, Mark.ankle - 3), .quad(x + 2.8, Mark.knee + 18, x + 1.8, Mark.knee + 6),
                .close,
            ]
            let knee: [Sketch] = [.move(x - 1.6, Mark.knee + 0.4), .quad(x, Mark.knee + 1.8, x + 1.6, Mark.knee + 0.4)]
            let foot: [Sketch] = [
                .move(x - 2.1, Mark.ankle - 1),
                .quad(x - 3.4, 244, x - 2.8, 247),
                .line(x + 2.8, 247),
                .quad(x + 3.4, 244, x + 2.1, Mark.ankle - 1),
                .close,
            ]
            // A pump seen from the front: a curved vamp, pointed toe, and a
            // sliver of stiletto at the back.
            let shoe: [Sketch] = [
                .move(x - 3.2, 244.2),
                .quad(x - 3.8, 249.4, x, 253.4),
                .quad(x + 3.8, 249.4, x + 3.2, 244.2),
                .quad(x, 246.6, x - 3.2, 244.2),
                .close,
            ]
            let heel: [Sketch] = [
                .move(x + 2.4, 246), .line(x + 3.6, 246.4), .line(x + 3.0, 252.2),
                .line(x + 2.4, 252.2), .close,
            ]
            func side(_ s: String, _ thighPart: Part, _ shinPart: Part, _ mirror: Double?) -> [Layer] {
                [
                    Layer(0, "heelSpike\(s)", shinPart, Ink.heelShade, stroke: 1.0, path: heel.path(mirrorAbout: mirror)),
                    Layer(0, "foot\(s)", shinPart, Ink.skin, stroke: 1.6, path: foot.path(mirrorAbout: mirror)),
                    Layer(0, "heel\(s)", shinPart, Ink.heels, stroke: 1.6, path: shoe.path(mirrorAbout: mirror)),
                    Layer(0, "thighLine\(s)", thighPart, Ink.skin, stroke: 2.4, path: thigh.path(mirrorAbout: mirror)),
                    Layer(0, "shinLine\(s)", shinPart, Ink.skin, stroke: 2.4, path: shin.path(mirrorAbout: mirror)),
                    Layer(0, "thigh\(s)", thighPart, Ink.skin, stroke: nil, path: thigh.path(mirrorAbout: mirror)),
                    Layer(0, "shin\(s)", shinPart, Ink.skin, stroke: nil, path: shin.path(mirrorAbout: mirror)),
                    Layer(0, "thighShade\(s)", thighPart, Ink.skinShade, stroke: nil,
                          path: thighShade.path(mirrorAbout: mirror)),
                    Layer(0, "calfShade\(s)", shinPart, Ink.skinShade, stroke: nil,
                          path: calfShade.path(mirrorAbout: mirror)),
                    Layer(0, "knee\(s)", shinPart, Ink.clear, stroke: 0.6, path: knee.path(mirrorAbout: mirror)),
                ]
            }
            return side("L", .legL, .shinL, nil) + side("R", .legR, .shinR, cx)
        }
    }

    // MARK: - Top

    /// The cropped red jacket-top, the bare midriff, the waist belt and the low
    /// hip sash.
    enum Top {
        /// The V neckline's left edge, from the collar to its point just above
        /// the belt. It bows out over the bust, so the inner curves show while
        /// the fabric keeps the outer bust covered.
        static let vTop = (92.6, 66.0)
        static let vCtrl = (83.2, 98.0)
        static let vApex = (cx, 106.8)

        /// One breast's volume (left), as an ellipse. The pair meet at the
        /// midline to make the cleavage.
        static let bustCentre = (86.6, 92.2)
        static let bustRadius = (14.0, 13.0)

        static func torso() -> [Sketch] {
            symmetric((cx, 63.6), [
                (97.4, 63.6, 95.4, 64.2),
                (88, 66.4, 80.6, 69.2),
                (74.6, 71.0, 74.4, 77.5),
                (75.0, 82.4, 78.4, 85.4),
                (80.8, 96, 83.8, 104.4),
                (84.4, 107.4, 84.6, 111.2),
                (93, 111.8, cx, 111.8),
            ])
        }

        static func skinV() -> [Sketch] {
            [
                .move(vTop.0, vTop.1),
                .quad(vCtrl.0, vCtrl.1, vApex.0, vApex.1),
                .quad(m(vCtrl.0), vCtrl.1, m(vTop.0), vTop.1),
                .line(m(95.6), 64.3),
                .line(m(95.6), 61.6),
                .line(95.6, 61.6),
                .line(95.6, 64.3),
                .close,
            ]
        }

        /// The V opening grown outward by `by`, so a moving shape can be kept
        /// clear of it.
        static func vGrown(_ by: Double) -> Path {
            let v = skinV().path()
            return v.union(v.strokedPath(StrokeStyle(lineWidth: by * 2, lineJoin: .round)))
        }

        static func vShrunk(_ by: Double) -> Path {
            let v = skinV().path()
            return v.subtracting(v.strokedPath(StrokeStyle(lineWidth: by * 2, lineJoin: .round)))
        }

        /// A thin strip along both V edges, between two points of the curve,
        /// on the skin side (`inward`) or the fabric side, tapering at both ends.
        static func band(from t0: Double, to t1: Double, width: Double, inward: Bool) -> Path {
            let steps = 20
            var edge: [(Double, Double)] = [], off: [(Double, Double)] = []
            for i in 0...steps {
                let t = t0 + (t1 - t0) * Double(i) / Double(steps)
                let p = point(onQuad: vTop, vCtrl, vApex, t)
                let q = point(onQuad: vTop, vCtrl, vApex, min(t + 0.01, 1))
                let r = point(onQuad: vTop, vCtrl, vApex, max(t - 0.01, 0))
                var dx = q.0 - r.0, dy = q.1 - r.1
                let len = max((dx * dx + dy * dy).squareRoot(), 0.0001)
                dx /= len; dy /= len
                let nx = -dy, ny = dx
                let away: Double = nx < 0 ? 1 : -1
                let sign = inward ? -away : away
                let taper = sin(Double(i) / Double(steps) * .pi)
                edge.append(p)
                off.append((p.0 + sign * nx * width * taper, p.1 + sign * ny * width * taper))
            }
            var sketch: [Sketch] = [.move(edge[0].0, edge[0].1)]
            for p in edge.dropFirst() { sketch.append(.line(p.0, p.1)) }
            for p in off.reversed() { sketch.append(.line(p.0, p.1)) }
            sketch.append(.close)
            return both(sketch)
        }

        /// The pink frill along the V, on the fabric side.
        static func trim() -> Path {
            let steps = 16
            var inner: [(Double, Double)] = [], outer: [(Double, Double)] = []
            for i in 0...steps {
                let t = Double(i) / Double(steps)
                let p = point(onQuad: vTop, vCtrl, vApex, t)
                let q = point(onQuad: vTop, vCtrl, vApex, min(t + 0.01, 1))
                let r = point(onQuad: vTop, vCtrl, vApex, max(t - 0.01, 0))
                var dx = q.0 - r.0, dy = q.1 - r.1
                let len = max((dx * dx + dy * dy).squareRoot(), 0.0001)
                dx /= len; dy /= len
                let nx = -dy, ny = dx
                let sign: Double = nx < 0 ? 1 : -1
                let width = (i % 2 == 0 ? 2.7 : 1.6) * (1 - 0.35 * t)
                inner.append(p)
                outer.append((p.0 + sign * nx * width, p.1 + sign * ny * width))
            }
            var sketch: [Sketch] = [.move(inner[0].0, inner[0].1)]
            for p in inner.dropFirst() { sketch.append(.line(p.0, p.1)) }
            for p in outer.reversed() { sketch.append(.line(p.0, p.1)) }
            sketch.append(.close)
            return both(sketch)
        }

        static func neck() -> [Layer] {
            let neck: [Sketch] = [
                .move(95.5, 52), .quad(95.8, 60, 95.2, 68),
                .line(104.8, 68), .quad(104.2, 60, 104.5, 52), .close,
            ]
            let shadow: [Sketch] = [
                .move(95.8, 58.4), .quad(cx, 62.6, 104.2, 58.4),
                .line(104.2, 61.0), .quad(cx, 64.0, 95.8, 61.0), .close,
            ]
            return [
                Layer(0, "neck", .chest, Ink.skin, stroke: 2.0, path: neck.path()),
                Layer(0, "neckShade", .chest, Ink.skinShade, stroke: nil, path: shadow.path()),
            ]
        }

        /// Upper midriff, on the chest. It overlaps the lower midriff on the
        /// hips past the waist, so a contrapposto tilt never opens a gap.
        static func upperMidriff() -> [Layer] {
            let skin = symmetric((cx, 103), [
                (92, 103, 84.0, 104.2),
                (85.6, 111, 86.5, 116),
                (86.7, 119.4, 86.3, 122),
                (93, 122.4, cx, 122.4),
            ])
            let side: [Sketch] = [.move(84.2, 108), .quad(85.6, 112, 86.5, 116), .quad(86.7, 117.6, 86.6, 119)]
            return [
                Layer(0, "midriffUpper", .chest, Ink.skin, stroke: nil, path: skin.path()),
                Layer(0, "midriffUpperSide", .chest, Ink.clear, stroke: 2.2, path: both(side)),
            ]
        }

        /// Lower midriff with the navel, on the hips, down under the sash.
        static func lowerMidriff() -> [Layer] {
            let skin = symmetric((cx, 112), [
                (92, 112, 86.8, 112.4),
                (86.7, 117, 86.2, 121),
                (85.0, 131, 78.8, 138),
                (74.8, 142, 74.2, 147),
                (88, 148.4, cx, 148.4),
            ])
            let side: [Sketch] = [
                .move(86.7, 116), .quad(86.5, 118.6, 86.2, 121),
                .quad(85.0, 131, 78.8, 138), .quad(74.8, 142, 74.2, 147),
            ]
            let shade: [Sketch] = [
                .move(87.6, 119), .quad(86.8, 129, 81.4, 137.4),
                .line(83.4, 137.6), .quad(88.4, 129, 89.4, 119), .close,
            ]
            let navel: [Sketch] = [.move(cx - 0.2, 126.6), .quad(cx + 0.9, 128.4, cx, 130.2)]
            let navelShade: [Sketch] = [
                .move(cx - 0.6, 126.8), .quad(cx + 1.4, 128.4, cx - 0.4, 130.0),
                .quad(cx - 1.2, 128.4, cx - 0.6, 126.8), .close,
            ]
            return [
                Layer(0, "midriffLower", .hips, Ink.skin, stroke: nil, path: skin.path()),
                Layer(0, "midriffShade", .hips, Ink.skinShade, stroke: nil, path: both(shade)),
                Layer(0, "midriffSide", .hips, Ink.clear, stroke: 2.2, path: both(side)),
                Layer(0, "navelShade", .hips, Ink.skinShade, stroke: nil, path: navelShade.path()),
                Layer(0, "navel", .hips, Ink.clear, stroke: 0.8, path: navel.path()),
            ]
        }

        static func chest() -> [Layer] {
            let sideShade: [Sketch] = [
                .move(78.6, 86), .quad(81, 96, 83.8, 104.4),
                .line(86.2, 104.4), .quad(83.4, 96, 81.4, 86), .close,
            ]
            let lapel: [Sketch] = [
                .move(vTop.0, vTop.1), .line(87.0, 67.6), .line(89.8, 73.6),
                .quad(91.0, 69.4, vTop.0, vTop.1), .close,
            ]
            return [
                Layer(0, "torso", .chest, Ink.red, stroke: 2.4, path: torso().path()),
                Layer(0, "torsoShade", .chest, Ink.redShade, stroke: nil, path: both(sideShade)),
                Layer(0, "lapelGold", .chest, Ink.gold, stroke: 0.9, path: both(lapel)),
            ]
        }

        /// The top's hem band at the natural waist, with the round gold buckle
        /// right under the V's point.
        static func belt() -> [Layer] {
            let band = symmetric((cx, 107.0), [
                (92, 107.0, 84.2, 107.4),
                (84.6, 109.4, 84.7, 111.6),
                (93, 112.2, cx, 112.2),
            ])
            var buckle = circle(cx, 109.6, 3.4).path()
            buckle.addPath(circle(cx, 109.6, 1.8, clockwise: false).path())
            return [
                Layer(0, "belt", .chest, Ink.redShade, stroke: 1.6, path: band.path()),
                Layer(0, "buckle", .chest, Ink.gold, stroke: 1.1, path: buckle),
                Layer(0, "buckleCore", .chest, Ink.goldShade, stroke: nil,
                      path: circle(cx, 109.6, 1.8).path()),
            ]
        }

        /// The open V, with a thin shadow just inside the fabric edge so the
        /// skin reads as rounded under it.
        static func neckline() -> [Layer] {
            let edgeShade = band(from: 0.12, to: 0.9, width: 1.5, inward: true)
            return [
                Layer(0, "chestSkin", .chest, Ink.skin, stroke: nil, path: skinV().path()),
                Layer(0, "chestSkinShade", .chest, Ink.skinShade, stroke: nil, path: edgeShade),
            ]
        }

        static func ellipse(_ c: (Double, Double), _ r: (Double, Double)) -> Path {
            Path.oval(c.0, c.1, r.0, r.1)
        }

        /// A point on the left bust ellipse; 0 degrees faces the midline, 90 is
        /// the bottom, 180 the outer side.
        static func onBust(_ degrees: Double, grow: Double = 0) -> (Double, Double) {
            let a = degrees * .pi / 180
            return (bustCentre.0 + (bustRadius.0 + grow) * cos(a),
                    bustCentre.1 + (bustRadius.1 + grow) * sin(a))
        }

        static func bustArc(from start: Double, to end: Double, grow: Double = 0) -> [Sketch] {
            let steps = max(Int(abs(end - start) / 6), 2)
            var sketch: [Sketch] = []
            for i in 0...steps {
                let p = onBust(start + (end - start) * Double(i) / Double(steps), grow: grow)
                sketch.append(i == 0 ? .move(p.0, p.1) : .line(p.0, p.1))
            }
            return sketch
        }

        /// The bust, as one rig part. The fabric over each breast is kept 3.6
        /// units clear of the V, so a lift or squash slides red over red and
        /// never over skin. Only lines cross the V (the under-curves, which
        /// tuck under the frill), so nothing at the neckline can tear.
        static func bust() -> [Layer] {
            let left = ellipse(bustCentre, bustRadius)
            var pair = left
            pair.addPath(left, transform: CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: 2 * cx, ty: 0))
            let keepOut = vGrown(3.6)
            let cups = pair.subtracting(keepOut)

            let sheen: [Sketch] = [
                .move(77.8, 88.6), .quad(79.6, 82.0, 85.6, 80.8),
                .line(86.0, 82.6), .quad(81.4, 83.6, 79.8, 89.0), .close,
            ]
            let shadeBand: [Sketch] = [
                .move(76.0, 99.0), .quad(79.6, 106.8, 87.4, 107.0),
                .quad(93.0, 106.8, 96.4, 103.4), .line(96.0, 101.2),
                .quad(92.6, 105.0, 87.4, 105.0), .quad(80.6, 104.8, 76.0, 99.0), .close,
            ]
            let underShade = both(shadeBand).subtracting(keepOut)

            // Inside the V: a soft shadow on the skin under each breast, where
            // the two meet low on the sternum.
            let underCurve: [Sketch] = [
                .move(onBust(80).0, onBust(80).1),
                .quad(98.6, 104.2, 99.6, 95.0),
                .quad(100.2, 89.6, 99.2, 85.0),
            ]
            let creaseShape: [Sketch] = [
                .move(onBust(80).0, onBust(80).1),
                .quad(98.6, 104.2, 99.6, 95.0),
                .line(cx, 97.0),
                .quad(99.8, 106.8, onBust(80).0, onBust(80).1 + 1.8),
                .close,
            ]
            let crease = both(creaseShape).intersection(vShrunk(0.6))
            let glint: [Sketch] = [
                .move(95.0, 86.4), .quad(96.0, 88.8, 95.6, 92.0),
                .quad(94.8, 89.2, 95.0, 86.4), .close,
            ]

            // The silhouette (bold) round the outer side, and the under-curve
            // (fine) from the bottom of the cup up into the cleavage.
            let outerLine = bustArc(from: 214, to: 120)
            let innerLine = bustArc(from: 120, to: 80) + underCurve.dropFirst()
            return [
                Layer(0, "bustCups", .bust, Ink.red, stroke: nil, path: cups),
                Layer(0, "bustSheen", .bust, Ink.redSheen, stroke: nil, path: both(sheen)),
                Layer(0, "bustShade", .bust, Ink.redShade, stroke: nil, path: underShade),
                Layer(0, "bustCrease", .bust, Ink.skinShade, stroke: nil, path: crease),
                Layer(0, "bustGlint", .bust, Ink.skinLight, stroke: nil, path: both(glint)),
                Layer(0, "bustOuter", .bust, Ink.clear, stroke: 2.2, path: both(outerLine)),
                Layer(0, "bustLines", .bust, Ink.clear, stroke: 1.0, path: both(innerLine)),
            ]
        }

        /// The frill along the V, drawn over the bust so the under-curves tuck
        /// under it.
        static func frill() -> [Layer] {
            [Layer(0, "chestTrim", .chest, Ink.pink, stroke: 0.8, path: trim())]
        }

        /// The pink sash, worn low on the hips and dipping at the front, with a
        /// knot on her left hip.
        static func sash() -> [Layer] {
            let band = symmetric((cx, 137.4), [
                (90, 137.2, 79.4, 133.2),
                (75.0, 138, 71.2, 145.6),
                (86, 149.6, cx, 149.6),
            ])
            let folds: [Sketch] = [
                .move(80.4, 138.0), .quad(90, 141.6, cx, 141.8),
                .move(78.6, 141.8), .quad(90, 145.6, cx, 145.8),
            ]
            let shade: [Sketch] = [
                .move(74.8, 143.4), .quad(86, 147.4, cx, 147.4),
                .line(cx, 149.6), .quad(86, 149.6, 71.2, 145.6), .close,
            ]
            return [
                Layer(0, "sash", .hips, Ink.pink, stroke: 2.0, path: band.path()),
                Layer(0, "sashShade", .hips, Ink.pinkShade, stroke: nil, path: both(shade)),
                Layer(0, "sashFolds", .hips, Ink.clear, stroke: 0.6, path: both(folds)),
            ]
        }

        static let knot = (75.6, 142.8)

        /// The long loose end hanging down the front from the knot.
        static func sashTail() -> [Layer] {
            let tail: [Sketch] = [
                .move(knot.0 - 2.0, knot.1),
                .quad(69.8, 160, 70.6, 178),
                .quad(71.6, 192, 69.8, 204.6),
                .line(76.2, 200.8),
                .quad(76.8, 190, 75.4, 177),
                .quad(74.4, 160, knot.0 + 2.0, knot.1),
                .close,
            ]
            let fold: [Sketch] = [.move(knot.0, 152), .quad(72.0, 166, 73.0, 180), .quad(73.6, 192, 72.8, 201.6)]
            return [
                Layer(0, "sashTail", .sashTail, Ink.pink, stroke: 1.8, path: tail.path()),
                Layer(0, "sashTailFold", .sashTail, Ink.clear, stroke: 0.6, path: fold.path()),
            ]
        }

        static func sashKnot() -> [Layer] {
            let loop: [Sketch] = [
                .move(knot.0 - 1.2, knot.1 - 1.6),
                .quad(68.4, 134.0, 67.8, 139.0),
                .quad(68.4, 144.0, knot.0 - 1.6, knot.1 + 0.6),
                .close,
            ]
            return [
                Layer(0, "sashLoop", .hips, Ink.pink, stroke: 1.6, path: loop.path()),
                Layer(0, "sashKnot", .hips, Ink.pinkShade, stroke: 1.6,
                      path: Path.oval(knot.0, knot.1, 3.2, 2.8)),
            ]
        }

        /// Gold epaulettes over the shoulder joints, with a short fringe.
        static func epaulettes() -> [Layer] {
            let dome: [Sketch] = [
                .move(70.8, 73.2),
                .quad(70.6, 65.8, 78.8, 65.0),
                .quad(86.6, 65.0, 87.0, 70.4),
                .quad(79, 75.0, 70.8, 73.2),
                .close,
            ]
            var fringe: [Sketch] = []
            for i in 0..<4 {
                let x = 71.8 + Double(i) * 2.3
                let y = 73.4 + Double(i) * 0.25
                fringe += [
                    .move(x - 0.7, y), .line(x - 0.6, y + 4.4),
                    .quad(x, y + 5.4, x + 0.6, y + 4.4), .line(x + 0.7, y), .close,
                ]
            }
            return [
                Layer(0, "epauletteFringe", .chest, Ink.gold, stroke: 0.6, path: both(fringe)),
                Layer(0, "epaulette", .chest, Ink.gold, stroke: 1.4, path: both(dome)),
            ]
        }
    }

    // MARK: - Arms

    enum Arms {
        static let x = Mark.shoulderX
        static let w = Mark.wrist

        /// Relaxed open hand hanging along the forearm, thumb toward the body.
        static func open() -> [Sketch] {
            [
                .move(x - 2.6, w - 0.5),
                .quad(x - 3.4, w + 5.0, x - 2.0, w + 9.6),
                .quad(x - 0.4, w + 12.2, x + 1.4, w + 10.2),
                .quad(x + 2.6, w + 7.6, x + 2.4, w + 5.4),
                .quad(x + 4.2, w + 4.2, x + 3.4, w + 1.8),
                .quad(x + 3.0, w + 0.2, x + 2.6, w - 0.5),
                .close,
            ]
        }

        /// Back of the hand with the fingers folded: what shows when she sets a
        /// hand on her hip.
        static func hip() -> [Sketch] {
            [
                .move(x - 3.0, w - 0.5),
                .quad(x - 4.4, w + 4.0, x - 3.0, w + 7.6),
                .quad(x + 0.2, w + 9.6, x + 3.6, w + 7.2),
                .quad(x + 4.6, w + 3.4, x + 3.0, w - 0.5),
                .close,
            ]
        }

        static func hipKnuckles() -> [Sketch] {
            [.move(x - 2.4, w + 5.6), .quad(x + 0.2, w + 7.0, x + 2.8, w + 5.2)]
        }

        /// A loose fist with the index finger out along the forearm.
        static func point() -> [Sketch] {
            [
                .move(x - 2.8, w - 0.5),
                .quad(x - 4.0, w + 3.6, x - 2.2, w + 6.8),
                .line(x - 1.6, w + 14.4),
                .quad(x - 0.4, w + 15.6, x + 0.6, w + 14.2),
                .line(x + 0.8, w + 7.6),
                .quad(x + 3.8, w + 6.6, x + 3.8, w + 3.2),
                .quad(x + 3.4, w + 0.2, x + 2.8, w - 0.5),
                .close,
            ]
        }

        /// The "ohoho" hand: bent back at the wrist, fingers curled, the back of
        /// the hand turned out. Fingertips sit toward the body side.
        static func mouth() -> [Sketch] {
            [
                .move(x - 2.8, w - 0.5),
                .quad(x - 4.0, w + 4.6, x - 2.0, w + 8.4),
                .quad(x + 1.4, w + 10.8, x + 4.4, w + 8.8),
                .quad(x + 6.0, w + 7.0, x + 4.4, w + 5.4),
                .quad(x + 2.8, w + 2.4, x + 2.6, w - 0.5),
                .close,
            ]
        }

        static func mouthCurl() -> [Sketch] {
            [.move(x + 1.0, w + 6.6), .quad(x + 2.6, w + 6.0, x + 3.4, w + 7.6)]
        }

        /// Pink feather cuff: a flared band with a three-feather hem.
        static func cuff() -> [Sketch] {
            let top = w - 8.0, bottom = w + 1.6
            return [
                .move(x - 3.3, top),
                .quad(x - 4.0, top + 4, x - 5.0, bottom),
                .quad(x - 3.8, bottom + 2.0, x - 2.4, bottom + 0.4),
                .quad(x - 1.2, bottom + 2.6, x + 0.2, bottom + 0.5),
                .quad(x + 1.6, bottom + 2.6, x + 2.8, bottom + 0.4),
                .quad(x + 4.4, bottom + 1.8, x + 5.0, bottom),
                .quad(x + 4.0, top + 4, x + 3.3, top),
                .close,
            ]
        }

        static func cuffVeins() -> [Sketch] {
            let top = w - 8.0, bottom = w + 1.6
            return [
                .move(x - 2.6, top + 1.4), .quad(x - 3.4, top + 5, x - 3.6, bottom),
                .move(x, top + 1.0), .line(x + 0.1, bottom + 0.6),
                .move(x + 2.6, top + 1.4), .quad(x + 3.4, top + 5, x + 3.4, bottom),
            ]
        }

        static func layers() -> [Layer] {
            let upper = capsule(x, Mark.shoulderY, Mark.elbow + 1, 9.6, 7.6, bow: 0.4)
            let fore = capsule(x, Mark.elbow, w - 4, 7.6, 6.4)
            // One shade strip per segment, each on its own joint, so a bent
            // elbow never drags the upper arm's shadow along with the forearm.
            let upperShade: [Sketch] = [
                .move(x + 2.0, Mark.shoulderY + 6), .quad(x + 3.4, 96, x + 2.4, Mark.elbow - 1),
                .line(x + 3.6, Mark.elbow - 1), .quad(x + 4.6, 96, x + 4.0, Mark.shoulderY + 4),
                .close,
            ]
            let foreShade: [Sketch] = [
                .move(x + 1.6, Mark.elbow + 3), .line(x + 1.4, w - 6),
                .line(x + 3.0, w - 6), .line(x + 3.4, Mark.elbow + 3), .close,
            ]
            func side(_ s: String, _ upperPart: Part, _ forePart: Part, _ hand: Part,
                      _ mirror: Double?) -> [Layer] {
                [
                    Layer(0, "sleeveLine\(s)", upperPart, Ink.red, stroke: 2.8, path: upper.path(mirrorAbout: mirror)),
                    Layer(0, "foreSleeveLine\(s)", forePart, Ink.red, stroke: 2.8, path: fore.path(mirrorAbout: mirror)),
                    Layer(0, "sleeve\(s)", upperPart, Ink.red, stroke: nil, path: upper.path(mirrorAbout: mirror)),
                    Layer(0, "foreSleeve\(s)", forePart, Ink.red, stroke: nil, path: fore.path(mirrorAbout: mirror)),
                    Layer(0, "sleeveShade\(s)", upperPart, Ink.redShade, stroke: nil,
                          path: upperShade.path(mirrorAbout: mirror)),
                    Layer(0, "foreSleeveShade\(s)", forePart, Ink.redShade, stroke: nil,
                          path: foreShade.path(mirrorAbout: mirror)),
                    Layer(0, "hand.open.\(s).palm", hand, Ink.skin, stroke: 1.5,
                          path: open().path(mirrorAbout: mirror)),
                    Layer(0, "hand.hip.\(s).palm", hand, Ink.skin, stroke: 1.5,
                          path: hip().path(mirrorAbout: mirror), restOpacity: 0),
                    Layer(0, "hand.hip.\(s).knuckles", hand, Ink.clear, stroke: 0.8,
                          path: hipKnuckles().path(mirrorAbout: mirror), restOpacity: 0),
                    Layer(0, "hand.point.\(s).palm", hand, Ink.skin, stroke: 1.5,
                          path: point().path(mirrorAbout: mirror), restOpacity: 0),
                    Layer(0, "hand.mouth.\(s).palm", hand, Ink.skin, stroke: 1.5,
                          path: mouth().path(mirrorAbout: mirror), restOpacity: 0),
                    Layer(0, "hand.mouth.\(s).curl", hand, Ink.clear, stroke: 0.8,
                          path: mouthCurl().path(mirrorAbout: mirror), restOpacity: 0),
                    Layer(0, "cuff\(s)", forePart, Ink.pink, stroke: 1.3, path: cuff().path(mirrorAbout: mirror)),
                    Layer(0, "cuffVeins\(s)", forePart, Ink.clear, stroke: 0.6,
                          path: cuffVeins().path(mirrorAbout: mirror)),
                ]
            }
            return side("L", .armL, .armL_fore, .handL, nil)
                + side("R", .armR, .armR_fore, .handR, cx)
        }
    }

    // MARK: - Face

    enum Face {
        static func skull() -> Path {
            let hw = Mark.headHalf, top = Mark.crown, fh = Mark.chin - Mark.crown
            let cheek = top + fh * 0.48
            let temple = top + fh * 0.02
            let jawCtrl = top + fh * 0.72
            let jawX = cx - hw * 0.74, jawY = top + fh * 0.84
            let chinX = cx - hw * 0.42, chinY = top + fh * 0.99
            return [
                .move(cx - hw, cheek),
                .quad(cx - hw, temple, cx, top),
                .quad(cx + hw, temple, cx + hw, cheek),
                .quad(cx + hw, jawCtrl, m(jawX), jawY),
                .quad(m(chinX), chinY, cx, Mark.chin),
                .quad(chinX, chinY, jawX, jawY),
                .quad(cx - hw, jawCtrl, cx - hw, cheek),
                .close,
            ].path()
        }

        static func head() -> [Layer] {
            let nose: [Sketch] = [.move(cx + 0.4, 48.6), .quad(cx + 1.3, 50.0, cx + 0.2, 50.4)]
            return [
                Layer(0, "headBase", .head, Ink.skin, stroke: 2.4, path: skull()),
                Layer(0, "nose", .head, Ink.clear, stroke: 0.9, path: nose.path()),
            ]
        }

        // Left eye geometry (screen left). Inner corner toward the midline.
        static let inner = (97.6, 45.0)
        static let outer = (88.4, 43.2)
        static let lowerCtrl = (93.2, 48.4)

        /// The visible eye white for a given top-lid control height.
        static func white(lid: Double) -> [Sketch] {
            [
                .move(inner.0, inner.1),
                .quad(93.6, lid, outer.0, outer.1),
                .quad(lowerCtrl.0, lowerCtrl.1, inner.0, inner.1),
                .close,
            ]
        }

        /// The heavy upper lash along the lid, ending in a wing past the outer
        /// corner. This line carries most of her look at 70pt.
        static func lash(lid: Double) -> [Sketch] {
            [
                .move(inner.0 + 0.3, inner.1 + 0.3),
                .quad(93.6, lid - 0.1, outer.0, outer.1),
                .line(85.4, outer.1 - 2.4),
                .line(87.4, outer.1 - 1.6),
                .line(86.6, outer.1 - 3.6),
                .line(88.8, outer.1 - 1.9),
                .quad(93.4, lid - 3.0, inner.0 - 0.2, inner.1 - 1.0),
                .close,
            ]
        }

        static func lowerLash() -> [Sketch] {
            // The outer half of the lower lid, on the eye's own curve.
            [.move(89.8, 44.6), .quad(92.0, 46.3, 94.0, 46.3)]
        }

        /// Iris clipped to the eye white.
        static func iris(lid: Double, dx: Double = 0, dy: Double = 0, scale: Double = 1) -> Path {
            Path.oval(93.0 + dx, 45.6 + dy, 2.3 * scale, 2.8 * scale)
                .intersection(white(lid: lid).path())
        }

        static func irisLight(lid: Double, dx: Double = 0, dy: Double = 0, scale: Double = 1) -> Path {
            Path.oval(93.0 + dx, 46.9 + dy, 1.5 * scale, 1.2 * scale)
                .intersection(white(lid: lid).path())
        }

        static func catchlight(dx: Double = 0, dy: Double = 0) -> Path {
            Path.oval(94.1 + dx, 44.9 + dy, 0.8, 0.8)
        }

        /// One open eye set, both sides.
        static func openEyes(_ set: String, lid: Double, dx: Double = 0, dy: Double = 0,
                             scale: Double = 1, catchlights: Bool = true,
                             only left: Bool? = nil) -> [Layer] {
            func mirrored(_ path: Path) -> Path {
                guard let left else {
                    var p = path
                    p.addPath(path, transform: CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: 2 * cx, ty: 0))
                    return p
                }
                if left { return path }
                var p = Path()
                p.addPath(path, transform: CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: 2 * cx, ty: 0))
                return p
            }
            var layers = [
                Layer(0, "face.\(set).white", .head, Ink.white, stroke: nil, path: mirrored(white(lid: lid).path())),
                Layer(0, "face.\(set).iris", .head, Ink.iris, stroke: nil,
                      path: mirrored(iris(lid: lid, dx: dx, dy: dy, scale: scale))),
            ]
            // A low lid can hide the lower iris entirely; skip the empty shape.
            let light = irisLight(lid: lid, dx: dx, dy: dy, scale: scale)
            if !light.boundingRect.isNull, !light.boundingRect.isInfinite {
                layers.append(Layer(0, "face.\(set).irisLight", .head, Ink.irisLight, stroke: nil,
                                    path: mirrored(light)))
            }
            if catchlights {
                layers.append(Layer(0, "face.\(set).catchlight", .head, Ink.white, stroke: nil,
                                    path: mirrored(catchlight(dx: dx, dy: dy))))
            }
            layers += [
                Layer(0, "face.\(set).lash", .head, Ink.lash, stroke: 0.5, path: mirrored(lash(lid: lid).path())),
                Layer(0, "face.\(set).lowerLash", .head, Ink.clear, stroke: 0.7, path: mirrored(lowerLash().path())),
            ]
            return layers
        }

        /// A closed eye: a lash line with a wing, curved down (`smile` false)
        /// or up into a laughing arc.
        static func closedEye(smile: Bool) -> [Sketch] {
            let c = smile ? 41.6 : 47.0
            return [
                .move(inner.0, 45.0),
                .quad(93.4, c, outer.0, 44.4),
                .line(86.8, 42.8),
                .line(88.4, 44.6),
                .quad(93.4, c + (smile ? 1.6 : 1.4), inner.0 - 0.2, 45.6),
                .close,
            ]
        }

        static func brows(arch: Double, innerY: Double, outerY: Double) -> [Sketch] {
            [.move(97.6, innerY), .quad(93.6, arch, 88.0, outerY)]
        }

        static func sets() -> [Layer] {
            let y = Mark.mouthY
            // Lips: a short dark line for the closed mouth over a red lower lip.
            func closedLips(_ set: String, lift: Double) -> [Layer] {
                let line: [Sketch] = [
                    .move(cx - 2.8, y - 0.1 + lift * 0.3),
                    .quad(cx, y + 0.5, cx + 2.8, y - 0.1 - lift),
                ]
                let lip: [Sketch] = [
                    .move(cx - 2.6, y + 0.2), .quad(cx, y + 3.2, cx + 2.6, y + 0.2 - lift * 0.4),
                    .quad(cx, y + 0.9, cx - 2.6, y + 0.2), .close,
                ]
                let upper: [Sketch] = [
                    .move(cx - 3.0, y), .quad(cx - 1.4, y - 1.5, cx, y - 0.6),
                    .quad(cx + 1.4, y - 1.5, cx + 3.0, y - lift * 0.8),
                    .quad(cx, y + 0.6, cx - 3.0, y), .close,
                ]
                return [
                    Layer(0, "face.\(set).lip", .head, Ink.lips, stroke: nil, path: lip.path()),
                    Layer(0, "face.\(set).upperLip", .head, Ink.lips, stroke: nil, path: upper.path()),
                    Layer(0, "face.\(set).mouth", .head, Ink.clear, stroke: 0.8, path: line.path()),
                ]
            }
            func openMouth(_ set: String, width: Double, depth: Double) -> [Layer] {
                let outer: [Sketch] = [
                    .move(cx - width, y - 0.6),
                    .quad(cx, y - 1.8, cx + width, y - 0.6),
                    .quad(cx + width * 0.9, y + depth, cx, y + depth + 0.4),
                    .quad(cx - width * 0.9, y + depth, cx - width, y - 0.6),
                    .close,
                ]
                let inner: [Sketch] = [
                    .move(cx - width + 1.0, y - 0.1),
                    .quad(cx, y - 0.8, cx + width - 1.0, y - 0.1),
                    .quad(cx + width * 0.7, y + depth - 1.0, cx, y + depth - 0.8),
                    .quad(cx - width * 0.7, y + depth - 1.0, cx - width + 1.0, y - 0.1),
                    .close,
                ]
                return [
                    Layer(0, "face.\(set).lips", .head, Ink.lips, stroke: 0.8, path: outer.path()),
                    Layer(0, "face.\(set).inside", .head, Ink.mouthDeep, stroke: nil, path: inner.path()),
                ]
            }
            func brow(_ set: String, arch: Double, innerY: Double, outerY: Double) -> Layer {
                Layer(0, "face.\(set).brows", .head, Ink.clear, stroke: 1.0,
                      path: both(brows(arch: arch, innerY: innerY, outerY: outerY)))
            }

            // Haughty, the default: half-lidded, brows high and calm, closed lips.
            var layers = openEyes("haughty", lid: 43.2, dy: 0.3)
            layers.append(brow("haughty", arch: 38.0, innerY: 40.0, outerY: 39.6))
            layers += closedLips("haughty", lift: 0.3)

            // Smug: lids lower, eyes looking down her nose, one corner up.
            layers += openEyes("smug", lid: 44.8, dy: 1.2, catchlights: false)
            layers.append(brow("smug", arch: 37.4, innerY: 39.8, outerY: 39.2))
            layers += closedLips("smug", lift: 1.4)

            // Flustered: eyes wide and sparkling, worried brows, pink cheeks.
            layers += openEyes("flustered", lid: 40.4, dy: 0.0, scale: 1.12)
            let sparkle: [Sketch] = [
                .move(92.0, 45.2), .line(92.6, 46.4), .line(93.8, 46.9), .line(92.6, 47.4),
                .line(92.0, 48.6), .line(91.4, 47.4), .line(90.2, 46.9), .line(91.4, 46.4), .close,
            ]
            layers.append(Layer(0, "face.flustered.sparkle", .head, Ink.white, stroke: nil,
                                path: both(sparkle)))
            layers.append(brow("flustered", arch: 38.2, innerY: 38.6, outerY: 40.2))
            let blush: [Sketch] = [
                .move(87.6, 49.6), .quad(91, 47.6, 94.4, 49.6), .quad(91, 51.6, 87.6, 49.6), .close,
            ]
            let hatch: [Sketch] = [
                .move(89.0, 50.6), .line(89.8, 48.8),
                .move(90.8, 50.8), .line(91.6, 49.0),
                .move(92.6, 50.6), .line(93.4, 48.8),
            ]
            layers.append(Layer(0, "face.flustered.blush", .head, Ink.blush, stroke: nil, path: both(blush)))
            layers.append(Layer(0, "face.flustered.hatch", .head, Ink.clear, stroke: 0.5, path: both(hatch)))
            layers += openMouth("flustered", width: 1.8, depth: 2.2)

            // Wink: the left eye shut with its wing, the right eye haughty.
            layers.append(Layer(0, "face.wink.closed", .head, Ink.lash, stroke: 0.5,
                                path: closedEye(smile: false).path()))
            layers += openEyes("wink", lid: 43.2, dy: 0.3, only: false)
            layers.append(Layer(0, "face.wink.brows", .head, Ink.clear, stroke: 1.0,
                                path: VectorPath.combined([
                                    brows(arch: 38.8, innerY: 40.6, outerY: 40.6).path(),
                                    brows(arch: 37.6, innerY: 39.8, outerY: 39.2).path(mirrorAbout: cx),
                                ])))
            layers += closedLips("wink", lift: 1.2)

            // Laugh: eyes shut in arcs, brows up, mouth open for "ohoho".
            layers.append(Layer(0, "face.laugh.closed", .head, Ink.lash, stroke: 0.5,
                                path: both(closedEye(smile: true))))
            layers.append(brow("laugh", arch: 37.0, innerY: 39.2, outerY: 39.0))
            layers += openMouth("laugh", width: 2.8, depth: 3.6)

            return layers.map { layer in
                let hidden = !layer.name.hasPrefix("face.haughty")
                return Layer(0, layer.name, layer.part, layer.fill, stroke: layer.stroke,
                             path: layer.path, restOpacity: hidden ? 0 : 1)
            }
        }
    }

    // MARK: - Props

    enum Props {
        static func heart() -> [Layer] {
            let x = 130.0, y = 16.0, s = 6.0
            let heart: [Sketch] = [
                .move(x, y + s * 0.95),
                .curve(x - s * 0.4, y + s * 0.6, x - s * 1.15, y + s * 0.1, x - s * 1.0, y - s * 0.4),
                .curve(x - s * 0.85, y - s * 1.05, x - s * 0.1, y - s * 1.0, x, y - s * 0.45),
                .curve(x + s * 0.1, y - s * 1.0, x + s * 0.85, y - s * 1.05, x + s * 1.0, y - s * 0.4),
                .curve(x + s * 1.15, y + s * 0.1, x + s * 0.4, y + s * 0.6, x, y + s * 0.95),
                .close,
            ]
            return [
                Layer(0, "heart.body", .heart, Ink.heart, stroke: 1.4, path: heart.path(), restOpacity: 0),
                Layer(0, "heart.shine", .heart, Ink.white, stroke: nil,
                      path: Path.oval(x - s * 0.5, y - s * 0.4, 1.3, 0.9), restOpacity: 0),
            ]
        }
    }
}
