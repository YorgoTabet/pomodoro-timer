import CoreGraphics
import SwiftUI

/// The anime girl's body, composed from parts instead of transcribed.
///
/// Each part is a pure function of `AnimeGirlProportions` returning its own
/// layers — its shapes, fills, strokes and rig assignment — so composition is
/// concatenation and a part is genuinely swappable: replacing `Hair.tails` with
/// a bob touches nothing else.
///
/// Everything paired is authored **once on the left and mirrored** about the
/// canvas midline. The old hand-written pairs had already drifted (her two hands
/// sat 0.4 units apart in x for no reason); mirroring makes that impossible.
///
/// Layer ids are assigned by `AnimeGirlArt` after concatenation, so a part never
/// has to know where it lands in the draw order.
enum AnimeGirlParts {

    /// Canvas midline — the mirror axis and the figure's centre.
    static let cx: Double = 100

    typealias P = AnimeGirlProportions
    typealias Layer = AnimeGirlArt.Layer
    typealias Ink = AnimeGirlArt.Ink

    /// One shape drawn on both sides of the midline.
    static func both(_ segments: [Sketch]) -> Path {
        var path = segments.path()
        path.addPath(segments.path(mirrorAbout: cx))
        return path
    }

    // MARK: - Head

    enum Head {
        /// Skull and jaw.
        ///
        /// `chinTaper` drives the whole lower face: 1 gives the sharp wedge, 0 a
        /// rounded jaw with no chin. `skullRound` lifts the temple control points
        /// toward the crown, which is the difference between a dome and a cap.
        static func skull(_ p: P) -> Path {
            let hw = p.headWidth / 2, fh = p.faceHeight
            let cheek = p.crown + fh * 0.467
            let temple = p.crown + fh * (0.16 - 0.14 * p.skullRound)
            let jawCtrl = p.crown + fh * 0.693
            let jawX = cx - hw * (1 - 0.25 * p.chinTaper)
            let jawY = p.crown + fh * 0.84
            let chinX = cx - hw * (1 - 0.535 * p.chinTaper)
            let chinY = p.crown + fh * 0.973
            return [
                .move(cx - hw, cheek),
                .quad(cx - hw, temple, cx, p.crown),
                .quad(cx + hw, temple, cx + hw, cheek),
                .quad(cx + hw, jawCtrl, 2 * cx - jawX, jawY),
                .quad(2 * cx - chinX, chinY, cx, p.chin),
                .quad(chinX, chinY, jawX, jawY),
                .quad(cx - hw, jawCtrl, cx - hw, cheek),
                .close,
            ].path()
        }

        static func layers(_ p: P) -> [Layer] {
            let fh = p.faceHeight
            let blushY = p.crown + fh * 0.733
            let mouthY = p.crown + fh * 0.869
            let hw = p.headWidth / 2

            return [
                Layer(0, "headBase", .head, Ink.skin, stroke: 3.0, path: skull(p)),
                Layer(0, "blush", .head, Ink.blush, stroke: nil, path: both([
                    .move(cx - hw * 0.857, blushY),
                    .quad(cx - hw * 0.657, blushY - 1.4, cx - hw * 0.457, blushY),
                    .quad(cx - hw * 0.657, blushY + 1.3, cx - hw * 0.857, blushY),
                    .close,
                ])),
                Layer(0, "nose", .head, Ink.clear, stroke: 1.2, path: [
                    .move(cx - 0.5, mouthY - 4.6),
                    .quad(cx + 0.8, mouthY - 3.9, cx + 0.2, mouthY - 2.6),
                ].path()),
                Layer(0, "mouthDefault", .head, Ink.clear, stroke: 1.6, path: [
                    .move(cx - 2.8, mouthY),
                    .quad(cx, mouthY + 1.6, cx + 2.8, mouthY),
                ].path()),
                Layer(0, "mouthHappy", .head, Ink.mouthDeep, stroke: 1.6, path: [
                    .move(cx - 3.6, mouthY - 0.8),
                    .line(cx + 3.6, mouthY - 0.8),
                    .quad(cx + 2.4, mouthY + 2.8, cx, mouthY + 2.8),
                    .quad(cx - 2.4, mouthY + 2.8, cx - 3.6, mouthY - 0.8),
                    .close,
                ].path(), restOpacity: 0),
                Layer(0, "mouthDetermined", .head, Ink.white, stroke: 1.6, path: [
                    .move(cx - 3.1, mouthY - 0.5),
                    .line(cx + 3.1, mouthY - 0.5),
                    .quad(cx + 2.4, mouthY + 1.5, cx, mouthY + 1.5),
                    .quad(cx - 2.4, mouthY + 1.5, cx - 3.1, mouthY - 0.5),
                    .close,
                ].path(), restOpacity: 0),
            ]
        }

