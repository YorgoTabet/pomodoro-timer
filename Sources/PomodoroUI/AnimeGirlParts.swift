import CoreGraphics
import SwiftUI

/// Power's body, composed from parts instead of transcribed.
///
/// Each part is a pure function of `AnimeGirlProportions` returning its own
/// layers (shapes, fills, strokes and rig assignment), so composition is
/// concatenation and a part is swappable without touching the others.
///
/// Everything paired is authored **once on the left and mirrored** about the
/// canvas midline, so the two sides can never drift apart.
///
/// Layer ids are assigned by `AnimeGirlArt` after concatenation, so a part never
/// has to know where it lands in the draw order.
///
/// Expression layers are named `face.<set>.<piece>` and hand layers
/// `hand.<kind>.<side>.<piece>`; `AnimeGirlPose.opacity(of:)` reads those names
/// to cross-fade the sets, so a rename here must be mirrored there.
enum AnimeGirlParts {

    /// Canvas midline: the mirror axis and the figure's centre.
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

    /// Reflects one x coordinate through the midline.
    static func m(_ x: Double) -> Double { 2 * cx - x }

    /// A limb segment whose top is a true semicircle centred on (`x`, `top`).
    ///
    /// Centring the cap on the joint pivot is what keeps a bend clean: the round
    /// end turns in place over the part above it, so no gap, notch or crease can
    /// open at any angle.
    static func capsule(_ x: Double, _ top: Double, _ bottom: Double,
                        _ topWidth: Double, _ bottomWidth: Double,
                        bow: Double = 0) -> [Sketch] {
        let a = topWidth / 2, b = bottomWidth / 2
        let k = 0.552
        let mid = (top + bottom) / 2
        return [
            .move(x - a, top),
            .quad(x - (a + b) / 2 - bow, mid, x - b, bottom),
            .line(x + b, bottom),
            .quad(x + (a + b) / 2 + bow, mid, x + a, top),
            .curve(x + a, top - a * k, x + a * k, top - a, x, top - a),
            .curve(x - a * k, top - a, x - a, top - a * k, x - a, top),
            .close,
        ]
    }

    /// A filled circle as sketch segments.
    static func circle(_ x: Double, _ y: Double, _ r: Double) -> [Sketch] {
        let k = 0.552 * r
        return [
            .move(x + r, y),
            .curve(x + r, y + k, x + k, y + r, x, y + r),
            .curve(x - k, y + r, x - r, y + k, x - r, y),
            .curve(x - r, y - k, x - k, y - r, x, y - r),
            .curve(x + k, y - r, x + r, y - k, x + r, y),
            .close,
        ]
    }

    // MARK: - Head

    enum Head {
        /// Skull and jaw. `chinTaper` drives the lower face: 1 gives a sharp
        /// wedge, 0 a rounded jaw with no chin.
        static func skull(_ p: P) -> Path {
            let hw = p.headWidth / 2, fh = p.faceHeight
            let cheek = p.crown + fh * 0.47
            let temple = p.crown + fh * (0.16 - 0.14 * p.skullRound)
            let jawCtrl = p.crown + fh * 0.70
            let jawX = cx - hw * (1 - 0.25 * p.chinTaper)
            let jawY = p.crown + fh * 0.84
            let chinX = cx - hw * (1 - 0.535 * p.chinTaper)
            let chinY = p.crown + fh * 0.975
            return [
                .move(cx - hw, cheek),
                .quad(cx - hw, temple, cx, p.crown),
                .quad(cx + hw, temple, cx + hw, cheek),
                .quad(cx + hw, jawCtrl, m(jawX), jawY),
                .quad(m(chinX), chinY, cx, p.chin),
                .quad(chinX, chinY, jawX, jawY),
                .quad(cx - hw, jawCtrl, cx - hw, cheek),
                .close,
            ].path()
        }

        static func neck(_ p: P) -> [Layer] {
            let hw = p.neckWidth / 2
            // No chin shadow on the neck: at 70pt it read as an orange bow tie.
            return [
                Layer(0, "neck", .torso, Ink.skin, stroke: 2.4, path: [
                    .move(cx - hw + 0.4, p.chin - 4),
                    .line(cx - hw, p.shoulder + 2),
                    .line(cx + hw, p.shoulder + 2),
                    .line(cx + hw - 0.4, p.chin - 4),
                    .close,
                ].path()),
            ]
        }

        static func layers(_ p: P) -> [Layer] {
            let my = p.mouthLine
            return [
                Layer(0, "headBase", .head, Ink.skin, stroke: 2.6, path: skull(p)),
                Layer(0, "nose", .head, Ink.clear, stroke: 1.0, path: [
                    .move(cx + 0.2, my - 6.4),
                    .quad(cx + 1.1, my - 5.4, cx + 0.1, my - 4.9),
                ].path()),
            ]
        }
    }

    // MARK: - Mouths

    /// Every mouth is open-and-fanged except the smirk and the doze, because a
    /// sharp-toothed grin is the second thing (after the horns) that says Power.
    /// Each set is named `face.<set>.<piece>` for the pose's cross-fade.
    enum Mouth {

        /// A row of teeth hanging from a mouth's top edge: a white band whose
        /// lower edge is a zigzag, with the two outer points long enough to read
        /// as fangs at 70pt.
        static func upperTeeth(_ y: Double, halfWidth w: Double, fang: Double,
                               sag: Double = 1.0) -> Path {
            [
                .move(cx - w, y - 0.2),
                .quad(cx, y + sag, cx + w, y - 0.2),
                .line(cx + w * 0.92, y + 1.0),
                .line(cx + w * 0.70, y + fang),          // right fang
                .line(cx + w * 0.50, y + 1.4),
                .line(cx + w * 0.28, y + 2.1),
                .line(cx + w * 0.10, y + 1.5 + sag * 0.3),
                .line(cx - w * 0.10, y + 2.1 + sag * 0.3),
                .line(cx - w * 0.28, y + 1.5),
                .line(cx - w * 0.50, y + 1.4),
                .line(cx - w * 0.70, y + fang),          // left fang
                .line(cx - w * 0.92, y + 1.0),
                .close,
            ].path()
        }

        /// Two small fangs pointing up from a mouth's lower edge.
        static func lowerFangs(_ y: Double, spread: Double, height: Double) -> Path {
            both([
                .move(cx - spread - 1.2, y + 0.4),
                .line(cx - spread, y - height),
                .line(cx - spread + 1.2, y + 0.4),
                .close,
            ])
        }

