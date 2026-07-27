import AppKit
import SwiftUI
import Testing
@testable import PomodoroUI

/// Render-based regression test for the rig's transform composition.
///
/// This exists because the structural tests in `RigTests` provably do not catch the
/// bug that shipped. Mutation-testing them showed that inverting the transform order
/// in `RigView` — the exact regression that detached the ninja's eyes from his head
/// — leaves every structural assertion passing: the chain *data* is still correct,
/// only its application is wrong. Composition can only be checked by composing.
///
/// A first attempt measured the bounding box of everything drawn, and that failed
/// too: a small part flying off barely moves the box (60% vs 65% coverage). What
/// actually discriminates is measuring whether a child still sits on its parent —
/// 2.8 design units apart when correct, 53.7 when not.
///
/// `ImageRenderer` rather than a screenshot: no window, no display, no timing luck,
/// so this runs in CI and with the screen locked.
@Suite("Rig rendering", .serialized)
@MainActor
struct RigRenderTests {

    /// Centre of mass of whatever the given layers draw, in design units.
    private func centroid(
        of layers: [RigLayer<NinjaArt.Part>],
        pose: NinjaPose
    ) throws -> CGPoint {
        let view = RigView(
            layers: layers,
            pose: pose,
            outline: NinjaArt.Ink.outline,
            rotation: { $0.rotation(of: $1) },
            opacity: { $0.opacity(of: $1) },
            extras: { view, part, pose in
                AnyView(view.modifier(NinjaPartExtras(part: part, pose: pose)))
            }
        )
        .frame(width: NinjaArt.canvas.width, height: NinjaArt.canvas.height)
        .background(Color.white)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1

        let image = try #require(renderer.nsImage, "renderer produced no image")
        // Nested #require does not expand; bind the intermediate first.
        let tiff = try #require(image.tiffRepresentation)
        let bitmap = try #require(NSBitmapImageRep(data: tiff))

        var sumX = 0, sumY = 0, count = 0
        for y in 0..<bitmap.pixelsHigh {
            for x in 0..<bitmap.pixelsWide {
                guard let colour = bitmap.colorAt(x: x, y: y) else { continue }
                // Anything meaningfully off-white is ink.
                if colour.brightnessComponent < 0.9 || colour.saturationComponent > 0.15 {
                    sumX += x; sumY += y; count += 1
                }
            }
        }

        try #require(count > 0, "those layers drew nothing")
        return CGPoint(x: Double(sumX) / Double(count), y: Double(sumY) / Double(count))
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> Double {
        ((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)).squareRoot()
    }

    /// The eyes are a grandchild of `figure` and carry their own scale, which is the
    /// combination that broke: a child transform anchored in unrotated space while
    /// its ancestor has rotated far away.
    @Test("A child stays on its parent through a large ancestor rotation")
    func childStaysAttachedUnderRotation() throws {
        var pose = NinjaPose()
        pose.emergence = 0
        pose.figureRotation = -240     // mid-backflip
        pose.eyesScaleY = 0.55         // the child's own transform

        let eyes = NinjaArt.layers.filter { $0.part == .eyes }
        let head = NinjaArt.layers.filter { $0.part == .head }

        let apart = distance(try centroid(of: eyes, pose: pose),
                             try centroid(of: head, pose: pose))

        // Measured: ~2.8 units correct, ~53.7 with the transform order inverted.
        // 15 sits an order of magnitude clear of both.
        #expect(apart < 15, """
            The eyes are \(String(format: "%.1f", apart)) design units from the head's \
            centre. They should sit within a few units of it — a larger gap means \
            child transforms are being composed against a stale anchor.
            """)
    }

    @Test("The same child sits on its parent at rest, as a control")
    func childAttachedAtRest() throws {
        var pose = NinjaPose()
        pose.emergence = 0

        let eyes = NinjaArt.layers.filter { $0.part == .eyes }
        let head = NinjaArt.layers.filter { $0.part == .head }
        let apart = distance(try centroid(of: eyes, pose: pose),
                             try centroid(of: head, pose: pose))

        // Unrotated, both orderings agree — so this is a control that proves the
        // measurement itself is sound, not a second test of the same thing.
        #expect(apart < 15, "eyes detached from the head even at rest: \(apart)")
    }
}