        static func neck(_ p: P) -> [Layer] {
            let hw = p.neckWidth / 2
            return [Layer(0, "neck", .torso, Ink.skin, stroke: nil, path: [
                .move(cx - hw + 0.4, p.chin - 3.5),
                .line(cx - hw, p.shoulder),
                .line(cx + hw, p.shoulder),
                .line(cx + hw - 0.4, p.chin - 3.5),
                .close,
            ].path())]
        }
    }

    // MARK: - Eyes

    /// Authored for the left eye and mirrored. `eyeHeightRatio` is the appeal
    /// dial — below ~0.17 she reads gaunt, above ~0.22 she reads like a child —
    /// but `lidWeight` does more of the aging work than eye size does.
    enum Eyes {
        /// Centre of the left eye.
        static func centre(_ p: P) -> (x: Double, y: Double) {
            (cx - p.eyeGap / 2 - p.eyeWidth / 2, p.eyeLine)
        }

        static func almond(_ p: P) -> [Sketch] {
            let (ex, ey) = centre(p)
            let w = p.eyeWidth, h = p.eyeHeight
            return [
                .move(ex - w / 2, ey),
                .quad(ex - w * 0.44, ey - h * 0.465, ex - w * 0.01, ey - h * 0.49),
                .quad(ex + w * 0.445, ey - h * 0.465, ex + w / 2, ey - h * 0.027),
                .quad(ex + w * 0.435, ey + h * 0.49, ex + w * 0.005, ey + h * 0.507),
                .quad(ex - w * 0.44, ey + h * 0.465, ex - w / 2, ey),
                .close,
            ]
        }

        static func lash(_ p: P) -> [Sketch] {
            let (ex, ey) = centre(p)
            let w = p.eyeWidth, h = p.eyeHeight
            // How far the lash's lower boundary sits below its upper edge.
            let weight = p.lidWeight / 1.9
            return [
                .move(ex - w * 0.636, ey - h * 0.164),
                .quad(ex - w * 0.562, ey - h * 0.657, ex - w * 0.011, ey - h * 0.698),
                .quad(ex + w * 0.477, ey - h * 0.684, ex + w * 0.562, ey - h * 0.191),
                .line(ex + w * 0.445, ey - h * 0.109),
                .quad(ex + w * 0.329, ey - h * 0.465 * weight,
                      ex - w * 0.011, ey - h * 0.438 * weight),
                .quad(ex - w * 0.350, ey - h * 0.410 * weight,
                      ex - w * 0.456, ey + h * 0.027),
                .close,
            ]
        }

        static func layers(_ p: P) -> [Layer] {
            let (ex, ey) = centre(p)
            let w = p.eyeWidth, h = p.eyeHeight
            let mirror = 2 * cx - ex
            let brow = p.browLine

            func pair(_ name: String, _ part: AnimeGirlArt.Part, _ fill: Color,
                      _ make: (Double) -> Path) -> [Layer] {
                [Layer(0, name + "L", part, fill, stroke: nil, path: make(ex)),
                 Layer(0, name + "R", part, fill, stroke: nil, path: make(mirror))]
            }

            return [
                Layer(0, "eyeWhiteL", .head, Ink.white, stroke: 1.2, path: almond(p).path()),
                Layer(0, "eyeWhiteR", .head, Ink.white, stroke: 1.2,
                      path: almond(p).path(mirrorAbout: cx)),
            ]
            + pair("iris", .eyes, Ink.iris) { .oval($0, ey, w * 0.286, h * p.irisFill / 2) }
            + pair("pupil", .eyes, Ink.ink) { .oval($0, ey + h * 0.034, h * 0.164, h * 0.294) }
            + pair("hiBig", .eyes, Ink.white) { .oval($0 - w * 0.148, ey - h * 0.26, 1.1, 1.1) }
            + pair("hiSmall", .eyes, Ink.white) { .oval($0 + w * 0.159, ey + h * 0.355, 0.6, 0.6) }
            + [
                Layer(0, "lashL", .head, Ink.ink, stroke: nil, path: lash(p).path()),
                Layer(0, "lashR", .head, Ink.ink, stroke: nil, path: lash(p).path(mirrorAbout: cx)),
                Layer(0, "browsDefault", .head, Ink.clear, stroke: 1.5, path: both([
                    .move(ex - w * 0.509, brow),
                    .quad(ex - w * 0.085, brow - 2.0, ex + w * 0.371, brow - 0.6),
                ])),
                Layer(0, "browsDetermined", .head, Ink.clear, stroke: 1.5, path: both([
                    .move(ex - w * 0.456, brow - 2.0),
                    .quad(ex - w * 0.032, brow - 1.2, ex + w * 0.382, brow + 1.0),
                ]), restOpacity: 0),
                Layer(0, "closedEyesHappy", .head, Ink.clear, stroke: 1.8, path: both([
                    .move(ex - w / 2, ey + h * 0.219),
                    .quad(ex, ey - h * 0.41, ex + w / 2, ey + h * 0.219),
                ]), restOpacity: 0),
            ]
        }
    }