        static func layers(_ p: P) -> [Layer] {
            let y = p.mouthLine
            let line: CGFloat = 1.3

            // Neutral grin: wide, corners up, fangs showing. Her resting face.
            let grin: [Sketch] = [
                .move(cx - 6.0, y - 2.4),
                .quad(cx, y - 0.8, cx + 6.0, y - 2.4),
                .quad(cx + 4.8, y + 3.6, cx, y + 3.6),
                .quad(cx - 4.8, y + 3.6, cx - 6.0, y - 2.4),
                .close,
            ]
            // Shout: tall, square-cornered, every tooth on show.
            let shout: [Sketch] = [
                .move(cx - 5.6, y - 3.2),
                .quad(cx, y - 4.4, cx + 5.6, y - 3.2),
                .quad(cx + 6.0, y + 6.4, cx, y + 6.2),
                .quad(cx - 6.0, y + 6.4, cx - 5.6, y - 3.2),
                .close,
            ]
            // Laugh: the grin opened right up, head-back wide.
            let laugh: [Sketch] = [
                .move(cx - 6.4, y - 3.0),
                .quad(cx, y - 1.8, cx + 6.4, y - 3.0),
                .quad(cx + 5.6, y + 5.6, cx, y + 5.6),
                .quad(cx - 5.6, y + 5.6, cx - 6.4, y - 3.0),
                .close,
            ]

            return [
                Layer(0, "face.grin.mouth", .head, Ink.mouthDeep, stroke: line,
                      path: grin.path()),
                Layer(0, "face.grin.tongue", .head, Ink.tongue, stroke: nil,
                      path: .oval(cx + 0.6, y + 2.6, 3.0, 1.0)),
                Layer(0, "face.grin.teeth", .head, Ink.white, stroke: nil,
                      path: upperTeeth(y - 2.0, halfWidth: 5.4, fang: 3.1, sag: 1.4)),

                Layer(0, "face.shout.mouth", .head, Ink.mouthDeep, stroke: line,
                      path: shout.path(), restOpacity: 0),
                Layer(0, "face.shout.tongue", .head, Ink.tongue, stroke: nil,
                      path: .oval(cx, y + 4.6, 3.6, 1.6), restOpacity: 0),
                Layer(0, "face.shout.teeth", .head, Ink.white, stroke: nil,
                      path: upperTeeth(y - 3.4, halfWidth: 5.2, fang: 3.4, sag: -0.4),
                      restOpacity: 0),
                Layer(0, "face.shout.fangs", .head, Ink.white, stroke: nil,
                      path: lowerFangs(y + 5.6, spread: 3.4, height: 2.2), restOpacity: 0),

                // Smug: mouth shut, one corner hitched, a single fang over the lip.
                Layer(0, "face.smug.mouth", .head, Ink.clear, stroke: 1.5, path: [
                    .move(cx - 4.8, y - 0.2),
                    .quad(cx - 0.5, y + 1.6, cx + 4.6, y - 2.0),
                    .move(cx + 4.6, y - 2.0),
                    .line(cx + 5.6, y - 2.6),
                ].path(), restOpacity: 0),
                Layer(0, "face.smug.fang", .head, Ink.white, stroke: 0.9, path: [
                    .move(cx + 1.0, y + 0.6),
                    .line(cx + 2.0, y + 2.9),
                    .line(cx + 2.9, y + 0.2),
                    .close,
                ].path(), restOpacity: 0),

                // Yawn: a tall round O with fangs hanging from the top lip.
                Layer(0, "face.yawn.mouth", .head, Ink.mouthDeep, stroke: line,
                      path: .oval(cx, y + 1.6, 4.0, 5.4), restOpacity: 0),
                Layer(0, "face.yawn.tongue", .head, Ink.tongue, stroke: nil,
                      path: .oval(cx, y + 4.6, 2.6, 1.6), restOpacity: 0),
                Layer(0, "face.yawn.fangs", .head, Ink.white, stroke: nil, path: both([
                    .move(cx - 3.2, y - 2.6),
                    .line(cx - 2.0, y + 0.6),
                    .line(cx - 1.0, y - 3.4),
                    .close,
                ]), restOpacity: 0),

                Layer(0, "face.laugh.mouth", .head, Ink.mouthDeep, stroke: line,
                      path: laugh.path(), restOpacity: 0),
                Layer(0, "face.laugh.tongue", .head, Ink.tongue, stroke: nil,
                      path: .oval(cx, y + 3.6, 3.8, 1.7), restOpacity: 0),
                Layer(0, "face.laugh.teeth", .head, Ink.white, stroke: nil,
                      path: upperTeeth(y - 2.6, halfWidth: 5.8, fang: 3.3, sag: 1.0),
                      restOpacity: 0),

                // Doze: a small closed smile with the fang still poking out.
                Layer(0, "face.doze.mouth", .head, Ink.clear, stroke: 1.3, path: [
                    .move(cx - 3.4, y - 0.6),
                    .quad(cx, y + 1.6, cx + 3.4, y - 0.6),
                ].path(), restOpacity: 0),
                Layer(0, "face.doze.fang", .head, Ink.white, stroke: 0.8, path: [
                    .move(cx + 0.9, y + 0.7),
                    .line(cx + 1.7, y + 2.5),
                    .line(cx + 2.4, y + 0.5),
                    .close,
                ].path(), restOpacity: 0),
            ]
        }
    }

    // MARK: - Eyes

    /// Authored for the left eye and mirrored.
    ///
    /// The cross pupil is the single most recognisable mark on her, so it is
    /// built to win at 70pt: the darkest ink in the face, laid across a yellow
    /// iris whose red core is kept small enough that the cross arms reach past
    /// it into the yellow, where the contrast is.
    enum Eyes {
        /// Centre of the left eye.
        static func centre(_ p: P) -> (x: Double, y: Double) {
            (cx - p.eyeGap / 2 - p.eyeWidth / 2, p.eyeLine)
        }

        /// Sharp almond: the outer corner sits low and pointed (the droopy,
        /// cocky slant), the lower lid runs flatter than the upper.
        static func almond(_ p: P) -> [Sketch] {
            let (ex, ey) = centre(p)
            let w = p.eyeWidth, h = p.eyeHeight
            return [
                .move(ex - w * 0.50, ey + h * 0.10),
                .quad(ex - w * 0.30, ey - h * 0.44, ex + w * 0.10, ey - h * 0.44),
                .quad(ex + w * 0.44, ey - h * 0.40, ex + w * 0.50, ey - h * 0.02),
                .quad(ex + w * 0.40, ey + h * 0.50, ex + w * 0.00, ey + h * 0.48),
                .quad(ex - w * 0.38, ey + h * 0.44, ex - w * 0.50, ey + h * 0.10),
                .close,
            ]
        }

        /// The heavy upper lash line, thickest at the outer corner, ending in a
        /// short flick past it.
        static func lash(_ p: P) -> [Sketch] {
            let (ex, ey) = centre(p)
            let w = p.eyeWidth, h = p.eyeHeight, lw = p.lidWeight
            return [
                .move(ex - w * 0.70, ey + h * 0.16),                 // flick tip, down-out
                .quad(ex - w * 0.40, ey - h * 0.46 - lw * 1.2,
                      ex + w * 0.10, ey - h * 0.44 - lw * 0.95),
                .quad(ex + w * 0.44, ey - h * 0.42 - lw * 0.5,
                      ex + w * 0.56, ey - h * 0.04),
                .line(ex + w * 0.48, ey + h * 0.00),
                .quad(ex + w * 0.42, ey - h * 0.36, ex + w * 0.10, ey - h * 0.38),
                .quad(ex - w * 0.28, ey - h * 0.38, ex - w * 0.50, ey + h * 0.12),
                .close,
            ]
        }

