import CoreGraphics
import PomodoroCore
import SwiftUI
import Testing
@testable import PomodoroUI

/// Empirical, pixel-level verification of the character mask.
///
/// The mask has burned this project twice: two implementations clipped the samurai
/// away entirely instead of partially, so 9c90904 shipped him unmasked. The current
/// change re-enables it, cutting at the pill's *bottom* edge (`pillFrame.maxY`) with
/// `.mask(alignment: .topLeading)` applied after `.frame().position()`. The open
/// question is coordinate space: `.position` wraps its content in a flexible frame
/// that fills the proposed space, so the mask view *should* be sized to the whole
/// panel and its `maxY`-tall rectangle should land in panel coordinates. These tests
/// render the real views offscreen and count pixels instead of trusting that theory.
///
/// Geometry is mirrored, not imported: `FloatingBar` lives in the executable target,
/// which a test target cannot depend on. The constants below must match
/// `FloatingBar.size` (236x46) and its `pillFrame` (pill inset by
/// `CharacterStage.margin` on all sides).
@Suite("StageMask")
@MainActor
struct StageMaskTests {

    // MARK: - Mirrored geometry

    /// `FloatingBar.size`.
    static let pillSize = CGSize(width: 236, height: 46)

    /// `FloatingBar.panelSize`: the pill plus the transparent stage margin.
    static var panelSize: CGSize {
        CGSize(width: pillSize.width + CharacterStage.margin * 2,
               height: pillSize.height + CharacterStage.margin * 2)
    }

    /// `FloatingBar.pillFrame`: the pill's rect in the panel's top-left space.
    static var pillFrame: CGRect {
        CGRect(x: CharacterStage.margin, y: CharacterStage.margin,
               width: pillSize.width, height: pillSize.height)
    }

    /// First whole pixel row strictly below the mask cut, with a one-pixel guard
    /// band for the rasterizer's edge antialiasing at y == maxY itself.
    static var belowCutRow: Int { Int(pillFrame.maxY.rounded()) + 1 }

    /// Mirror of `CharacterStage.hidden(_:)` + `hideDistance` for `.top` in the
    /// working tree: emergence 0...200 mapped onto character height + pill depth.
    private func hiddenOffset(for emergence: Double) -> Double {
        emergence / 200 * (CharacterStage.displaySize.height + Self.pillFrame.height)
    }

    // MARK: - Rendering harness

    /// Alpha channel of an offscreen render, row 0 = top of the panel.
    private struct AlphaMap {
        let width: Int
        let height: Int
        let alpha: [UInt8]

        /// Pixels with meaningful coverage (alpha >= 8 of 255) in a row range.
        func visible(rows: Range<Int>) -> Int {
            let rows = rows.clamped(to: 0..<height)
            var count = 0
            for y in rows {
                let base = y * width
                for x in 0..<width where alpha[base + x] >= 8 { count += 1 }
            }
            return count
        }

        var total: Int { visible(rows: 0..<height) }
    }