    // MARK: - Hair

    enum Hair {
        /// Root of the left twin tail.
        static func tailRoot(_ p: P) -> (x: Double, y: Double) {
            (cx - p.headWidth / 2, p.crown + 6)
        }

        /// Where the left tail's base hands off to its tip.
        static func tailPivot(_ p: P) -> (x: Double, y: Double) {
            (tailRoot(p).x - p.tailFlare + p.tailCurl * 2, p.tailHandoff)
        }

        /// The upper half of a tail: sweeps `tailFlare` away from the head, then
        /// falls. Straight parallel tubes read as curtains hung beside the head,
        /// which is what the sweep exists to avoid.
        static func tailBase(_ p: P) -> [Sketch] {
            let (rx, ry) = tailRoot(p)
            let length = p.tailHandoff - ry
            let outer = rx - p.tailFlare - p.tailWidth / 2
            let inner = rx - p.tailFlare + p.tailWidth / 2
            return [
                .move(rx + p.tailRootWidth * 0.4, ry - 4),
                .quad(rx - p.tailFlare * 0.9, ry + length * 0.08, outer + 3, ry + length * 0.25),
                .quad(outer - 0.5, ry + length * 0.48, outer, ry + length * 0.78),
                .quad(outer + 0.3, ry + length * 0.92, outer + 1.5, p.tailHandoff + 0.5),
                .line(inner, p.tailHandoff),
                .quad(inner + 0.5, ry + length * 0.69, inner + 1, ry + length * 0.41),
                .quad(inner + 1.5, ry + length * 0.14, rx + p.tailRootWidth * 0.4, ry - 4),
                .close,
            ]
        }

        /// The lower half, capped over the handoff so no gap can open, tapering
        /// to a point. `tailCurl` swings the falling end back under itself.
        static func tailTip(_ p: P) -> [Sketch] {
            let (tx, ty) = tailPivot(p)
            let hw = p.tailTipWidth / 2
            let length = p.tailEnd - ty
            let curl = p.tailCurl * 10
            return [
                .move(tx - hw, ty),
                .quad(tx - hw, ty - 5.5, tx, ty - 5.5),
                .quad(tx + hw, ty - 5.5, tx + hw, ty),
                .quad(tx + hw + 1, ty + length * 0.314, tx + hw - 2, ty + length * 0.629),
                .quad(tx + hw - curl, ty + length * 0.857, tx - curl, p.tailEnd),
                .quad(tx - curl - 4.5, ty + length * 0.829, tx - curl - 4.5, ty + length * 0.529),
                .quad(tx - curl - 4.5, ty + length * 0.229, tx - hw, ty),
                .close,
            ]
        }

        static func crown(_ p: P) -> [Sketch] {
            let hw = p.headWidth / 2, fh = p.faceHeight, v = p.hairVolume
            let base = p.crown + fh * 0.533
            return [
                .move(cx - hw - v * 0.417, base),
                .quad(cx - hw - v * 1.083, p.crown + 2, cx - 9.5, p.crown - v),
                .quad(cx, p.crown - v * 2, cx + 10.5, p.crown - v * 1.167),
                .quad(cx + hw + v, p.crown - 1.5, cx + hw + v * 0.667, base),
                .quad(cx + hw + v * 0.417, p.crown + 10, cx + hw - 1.5, p.crown + 5),
                .quad(cx, p.crown - 1, cx - 12, p.crown + 5),
                .quad(cx - hw + 1.5, p.crown + 10, cx - hw - v * 0.417, base),
                .close,
            ]
        }

