import AppKit
import PomodoroCore
import QuartzCore
import SwiftUI
import Testing
@testable import PomodoroUI

@Suite("Hanging companion", .serialized)
@MainActor
struct HangingCompanionTests {
    @Test("Every bundled kit has matched optical sizes, transparency, and resting frames",
          arguments: PomodoroCharacter.allCases.filter { $0 != .none })
    func artwork(character: PomodoroCharacter) throws {
        let kit = try #require(CompanionKit.load(for: character))
        var areas: [Double] = []
        for edge in [StageEdge.top, .bottom, .leading] {
            let art = kit.artwork(for: edge)
            let bitmap = NSBitmapImageRep(cgImage: art.open)
            var alpha = 0.0
            for y in 0..<bitmap.pixelsHigh {
                for x in 0..<bitmap.pixelsWide {
                    alpha += Double(bitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0)
                }
            }
            let scale = art.size.height / Double(art.open.height)
            areas.append(alpha * scale * scale)
            #expect(alpha > 10_000)
            #expect(bitmap.colorAt(x: 0, y: 0)!.alphaComponent < 0.05)
            #expect(art.open.dataProvider?.data != art.blink.dataProvider?.data)
        }
        #expect(areas.max()! / areas.min()! < 1.15, "A pose changes \(character)'s visual weight: \(areas)")
        #expect(areas.allSatisfy { (950...1300).contains($0) }, "\(character) differs too much from the roster: \(areas)")
        #expect(CompanionKit.load(for: .none) == nil)
    }

