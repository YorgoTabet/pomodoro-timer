import CoreGraphics
import SwiftUI
import Testing
@testable import PomodoroUI

/// The parser is load-bearing: all 60 samurai paths are stored as spec strings and
/// go through it. A silent misparse would be a subtly wrong drawing rather than a
/// crash, so these assert structure element by element rather than eyeballing a
/// bounding box.
@Suite("VectorPath")
struct VectorPathTests {

    /// Flattens a `Path` into a comparable list of commands and points.
    private func elements(_ path: Path) -> [String] {
        var out: [String] = []
        path.forEach { element in
            switch element {
            case .move(let to):
                out.append("M \(fmt(to))")
            case .line(let to):
                out.append("L \(fmt(to))")
            case .quadCurve(let to, let control):
                out.append("Q \(fmt(control)) \(fmt(to))")
            case .curve(let to, let control1, let control2):
                out.append("C \(fmt(control1)) \(fmt(control2)) \(fmt(to))")
            case .closeSubpath:
                out.append("Z")
            }
        }
        return out
    }

    private func fmt(_ p: CGPoint) -> String {
        "\(Int(p.x.rounded()))/\(Int(p.y.rounded()))"
    }

    @Test("Move and line")
    func moveAndLine() {
        let path = VectorPath.parse("M 10 20 L 30 40 Z")
        #expect(elements(path) == ["M 10/20", "L 30/40", "Z"])
    }

    @Test("Quadratic curves keep control and end points in the right order")
    func quadCurve() {
        // SVG orders the control point first, SwiftUI's API takes the end point
        // first — an easy place to silently swap them.
        let path = VectorPath.parse("M 0 0 Q 5 10 20 0")
        #expect(elements(path) == ["M 0/0", "Q 5/10 20/0"])
    }

    @Test("Cubic curves take both controls then the end point")
    func cubicCurve() {
        let path = VectorPath.parse("M 0 0 C 2 8 14 8 16 0")
        #expect(elements(path) == ["M 0/0", "C 2/8 14/8 16/0"])
    }

    @Test("Decimals and negative numbers survive")
    func numbers() {
        let path = VectorPath.parse("M -4.5 12.25 L 8.75 -3.5")
        var points: [CGPoint] = []
        path.forEach { element in
            if case .move(let p) = element { points.append(p) }
            if case .line(let p) = element { points.append(p) }
        }
        #expect(points.count == 2)
        #expect(points[0].x == -4.5)
        #expect(points[0].y == 12.25)
        #expect(points[1].x == 8.75)
        #expect(points[1].y == -3.5)
    }

    @Test("A minus sign separates numbers even without whitespace")
    func negativesWithoutSpaces() {
        let path = VectorPath.parse("M 0 0 L-10-20")
        #expect(elements(path) == ["M 0/0", "L -10/-20"])
    }

    @Test("Commas are separators, like whitespace")
    func commas() {
        #expect(elements(VectorPath.parse("M 1,2 L 3,4")) == elements(VectorPath.parse("M 1 2 L 3 4")))
    }

    @Test("Repeated coordinate pairs continue the same command")
    func repeatedPairs() {
        let path = VectorPath.parse("M 0 0 L 10 0 20 0")
        #expect(elements(path) == ["M 0/0", "L 10/0", "L 20/0"])
    }

    @Test("Extra pairs after a move become implicit lines, per SVG")
    func implicitLineAfterMove() {
        let path = VectorPath.parse("M 0 0 5 5")
        #expect(elements(path) == ["M 0/0", "L 5/5"])
    }

    @Test("Multiple subpaths in one string, as the paired details use")
    func multipleSubpaths() {
        let path = VectorPath.parse("M 0 0 L 5 0 Z M 10 0 L 15 0 Z")
        #expect(elements(path) == ["M 0/0", "L 5/0", "Z", "M 10/0", "L 15/0", "Z"])
    }

    @Test("Empty and malformed input yields an empty path rather than crashing")
    func malformed() {
        #expect(VectorPath.parse("").isEmpty)
        #expect(VectorPath.parse("   ").isEmpty)
        // A command with too few numbers contributes nothing rather than trapping.
        #expect(elements(VectorPath.parse("M 5 5 Q 1 2 3")) == ["M 5/5"])
    }

    @Test("Circles are centred on the given point with the given radius")
    func circle() {
        let path = VectorPath.circle(50, 30, 10)
        let box = path.boundingRect
        #expect(box.midX == 50)
        #expect(box.midY == 30)
        #expect(box.width == 20)
        #expect(box.height == 20)
    }

    @Test("Combining paths preserves every subpath")
    func combined() {
        let path = VectorPath.combined([
            VectorPath.circle(10, 10, 5),
            VectorPath.circle(90, 10, 5),
        ])
        #expect(path.boundingRect.minX == 5)
        #expect(path.boundingRect.maxX == 95)
    }
}

/// Guards the transcription itself: sixty hand-copied paths is exactly where a
/// truncated string or dropped command hides.
@Suite("SamuraiArt")
struct SamuraiArtTests {

    @Test("Every layer parsed to a non-empty path")
    func noEmptyLayers() {
        for layer in SamuraiArt.layers {
            #expect(!layer.path.isEmpty, "\(layer.name) (#\(layer.id)) parsed to nothing")
        }
    }

    @Test("The full set is present and numbered without gaps")
    func layerCount() {
        #expect(SamuraiArt.layers.count == 68)
        #expect(SamuraiArt.layers.map(\.id) == Array(1...68))
    }

    @Test("Every layer sits inside the design canvas, allowing for the blade's reach")
    func withinCanvas() {
        for layer in SamuraiArt.layers {
            let box = layer.path.boundingRect
            // The spec allows the blade and crest to travel outside during
            // animation, but at rest everything should be on or near the canvas.
            #expect(box.minX >= -5, "\(layer.name) starts left of the canvas at \(box.minX)")
            #expect(box.minY >= -5, "\(layer.name) starts above the canvas at \(box.minY)")
            #expect(box.maxX <= 205, "\(layer.name) runs past the right edge to \(box.maxX)")
            #expect(box.maxY <= 265, "\(layer.name) runs past the bottom to \(box.maxY)")
        }
    }

    @Test("Every rig part's ancestor chain terminates at root")
    func rigChainsTerminate() {
        for part in SamuraiArt.Part.allCases {
            #expect(part.chain.first == .root, "\(part.rawValue) does not descend from root")
            #expect(part.chain.count <= 5, "\(part.rawValue) chain is suspiciously deep")
        }
    }

    @Test("Pivots convert to anchors inside the unit square")
    func anchorsInRange() {
        for part in SamuraiArt.Part.allCases {
            let anchor = part.anchor
            #expect(anchor.x >= 0 && anchor.x <= 1, "\(part.rawValue) anchor.x = \(anchor.x)")
            #expect(anchor.y >= 0 && anchor.y <= 1, "\(part.rawValue) anchor.y = \(anchor.y)")
        }
    }

    @Test("Every layer's rig part is one the pose can drive")
    func posesCoverEveryPart() {
        let pose = SamuraiPose()
        for part in Set(SamuraiArt.layers.map(\.part)) {
            // Reaching every part without trapping proves the switch is exhaustive
            // in practice, not just at compile time.
            _ = pose.rotation(of: part)
        }
    }
}
