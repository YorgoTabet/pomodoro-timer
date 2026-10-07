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
            let fold: [Sketch] = [
                .move(65.6, 98),
                .quad(59.6, 172, 54.6, 249.6),
                .quad(59, 251, 63.4, 251.2),
                .quad(66, 172, 68.6, 98),
                .close,
            ]
            return [
                Layer(0, "capeL", .capeL, Ink.cape, stroke: 2.4, path: cape.path()),
                Layer(0, "capeFoldL", .capeL, Ink.capeShade, stroke: nil, path: fold.path()),
                Layer(0, "capeR", .capeR, Ink.cape, stroke: 2.4, path: cape.path(mirrorAbout: cx)),
                Layer(0, "capeFoldR", .capeR, Ink.capeShade, stroke: nil,
                      path: fold.path(mirrorAbout: cx)),
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
                .quad(81.6, 62, 81.8, 92.5),
                .line(84.6, 95.2),
                .line(87.6, 92.6),
                .quad(87.6, 64, 87.0, 48),
                .quad(86.6, 38, 86.0, 33.5),
                .close,
            ]
            let lockRim: [Sketch] = [
                .move(83.3, 44),
                .quad(82.8, 66, 83.0, 89.6),
                .line(83.9, 90.4),
                .quad(83.8, 66, 84.2, 44),
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

    /// Long red skirt with a high slit over the left leg. The main piece and
    /// the front panel are filled without a stroke and outlined separately, so
    /// the seam between them never draws a line across the fabric.
    enum Skirt {
        /// Left edge from the waist to the hem.
        static let waistY = 116.0
        static let hemY = 248.4
        static let slitTop = (92.2, 165.0)
        static let slitBottom = (93.4, 248.6)
        static let panelHinge = (71.6, 150.0)

        static func silhouette() -> [Sketch] {
            symmetric((cx, waistY), [
                (93, waistY, 87.2, waistY),
                (71.2, 123, 71.4, 144),
                (72.6, 172, 81.0, 196),
                (78.4, 222, 75.6, 247.5),
                (88, 249.4, cx, hemY),
            ])
        }

        static func lining() -> [Layer] {
            [Layer(0, "skirtLining", .hips, Ink.lining, stroke: 2.0, path: silhouette().path())]
        }

        static func mainShape() -> [Sketch] {
            [
                .move(cx, waistY),
                .line(87.2, waistY),
                .quad(71.2, 123, 71.4, 144),
                // Main reaches under the panel's top, so the panel can swing
                // without opening a wedge above the slit.
                .quad(71.5, 154, 72.1, 161),
                .quad(83, 166.4, slitTop.0, slitTop.1),
                .line(slitBottom.0, slitBottom.1),
                .quad(96.6, 248.5, cx, hemY),
                .quad(m(88), 249.4, m(75.6), 247.5),
                .quad(m(78.4), 222, m(81.0), 196),
                .quad(m(72.6), 172, m(71.4), 144),
                .quad(m(71.2), 123, m(87.2), waistY),
                .close,
            ]
        }

        static func mainOutline() -> [Sketch] {
            [
                .move(87.2, waistY),
                .quad(71.2, 123, 71.4, 144),
                .quad(71.5, 154, 72.1, 161),
                .move(slitTop.0, slitTop.1),
                .line(slitBottom.0, slitBottom.1),
                .quad(96.6, 248.5, cx, hemY),
                .quad(m(88), 249.4, m(75.6), 247.5),
                .quad(m(78.4), 222, m(81.0), 196),
                .quad(m(72.6), 172, m(71.4), 144),
                .quad(m(71.2), 123, m(87.2), waistY),
            ]
        }

        /// The flap over the left leg, overlapping the main piece a little at
        /// its top so the seam is never open.
        static func panelShape() -> [Sketch] {
            [
                .move(panelHinge.0 - 0.2, panelHinge.1 - 3),
                .quad(80.6, 155.6, slitTop.0 + 0.2, slitTop.1 - 2.4),
                .line(slitBottom.0, slitBottom.1),
                .quad(84, 249.2, 75.6, 247.5),
                .quad(78.4, 222, 81.0, 196),
                .quad(72.4, 170, panelHinge.0, panelHinge.1 - 3),
                .close,
            ]
        }

        static func panelOutline() -> [Sketch] {
            [
                // The last stretch of the top edge, curving into the slit, so
                // the opening reads as a cut with a rounded top when it parts.
                .move(87.8, 159.8),
                .quad(90.0, 161.2, slitTop.0 + 0.2, slitTop.1 - 2.4),
                .line(slitBottom.0, slitBottom.1),
                .quad(84, 249.2, 75.6, 247.5),
                .quad(78.4, 222, 81.0, 196),
                .quad(72.4, 170, panelHinge.0, panelHinge.1 - 1),
            ]
        }

        static func main() -> [Layer] {
            let region = mainShape().path()
            let green = VectorPath.combined([
                swirl(112, 166, radius: 12.5, thickness: 6.0, start: 0.6),
                swirl(111, 226, radius: 11.5, thickness: 5.6, start: 3.2, flip: true),
                swirl(85, 133, radius: 8.0, thickness: 4.2, start: 2.0, flip: true),
            ]).intersection(region)
            let white = VectorPath.combined([
                swirl(100, 196, radius: 5.6, thickness: 2.6, start: 4.0),
                swirl(119, 140, radius: 4.8, thickness: 2.2, start: 2.4),
            ]).intersection(region)
            let shade: [Sketch] = [
                .move(m(75.0), 150),
                .quad(m(75.6), 176, m(83.0), 196),
                .quad(m(80.8), 222, m(78.4), 246.6),
                .line(m(75.6) + 0.4, 247.4),
                .quad(m(78.4), 222, m(81.0), 196),
                .quad(m(72.6), 172, m(71.6), 150),
                .close,
            ]
            return [
                Layer(0, "skirtMain", .hips, Ink.red, stroke: nil, path: region),
                Layer(0, "skirtShade", .hips, Ink.redShade, stroke: nil, path: shade.path()),
                Layer(0, "skirtSwirlGreen", .hips, Ink.green, stroke: 0.7, path: green),
                Layer(0, "skirtSwirlWhite", .hips, Ink.white, stroke: 0.6, path: white),
                Layer(0, "skirtOutline", .hips, Ink.clear, stroke: 2.4, path: mainOutline().path()),
            ]
        }

        static func panel() -> [Layer] {
            let region = panelShape().path()
            let green = swirl(84, 214, radius: 9.6, thickness: 4.8, start: 1.4).intersection(region)
            let white = swirl(83.4, 181, radius: 4.4, thickness: 2.0, start: 0.2, flip: true)
                .intersection(region)
            return [
                Layer(0, "skirtPanel", .skirtPanel, Ink.red, stroke: nil, path: region),
                Layer(0, "skirtPanelSwirlGreen", .skirtPanel, Ink.green, stroke: 0.7, path: green),
                Layer(0, "skirtPanelSwirlWhite", .skirtPanel, Ink.white, stroke: 0.6, path: white),
                Layer(0, "skirtPanelOutline", .skirtPanel, Ink.clear, stroke: 2.4,
                      path: panelOutline().path()),
            ]
        }
    }

    // MARK: - Legs

    enum Legs {
        static func layers() -> [Layer] {
            let x = Mark.legX
            let thigh = capsule(x, Mark.legTop, Mark.knee + 1, 18.4, 10.8, bow: 1.0)
            let shin = capsule(x, Mark.knee, Mark.ankle + 1, 10.8, 5.4, bow: 1.5)
            let thighShade: [Sketch] = [
                .move(x + 5.6, 160), .quad(x + 6.4, 178, x + 4.0, Mark.knee - 2),
                .line(x + 2.4, Mark.knee - 2.6), .quad(x + 4.2, 178, x + 3.4, 160), .close,
            ]
            let foot: [Sketch] = [
                .move(x - 2.8, Mark.ankle - 1),
                .quad(x - 3.6, 245, x - 2.6, 248),
                .line(x + 2.6, 248),
                .quad(x + 3.4, 245, x + 2.8, Mark.ankle - 1),
                .close,
            ]
            let heel: [Sketch] = [
                .move(x - 3.4, 244.4),
                .quad(x - 4.2, 249, x - 1.4, 251.2),
                .quad(x, 252.4, x + 1.4, 251.2),
                .quad(x + 4.2, 249, x + 3.4, 244.4),
                .quad(x, 246.6, x - 3.4, 244.4),
                .close,
            ]
            func side(_ s: String, _ thighPart: Part, _ shinPart: Part, _ mirror: Double?) -> [Layer] {
                [
                    Layer(0, "foot\(s)", shinPart, Ink.skin, stroke: 1.8, path: foot.path(mirrorAbout: mirror)),
                    Layer(0, "heel\(s)", shinPart, Ink.heels, stroke: 1.8, path: heel.path(mirrorAbout: mirror)),
                    Layer(0, "thighLine\(s)", thighPart, Ink.skin, stroke: 2.6, path: thigh.path(mirrorAbout: mirror)),
                    Layer(0, "shinLine\(s)", shinPart, Ink.skin, stroke: 2.6, path: shin.path(mirrorAbout: mirror)),
                    Layer(0, "thigh\(s)", thighPart, Ink.skin, stroke: nil, path: thigh.path(mirrorAbout: mirror)),
                    Layer(0, "shin\(s)", shinPart, Ink.skin, stroke: nil, path: shin.path(mirrorAbout: mirror)),
                    Layer(0, "thighShade\(s)", thighPart, Ink.skinShade, stroke: nil,
                          path: thighShade.path(mirrorAbout: mirror)),
                ]
            }
            return side("L", .legL, .shinL, nil) + side("R", .legR, .shinR, cx)
        }
    }

    // MARK: - Top

    enum Top {
        /// The V neckline's left edge: from the shoulder line to the point.
        static let vTop = (91.0, 65.9)
        static let vCtrl = (92.6, 92.0)
        static let vApex = (cx, 103.0)

        static func torso() -> [Sketch] {
            symmetric((cx, 63.6), [
                (97.4, 63.6, 95.4, 64.2),
                (88, 66.4, 80.6, 69.2),
                (74.6, 71.0, 74.4, 77.5),
                (75.2, 81.6, 81.2, 83.0),
                (78.0, 91.6, 80.8, 100.8),
                (85.0, 107, 87.6, 117),
                (88.0, 122, 87.6, 126),
                (93, 126.4, cx, 126.4),
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

        /// The pink zigzag trim along the V, on the fabric side.
        static func trim() -> Path {
            let steps = 14
            var inner: [(Double, Double)] = [], outer: [(Double, Double)] = []
            for i in 0...steps {
                let t = Double(i) / Double(steps)
                let p = point(onQuad: vTop, vCtrl, vApex, t)
                let q = point(onQuad: vTop, vCtrl, vApex, min(t + 0.01, 1))
                let r = point(onQuad: vTop, vCtrl, vApex, max(t - 0.01, 0))
                var dx = q.0 - r.0, dy = q.1 - r.1
                let len = max((dx * dx + dy * dy).squareRoot(), 0.0001)
                dx /= len; dy /= len
                // Outward normal (away from the midline).
                let nx = -dy, ny = dx
                let sign: Double = nx < 0 ? 1 : -1
                let width = (i % 2 == 0 ? 2.9 : 1.7) * (1 - 0.3 * t)
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

        static func chest() -> [Layer] {
            let sideShade: [Sketch] = [
                .move(82.2, 84), .quad(79.4, 92, 82.0, 100.8),
                .quad(85.8, 107, 88.2, 116.6), .line(90.4, 116.6),
                .quad(88.0, 107, 85.0, 101), .quad(83.4, 92, 85, 84), .close,
            ]
            return [
                Layer(0, "torso", .chest, Ink.red, stroke: 2.4, path: torso().path()),
                Layer(0, "torsoShade", .chest, Ink.redShade, stroke: nil, path: sideShade.path()),
            ]
        }

        /// The V: skin, zigzag trim and the cleavage line. Drawn on the chest
        /// over the bust part, so the neckline never moves when the bust does
        /// and nothing at the V can tear.
        static func neckline() -> [Layer] {
            // A simple cleavage line: two short curves bowing apart, meeting
            // just above the V's point.
            let cleavage: [Sketch] = [
                .move(97.6, 93.6), .quad(97.9, 98.8, 100.0, 101.6),
            ]
            return [
                Layer(0, "chestSkin", .chest, Ink.skin, stroke: nil, path: skinV().path()),
                Layer(0, "chestTrim", .chest, Ink.pink, stroke: 0.8, path: trim()),
                Layer(0, "chestCleavage", .chest, Ink.clear, stroke: 0.8, path: both(cleavage)),
            ]
        }

        /// The bust volume, as one rig part: a sheen on each side, the hard
        /// shadow beneath and the underbust lines. It sits on plain red between
        /// the torso and the neckline, has no edges of its own, and its inner
        /// ends tuck under the trim, so lifting or scaling it moves the volume
        /// without any seam opening.
        static func bust() -> [Layer] {
            let sheen: [Sketch] = [
                .move(88.0, 92.4), .quad(88.8, 88.8, 91.8, 87.4),
                .line(92.2, 88.6), .quad(90.0, 89.8, 89.2, 92.8), .close,
            ]
            let shade: [Sketch] = [
                .move(82.2, 99.2),
                .quad(84.4, 106.4, 90.6, 106.4),
                .quad(94.8, 106.2, 96.8, 104.6),
                .line(98.6, 106.8),
                .quad(96, 109.2, 90.4, 109.2),
                .quad(84.2, 109, 82.2, 99.2),
                .close,
            ]
            let underbust: [Sketch] = [
                .move(82.0, 97.4),
                .quad(84.2, 106.0, 90.6, 106.2),
                .quad(94.6, 106.0, 96.6, 104.4),
            ]
            return [
                Layer(0, "bustSheen", .bust, Ink.redSheen, stroke: nil, path: both(sheen)),
                Layer(0, "bustShade", .bust, Ink.redShade, stroke: nil, path: both(shade)),
                Layer(0, "bustLines", .bust, Ink.clear, stroke: 1.1, path: both(underbust)),
            ]
        }

        /// Pink cloth sash with a round gold buckle.
        static func sash() -> [Layer] {
            let band = symmetric((cx, 111.6), [
                (92, 111.8, 86.0, 112.8),
                (88.0, 118.6, 85.6, 124.6),
                (92, 126.0, cx, 125.8),
            ])
            let folds: [Sketch] = [
                .move(88.0, 116.4), .quad(91.4, 117.6, 94.6, 117.2),
                .move(87.8, 121.2), .quad(91.4, 122.6, 94.8, 121.8),
            ]
            let shade: [Sketch] = [
                .move(86.0, 121.8), .quad(92, 124.4, cx, 124.2),
                .line(cx, 125.8), .quad(92, 126.0, 85.6, 124.6), .close,
            ]
            var buckle = circle(cx, 118.8, 4.6).path()
            buckle.addPath(circle(cx, 118.8, 2.6, clockwise: false).path())
            return [
                Layer(0, "sash", .hips, Ink.pink, stroke: 2.0, path: band.path()),
                Layer(0, "sashShade", .hips, Ink.pinkShade, stroke: nil, path: both(shade)),
                Layer(0, "sashFolds", .hips, Ink.clear, stroke: 0.7, path: both(folds)),
                Layer(0, "buckle", .hips, Ink.gold, stroke: 1.2, path: buckle),
                Layer(0, "buckleCore", .hips, Ink.goldShade, stroke: nil,
                      path: circle(cx, 118.8, 2.6).path()),
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
