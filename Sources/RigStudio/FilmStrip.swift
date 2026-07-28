import AppKit
import PomodoroCore
import PomodoroUI
import SwiftUI

/// Renders every performance to a contact sheet PNG, headlessly.
///
/// `swift run RigStudio --filmstrip <dir>`
///
/// The scrubber is the tool for judging motion; this is the tool for judging a whole
/// performance at once. Laying the frames side by side is how spacing becomes
/// visible as a *shape* — evenly spaced poses look mechanical on the sheet long
/// before you can name what is wrong with them on screen. It also runs without a
/// display, so it works over SSH and in CI.
@MainActor
enum FilmStrip {

    static let framesPerRow = 10
    /// Design units of slack around each frame, so jumps and twirls that leave the
    /// canvas are still visible.
    static let margin = CGSize(width: 55, height: 95)

    static func renderAll(into directory: String) {
        let url = URL(fileURLWithPath: directory, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)

        render(SamuraiSubject.self, into: url)
        render(NinjaSubject.self, into: url)
        render(GeneralSubject.self, into: url)
        render(RabbitSubject.self, into: url)
        render(AnimeGirlSubject.self, into: url)
    }

    static func render<S: RigSubject>(_ subject: S.Type, into directory: URL) {
        let sheet = Sheet(subject: subject)
        let renderer = ImageRenderer(content: sheet)
        renderer.scale = 1

        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:])
        else {
            FileHandle.standardError.write(
                Data("could not render \(S.character.displayName)\n".utf8))
            return
        }

        let file = directory.appendingPathComponent("\(S.character.rawValue).png")
        try? png.write(to: file)
        print("wrote \(file.path)")
    }

    /// One character: three rows, one per performance, sampled evenly.
    struct Sheet<S: RigSubject>: View {
        let subject: S.Type

        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(CharacterCue.allCases, id: \.self) { cue in
                    row(cue)
                }
            }
            .padding(6)
            .background(Color(white: 0.55))
        }

        private func row(_ cue: CharacterCue) -> some View {
            let poses = S.poses(for: cue, count: FilmStrip.framesPerRow)
            return HStack(spacing: 2) {
                ForEach(Array(poses.enumerated()), id: \.offset) { _, pose in
                    cell(pose)
                }
            }
        }

        /// One frame, with room around the canvas.
        ///
        /// `ImageRenderer` rasterises exactly the root view's bounds, so anything
        /// drawn outside the 200×260 design space is cropped — which made the
        /// rabbit's jump render as two blank frames and looked like a rig bug. It is
        /// not one: `.frame()` does not clip in SwiftUI, so on the real stage that
        /// motion draws fine. The margins exist purely so the tool stops lying.
        private func cell(_ pose: S.Pose) -> some View {
            S.draw(pose)
                .frame(width: S.canvas.width, height: S.canvas.height, alignment: .topLeading)
                .offset(x: FilmStrip.margin.width, y: FilmStrip.margin.height)
                .frame(width: S.canvas.width + FilmStrip.margin.width * 2,
                       height: S.canvas.height + FilmStrip.margin.height * 2,
                       alignment: .topLeading)
                .background(Color.white)
                .overlay(alignment: .topLeading) {
                    // The authored ground line, so a character drifting off its
                    // footing across the row is obvious.
                    Rectangle()
                        .fill(Color.red.opacity(0.3))
                        .frame(height: 0.5)
                        .offset(y: 196 + FilmStrip.margin.height)
                }
        }
    }
}