        static func irisCentre(_ p: P) -> (x: Double, y: Double) {
            let (ex, ey) = centre(p)
            return (ex + p.eyeWidth * 0.06, ey + p.eyeHeight * 0.04)
        }

        /// A plus sign. `arm` is the half-length, `t` the bar thickness.
        static func cross(_ x: Double, _ y: Double, armX: Double, armY: Double,
                          t: Double) -> [Sketch] {
            let h = t / 2
            return [
                .move(x - h, y - armY),
                .line(x + h, y - armY),
                .line(x + h, y - h),
                .line(x + armX, y - h),
                .line(x + armX, y + h),
                .line(x + h, y + h),
                .line(x + h, y + armY),
                .line(x - h, y + armY),
                .line(x - h, y + h),
                .line(x - armX, y + h),
                .line(x - armX, y - h),
                .line(x - h, y - h),
                .close,
            ]
        }

        static func layers(_ p: P) -> [Layer] {
            let (ex, ey) = centre(p)
            let (ix, iy) = irisCentre(p)
            let w = p.eyeWidth, h = p.eyeHeight
            let rx = w * 0.33, ry = h * p.irisFill * 0.5

            func pair(_ name: String, _ part: AnimeGirlArt.Part, _ fill: Color,
                      stroke: CGFloat? = nil, rest: Double = 1,
                      _ sketch: [Sketch]) -> [Layer] {
                [Layer(0, name + ".L", part, fill, stroke: stroke,
                       path: sketch.path(), restOpacity: rest),
                 Layer(0, name + ".R", part, fill, stroke: stroke,
                       path: sketch.path(mirrorAbout: cx), restOpacity: rest)]
            }

            // Half-lidded smug eyes: a skin lid lowered over the top of the eye,
            // with its own heavy lash line along the new edge. The cross stays
            // visible underneath, which is the point.
            let lid: [Sketch] = [
                .move(ex - w * 0.72, ey + h * 0.20),
                .line(ex - w * 0.72, ey - h * 1.05),
                .line(ex + w * 0.62, ey - h * 1.05),
                .line(ex + w * 0.62, ey + h * 0.02),
                .quad(ex + w * 0.05, ey - h * 0.40, ex - w * 0.52, ey + h * 0.18),
                .close,
            ]
            let lidLine: [Sketch] = [
                .move(ex - w * 0.70, ey + h * 0.12),
                .quad(ex - w * 0.10, ey - h * 0.64, ex + w * 0.58, ey - h * 0.10),
                .line(ex + w * 0.52, ey + h * 0.04),
                .quad(ex + w * 0.05, ey - h * 0.38, ex - w * 0.52, ey + h * 0.20),
                .close,
            ]

            return
                pair("face.open.white", .head, Ink.white, almond(p))
                + pair("face.open.iris", .eyes, Ink.irisOuter,
                       [Sketch].ellipse(ix, iy, rx, ry))
                + pair("face.open.core", .eyes, Ink.irisInner,
                       [Sketch].ellipse(ix, iy, rx * 0.46, ry * 0.46))
                // Arms run to the iris rim, so even when the eye is only a few
                // pixels wide the cross splits the yellow into four quadrants.
                + pair("face.open.cross", .eyes, Ink.pupil,
                       cross(ix, iy, armX: rx * 1.0, armY: ry * 1.0, t: h * 0.19))
                + pair("face.open.shine", .eyes, Ink.white,
                       [Sketch].ellipse(ix - rx * 0.52, iy - ry * 0.52, 0.85, 0.85))
                + pair("face.open.lash", .head, Ink.ink, lash(p))
                + pair("face.open.lower", .head, Ink.clear, stroke: 0.9, [
                    .move(ex - w * 0.46, ey + h * 0.22),
                    .quad(ex - w * 0.32, ey + h * 0.50, ex + w * 0.02, ey + h * 0.52),
                ])
                + pair("face.smug.lid", .head, Ink.skin, rest: 0, lid)
                + pair("face.smug.lidLine", .head, Ink.ink, rest: 0, lidLine)
                // Yawn: squeezed shut into a chevron, > on the left eye.
                + pair("face.yawn.eye", .head, Ink.clear, stroke: 1.9, rest: 0, [
                    .move(ex - w * 0.42, ey - h * 0.36),
                    .line(ex + w * 0.36, ey + h * 0.02),
                    .line(ex - w * 0.42, ey + h * 0.36),
                ])
                // Laugh: the closed upward arc.
                + pair("face.laugh.eye", .head, Ink.clear, stroke: 2.0, rest: 0, [
                    .move(ex - w * 0.52, ey + h * 0.22),
                    .quad(ex, ey - h * 0.62, ex + w * 0.50, ey + h * 0.18),
                ])
                // Doze: relaxed closed lids, curving down, with the lash flick.
                + pair("face.doze.eye", .head, Ink.clear, stroke: 1.8, rest: 0, [
                    .move(ex - w * 0.64, ey + h * 0.02),
                    .quad(ex - w * 0.05, ey + h * 0.52, ex + w * 0.52, ey + h * 0.04),
                ])
        }

        /// Brows draw over the fringe, as anime brows do, or the bangs would hide
        /// half of every expression change.
        static func brows(_ p: P) -> [Layer] {
            let (ex, _) = centre(p)
            let w = p.eyeWidth, b = p.browLine
            return [
                Layer(0, "face.brows.default", .head, Ink.clear, stroke: 1.4, path: both([
                    .move(ex - w * 0.52, b + 1.0),
                    .quad(ex - w * 0.10, b - 1.6, ex + w * 0.46, b + 0.2),
                ])),
                Layer(0, "face.brows.angry", .head, Ink.clear, stroke: 1.7, path: both([
                    .move(ex - w * 0.52, b - 1.6),
                    .quad(ex - w * 0.05, b - 1.2, ex + w * 0.50, b + 2.2),
                ]), restOpacity: 0),
                Layer(0, "face.brows.raised", .head, Ink.clear, stroke: 1.4, path: both([
                    .move(ex - w * 0.52, b - 0.2),
                    .quad(ex - w * 0.05, b - 3.6, ex + w * 0.46, b - 1.6),
                ]), restOpacity: 0),
            ]
        }
    }

    // MARK: - Hair

    enum Hair {
        /// Root of the left back hair mass, tucked behind the skull.
        static func tailRoot(_ p: P) -> (x: Double, y: Double) {
            (cx - p.headWidth / 2 + 3, p.crown + 8)
        }

        /// Outer edge of the left mass at the handoff.
        static func tailOuter(_ p: P) -> Double {
            cx - p.headWidth / 2 - p.tailFlare - 3
        }

