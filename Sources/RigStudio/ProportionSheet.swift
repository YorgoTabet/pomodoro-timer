import AppKit
import PomodoroUI
import SwiftUI

/// Renders the anime girl across a sweep of one proportion at a time.
///
/// `swift run RigStudio --proportions <dir>`
///
/// The point of generating the figure from `AnimeGirlProportions` is that a dial
/// can be *checked* rather than argued about. Each row here holds every value
/// fixed but one and steps it across its useful range, so "is 0.195 the right
/// eye ratio" becomes something you look at instead of something you reason
/// about from a number — which is exactly the mistake that produced a face that
/// measured correctly and looked gaunt.
@MainActor
enum ProportionSheet {

    /// One dial, its label, and the values to step through.
    struct Sweep {
        let name: String
        let values: [String]
        let apply: (Int, inout AnimeGirlProportions) -> Void
    }

    static let sweeps: [Sweep] = [
        Sweep(name: "chinTaper", values: ["0.0", "0.4", "0.7", "1.0"]) { step, p in
            p.chinTaper = [0.0, 0.4, 0.7, 1.0][step]
        },
        Sweep(name: "eyeHeightRatio", values: ["0.14", "0.17", "0.195", "0.24"]) { step, p in
            p.eyeHeightRatio = [0.14, 0.17, 0.195, 0.24][step]
        },
        Sweep(name: "headWidth", values: ["24", "28", "32", "36"]) { step, p in
            p.headWidth = [24, 28, 32, 36][step]
        },
        Sweep(name: "deltoid (shoulders)", values: ["1", "5", "8", "12"]) { step, p in
            p.deltoid = [1, 5, 8, 12][step]
        },
        Sweep(name: "waistWidth", values: ["25", "31", "35", "39"]) { step, p in
            p.waistWidth = [25, 31, 35, 39][step]
        },
        Sweep(name: "hairVolume", values: ["2", "6", "10", "14"]) { step, p in
            p.hairVolume = [2, 6, 10, 14][step]
        },
        Sweep(name: "tailWidth", values: ["6", "12", "18", "24"]) { step, p in
            p.tailWidth = [6, 12, 18, 24][step]
        },
        Sweep(name: "tailCurl", values: ["0.0", "0.45", "0.9", "1.4"]) { step, p in
            p.tailCurl = [0.0, 0.45, 0.9, 1.4][step]
        },
        Sweep(name: "fringeDepth", values: ["0.2", "0.45", "0.62", "0.9"]) { step, p in
            p.fringeDepth = [0.2, 0.45, 0.62, 0.9][step]
        },
        Sweep(name: "pleats", values: ["2", "3", "4", "6"]) { step, p in
            p.pleats = [2, 3, 4, 6][step]
        },
    ]

    static func render(into directory: String) {
        let url = URL(fileURLWithPath: directory, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)

        let renderer = ImageRenderer(content: Sheet())
        renderer.scale = 1
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:])
        else {
            FileHandle.standardError.write(Data("could not render proportion sheet\n".utf8))
            return
        }
        let file = url.appendingPathComponent("proportions.png")
        try? png.write(to: file)
        print("wrote \(file.path)")
    }

    struct Sheet: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(sweeps.enumerated()), id: \.offset) { _, sweep in
                    row(sweep)
                }
            }
            .padding(8)
            .background(Color(white: 0.5))
        }

        private func row(_ sweep: Sweep) -> some View {
            HStack(spacing: 3) {
                Text(sweep.name)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                    .frame(width: 150, alignment: .leading)
                ForEach(Array(sweep.values.enumerated()), id: \.offset) { step, label in
                    cell(sweep, step, label)
                }
            }
        }

        private func cell(_ sweep: Sweep, _ step: Int, _ label: String) -> some View {
            var proportions = AnimeGirlArt.shape
            sweep.apply(step, &proportions)
            var pose = AnimeGirlPose()
            pose.emergence = 0

            return VStack(spacing: 1) {
                Text(label)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white)
                AnimeGirlView(pose: pose, layers: AnimeGirlArt.build(proportions))
                    .frame(width: AnimeGirlArt.canvas.width,
                           height: AnimeGirlArt.canvas.height, alignment: .topLeading)
                    .scaleEffect(0.62, anchor: .topLeading)
                    .frame(width: AnimeGirlArt.canvas.width * 0.62,
                           height: AnimeGirlArt.canvas.height * 0.62, alignment: .topLeading)
                    .background(Color.white)
            }
        }
    }
}
