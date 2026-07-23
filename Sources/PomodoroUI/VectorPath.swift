import CoreGraphics
import SwiftUI

/// Parses the SVG-style path data the art direction is written in.
///
/// The alternative — hand-converting sixty paths into `move(to:)` / `addCurve(to:)`
/// calls — puts a transcription error behind every one of several hundred numbers.
/// Keeping the spec's own strings verbatim means the source can be diffed against
/// the design doc by eye, and only this one small parser has to be correct.
///
/// Absolute commands only, which is all the spec uses: `M` move, `L` line,
/// `Q` quadratic, `C` cubic, `Z` close.
public enum VectorPath {

    public static func parse(_ data: String) -> Path {
        var path = Path()
        var numbers: [CGFloat] = []
        var command: Character = "M"
        var start = CGPoint.zero
        var current = CGPoint.zero

        func flush() {
            guard !numbers.isEmpty || command == "Z" else { return }
            switch command {
            case "M":
                // Extra coordinate pairs after an M are implicit line-tos, per SVG.
                for pair in stride(from: 0, to: numbers.count - 1, by: 2) {
                    let point = CGPoint(x: numbers[pair], y: numbers[pair + 1])
                    if pair == 0 {
                        path.move(to: point)
                        start = point
                    } else {
                        path.addLine(to: point)
                    }
                    current = point
                }
            case "L":
                for pair in stride(from: 0, to: numbers.count - 1, by: 2) {
                    let point = CGPoint(x: numbers[pair], y: numbers[pair + 1])
                    path.addLine(to: point)
                    current = point
                }
            case "Q":
                for set in stride(from: 0, to: numbers.count - 3, by: 4) {
                    let control = CGPoint(x: numbers[set], y: numbers[set + 1])
                    let end = CGPoint(x: numbers[set + 2], y: numbers[set + 3])
                    path.addQuadCurve(to: end, control: control)
                    current = end
                }
            case "C":
                for set in stride(from: 0, to: numbers.count - 5, by: 6) {
                    let c1 = CGPoint(x: numbers[set], y: numbers[set + 1])
                    let c2 = CGPoint(x: numbers[set + 2], y: numbers[set + 3])
                    let end = CGPoint(x: numbers[set + 4], y: numbers[set + 5])
                    path.addCurve(to: end, control1: c1, control2: c2)
                    current = end
                }
            case "Z":
                path.closeSubpath()
                current = start
            default:
                break
            }
            numbers.removeAll(keepingCapacity: true)
        }

        var token = ""
        func takeNumber() {
            guard !token.isEmpty else { return }
            if let value = Double(token) { numbers.append(CGFloat(value)) }
            token.removeAll(keepingCapacity: true)
        }

        for character in data {
            switch character {
            case "M", "L", "Q", "C", "Z", "m", "l", "q", "c", "z":
                takeNumber()
                flush()
                command = Character(character.uppercased())
                if command == "Z" { flush() }
            case " ", ",", "\n", "\t":
                takeNumber()
            case "-":
                // A minus starts a new number unless it follows an exponent marker.
                if !token.isEmpty, !token.hasSuffix("e"), !token.hasSuffix("E") {
                    takeNumber()
                }
                token.append(character)
            default:
                token.append(character)
            }
        }
        takeNumber()
        flush()

        _ = current
        return path
    }

    /// The spec expresses genuinely circular details as "Circle centred (x, y) r=n".
    public static func circle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
    }

    /// Two subpaths drawn in one pass, as the spec's paired details specify.
    public static func combined(_ parts: [Path]) -> Path {
        var path = Path()
        for part in parts { path.addPath(part) }
        return path
    }
}
