import AppKit
import PomodoroCore
import SwiftUI
import Testing
@testable import PomodoroUI

@Suite("Theme rendering")
@MainActor
struct ThemeRenderTests {
    @Test("Shared dials and cycle indicators reflect every palette, phase, and appearance")
    func previews() throws {
        _ = NSApplication.shared
        for appearance in [ThemeAppearance.light, .dark] {
            for phase in Phase.allCases {
                var images = Set<Data>()
                for preset in ThemePreset.allCases where preset != .custom {
                    var theme = ThemeConfiguration()
                    theme.preset = preset
                    theme.appearance = appearance
                    // Native Liquid Glass is omitted by the UI test process's
                    // offscreen renderer. Exercise the actual shared dial/pips
                    // here; inspect glass in the signed app.
                    let renderer = ImageRenderer(content: VStack(spacing: 10) {
                        TimerDial(phase: phase, progress: 0.65) {
                            Text("18:42").font(.system(size: 14))
                        }
                        .frame(width: 76, height: 76)
                        CyclePips(position: 2, length: 4, phase: phase)
                    }
                        .padding(10)
                        .background(appearance == .dark ? Color(white: 0.14) : Color(white: 0.96))
                        .pomodoroAppearance(theme, inWindow: false))
                    renderer.scale = 2
                    let image = try #require(renderer.nsImage)
                    let data = try #require(image.tiffRepresentation)
                    let bitmap = try #require(NSBitmapImageRep(data: data))
                    if let directory = ProcessInfo.processInfo.environment["POMODORO_THEME_PREVIEW"] {
                        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
                        let png = try #require(bitmap.representation(using: .png, properties: [:]))
                        try png.write(to: URL(fileURLWithPath: directory).appendingPathComponent("\(preset.rawValue)-\(phase.rawValue)-\(appearance.rawValue).png"))
                    }
                    #expect(bitmap.pixelsWide > 150 && bitmap.pixelsHigh > 150)
                    images.insert(data)
                }
                #expect(images.count == ThemePreset.allCases.count - 1, "A theme was lost before reaching the timer's environment")
            }
        }
    }
}