        /// Where the left mass's base hands off to its tip.
        static func tailPivot(_ p: P) -> (x: Double, y: Double) {
            (tailOuter(p) + p.tailWidth / 2, p.tailHandoff)
        }

        /// The upper half of a back hair mass: leaves the head behind the skull,
        /// flares out past the shoulders, then falls. This flare is most of her
        /// silhouette, so it is wide on purpose.
        static func tailBase(_ p: P) -> [Sketch] {
            let (rx, ry) = tailRoot(p)
            let hw = p.headWidth / 2, v = p.hairVolume
            let outer = tailOuter(p)
            let inner = outer + p.tailWidth
            let length = p.tailHandoff - ry
            // Starts flush with the crown's outer edge, so the dome flows into the
            // falling hair instead of two tubes hanging off the head.
            // Emerges from under the dome's lower edge, never above it, or its
            // outline pokes out at the temples like headphones.
            let emerge = p.crown + p.faceHeight * 0.36
            return [
                .move(rx + 1, ry),
                .line(cx - hw - v * 0.4, emerge),
                .quad(outer + 1.0, emerge + length * 0.18, outer, p.tailHandoff + 1),
                .line(inner, p.tailHandoff + 1),
                .quad(inner + 0.6, ry + length * 0.45, rx + p.tailRootWidth * 0.5, ry + 4),
                .close,
            ]
        }

        /// The lower half: capped over the handoff so no gap opens when the two
        /// halves bend, flaring out and ending past the waist in uneven points.
        static func tailTip(_ p: P) -> [Sketch] {
            let (tx, ty) = tailPivot(p)
            let half = p.tailWidth / 2
            let spread = p.tailTipWidth - p.tailWidth   // how much wider the ends get
            let end = p.tailEnd
            let length = end - ty
            let kick = p.tailCurl * 6
            let o = tx - half - spread * 0.8 - kick      // outer edge at the ends
            let i = tx + half + spread * 0.2             // inner edge at the ends
            return [
                .move(tx - half, ty),
                .quad(tx - half, ty - 7, tx, ty - 7),
                .quad(tx + half, ty - 7, tx + half, ty),
                .quad(tx + half + 0.5, ty + length * 0.5, i, end - 10),
                .line(i - 4.0, end - 17),
                .line(i - 6.5, end - 3),
                .line(i - 10.0, end - 14),
                .line((o + i) / 2 - 3.0, end + 1),
                .line(o + 5.0, end - 13),
                .line(o, end - 6),
                .quad(tx - half - spread * 0.3, ty + length * 0.4, tx - half, ty),
                .close,
            ]
        }

        /// A fill-only patch over the handoff, so the tip's cap does not draw a
        /// line across the hair at rest. Smaller than the mass so its outline
        /// stays.
        static func tailSeam(_ p: P) -> [Sketch] {
            let (tx, ty) = tailPivot(p)
            return [Sketch].ellipse(tx, ty - 1, p.tailWidth / 2 - 1.6, 6.5)
        }

        /// One long lighter streak down each mass: tells the eye it is hair, not
        /// a cape.
        static func tailShine(_ p: P) -> [Sketch] {
            let (rx, ry) = tailRoot(p)
            let outer = tailOuter(p)
            let x = outer + 4.5
            return [
                .move(rx - 6, ry + 10),
                .quad(x - 1, ry + 30, x, p.tailHandoff - 6),
                .line(x + 2.4, p.tailHandoff - 6),
                .quad(x + 1.5, ry + 30, rx - 3.5, ry + 10),
                .close,
            ]
        }

        /// The dome over the skull.
        static func crown(_ p: P) -> [Sketch] {
            let hw = p.headWidth / 2, v = p.hairVolume
            let base = p.crown + p.faceHeight * 0.48
            return [
                .move(cx - hw - v * 0.5, base),
                .quad(cx - hw - v * 1.2, p.crown - 1, cx - 8, p.crown - v * 1.6),
                .quad(cx, p.crown - v * 2.1, cx + 9, p.crown - v * 1.6),
                .quad(cx + hw + v * 1.2, p.crown - 1, cx + hw + v * 0.5, base),
                .quad(cx + hw + 0.5, p.crown + 9, cx + hw - 3, p.crown + 5),
                .quad(cx, p.crown - 1, cx - hw + 3, p.crown + 5),
                .quad(cx - hw - 0.5, p.crown + 9, cx - hw - v * 0.5, base),
                .close,
            ]
        }

        /// Messy, uneven, pointed bangs, parted a little off centre, with one
        /// strand falling between her eyes. Every point is placed by hand: an
        /// evenly spaced zigzag reads as a saw blade, not hair.
        static func fringe(_ p: P) -> [Sketch] {
            let hw = p.headWidth / 2, v = p.hairVolume
            let c = p.crown
            let d = (p.browLine - c) * p.fringeDepth
            let eye = p.eyeLine - c
            // (x offset, y offset from crown), left to right along the lower edge.
            let edge: [(Double, Double)] = [
                (-hw - 1.0, 13),
                (-hw + 1.8, eye - 2.5),        // long lock over the outer corner
                (-hw + 4.5, d * 0.62),
                (-9.5, d + 0.5),
                (-7.0, d * 0.58),
                (-3.6, d + 1.2),
                (-1.8, d * 0.66),
                (0.6, eye + 0.5),               // the strand between the eyes
                (2.2, d * 0.62),
                (6.0, d + 0.8),
                (8.6, d * 0.55),
                (12.0, d + 0.2),
                (hw - 3.8, d * 0.62),
                (hw - 1.6, eye - 3.0),          // right side lock
                (hw + 1.0, 13),
            ]
            var sketch: [Sketch] = [.move(cx + edge[0].0, c + edge[0].1)]
            for index in 1..<edge.count {
                let (px, py) = edge[index - 1]
                let (x, y) = edge[index]
                // A slight bow on every lock, all sweeping the same way, so the
                // fringe has a direction instead of a sawtooth.
                sketch.append(.quad(cx + (px + x) / 2 + 0.6, c + (py + y) / 2 - 0.4,
                                    cx + x, c + y))
            }
            sketch += [
                .quad(cx + hw + v * 1.0, c - 1, cx + 9, c - v * 1.5),
                .quad(cx, c - v * 2.0, cx - 8, c - v * 1.5),
                .quad(cx - hw - v * 1.0, c - 1, cx + edge[0].0, c + edge[0].1),
                .close,
            ]
            return sketch
        }

        /// The long front lock that falls over her shoulder to the chest, with a
        /// split end. Authored on the left.
        static func sideLock(_ p: P) -> [Sketch] {
            let hw = p.headWidth / 2, w = p.sideLockWidth
            let top = p.crown + 9
            let end = p.sideLockEnd
            let outer = cx - hw - 3.0
            return [
                .move(cx - hw + 3.0, top),
                .quad(cx - hw - 3.5, top + 14, outer, p.chin - 2),
                .quad(outer - 1.2, p.chin + 16, outer - 2.0, end),
                .line(outer + w * 0.45, end - 9),
                .line(outer + w * 0.70, end - 4),
                .quad(outer + w + 0.6, p.chin + 10, outer + w, p.chin - 4),
                .quad(cx - hw + 2.6, top + 14, cx - hw + 3.0, top),
                .close,
            ]
        }