    @Test("Every character stays attached and falls back safely at screen boundaries",
          arguments: PomodoroCharacter.allCases.filter { $0 != .none })
    func layout(character: PomodoroCharacter) throws {
        let kit = try #require(CompanionKit.load(for: character))
        let screen = CGRect(x: -1440, y: -900, width: 1440, height: 900)
        for orientation in PillOrientation.allCases {
        for length in [236.0, 172] {
            let size = PillLayout(orientation: orientation).size(length: length)
            let width = size.width
            let height = size.height
            for origin in [CGPoint(x: -900, y: -500), CGPoint(x: -1439, y: -899),
                           CGPoint(x: -width - 1, y: -899), CGPoint(x: -1439, y: -height - 1),
                           CGPoint(x: -width - 1, y: -height - 1)] {
                let pill = CGRect(origin: origin, size: size)
                for edge in StageEdge.allCases {
                    for position in [0.0, 0.5, 1] {
                        let placed = CompanionDock.resolve(preferred: edge, position: position,
                            pill: pill, screen: screen) { kit.metrics(for: $0) }
                        #expect(screen.contains(placed.frame))
                        let m = kit.metrics(for: placed.edge)
                        #expect(abs(placed.frame.minX + m.grip.x * m.size.width - placed.contact.x) < 0.001)
                        #expect(abs(placed.frame.minY + m.grip.y * m.size.height - placed.contact.y) < 0.001)
                        if placed.edge == .top { #expect(placed.contact.y == pill.minY + (orientation == .vertical ? 5 : 0)) }
                        if placed.edge == .bottom { #expect(placed.contact.y == pill.maxY - (orientation == .vertical ? 5 : 0)) }
                    }
                }
            }
        }
        }
    }

    @Test("Every native companion leaves dragging alone; Idle and Reduce Motion stay parked",
          arguments: PomodoroCharacter.allCases.filter { $0 != .none })
    func stationary(character: PomodoroCharacter) async throws {
        let kit = try #require(CompanionKit.load(for: character))
        let view = HangingSpriteView(frame: CGRect(x: 0, y: 0, width: 400, height: 200))
        let pill = CGRect(x: 82, y: 60, width: 236, height: 46)
        view.configure(kit: kit, mode: .calm, edge: .bottom, position: 0.5,
                       pill: pill, screen: view.bounds, reduceMotion: false)
        let initial = view.placement
        #expect(view.hitTest(CGPoint(x: 200, y: 120)) == nil)
        try await Task.sleep(for: .seconds(1.5))
        #expect(view.placement == initial)
        view.configure(kit: kit, mode: .stroll, edge: .bottom, position: 0.5,
                       pill: pill, screen: view.bounds, reduceMotion: true)
        try await Task.sleep(for: .seconds(1.5))
        #expect(view.placement == initial)
        #expect(view.layer?.sublayers?.first?.animationKeys()?.isEmpty != false)
        view.stop()
    }

    @Test("Every Lively companion relocates immediately and cancels unfinished work",
          arguments: PomodoroCharacter.allCases.filter { $0 != .none }, PillOrientation.allCases)
    func lively(character: PomodoroCharacter, orientation: PillOrientation) async throws {
        let kit = try #require(CompanionKit.load(for: character))
        let layout = PillLayout(orientation: orientation)
        let view = HangingSpriteView(frame: CGRect(origin: .zero, size: layout.panelSize))
        let pill = layout.pillFrame
        view.configure(kit: kit, mode: .stroll, edge: .top, position: 0.5,
                       pill: pill, screen: view.bounds, reduceMotion: false)
        try await Task.sleep(for: .seconds(1.6))
        #expect(view.placement?.edge == .trailing)
        // Changing the preference during settling cancels the old transition.
        view.configure(kit: kit, mode: .calm, edge: .leading, position: 0.2,
                       pill: pill, screen: view.bounds, reduceMotion: false)
        try await Task.sleep(for: .seconds(0.8))
        #expect(view.placement?.edge == .leading)
        view.stop()
    }

    @Test("Inspect the native hanging renderer locally when requested")
    func nativeReview() async throws {
        guard ProcessInfo.processInfo.environment["POMODORO_HANGING_REVIEW"] == "1" else { return }
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let host = NSHostingController(rootView: HangingReview())
        let window = NSWindow(contentViewController: host)
        window.title = "Companion Roster Review"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        let delegate = CompanionReviewDelegate()
        window.delegate = delegate
        window.center(); window.makeKeyAndOrderFront(nil); app.activate(ignoringOtherApps: true)
        let timeout = Timer.scheduledTimer(withTimeInterval: 600, repeats: false) { _ in
            MainActor.assumeIsolated { CompanionReviewDelegate.stopReview() }
        }
        // Yield the test's MainActor task before entering AppKit's event loop.
        // A run-loop callback (rather than a MainActor task or main-queue block)
        // leaves the relocation tasks free to run alongside native UI events.
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            RunLoop.main.perform {
                MainActor.assumeIsolated {
                    withExtendedLifetime(delegate) { app.run() }
                    continuation.resume()
                }
            }
        }
        timeout.invalidate()
        window.close()
    }

    @Test("Switching kits during a Lively tuck cannot bring back the previous character",
          arguments: PomodoroCharacter.allCases.filter { $0 != .none })
    func replacingKit(character: PomodoroCharacter) async throws {
        let roster = PomodoroCharacter.allCases.filter { $0 != .none }
        let next = roster[(roster.firstIndex(of: character)! + 1) % roster.count]
        let original = try #require(CompanionKit.load(for: character))
        let replacement = try #require(CompanionKit.load(for: next))
        let view = HangingSpriteView(frame: CGRect(x: 0, y: 0, width: 400, height: 200))
        let pill = CGRect(x: 82, y: 60, width: 236, height: 46)
        view.configure(kit: original, mode: .stroll, edge: .top, position: 0.5,
                       pill: pill, screen: view.bounds, reduceMotion: false)
        try await Task.sleep(for: .seconds(0.95))
        view.configure(kit: replacement, mode: .calm, edge: .bottom, position: 0.5,
                       pill: pill, screen: view.bounds, reduceMotion: false)
        try await Task.sleep(for: .seconds(0.75))
        #expect(view.placement?.edge == .bottom)
        let content = try #require(view.layer?.sublayers?.first?.sublayers?.first?.contents)
        // Evaluate CF identity before the assertion macro; passing AnyObject
        // identity through the current Testing macro crashes Swift's SIL lowering.
        let matches = (content as AnyObject) === (replacement.artwork(for: .bottom).open as AnyObject)
        #expect(matches)
        view.stop()
    }
}

private struct HangingReview: View {
    @State private var mode = CharacterIdleMode.calm
    @State private var character = PomodoroCharacter(rawValue: ProcessInfo.processInfo.environment["POMODORO_REVIEW_CHARACTER"] ?? "samurai") ?? .samurai
    @State private var appearance = ThemeAppearance.dark
    private var reviewTheme: ThemeConfiguration {
        var theme = ThemeConfiguration()
        theme.appearance = appearance
        theme.preset = ThemePreset.matching(character) ?? .classic
        return theme
    }
    var body: some View {
        VStack(spacing: 8) {
            let roster = PomodoroCharacter.allCases.filter { $0 != .none }
            ForEach(0..<((roster.count + 2) / 3), id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(Array(roster[(row * 3)..<min(row * 3 + 3, roster.count)])) { choice in
                        Button(choice.displayName) { character = choice }
                            .buttonStyle(.bordered)
                            .tint(character == choice ? .red : .gray)
                            .font(.system(size: 11))
                    }
                }
            }
            Picker("Mode", selection: $mode) {
                Text("Idle").tag(CharacterIdleMode.calm)
                Text("Lively").tag(CharacterIdleMode.stroll)
            }.pickerStyle(.segmented).frame(width: 250)
            Picker("Appearance", selection: $appearance) {
                Text("Light").tag(ThemeAppearance.light)
                Text("Dark").tag(ThemeAppearance.dark)
            }.pickerStyle(.segmented).frame(width: 250)
            ForEach(StageEdge.allCases, id: \.self) { edge in
                ZStack(alignment: .topLeading) {
                    ThemeTimerPreview().position(x: 200, y: 70)
                    HangingCompanion(character: character, mode: mode, edge: edge, position: 0.5,
                        pill: CGRect(x: 82, y: 47, width: 236, height: 46),
                        screen: CGRect(x: 0, y: 0, width: 400, height: 172))
                }.frame(width: 400, height: 172)
            }
        }.padding(18).background(Color(white: appearance == .light ? 0.96 : 0.14))
            .pomodoroAppearance(reviewTheme, inWindow: true)
    }
}

@MainActor
private final class CompanionReviewDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) { Self.stopReview() }
    static func stopReview() {
        let app = NSApplication.shared
        app.stop(nil)
        if let event = NSEvent.otherEvent(with: .applicationDefined, location: .zero, modifierFlags: [],
            timestamp: 0, windowNumber: 0, context: nil, subtype: 0, data1: 0, data2: 0) {
            app.postEvent(event, atStart: true)
        }
    }
}