        /// One swept curve, not a row of lock tips. At this scale a 3pt stroke
        /// turns every interior point into a spike, which rendered as a sawtooth
        /// band across her forehead. `fringeDepth` above ~0.8 becomes blunt bangs.
        static func fringe(_ p: P) -> [Sketch] {
            let hw = p.headWidth / 2, fh = p.faceHeight, v = p.hairVolume
            let dip = p.crown + (p.browLine - p.crown) * p.fringeDepth * 1.3
            return [
                .move(cx - hw - v * 0.417, p.crown + fh * 0.507),
                .quad(cx - hw - v * 1.083, p.crown + 1, cx - 9, p.crown - v * 1.083),
                .quad(cx + 1, p.crown - v * 2.083, cx + 11, p.crown - v * 1.25),
                .quad(cx + hw + v, p.crown - 2, cx + hw + v * 0.667, p.crown + fh * 0.507),
                .quad(cx + hw + v * 0.333, p.crown + 6, cx + 11, p.crown + 2.5),
                .quad(cx, dip, cx - 10, p.crown + 3.5),
                .quad(cx - hw - 0.5, p.crown + 7, cx - hw - v * 0.417, p.crown + fh * 0.507),
                .close,
            ]
        }

        /// Short, swept, tapering at the jaw — framing the face rather than
        /// hanging past it and splitting it into thirds.
        static func sideLock(_ p: P) -> [Sketch] {
            let hw = p.headWidth / 2, w = p.sideLockWidth
            let top = p.crown + 8
            return [
                .move(cx - hw, top),
                .quad(cx - hw - 4.5, top + 12, cx - hw - 3.8, top + 24),
                .quad(cx - hw - 3.2, top + 33, cx - hw - 0.5, p.sideLockEnd),
                .quad(cx - hw + 2.8, top + 30, cx - hw + 2.4, top + 18),
                .quad(cx - hw + 2.2, top + 9, cx - hw + 2.8, top + 1.5),
                .close,
            ]
        }

        static func layers(_ p: P) -> (back: [Layer], front: [Layer]) {
            let hw = p.headWidth / 2
            let (rx, ry) = tailRoot(p)
            let (tpx, _) = tailPivot(p)
            let mid = (rx - p.tailFlare)

            let back: [Layer] = [
                Layer(0, "backHair", .head, Ink.hairShadow, stroke: 3.0, path: [
                    .move(cx - hw - 1, p.crown + 14),
                    .quad(cx - hw - 4.5, p.crown + 34, cx - hw - 4, p.crown + 60),
                    .quad(cx - hw - 3.5, p.crown + 82, cx - hw - 1, p.crown + 100),
                    .quad(cx - 7, p.crown + 105, cx, p.crown + 103),
                    .quad(cx + 7, p.crown + 105, cx + hw - 1, p.crown + 100),
                    .quad(cx + hw + 3.5, p.crown + 82, cx + hw + 4, p.crown + 60),
                    .quad(cx + hw + 4.5, p.crown + 34, cx + hw + 1, p.crown + 14),
                    .quad(cx, p.crown + 4, cx - hw - 1, p.crown + 14),
                    .close,
                ].path()),
                Layer(0, "tailL_base", .tailL_base, Ink.hair, stroke: 3.0,
                      path: tailBase(p).path()),
                Layer(0, "tailL_tip", .tailL_tip, Ink.hair, stroke: 3.0,
                      path: tailTip(p).path()),
                Layer(0, "tailShineL", .tailL_base, Ink.hairShine, stroke: nil, path: [
                    .move(mid + 2, ry + 12),
                    .quad(mid - 1.5, ry + 28, mid - 1, ry + 48),
                    .line(mid + 2, ry + 48),
                    .quad(mid + 2, ry + 28, mid + 4.5, ry + 12),
                    .close,
                ].path()),
                Layer(0, "tailR_base", .tailR_base, Ink.hair, stroke: 3.0,
                      path: tailBase(p).path(mirrorAbout: cx)),
                Layer(0, "tailR_tip", .tailR_tip, Ink.hair, stroke: 3.0,
                      path: tailTip(p).path(mirrorAbout: cx)),
                Layer(0, "tailShineR", .tailR_base, Ink.hairShine, stroke: nil, path: [
                    .move(mid + 2, ry + 12),
                    .quad(mid - 1.5, ry + 28, mid - 1, ry + 48),
                    .line(mid + 2, ry + 48),
                    .quad(mid + 2, ry + 28, mid + 4.5, ry + 12),
                    .close,
                ].path(mirrorAbout: cx)),
            ]

            let front: [Layer] = [
                Layer(0, "hairCrown", .head, Ink.hair, stroke: 3.0, path: crown(p).path()),
                Layer(0, "sideLockL", .head, Ink.hair, stroke: 2.2, path: sideLock(p).path()),
                Layer(0, "sideLockR", .head, Ink.hair, stroke: 2.2,
                      path: sideLock(p).path(mirrorAbout: cx)),
                Layer(0, "bangs", .head, Ink.hair, stroke: 3.0, path: fringe(p).path()),
                Layer(0, "hairShine", .head, Ink.hairShine, stroke: nil, path: [
                    .move(cx - 12, p.crown),
                    .quad(cx - 2, p.crown - 6.5, cx + 8.5, p.crown - 3.5),
                    .quad(cx + 13, p.crown - 1.5, cx + 15, p.crown + 1.5),
                    .quad(cx + 4, p.crown - 3.5, cx - 8.5, p.crown + 2.5),
                    .quad(cx - 11, p.crown + 1.5, cx - 12, p.crown),
                    .close,
                ].path()),
            ]

            _ = tpx
            return (back, front)
        }