        static func layers(_ p: P) -> (back: [Layer], front: [Layer]) {
            let hw = p.headWidth / 2
            let c = p.crown
            let bottom = p.hip + 2

            /// One back hair mass: base, its shine, then the tip over the base
            /// with a seam patch so the handoff draws no line at rest.
            func mass(_ s: String, _ base: AnimeGirlArt.Part, _ tip: AnimeGirlArt.Part,
                      _ mirror: Double?) -> [Layer] {
                [
                    Layer(0, "tail\(s)_base", base, Ink.hair, stroke: 2.6,
                          path: tailBase(p).path(mirrorAbout: mirror)),
                    Layer(0, "tailShine\(s)", base, Ink.hairShine, stroke: nil,
                          path: tailShine(p).path(mirrorAbout: mirror)),
                    Layer(0, "tail\(s)_tip", tip, Ink.hair, stroke: 2.6,
                          path: tailTip(p).path(mirrorAbout: mirror)),
                    Layer(0, "tailSeam\(s)", tip, Ink.hair, stroke: nil,
                          path: tailSeam(p).path(mirrorAbout: mirror)),
                ]
            }

            let back: [Layer] = [
                // The curtain behind her back: fills between the two masses so a
                // swing never opens a hole behind the neck.
                Layer(0, "backHair", .head, Ink.hair, stroke: 2.6, path: [
                    .move(cx - hw - 2, c + 12),
                    .quad(cx - hw - 6, c + 50, cx - hw - 4, bottom - 6),
                    .line(cx - 11, bottom),
                    .line(cx - 5, bottom - 6),
                    .line(cx, bottom + 2),
                    .line(cx + 5, bottom - 6),
                    .line(cx + 11, bottom),
                    .line(cx + hw + 4, bottom - 6),
                    .quad(cx + hw + 6, c + 50, cx + hw + 2, c + 12),
                    .quad(cx, c - 4, cx - hw - 2, c + 12),
                    .close,
                ].path()),
            ]
            + mass("L", .tailL_base, .tailL_tip, nil)
            + mass("R", .tailR_base, .tailR_tip, cx)

            let front: [Layer] = [
                Layer(0, "hairCrown", .head, Ink.hair, stroke: 2.6, path: crown(p).path()),
                Layer(0, "sideLockL", .head, Ink.hair, stroke: 2.0, path: sideLock(p).path()),
                Layer(0, "sideLockR", .head, Ink.hair, stroke: 2.0,
                      path: sideLock(p).path(mirrorAbout: cx)),
                Layer(0, "bangs", .head, Ink.hair, stroke: 2.0, path: fringe(p).path()),
                Layer(0, "hairShine", .head, Ink.hairShine, stroke: nil, path: [
                    .move(cx - 12, c - 1),
                    .quad(cx - 2, c - 7.5, cx + 8.5, c - 4.5),
                    .quad(cx + 13, c - 2.5, cx + 14, c + 0.5),
                    .quad(cx + 4, c - 4.5, cx - 8.5, c + 1.5),
                    .quad(cx - 11, c + 0.5, cx - 12, c - 1),
                    .close,
                ].path()),
            ]
            return (back, front)
        }

        // MARK: Horns

        /// Two short red horns on top of her head, slightly curved outward,
        /// spaced apart. Drawn as fixed layers on the head so they never lag it.
        static func horns(_ p: P) -> [Layer] {
            let bx = cx - p.hornGap / 2
            let by = p.crown - p.hairVolume * 1.15
            let h = p.hornHeight
            let horn: [Sketch] = [
                .move(bx - 3.4, by + 2.5),
                .quad(bx - 3.8, by - h * 0.55, bx - 2.6, by - h),
                .quad(bx + 1.2, by - h * 0.55, bx + 3.4, by + 2.5),
                .close,
            ]
            // The inner half in the darker red: one hard cel shadow.
            let shade: [Sketch] = [
                .move(bx - 0.2, by + 2.2),
                .quad(bx - 0.6, by - h * 0.45, bx - 2.6, by - h),
                .quad(bx + 1.2, by - h * 0.55, bx + 3.2, by + 2.2),
                .close,
            ]
            return [
                Layer(0, "hornL", .head, Ink.horn, stroke: 2.0, path: horn.path()),
                Layer(0, "hornShadeL", .head, Ink.hornShade, stroke: nil, path: shade.path()),
                Layer(0, "hornR", .head, Ink.horn, stroke: 2.0,
                      path: horn.path(mirrorAbout: cx)),
                Layer(0, "hornShadeR", .head, Ink.hornShade, stroke: nil,
                      path: shade.path(mirrorAbout: cx)),
            ]
        }

        static func ahogeRoot(_ p: P) -> (x: Double, y: Double) {
            (cx + 3, p.crown - p.hairVolume * 1.75)
        }

        /// One messy lock curling up off the crown and over to the side. The
        /// performances drive it as the emotional lag, so it has to exist. It is
        /// curved and leans sideways so it never reads as a third horn.
        static func ahogeLayer(_ p: P) -> [Layer] {
            let (ax, ay) = ahogeRoot(p)
            return [Layer(0, "ahoge", .ahoge, Ink.hair, stroke: 1.7, path: [
                .move(ax + 2.4, ay + 3),
                .quad(ax + 2.2, ay - 5.0, ax - 5.0, ay - 5.4),
                .quad(ax - 2.0, ay - 3.4, ax - 0.2, ay - 1.4),
                .quad(ax - 1.4, ay + 0.8, ax - 1.8, ay + 3),
                .close,
            ].path())]
        }
    }

    // MARK: - Torso and outfit

    enum Outfit {

        /// The jacket's back, hanging off her upper arms behind the torso. Mostly
        /// hidden at rest; it shows at her sides whenever an arm lifts.
        static func jacketBack(_ p: P) -> [Layer] {
            let top = p.torsoTopWidth / 2, hip = p.hipWidth / 2
            let y = p.shoulder + 10
            // Wider than the hanging arms, so navy shows outside each sleeve down
            // to the hem: that drape is what says "jacket slipped off her
            // shoulders" rather than "navy gloves".
            let out = hip + 12
            return [Layer(0, "jacketBack", .torso, Ink.navyDeep, stroke: 2.6, path: [
                .move(cx - top - 7, y),
                .line(cx + top + 7, y),
                .quad(cx + out - 1, p.waist - 6, cx + out, p.jacketHem + 1),
                .line(cx + out - 6, p.jacketHem + 3),
                .line(cx - out + 6, p.jacketHem + 3),
                .line(cx - out, p.jacketHem + 1),
                .quad(cx - out + 1, p.waist - 6, cx - top - 7, y),
                .close,
            ].path())]
        }

