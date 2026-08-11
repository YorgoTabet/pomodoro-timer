import CoreGraphics
import SwiftUI

/// A path described as data, so it can be transformed before it is drawn.
///
/// The character art is authored as SVG-ish strings, which is right for
/// transcribing a spec by eye but useless once shapes are *generated*: you
/// cannot mirror a string, and every left/right pair in the old anime girl was a
/// hand-mirrored duplicate that could drift from its twin (and did — her two
/// hands were 0.4 units apart in x for no reason).
///
/// Authoring one side and calling `mirrored` makes that class of bug impossible.
public enum Sketch {
    case move(Double, Double)
    case line(Double, Double)
    /// Control point, then end point.
    case quad(Double, Double, Double, Double)
    case curve(Double, Double, Double, Double, Double, Double)
    case close
}

public extension Array where Element == Sketch {

    /// - Parameter mirrorAbout: reflect every x through this axis. Pass the
    ///   canvas midline to turn a left-side part into its right-side twin.
    func path(mirrorAbout axis: Double? = nil) -> Path {
        var path = Path()
        func x(_ value: Double) -> CGFloat {
            guard let axis else { return value }
            return axis * 2 - value
        }
        for segment in self {
            switch segment {
            case let .move(px, py):
                path.move(to: CGPoint(x: x(px), y: py))
            case let .line(px, py):
                path.addLine(to: CGPoint(x: x(px), y: py))
            case let .quad(cx, cy, px, py):
                path.addQuadCurve(to: CGPoint(x: x(px), y: py),
                                  control: CGPoint(x: x(cx), y: cy))
            case let .curve(c1x, c1y, c2x, c2y, px, py):
                path.addCurve(to: CGPoint(x: x(px), y: py),
                              control1: CGPoint(x: x(c1x), y: c1y),
                              control2: CGPoint(x: x(c2x), y: c2y))
            case .close:
                path.closeSubpath()
            }
        }
        return path
    }
}

public extension Path {

    /// An axis-aligned ellipse, the workhorse for irises, pupils and highlights.
    static func oval(_ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double) -> Path {
        Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
    }

    /// A limb segment: a quadrilateral that tapers from `topWidth` to
    /// `bottomWidth`, with the sides bowed out by `bow` so it reads as a limb
    /// rather than a stick.
    static func taper(cx: Double, top: Double, bottom: Double,
                      topWidth: Double, bottomWidth: Double, bow: Double = 0) -> Path {
        let ht = topWidth / 2, hb = bottomWidth / 2
        let mid = (top + bottom) / 2
        let hm = (ht + hb) / 2 + bow
        return [
            .move(cx - ht, top),
            .quad(cx - hm, mid, cx - hb, bottom),
            .line(cx + hb, bottom),
            .quad(cx + hm, mid, cx + ht, top),
            .close,
        ].path()
    }
}