        static func ahogeRoot(_ p: P) -> (x: Double, y: Double) { (cx - 3, p.crown - 9) }

        /// Small and subtle — a tall bouncing ahoge is a genki-kid signal. It has
        /// to exist regardless: the performances drive it as the emotional lag.
        static func ahogeLayer(_ p: P) -> [Layer] {
            let (ax, ay) = ahogeRoot(p)
            return [Layer(0, "ahoge", .ahoge, Ink.clear, stroke: 2.2, path: [
                .move(ax, ay),
                .curve(ax - 2.2, ay - 5.5, ax + 1.8, ay - 9.5, ax + 6.4, ay - 8.0),
                .curve(ax + 9.6, ay - 7.0, ax + 7.6, ay - 3.0, ax + 3.8, ay - 4.4),
            ].path())]
        }

        static func ties(_ p: P) -> [Layer] {
            let (rx, ry) = tailRoot(p)
            return [
                Layer(0, "tieHairL", .tailL_base, Ink.teal, stroke: 1.6,
                      path: .oval(rx, ry, 2.6, 2.6)),
                Layer(0, "tieHairR", .tailR_base, Ink.teal, stroke: 1.6,
                      path: .oval(2 * cx - rx, ry, 2.6, 2.6)),
            ]
        }
    }

    // MARK: - Torso

    enum Torso {
        /// Shoulders down to the waist. `ribWidth` over `waistWidth` is the
        /// taper; keep the ratio near 0.7 — much tighter reads as exaggerated,
        /// much looser reads as a child's straight tube.
        static func silhouette(_ p: P, inset: Double = 0) -> [Sketch] {
            let top = p.torsoTopWidth / 2 - inset
            let rib = p.ribWidth / 2 - inset
            let waist = p.waistWidth / 2 - inset
            let ribY = p.shoulder + 17
            return [
                .move(cx - top, p.shoulder + 2),
                .quad(cx - top + 7, p.shoulder - 2.5, cx, p.shoulder - 3),
                .quad(cx + top - 7, p.shoulder - 2.5, cx + top, p.shoulder + 2),
                .quad(cx + rib, p.shoulder + 8, cx + rib, ribY),
                .quad(cx + rib - 0.5, ribY + 9, cx + waist + 1.1, ribY + 17),
                .quad(cx + waist + 0.4, ribY + 22, cx + waist, p.waist + 0.5),
                .line(cx - waist, p.waist + 0.5),
                .quad(cx - waist - 0.4, ribY + 22, cx - waist - 1.1, ribY + 17),
                .quad(cx - rib + 0.5, ribY + 9, cx - rib, ribY),
                .quad(cx - rib, p.shoulder + 8, cx - top, p.shoulder + 2),
                .close,
            ]
        }