        /// The loose cream shirt, tucked in at the waist.
        static func shirt(_ p: P) -> [Layer] {
            let top = p.torsoTopWidth / 2
            let rib = p.ribWidth / 2
            let waist = p.waistWidth / 2
            let s = p.shoulder
            let ribY = s + 17
            let body: [Sketch] = [
                .move(cx - 4.6, s - 3.2),
                .quad(cx - top + 4, s - 2.8, cx - top - 1.5, s + 2),
                .quad(cx - rib - 1.8, s + 8, cx - rib - 1.2, ribY),
                .quad(cx - rib - 0.6, p.waist - 7, cx - waist - 2.0, p.waist + 1),
                .line(m(cx - waist - 2.0), p.waist + 1),
                .quad(m(cx - rib - 0.6), p.waist - 7, m(cx - rib - 1.2), ribY),
                .quad(m(cx - rib - 1.8), s + 8, m(cx - top - 1.5), s + 2),
                .quad(m(cx - top + 4), s - 2.8, m(cx - 4.6), s - 3.2),
                .close,
            ]
            let shade: [Sketch] = [
                .move(cx + 9, s + 5),
                .quad(cx + rib - 1, s + 6, cx + rib + 1.2, s + 12),
                .quad(m(cx - rib - 0.6), p.waist - 7, m(cx - waist - 2.0), p.waist + 1),
                .line(cx + 8, p.waist + 1),
                .quad(cx + 11, ribY, cx + 9, s + 5),
                .close,
            ]
            // The blouse where it is tucked: two short folds just above the waist.
            let folds: [Sketch] = [
                .move(cx - waist + 1.5, p.waist - 4), .quad(cx - waist + 3, p.waist - 1,
                                                            cx - waist + 2.5, p.waist + 0.5),
                .move(m(cx - waist + 2.5), p.waist - 5), .quad(m(cx - waist + 4), p.waist - 2,
                                                               m(cx - waist + 3.5), p.waist + 0.5),
            ]
            let collar: [Sketch] = [
                .move(cx - 5.2, s - 3.4),
                .line(cx - 0.4, s + 1.4),
                .line(cx - 2.6, s + 6.6),
                .line(cx - 7.6, s + 1.4),
                .close,
            ]
            // A thin black tie, knot pulled a little loose and to one side.
            let tie: [Sketch] = [
                .move(cx - 1.9, s + 0.6),
                .line(cx + 2.1, s + 0.6),
                .line(cx + 1.3, s + 4.0),
                .line(cx + 1.9, p.waist - 8),
                .line(cx + 0.4, p.waist - 4.5),
                .line(cx - 1.0, p.waist - 8),
                .line(cx - 0.7, s + 4.0),
                .close,
            ]

            return [
                Layer(0, "shirt", .torso, Ink.shirt, stroke: 2.6, path: body.path()),
                Layer(0, "shirtShade", .torso, Ink.shirtShade, stroke: nil, path: shade.path()),
                Layer(0, "shirtFolds", .torso, Ink.clear, stroke: 0.9, path: folds.path()),
                Layer(0, "tie", .torso, Ink.tie, stroke: 1.2, path: tie.path()),
                Layer(0, "collar", .torso, Ink.shirt, stroke: 1.5, path: both(collar)),
            ]
        }

        /// The black slacks' seat, drawn over the shirt's tuck and the thigh tops.
        static func seat(_ p: P) -> [Layer] {
            let waist = p.waistWidth / 2, hip = p.hipWidth / 2
            return [
                Layer(0, "slacksSeat", .hips, Ink.slacks, stroke: 2.6, path: [
                    .move(cx - waist - 0.8, p.waist - 1),
                    .line(cx + waist + 0.8, p.waist - 1),
                    .quad(cx + hip + 0.6, p.waist + 7, cx + hip + 0.6, p.hip + 4),
                    .quad(cx + 4, p.hip + 8, cx, p.hip + 5),
                    .quad(cx - 4, p.hip + 8, cx - hip - 0.6, p.hip + 4),
                    .quad(cx - hip - 0.6, p.waist + 7, cx - waist - 0.8, p.waist - 1),
                    .close,
                ].path()),
                Layer(0, "belt", .hips, Ink.belt, stroke: nil, path: [
                    .move(cx - waist - 0.6, p.waist - 0.4),
                    .line(cx + waist + 0.6, p.waist - 0.4),
                    .line(cx + waist + 1.0, p.waist + 2.4),
                    .line(cx - waist - 1.0, p.waist + 2.4),
                    .close,
                ].path()),
            ]
        }

        /// The open jacket's two front panels, hanging at her sides from where it
        /// slipped off her shoulders down past her hips.
        static func jacketFront(_ p: P) -> [Layer] {
            let rib = p.ribWidth / 2, hip = p.hipWidth / 2
            let s = p.shoulder
            let panel: [Sketch] = [
                .move(cx - rib - 2.5, s + 10),
                .quad(cx - rib + 4, s + 11, cx - 9.5, s + 25),
                .quad(cx - 10.5, p.waist, cx - 11.5, p.jacketHem),
                .line(cx - hip - 4.5, p.jacketHem + 0.5),
                .quad(cx - hip - 4, p.hip - 12, cx - rib - 2.5, s + 10),
                .close,
            ]
            // The lapel's fold, a darker band along the open edge.
            let lapel: [Sketch] = [
                .move(cx - rib + 1.5, s + 11.5),
                .quad(cx - rib + 4.5, s + 12.5, cx - 9.5, s + 25),
                .quad(cx - 10.3, s + 31, cx - 10.6, s + 36),
                .line(cx - 13.6, s + 30),
                .quad(cx - 14.5, s + 18, cx - rib + 1.5, s + 11.5),
                .close,
            ]
            return [
                Layer(0, "jacketFront", .torso, Ink.navy, stroke: 2.4, path: both(panel)),
                Layer(0, "jacketLapel", .torso, Ink.navyDeep, stroke: nil, path: both(lapel)),
            ]
        }
    }

    // MARK: - Limbs

    enum Limbs {
        /// Left shoulder joint.
        static func shoulder(_ p: P) -> (x: Double, y: Double) {
            (cx - p.torsoTopWidth / 2 - p.deltoid + p.upperArmWidth / 2, p.shoulder + 4)
        }

        /// Centre of the left leg.
        static func legCentre(_ p: P) -> Double { cx - p.hipWidth * 0.23 }

        // MARK: Hands

        /// Relaxed open hand, hanging along the forearm: a mitten with the thumb
        /// on the body side.
        static func openHand(_ sx: Double, _ w: Double) -> [Sketch] {
            [
                .move(sx - 3.2, w),
                .quad(sx - 4.4, w + 6.0, sx - 2.8, w + 11.0),
                .quad(sx - 0.2, w + 13.2, sx + 2.4, w + 11.2),
                .quad(sx + 3.0, w + 9.5, sx + 3.0, w + 7.5),
                .quad(sx + 5.4, w + 6.0, sx + 4.4, w + 3.6),
                .quad(sx + 3.6, w + 1.2, sx + 3.0, w),
                .quad(sx, w - 1.6, sx - 3.2, w),
                .close,
            ]
        }

