import CoreGraphics
import PomodoroCore
import Testing
@testable import PomodoroUI

/// Structural checks on the character rigs.
///
/// These exist because a rig failure is silent: nothing crashes, nothing logs, a
/// limb simply draws in the wrong place — and catching that by eye needs the right
/// pose at the right moment. Cheap invariants catch it at build time instead.
@Suite("Rig structure")
struct RigTests {

    // MARK: - Coverage

    /// Every implemented character must appear here. The structural checks below
    /// iterate this rather than naming characters inline, so adding a fifth rig
    /// without adding it to this list fails `allImplementedRigsAreCovered`.
    @Test("Every implemented character has its rig checked here")
    func allImplementedRigsAreCovered() {
        let implemented = PomodoroCharacter.allCases
            .filter { $0.isImplemented && $0 != .none }
            .map(\.rawValue)
            .sorted()
        let covered = ["animeGirl", "general", "hancock", "ninja", "rabbit", "samurai"]
        #expect(implemented == covered, """
            Rig tests cover \(covered) but the app implements \(implemented).             Add the new character's Part/layers to this file.
            """)
    }

    // MARK: - Chain ordering

    /// The regression test for the bug that detached the ninja's eyes.
    ///
    /// `chain` is built root-first so it reads like a path from the root down, and
    /// `RigView` reverses it before composing transforms — SwiftUI applies modifiers
    /// bottom-up, so an ancestor's rotation has to wrap its child's. If this
    /// ordering is ever flipped, a child's anchor gets evaluated against
    /// already-rotated content and the part flies off its joint under large
    /// rotations. Small angles hide it, which is exactly why it shipped once.
    @Test("Ancestor chains run root-first, each entry the parent of the next")
    func chainOrdering() {
        for part in SamuraiArt.Part.allCases {
            assertWellOrdered(part.chain, of: part.rawValue)
        }
        for part in NinjaArt.Part.allCases {
            assertWellOrdered(part.chain, of: part.rawValue)
        }
        for part in GeneralArt.Part.allCases {
            assertWellOrdered(part.chain, of: part.rawValue)
        }
        for part in RabbitArt.Part.allCases {
            assertWellOrdered(part.chain, of: part.rawValue)
        }
        for part in AnimeGirlArt.Part.allCases {
            assertWellOrdered(part.chain, of: part.rawValue)
        }
        for part in HancockArt.Part.allCases {
            assertWellOrdered(part.chain, of: part.rawValue)
        }
    }

    private func assertWellOrdered<P: RigPart>(_ chain: [P], of name: String) {
        #expect(!chain.isEmpty, "\(name) has an empty chain")
        #expect(chain.last == chain.last, "\(name) chain must end at itself")

        for index in chain.indices.dropFirst() {
            #expect(
                chain[index].parent == chain[index - 1],
                "\(name): chain[\(index)] is not the child of chain[\(index - 1)]"
            )
        }
        #expect(chain.first?.parent == nil, "\(name) chain does not start at a root")
    }

    @Test("No rig contains a cycle")
    func noCycles() {
        // `chain` walks parents, so a cycle would hang. Bound the walk instead.
        for part in SamuraiArt.Part.allCases {
            #expect(depth(of: part) <= 8, "\(part.rawValue) is suspiciously deep or cyclic")
        }
        for part in NinjaArt.Part.allCases {
            #expect(depth(of: part) <= 8, "\(part.rawValue) is suspiciously deep or cyclic")
        }
        for part in GeneralArt.Part.allCases {
            #expect(depth(of: part) <= 8, "\(part.rawValue) is suspiciously deep or cyclic")
        }
        for part in RabbitArt.Part.allCases {
            #expect(depth(of: part) <= 8, "\(part.rawValue) is suspiciously deep or cyclic")
        }
        for part in AnimeGirlArt.Part.allCases {
            #expect(depth(of: part) <= 8, "\(part.rawValue) is suspiciously deep or cyclic")
        }
        for part in HancockArt.Part.allCases {
            #expect(depth(of: part) <= 8, "\(part.rawValue) is suspiciously deep or cyclic")
        }
    }

    private func depth<P: RigPart>(of part: P) -> Int {
        var count = 0
        var node: P? = part
        while let current = node, count < 32 {
            count += 1
            node = current.parent
        }
        return count
    }

    // MARK: - Pivots

    /// A pivot outside the canvas converts to a `UnitPoint` beyond 0…1, which sends
    /// the joint swinging around a point off-screen.
    @Test("Every pivot lies inside its canvas")
    func pivotsInBounds() {
        for part in SamuraiArt.Part.allCases {
            expectInBounds(part.pivot, canvas: SamuraiArt.canvas, name: part.rawValue)
        }
        for part in NinjaArt.Part.allCases {
            expectInBounds(part.pivot, canvas: NinjaArt.canvas, name: part.rawValue)
        }
        for part in GeneralArt.Part.allCases {
            expectInBounds(part.pivot, canvas: GeneralArt.canvas, name: part.rawValue)
        }
        for part in RabbitArt.Part.allCases {
            expectInBounds(part.pivot, canvas: RabbitArt.canvas, name: part.rawValue)
        }
        for part in AnimeGirlArt.Part.allCases {
            expectInBounds(part.pivot, canvas: AnimeGirlArt.canvas, name: part.rawValue)
        }
        for part in HancockArt.Part.allCases {
            expectInBounds(part.pivot, canvas: HancockArt.canvas, name: part.rawValue)
        }
    }

    private func expectInBounds(_ pivot: CGPoint, canvas: CGSize, name: String) {
        #expect(pivot.x >= 0 && pivot.x <= canvas.width, "\(name) pivot.x \(pivot.x) is outside the canvas")
        #expect(pivot.y >= 0 && pivot.y <= canvas.height, "\(name) pivot.y \(pivot.y) is outside the canvas")
    }

    @Test("Anchors are normalised fractions of the canvas")
    func anchorsNormalised() {
        for part in SamuraiArt.Part.allCases {
            let anchor = part.anchor
            #expect(anchor.x >= 0 && anchor.x <= 1, "\(part.rawValue) anchor.x out of range")
            #expect(anchor.y >= 0 && anchor.y <= 1, "\(part.rawValue) anchor.y out of range")
        }
    }

    // MARK: - Layers

    @Test("Layer ids are unique, so ForEach cannot silently drop one")
    func uniqueLayerIDs() {
        let samuraiIDs = SamuraiArt.layers.map(\.id)
        #expect(Set(samuraiIDs).count == samuraiIDs.count, "duplicate samurai layer id")

        let ninjaIDs = NinjaArt.layers.map(\.id)
        #expect(Set(ninjaIDs).count == ninjaIDs.count, "duplicate ninja layer id")

        let generalIDs = GeneralArt.layers.map(\.id)
        #expect(Set(generalIDs).count == generalIDs.count, "duplicate general layer id")

        let rabbitIDs = RabbitArt.layers.map(\.id)
        #expect(Set(rabbitIDs).count == rabbitIDs.count, "duplicate rabbit layer id")

        let girlIDs = AnimeGirlArt.layers.map(\.id)
        #expect(Set(girlIDs).count == girlIDs.count, "duplicate anime girl layer id")

        let hancockIDs = HancockArt.layers.map(\.id)
        #expect(Set(hancockIDs).count == hancockIDs.count, "duplicate hancock layer id")
    }

    @Test("Every layer parses to a non-empty path")
    func layersNonEmpty() {
        for layer in SamuraiArt.layers {
            #expect(!layer.path.isEmpty, "samurai layer \(layer.name) parsed to an empty path")
        }
        for layer in NinjaArt.layers {
            #expect(!layer.path.isEmpty, "ninja layer \(layer.name) parsed to an empty path")
        }
        for layer in GeneralArt.layers {
            #expect(!layer.path.isEmpty, "general layer \(layer.name) parsed to an empty path")
        }
        for layer in RabbitArt.layers {
            #expect(!layer.path.isEmpty, "rabbit layer \(layer.name) parsed to an empty path")
        }
        for layer in AnimeGirlArt.layers {
            #expect(!layer.path.isEmpty, "anime girl layer \(layer.name) parsed to an empty path")
        }
        for layer in HancockArt.layers {
            #expect(!layer.path.isEmpty, "hancock layer \(layer.name) parsed to an empty path")
        }
    }

    /// A path far outside the canvas usually means a typo in a coordinate — a
    /// dropped decimal point turns 82.4 into 824 and the shape vanishes off-screen.
    @Test("Every layer's geometry stays near its canvas")
    func layersInBounds() {
        for layer in SamuraiArt.layers {
            expectPlausible(layer.path.boundingRect, canvas: SamuraiArt.canvas, name: layer.name)
        }
        for layer in NinjaArt.layers {
            expectPlausible(layer.path.boundingRect, canvas: NinjaArt.canvas, name: layer.name)
        }
        for layer in GeneralArt.layers {
            expectPlausible(layer.path.boundingRect, canvas: GeneralArt.canvas, name: layer.name)
        }
        for layer in RabbitArt.layers {
            expectPlausible(layer.path.boundingRect, canvas: RabbitArt.canvas, name: layer.name)
        }
        for layer in AnimeGirlArt.layers {
            expectPlausible(layer.path.boundingRect, canvas: AnimeGirlArt.canvas, name: layer.name)
        }
        for layer in HancockArt.layers {
            expectPlausible(layer.path.boundingRect, canvas: HancockArt.canvas, name: layer.name)
        }
    }

    private func expectPlausible(_ rect: CGRect, canvas: CGSize, name: String) {
        // A generous margin: the katana tip and the maedate crest legitimately sit
        // near the canvas edge, and animation carries them outside it at runtime.
        let slack: CGFloat = 40
        #expect(rect.minX >= -slack, "\(name) extends far left of the canvas (minX \(rect.minX))")
        #expect(rect.minY >= -slack, "\(name) extends far above the canvas (minY \(rect.minY))")
        #expect(rect.maxX <= canvas.width + slack, "\(name) extends far right (maxX \(rect.maxX))")
        #expect(rect.maxY <= canvas.height + slack, "\(name) extends far below (maxY \(rect.maxY))")
    }

    @Test("Expression layers that start hidden are opt-in, not accidental")
    func hiddenLayersAreDeliberate() {
        let hidden = NinjaArt.layers.filter { $0.restOpacity == 0 }.map(\.name)
        // Alternate expressions and the smoke burst — nothing else should be
        // invisible at rest, or it is simply dead weight in the draw loop.
        let expected = Set(["contentEyeL", "contentEyeR", "sparkL", "sparkR",
                            "puffA", "puffB", "puffC"])
        #expect(Set(hidden) == expected, "unexpected hidden ninja layers: \(hidden)")
    }
}