        static func layers(_ p: P) -> [Layer] {
            let waist = p.waistWidth / 2
            let ribY = p.shoulder + 17
            return [
                Layer(0, "torsoSkin", .torso, Ink.skin, stroke: 3.0,
                      path: silhouette(p).path()),
                Layer(0, "waistShade", .torso, Ink.skinShade, stroke: nil, path: [
                    .move(cx + waist - 2.5, ribY + 17),
                    .quad(cx + waist - 1.3, ribY + 22, cx + waist - 0.7, p.waist + 0.5),
                    .line(cx + waist - 6.5, p.waist + 0.5),
                    .quad(cx + waist - 5.7, ribY + 22, cx + waist - 5, ribY + 17),
                    .close,
                ].path()),
            ]
        }
    }

    // MARK: - Limbs

    enum Limbs {
        /// Left shoulder joint. The deltoid pushing past the torso is what sets
        /// shoulder span, and shoulder span relative to head width is the single
        /// strongest adult-vs-child cue in the whole figure.
        static func shoulder(_ p: P) -> (x: Double, y: Double) {
            (cx - p.torsoTopWidth / 2 - p.deltoid + p.upperArmWidth / 2, p.shoulder + 4)
        }

        static func arm(_ p: P) -> [Layer] {
            let (sx, sy) = shoulder(p)
            let outer = cx - p.torsoTopWidth / 2 - p.deltoid
            let inner = outer + p.upperArmWidth
            let fore = p.foreArmWidth / 2

            let upper: [Sketch] = [
                .move(sx + 4.5, sy - 4.5),
                .quad(outer + 3, sy - 2.5, outer + 1.3, sy + 5.5),
                .quad(outer, sy + 13.5, outer + 0.8, p.elbow),
                .line(inner + 0.2, p.elbow),
                .quad(inner + 0.6, sy + 15.5, inner + 1.6, sy + 3.5),
                .quad(inner + 2.2, sy - 2.5, sx + 4.5, sy - 4.5),
                .close,
            ]
            // Rounded proximal cap centred on the elbow and drawn over the flat
            // cut above it, so no gap opens at any angle.
            let sleeve: [Sketch] = [
                .move(sx - fore, p.elbow),
                .quad(sx - fore, p.elbow - 5.2, sx, p.elbow - 5.2),
                .quad(sx + fore, p.elbow - 5.2, sx + fore, p.elbow),
                .line(sx + fore - 0.3, p.wrist - 6),
                .quad(sx + fore + 0.8, p.wrist - 1, sx + fore - 0.8, p.wrist + 1),
                .line(sx - fore + 0.8, p.wrist + 1),
                .quad(sx - fore - 0.8, p.wrist - 1, sx - fore + 0.3, p.wrist - 6),
                .close,
            ]
            let hand: [Sketch] = [
                .move(sx - 3, p.wrist),
                .quad(sx - 4.2, p.wrist + 5.8, sx - 2.7, p.wrist + 10.5),
                .quad(sx, p.wrist + 12.6, sx + 2.9, p.wrist + 10.5),
                .quad(sx + 4.4, p.wrist + 5.8, sx + 3.2, p.wrist),
                .quad(sx, p.wrist - 1.8, sx - 3, p.wrist),
                .close,
            ]

            return [
                Layer(0, "armL_skin", .armL, Ink.skin, stroke: 3.0, path: upper.path()),
                Layer(0, "foreSleeveL", .armL_fore, Ink.navy, stroke: 3.0, path: sleeve.path()),
                Layer(0, "handL", .armL_fore, Ink.skin, stroke: 1.8, path: hand.path()),
                Layer(0, "armR_skin", .armR, Ink.skin, stroke: 3.0,
                      path: upper.path(mirrorAbout: cx)),
                Layer(0, "foreSleeveR", .armR_fore, Ink.navy, stroke: 3.0,
                      path: sleeve.path(mirrorAbout: cx)),
                Layer(0, "handR", .armR_fore, Ink.skin, stroke: 1.8,
                      path: hand.path(mirrorAbout: cx)),
            ]
        }

        /// Centre of the left leg.
        static func legCentre(_ p: P) -> Double { cx - p.hipWidth * 0.184 }