        /// The clawed hand: fingers spread and hooked, tips sharp. Built as
        /// separate fingers under a palm, so the palm's outline reads as knuckles.
        static func clawFingers(_ sx: Double, _ w: Double) -> [Sketch] {
            let cy = w + 5.4
            // (angle from straight down in degrees, length). Spread wide so the
            // gaps between fingers survive the downscale to 70pt.
            let fingers: [(Double, Double)] = [(-62, 8.6), (-24, 10.2), (14, 10.0), (50, 8.4)]
            var sketch: [Sketch] = []
            for (angle, length) in fingers {
                let a = angle * .pi / 180
                // Direction along the finger (screen y down) and across it.
                let dx = sin(a), dy = cos(a)
                let px = cos(a), py = -sin(a)
                let base = 3.4, half = 1.9
                let bx = sx + dx * base, by = cy + dy * base
                let reach = base + length
                // The hook: the tip curls back toward the hand's centre line.
                let curl = angle < 0 ? 1.0 : -1.0
                let tx = sx + dx * reach + px * curl * 1.8
                let ty = cy + dy * reach + py * curl * 1.8
                let mx = sx + dx * (base + length * 0.6), my = cy + dy * (base + length * 0.6)
                sketch += [
                    .move(bx - px * half, by - py * half),
                    .quad(mx - px * half * 1.3, my - py * half * 1.3, tx, ty),
                    .quad(mx + px * half * 0.6, my + py * half * 0.6,
                          bx + px * half, by + py * half),
                    .close,
                ]
            }
            // Thumb, hooked out toward the body.
            sketch += [
                .move(sx + 2.4, cy - 3.4),
                .quad(sx + 8.6, cy - 4.0, sx + 9.6, cy + 1.6),
                .quad(sx + 6.6, cy + 0.4, sx + 2.6, cy + 2.0),
                .close,
            ]
            return sketch
        }

        static func clawPalm(_ sx: Double, _ w: Double) -> [Sketch] {
            circle(sx + 0.2, w + 5.0, 4.5)
        }

        static func fist(_ sx: Double, _ w: Double) -> [Sketch] {
            [
                .move(sx - 4.4, w + 1),
                .quad(sx - 6.2, w + 6.5, sx - 4.2, w + 11),
                .quad(sx, w + 13.6, sx + 4.2, w + 11),
                .quad(sx + 6.2, w + 6.5, sx + 4.4, w + 1),
                .quad(sx, w - 1.6, sx - 4.4, w + 1),
                .close,
            ]
        }

        static func fistCreases(_ sx: Double, _ w: Double) -> [Sketch] {
            [
                .move(sx - 3.8, w + 6.2), .line(sx + 3.8, w + 6.2),
                .move(sx - 3.4, w + 9.4), .line(sx + 3.4, w + 9.4),
            ]
        }

        // MARK: Arms

        /// Shirt sleeve on the upper arm, the jacket slipped down over it, and the
        /// jacket's loose sleeve hanging over the forearm past the wrist.
        static func arm(_ p: P) -> [Layer] {
            let (sx, sy) = shoulder(p)
            let sw = p.sleeveWidth
            let w = p.wrist

            // Shirt sleeve: the round top is centred on the shoulder pivot.
            let shirtSleeve = capsule(sx, sy, p.elbow + 1, p.upperArmWidth + 1.6,
                                      p.upperArmWidth + 0.4)
            // The jacket where it has slipped to: a slanted top edge, loose below.
            let jacketUpper: [Sketch] = [
                .move(sx - sw / 2 - 0.4, sy + 8),
                .quad(sx, sy + 9, sx + sw / 2 - 0.2, sy + 13),
                .line(sx + sw / 2, p.elbow + 1),
                .line(sx - sw / 2, p.elbow + 1),
                .close,
            ]
            // Forearm sleeve: round top centred on the elbow (the elbow cap), then
            // widening into a loose cuff that hangs past the wrist.
            let foreSleeve: [Sketch] = {
                let a = sw / 2, k = 0.552, e = p.elbow
                let cuffY = w + 4.5
                return [
                    .move(sx - a, e),
                    .quad(sx - a - 0.6, (e + cuffY) / 2, sx - a - 1.6, cuffY - 0.6),
                    .quad(sx - 1, cuffY + 2.2, sx + a + 1.6, cuffY + 0.4),
                    .quad(sx + a + 0.6, (e + cuffY) / 2, sx + a, e),
                    .curve(sx + a, e - a * k, sx + a * k, e - a, sx, e - a),
                    .curve(sx - a * k, e - a, sx - a, e - a * k, sx - a, e),
                    .close,
                ]
            }()
            let foreShade: [Sketch] = [
                .move(sx + sw / 2 - 2.6, p.elbow + 2),
                .quad(sx + sw / 2 - 1.8, (p.elbow + w) / 2, sx + sw / 2 - 0.8, w + 3.6),
                .line(sx + sw / 2 + 1.0, w + 4.2),
                .quad(sx + sw / 2 + 0.4, (p.elbow + w) / 2, sx + sw / 2 - 0.2, p.elbow + 2),
                .close,
            ]

            func side(_ s: String, _ upper: AnimeGirlArt.Part, _ fore: AnimeGirlArt.Part,
                      _ mirror: Double?) -> [Layer] {
                [
                    Layer(0, "shirtSleeve\(s)", upper, Ink.shirt, stroke: 2.6,
                          path: shirtSleeve.path(mirrorAbout: mirror)),
                    Layer(0, "jacketUpper\(s)", upper, Ink.navy, stroke: 2.4,
                          path: jacketUpper.path(mirrorAbout: mirror)),
                    Layer(0, "jacketSleeve\(s)", fore, Ink.navy, stroke: 2.4,
                          path: foreSleeve.path(mirrorAbout: mirror)),
                    // Fill-only cap over the elbow: hides the seam where the
                    // forearm sleeve overlaps the upper one, at any bend.
                    Layer(0, "elbowCap\(s)", fore, Ink.navy, stroke: nil,
                          path: circle(sx, p.elbow, sw / 2 - 1.3).path(mirrorAbout: mirror)),
                    Layer(0, "jacketSleeveShade\(s)", fore, Ink.navyDeep, stroke: nil,
                          path: foreShade.path(mirrorAbout: mirror)),
                    Layer(0, "hand.open.\(s)", fore, Ink.skin, stroke: 1.7,
                          path: openHand(sx, w).path(mirrorAbout: mirror)),
                    Layer(0, "hand.claw.\(s).fingers", fore, Ink.skin, stroke: 1.5,
                          path: clawFingers(sx, w).path(mirrorAbout: mirror), restOpacity: 0),
                    Layer(0, "hand.claw.\(s).palm", fore, Ink.skin, stroke: 1.5,
                          path: clawPalm(sx, w).path(mirrorAbout: mirror), restOpacity: 0),
                    Layer(0, "hand.fist.\(s)", fore, Ink.skin, stroke: 1.9,
                          path: fist(sx, w).path(mirrorAbout: mirror), restOpacity: 0),
                    Layer(0, "hand.fist.\(s).creases", fore, Ink.clear, stroke: 1.1,
                          path: fistCreases(sx, w).path(mirrorAbout: mirror), restOpacity: 0),
                ]
            }
            return side("L", .armL, .armL_fore, nil) + side("R", .armR, .armR_fore, cx)
        }