    /// Renders the samurai on the stage exactly as `CharacterStage.samuraiAnimator`
    /// composes it (scale -> frame -> emergence offset -> StagePlacement), inside a
    /// panel-sized container mirroring `FloatingBarView`'s ZStack.
    private func render(pose: SamuraiPose, masked: Bool) throws -> AlphaMap {
        let stage = SamuraiView(pose: pose)
            .scaleEffect(CharacterStage.scale, anchor: .topLeading)
            .frame(width: CharacterStage.displaySize.width,
                   height: CharacterStage.displaySize.height,
                   alignment: .topLeading)
            .offset(x: -hiddenOffset(for: pose.emergence) * StageEdge.top.inwardNormal.x,
                    y: -hiddenOffset(for: pose.emergence) * StageEdge.top.inwardNormal.y)
            .modifier(StagePlacement(edge: .top, pillFrame: Self.pillFrame,
                                     box: CharacterStage.displaySize, masked: masked))

        let panel = ZStack(alignment: .topLeading) { stage }
            .frame(width: Self.panelSize.width, height: Self.panelSize.height)

        let renderer = ImageRenderer(content: panel)
        renderer.proposedSize = ProposedViewSize(Self.panelSize)
        renderer.scale = 1

        let image = try #require(renderer.cgImage, "offscreen render produced no image")
        #expect(image.width == Int(Self.panelSize.width))
        #expect(image.height == Int(Self.panelSize.height))

        var data = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let context = try #require(CGContext(
            data: &data,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: image.width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))

        var alpha = [UInt8](repeating: 0, count: image.width * image.height)
        for i in 0..<alpha.count { alpha[i] = data[i * 4 + 3] }
        return AlphaMap(width: image.width, height: image.height, alpha: alpha)
    }

    private func pose(emergence: Double) -> SamuraiPose {
        var pose = SamuraiPose()
        pose.emergence = emergence
        return pose
    }

    // MARK: - Tests

    /// (a) + (b): the risen character survives the mask. This is the regression the
    /// mask has caused twice — a mask in the wrong coordinate space multiplies the
    /// whole character by zero coverage and he vanishes.
    @Test("Risen character is substantially visible through the mask")
    func risenCharacterVisible() throws {
        let unmasked = try render(pose: pose(emergence: 0), masked: false).total
        let masked = try render(pose: pose(emergence: 0), masked: true).total

        print("STAGEMASK risen: unmasked=\(unmasked) masked=\(masked)")

        // Harness self-check: the character must actually render at all.
        #expect(unmasked > 1000, "unmasked risen render is empty; harness is broken")
        // (b) A mask can only remove pixels.
        #expect(masked <= unmasked)
        // (a) Regression guard against total clipping.
        #expect(masked > unmasked / 4,
                "mask removed the character (\(masked) of \(unmasked) px) — the old total-clipping bug")
    }

    /// (c) at full rise: with the mask on, nothing below the pill's bottom edge,
    /// plenty above it.
    @Test("Risen: no pixels below pillFrame.maxY, many above")
    func risenCutRegions() throws {
        let masked = try render(pose: pose(emergence: 0), masked: true)
        let above = masked.visible(rows: 0..<Int(Self.pillFrame.maxY))
        let below = masked.visible(rows: Self.belowCutRow..<masked.height)

        print("STAGEMASK risen regions: above=\(above) below=\(below)")

        #expect(above > 1000, "risen character should stand above the pill's bottom edge")
        #expect(below == 0, "\(below) px leaked below pillFrame.maxY with the mask on")
    }

    /// The load-bearing case: mid-rise, the body genuinely straddles the cut line, so
    /// this proves the mask cuts *at pillFrame.maxY in panel coordinates* rather than
    /// passing vacuously because nothing was below anyway.
    @Test("Mid-rise: mask cuts exactly at the pill's bottom edge")
    func midRiseCutsAtPillBottom() throws {
        let mid = pose(emergence: 100) // box spans ~y 109...205, crossing maxY=156

        let unmasked = try render(pose: mid, masked: false)
        let masked = try render(pose: mid, masked: true)

        let cut = Int(Self.pillFrame.maxY)
        let unmaskedBelow = unmasked.visible(rows: Self.belowCutRow..<unmasked.height)
        let maskedBelow = masked.visible(rows: Self.belowCutRow..<masked.height)
        let maskedAbove = masked.visible(rows: 0..<cut)

        print("STAGEMASK mid: unmaskedBelow=\(unmaskedBelow) maskedBelow=\(maskedBelow) maskedAbove=\(maskedAbove) total(unmasked=\(unmasked.total) masked=\(masked.total))")

        // Control: without the mask the body must dangle below the cut, or this
        // test could not detect a broken mask.
        #expect(unmaskedBelow > 500, "mid-rise body should extend below the cut unmasked")
        // The mask must remove exactly that dangling region...
        #expect(maskedBelow == 0, "\(maskedBelow) px leaked below pillFrame.maxY with the mask on")
        // ...while leaving the emerged part alone.
        #expect(maskedAbove > 500, "mask removed the emerged body above the cut")
    }

    /// At rest (emergence 200) the pose must be fully hidden: the working tree
    /// mounts the stage permanently, so any resting pixel would be a persistent
    /// artifact on screen, not a 2.5-second one.
    @Test("At rest the character is fully hidden")
    func restingPoseHidden() throws {
        let masked = try render(pose: pose(emergence: 200), masked: true)
        let unmasked = try render(pose: pose(emergence: 200), masked: false)

        print("STAGEMASK rest: masked=\(masked.total) unmasked=\(unmasked.total)")

        #expect(masked.total == 0,
                "\(masked.total) px visible at rest — the resting pose does not clear the mask")
    }
}