        static func legs(_ p: P) -> [Layer] {
            let lx = legCentre(p)
            let tw = p.thighWidth / 2, bw = p.bootWidth / 2

            let thigh = Path.taper(cx: lx, top: p.hip - 2, bottom: p.bootTop + 6,
                                   topWidth: p.thighWidth, bottomWidth: p.thighWidth * 0.83)
            let boot: [Sketch] = [
                .move(lx - bw + 0.3, p.bootTop),
                .quad(lx - bw - 0.9, p.bootTop + 24, lx - bw + 0.9, p.bootTop + 50),
                .quad(lx - bw + 2.5, p.bootTop + 61, lx - bw + 1.9, p.sole - 3.5),
                .quad(lx - bw - 0.7, p.sole, lx - bw + 1.7, p.sole),
                .line(lx + bw - 0.7, p.sole),
                .quad(lx + bw + 0.9, p.sole - 5, lx + bw - 1.1, p.bootTop + 56),
                .quad(lx + bw - 0.9, p.bootTop + 24, lx + bw - 0.3, p.bootTop),
                .quad(lx, p.bootTop - 2.5, lx - bw + 0.3, p.bootTop),
                .close,
            ]
            let trim: [Sketch] = [
                .move(lx - bw + 0.35, p.bootTop + 0.5),
                .line(lx + bw - 0.35, p.bootTop + 0.5),
                .line(lx + bw - 0.4, p.bootTop + 4),
                .line(lx - bw + 0.3, p.bootTop + 4),
                .close,
            ]

            _ = tw
            return [
                Layer(0, "thighL", .legL, Ink.skin, stroke: 3.0, path: thigh),
                Layer(0, "bootL", .legL, Ink.navy, stroke: 3.0, path: boot.path()),
                Layer(0, "bootTrimL", .legL, Ink.teal, stroke: nil, path: trim.path()),
                Layer(0, "thighR", .legR, Ink.skin, stroke: 3.0,
                      path: Path.taper(cx: 2 * cx - lx, top: p.hip - 2, bottom: p.bootTop + 6,
                                       topWidth: p.thighWidth,
                                       bottomWidth: p.thighWidth * 0.83)),
                Layer(0, "bootR", .legR, Ink.navy, stroke: 3.0, path: boot.path(mirrorAbout: cx)),
                Layer(0, "bootTrimR", .legR, Ink.teal, stroke: nil,
                      path: trim.path(mirrorAbout: cx)),
            ]
        }
    }

    // MARK: - Outfit

    /// Vocaloid-*inspired* stagewear, not a copy: lavender hair, no headset, our
    /// own face. The top follows the torso silhouette so a change to `ribWidth`
    /// or `waistWidth` carries through to the clothing automatically.
    enum Outfit {
        static func top(_ p: P) -> [Layer] {
            let top = p.torsoTopWidth / 2
            let rib = p.ribWidth / 2
            let ribY = p.shoulder + 17
            let hem = p.topHem
            let scoop = p.shoulder + 6.5

            let shirt: [Sketch] = [
                .move(cx - top + 1, p.shoulder + 1),
                .quad(cx - top + 7, scoop, cx, scoop),
                .quad(cx + top - 7, scoop, cx + top - 1, p.shoulder + 1),
                .quad(cx + top + 2.5, p.shoulder + 0.5, cx + top + 3.5, p.shoulder + 3),
                .quad(cx + rib + 1, p.shoulder + 9, cx + rib + 0.8, ribY),
                .quad(cx + rib + 0.3, ribY + 9, cx + rib - 1.3, hem),
                .line(cx - rib + 1.3, hem),
                .quad(cx - rib - 0.3, ribY + 9, cx - rib - 0.8, ribY),
                .quad(cx - rib - 1, p.shoulder + 9, cx - top - 3.5, p.shoulder + 3),
                .quad(cx - top - 2.5, p.shoulder + 0.5, cx - top + 1, p.shoulder + 1),
                .close,
            ]
            // Kept low deliberately: this is enough form that the top does not
            // read as cardboard, and no more.
            let shade: [Sketch] = [
                .move(cx + 10, p.shoulder + 4.5),
                .quad(cx + rib - 2, p.shoulder + 5, cx + rib - 0.5, p.shoulder + 8),
                .quad(cx + rib + 1.9, p.shoulder + 14, cx + rib + 0.8, p.shoulder + 20),
                .quad(cx + rib + 0.4, ribY + 10, cx + rib - 1.3, hem),
                .line(cx + 10.5, hem),
                .quad(cx + 11.5, ribY, cx + 10, p.shoulder + 4.5),
                .close,
            ]
            let tie: [Sketch] = [
                .move(cx - 2.5, scoop + 1.5),
                .line(cx + 2.5, scoop + 1.5),
                .line(cx + 1.6, scoop + 5),
                .line(cx - 1.6, scoop + 5),
                .close,
                .move(cx - 1.6, scoop + 5),
                .line(cx + 1.6, scoop + 5),
                .quad(cx + 2.8, scoop + 11.5, cx, scoop + 16.5),
                .quad(cx - 2.8, scoop + 11.5, cx - 1.6, scoop + 5),
                .close,
            ]

            return [
                Layer(0, "cropTop", .torso, Ink.white, stroke: 3.0, path: shirt.path()),
                Layer(0, "topShade", .torso, Ink.cloth, stroke: nil, path: shade.path()),
                Layer(0, "topHem", .torso, Ink.teal, stroke: nil, path: [
                    .move(cx - rib + 1.4, hem - 2.7),
                    .line(cx + rib - 1.4, hem - 2.7),
                    .line(cx + rib - 1.3, hem),
                    .line(cx - rib + 1.3, hem),
                    .close,
                ].path()),
                Layer(0, "tie", .torso, Ink.teal, stroke: 1.8, path: tie.path()),
            ]
        }