        // MARK: Legs

        /// Black slacks to a rolled cuff at mid-calf, bare shins, white high-tops
        /// with red soles and laces. Thigh and shin are separate joints, each
        /// topped with a round cap centred on its pivot.
        static func legs(_ p: P) -> [Layer] {
            let lx = legCentre(p)
            let cw = p.calfWidth
            let fw = p.shoeWidth / 2

            let thigh = capsule(lx, p.hip + 2, p.knee + 1, p.thighWidth, cw, bow: 0.4)
            let shin = capsule(lx, p.knee, p.cuff - 2, cw, cw - 0.4)
            let cuffBand: [Sketch] = [
                .move(lx - cw / 2 - 1.0, p.cuff - 5),
                .line(lx + cw / 2 + 1.0, p.cuff - 5),
                .line(lx + cw / 2 + 1.2, p.cuff),
                .line(lx - cw / 2 - 1.2, p.cuff),
                .close,
            ]
            let cuffFolds: [Sketch] = {
                let count = max(1, p.pleats) - 1
                guard count > 0 else {
                    return [.move(lx - cw / 2, p.cuff - 2.5), .line(lx + cw / 2, p.cuff - 2.5)]
                }
                return (1...count).flatMap { index -> [Sketch] in
                    let y = p.cuff - 5 + 5 * Double(index) / Double(count + 1)
                    return [.move(lx - cw / 2 - 0.4, y), .line(lx + cw / 2 + 0.4, y)]
                }
            }()
            // Bare shin between the cuff and the sneaker. Symmetric, so the right
            // one is the same taper about the mirrored centre.
            func calf(_ x: Double) -> Path {
                Path.taper(cx: x, top: p.cuff - 3, bottom: p.shoeTop + 3,
                           topWidth: 6.2, bottomWidth: 5.0)
            }
            // Front view of a high-top, toe turned slightly out.
            let shoe: [Sketch] = [
                .move(lx - 4.0, p.shoeTop),
                .line(lx + 4.0, p.shoeTop),
                .quad(lx + 4.6, p.sole - 9, lx + fw - 0.2, p.sole - 3),
                .line(lx + fw - 0.4, p.sole - 1.5),
                .line(lx - fw - 1.4, p.sole - 1.5),
                .quad(lx - fw - 1.8, p.sole - 5, lx - 4.6, p.sole - 9),
                .line(lx - 4.0, p.shoeTop),
                .close,
            ]
            let sole: [Sketch] = [
                .move(lx - fw - 2.0, p.sole - 3.2),
                .line(lx + fw + 0.4, p.sole - 3.2),
                .quad(lx + fw + 0.8, p.sole, lx + fw - 0.4, p.sole),
                .line(lx - fw - 1.0, p.sole),
                .quad(lx - fw - 2.4, p.sole, lx - fw - 2.0, p.sole - 3.2),
                .close,
            ]
            let laces: [Sketch] = [
                .move(lx - 1.6, p.shoeTop + 1.5),
                .line(lx + 1.4, p.shoeTop + 1.5),
                .line(lx + 0.4, p.sole - 6),
                .line(lx - 2.4, p.sole - 6),
                .close,
            ]

            func side(_ s: String, _ thighPart: AnimeGirlArt.Part,
                      _ shinPart: AnimeGirlArt.Part, _ mirror: Double?) -> [Layer] {
                [
                    Layer(0, "calf\(s)", shinPart, Ink.skin, stroke: 2.4,
                          path: calf(mirror == nil ? lx : m(lx))),
                    Layer(0, "shoe\(s)", shinPart, Ink.white, stroke: 2.2,
                          path: shoe.path(mirrorAbout: mirror)),
                    Layer(0, "shoeLaces\(s)", shinPart, Ink.horn, stroke: nil,
                          path: laces.path(mirrorAbout: mirror)),
                    Layer(0, "shoeSole\(s)", shinPart, Ink.horn, stroke: 1.8,
                          path: sole.path(mirrorAbout: mirror)),
                    Layer(0, "thigh\(s)", thighPart, Ink.slacks, stroke: 2.6,
                          path: thigh.path(mirrorAbout: mirror)),
                    Layer(0, "shin\(s)", shinPart, Ink.slacks, stroke: 2.6,
                          path: shin.path(mirrorAbout: mirror)),
                    // Fill-only knee cap: hides the thigh/shin seam at any bend.
                    Layer(0, "kneeCap\(s)", shinPart, Ink.slacks, stroke: nil,
                          path: circle(lx, p.knee, cw / 2 - 1.3).path(mirrorAbout: mirror)),
                    Layer(0, "cuff\(s)", shinPart, Ink.slacksRoll, stroke: 2.2,
                          path: cuffBand.path(mirrorAbout: mirror)),
                    Layer(0, "cuffFolds\(s)", shinPart, Ink.clear, stroke: 0.8,
                          path: cuffFolds.path(mirrorAbout: mirror)),
                ]
            }
            return side("L", .legL, .shinL, nil) + side("R", .legR, .shinR, cx)
        }
    }

    // MARK: - Sparkles

    /// Pop marks for the celebration. All three sit high and wide so an orbit
    /// about the sparkle pivot never sweeps across the body.
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
                Layer(0, "sparkleB", .sparkles, Ink.horn, stroke: nil,
                      path: star(56, 20, 6), restOpacity: 0),
                Layer(0, "sparkleC", .sparkles, Ink.white, stroke: nil,
                      path: star(150, 26, 5), restOpacity: 0),
            ]
        }
    }
}

extension Array where Element == Sketch {
    /// An axis-aligned ellipse as sketch segments, so it can be mirrored.
    static func ellipse(_ x: Double, _ y: Double, _ rx: Double, _ ry: Double) -> [Sketch] {
        let kx = 0.552 * rx, ky = 0.552 * ry
        return [
            .move(x + rx, y),
            .curve(x + rx, y + ky, x + kx, y + ry, x, y + ry),
            .curve(x - kx, y + ry, x - rx, y + ky, x - rx, y),
            .curve(x - rx, y - ky, x - kx, y - ry, x, y - ry),
            .curve(x + kx, y - ry, x + rx, y - ky, x + rx, y),
            .close,
        ]
    }
}
