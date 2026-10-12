import AppKit
import PomodoroCore
import SwiftUI
import Testing
@testable import PomodoroUI

@Suite("Idle companion")
struct IdleCompanionTests {
    @Test("Stroll walks immediately, rests, and returns without jumping")
    func strollMotion() {
        let preview = IdleMotion.sample(time: 0.3, mode: .stroll)
        #expect(preview.step > 0 && preview.travel > 0)
        #expect(IdleMotion.sample(time: 2, mode: .stroll).travel == 0.5)
        #expect(IdleMotion.sample(time: 6, mode: .stroll).step == 0)
        #expect(IdleMotion.sample(time: 6, mode: .stroll).travel == 1)
        #expect(IdleMotion.sample(time: 14, mode: .stroll).travel == 0.5)
        #expect(IdleMotion.sample(time: 20, mode: .stroll).travel == 0)
        #expect(IdleMotion.sample(time: 31, mode: .stroll).travel == 0)
        for boundary in [4.0, 12, 16, 32] {
            let before = IdleMotion.sample(time: boundary - 0.001, mode: .stroll)
            let after = IdleMotion.sample(time: boundary + 0.001, mode: .stroll)
            #expect(abs(before.travel - after.travel) < 0.001)
            #expect(abs(before.step - after.step) < 0.01)
        }
    }

    @Test("Still never travels, and Reduce Motion disables both modes")
    func quietModes() {
        for t in stride(from: 0.0, through: 64, by: 0.1) {
            let calm = IdleMotion.sample(time: t, mode: .calm)
            #expect(calm.travel == 0 && calm.step == 0)
            #expect((0...1).contains(calm.blink))
            for mode in CharacterIdleMode.allCases {
                #expect(IdleMotion.sample(time: t, mode: mode, reduceMotion: true) == IdleMotion())
            }
        }
    }

    @Test("Companion clears the pill, stays onscreen, and is stable in compact mode")
    func placement() {
        // A secondary display with negative screen coordinates.
        let screen = CGRect(x: -1440, y: -900, width: 1440, height: 900)
        for pill in [CGRect(x: -400, y: -400, width: 236, height: 46),
                     CGRect(x: -400, y: -895, width: 236, height: 46),
                     CGRect(x: -10, y: -400, width: 236, height: 46)] {
            for travel in [0.0, 0.5, 1] {
                let expanded = IdleCompanionLayout.frame(pill: pill, screen: screen,
                                                         readoutCenterX: pill.minX + 85, travel: travel)
                var compactPill = pill
                compactPill.size.width = 172
                let compact = IdleCompanionLayout.frame(pill: compactPill, screen: screen,
                                                        readoutCenterX: pill.minX + 85, travel: travel)
                #expect(expanded == compact)
                #expect(screen.contains(expanded))
                #expect(!expanded.intersects(pill))
                if pill.minY < screen.minY + 48 { #expect(expanded.minY == pill.maxY) }
            }
        }
    }

    @Test("Every mini character renders in still, blinking and walking poses",
          arguments: PomodoroCharacter.allCases.filter { $0 != .none })
    @MainActor
    func rendersEveryCharacter(character: PomodoroCharacter) throws {
        var images: [Data] = []
        for t in [0.0, 8.175, 2, 14] {
            let renderer = ImageRenderer(content: IdleCharacterDrawing(
                character: character, motion: .sample(time: t, mode: .stroll)
            ))
            renderer.scale = 2
            let image = try #require(renderer.nsImage)
            let data = try #require(image.tiffRepresentation)
            let bitmap = try #require(NSBitmapImageRep(data: data))
            var ink = 0
            for y in 0..<bitmap.pixelsHigh {
                for x in 0..<bitmap.pixelsWide {
                    if let color = bitmap.colorAt(x: x, y: y), color.alphaComponent > 0.1 { ink += 1 }
                }
            }
            #expect(ink > 300, "\(character) produced an empty or clipped miniature")
            images.append(data)
        }
        #expect(images[0] != images[2], "\(character) has no animated walking pose")
    }

    @Test("Export a local review sheet when requested")
    @MainActor
    func reviewSheet() throws {
        guard let path = ProcessInfo.processInfo.environment["POMODORO_IDLE_PREVIEW"] else { return }
        let characters = PomodoroCharacter.allCases.filter { $0 != .none }
        let content = VStack(spacing: 18) {
            ForEach(characters) { character in
                HStack(spacing: 16) {
                    Text(character.displayName).frame(width: 110, alignment: .leading)
                    ForEach([0.0, 8.175, 2, 14], id: \.self) { time in
                        VStack(spacing: 0) {
                            IdleCharacterDrawing(character: character, motion: .sample(time: time, mode: .stroll))
                            RoundedRectangle(cornerRadius: 14).fill(Color.gray.opacity(0.22))
                                .frame(width: 120, height: 32)
                                .overlay(Text("25:00   ▶").font(.system(size: 13)))
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(Color(red: 0.12, green: 0.13, blue: 0.16))
        .foregroundStyle(.white)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        let image = try #require(renderer.nsImage)
        let tiff = try #require(image.tiffRepresentation)
        let bitmap = try #require(NSBitmapImageRep(data: tiff))
        let png = try #require(bitmap.representation(using: .png, properties: [:]))
        try png.write(to: URL(fileURLWithPath: path))
    }

    @Test("Cached playback supplies visible Retina frames for every character",
          arguments: PomodoroCharacter.allCases.filter { $0 != .none })
    @MainActor
    func cachedPlayback(character: PomodoroCharacter) async throws {
        let sprites = try #require(await IdleSpriteCache.frames(for: character))
        for t in [0.0, 2, 8.25, 14, 20, 32, 64] {
            let image = sprites.image(time: t, motion: .sample(time: t, mode: .stroll))
            #expect(image.height == 96)
            #expect(image.width >= 73 && image.width <= 75)
            let bitmap = NSBitmapImageRep(cgImage: image)
            var ink = 0
            for y in 0..<bitmap.pixelsHigh {
                for x in 0..<bitmap.pixelsWide {
                    if let color = bitmap.colorAt(x: x, y: y), color.alphaComponent > 0.1 { ink += 1 }
                }
            }
            #expect(ink > 300, "\(character)'s cached playback is blank")
        }
    }
}