        /// Pleats are generated, so `pleats` is a real dial rather than a
        /// hand-drawn zigzag that has to be redrawn to change count.
        static func skirt(_ p: P) -> [Layer] {
            let waist = p.waistWidth / 2
            let hip = p.hipWidth / 2
            let flare = p.skirtFlare
            let hemY = p.skirtHem
            let high = hemY - 3.5, low = hemY + 1

            var body: [Sketch] = [
                .move(cx - waist, p.waist + 1),
                .line(cx + waist, p.waist + 1),
                .quad(cx + hip - 0.5, p.hip, cx + hip + flare - 2.5, hemY - 7),
                .quad(cx + hip + flare - 2, hemY - 3, cx + hip + flare - 2.5, hemY),
            ]
            // Alternating tips between the two hem corners, high first.
            let count = max(0, p.pleats * 2 - 3)
            let step = (p.waistWidth + flare) / Double(count + 1)
            for index in 0..<count {
                let x = cx + waist + flare / 2 - step * Double(index + 1)
                body.append(.line(x, index.isMultiple(of: 2) ? high : low))
            }
            body += [
                .line(cx - hip - flare + 2.5, hemY),
                .quad(cx - hip - flare + 2, hemY - 3, cx - hip - flare + 2.5, hemY - 7),
                .quad(cx - hip + 0.5, p.hip, cx - waist, p.waist + 1),
                .close,
            ]

            return [
                Layer(0, "skirt", .hips, Ink.blue, stroke: 3.0, path: body.path()),
                Layer(0, "skirtShade", .hips, Ink.blueDeep, stroke: nil, path: [
                    .move(cx + 9, p.waist + 1),
                    .line(cx + waist, p.waist + 1),
                    .quad(cx + hip - 0.5, p.hip, cx + hip + flare - 2.5, hemY - 7),
                    .quad(cx + hip + flare - 2, hemY - 3, cx + hip + flare - 2.5, hemY),
                    .line(cx + waist - 3, high),
                    .line(cx + 12, hemY - 7),
                    .close,
                ].path()),
                Layer(0, "skirtBand", .hips, Ink.blueDeep, stroke: nil, path: [
                    .move(cx - waist - 0.3, p.waist - 3),
                    .line(cx + waist + 0.3, p.waist - 3),
                    .line(cx + waist + 0.2, p.waist + 3),
                    .line(cx - waist - 0.2, p.waist + 3),
                    .close,
                ].path()),
            ]
        }
    }

    // MARK: - Sparkles

    /// All three sit high and wide so the twirl's 90° orbit about the sparkle
    /// pivot — cubic overshoot included — never sweeps across the body.
    enum Sparkles {
        static func star(_ x: Double, _ y: Double, _ radius: Double) -> Path {
            let inner = radius * 0.28
            return [
                .move(x, y - radius),
                .line(x + inner, y - inner),
                .line(x + radius, y),
                .line(x + inner, y + inner),
                .line(x, y + radius),
                .line(x - inner, y + inner),
                .line(x - radius, y),
                .line(x - inner, y - inner),
                .close,
            ].path()
        }

        static func layers(_: P) -> [Layer] {
            [
                Layer(0, "sparkleA", .sparkles, Ink.white, stroke: nil,
                      path: star(42, 38, 8), restOpacity: 0),
                Layer(0, "sparkleB", .sparkles, Ink.teal, stroke: nil,
                      path: star(56, 20, 6), restOpacity: 0),
                Layer(0, "sparkleC", .sparkles, Ink.white, stroke: nil,
                      path: star(150, 26, 5), restOpacity: 0),
            ]
        }
    }
}
