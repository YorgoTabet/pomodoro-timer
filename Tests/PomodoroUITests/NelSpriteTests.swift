import AppKit
import PomodoroCore
import SwiftUI
import Testing
@testable import PomodoroUI

@Suite("Nel original artwork")
struct NelSpriteTests {
    @Test("Every original populated sprite is bundled and retains transparent margins")
    @MainActor
    func sourceFrames() throws {
        #expect(NelSprites.frames.count == 73)
        for image in NelSprites.frames.values {
            #expect(image.width == 192 && image.height == 208)
            let bitmap = NSBitmapImageRep(cgImage: image)
            #expect(bitmap.colorAt(x: 0, y: 0)?.alphaComponent == 0)
        }
        #expect(NelSprites.frames[0]?.dataProvider?.data != NelSprites.frames[3]?.dataProvider?.data)
    }

    @Test("Every cue plays distinct original frames and returns fully behind the pill")
    func performances() {
        var sequences = Set<[Int]>()
        for cue in CharacterCue.allCases {
            let timeline = NelPerformance.timeline(for: cue)
            #expect(abs(timeline.duration - CharacterPlan.duration(for: cue, character: .nel)) < 0.001)
            #expect(timeline.value(time: 0).emergence == 200)
            #expect(timeline.value(time: 1).emergence == 0)
            #expect(timeline.value(time: timeline.duration).emergence == 200)
            let sequence = (0..<12).map { NelPerformance.frame(for: cue, at: 0.45 + Double($0) * 0.2 + 0.01) }
            #expect(Set(sequence).count >= 4)
            sequences.insert(sequence)
        }
        #expect(sequences.count == 3)
    }

    @Test("Nel's original art renders through the shared miniature drawing")
    @MainActor
    func renders() throws {
        let renderer = ImageRenderer(content: NelSprite())
        let image = try #require(renderer.nsImage)
        let data = try #require(image.tiffRepresentation)
        let bitmap = try #require(NSBitmapImageRep(data: data))
        #expect(bitmap.pixelsWide == 200 && bitmap.pixelsHigh == 260)
    }
}
