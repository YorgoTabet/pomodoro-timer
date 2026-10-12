import AppKit
import PomodoroCore
@testable import PomodoroUI
import SwiftUI
import Testing
@testable import Pomodoro

@Suite("Pill orientation and context menu", .serialized)
@MainActor
struct PillOrientationTests {
    @Test("Inspect the real floating panel and settings locally when requested")
    func nativeReview() async throws {
        guard ProcessInfo.processInfo.environment["POMODORO_PILL_LAYOUT_REVIEW"] == "1" else { return }
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let (bar, settings, controller) = makeBar()
        settings.character = PomodoroCharacter(rawValue: ProcessInfo.processInfo.environment["POMODORO_REVIEW_CHARACTER"] ?? "hancock") ?? .hancock
        settings.characterIdleMode = .calm
        var theme = settings.theme
        theme.preset = ThemePreset.matching(settings.character) ?? .classic; theme.appearance = .dark
        settings.theme = theme
        func syncCompanion() {
            bar.stage.character = settings.character
            bar.stage.idleMode = settings.characterIdleMode
            bar.stage.companionEdge = settings.characterCompanionEdge
            bar.stage.companionPosition = settings.characterCompanionPosition
        }
        syncCompanion()
        settings.onCompanionChange = { syncCompanion() }
        settings.onChange = { controller.settingsChanged() }
        settings.onAppearanceChange = { controller.appearanceChanged() }
        settings.onFloatingBarChange = {
            bar.setOrientation(settings.pillOrientation)
            bar.presentation.setCompactEnabled(settings.compactFloatingBar)
            if settings.showFloatingBar { bar.orderFrontRegardless() }
            else { bar.orderOut(nil) }
            bar.setCompanionVisible(settings.showFloatingBar)
        }
        controller.onUpdate = { bar.presentation.setRunning(controller.isRunning) }
        let window = NSWindow(contentViewController: NSHostingController(rootView: ThemedView(settings: settings) {
            SettingsView(settings: settings, onChange: { controller.settingsChanged() }, onPreview: {
                bar.stage.perform($0, character: settings.character, edge: .top)
            })
        }))
        window.title = "Pill Layout Review"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.setContentSize(CGSize(width: 440, height: 640))
        let delegate = PillReviewDelegate()
        window.delegate = delegate
        window.center()
        bar.onOpenSettings = { window.makeKeyAndOrderFront(nil); app.activate(ignoringOtherApps: true) }
        let roster = NSWindow(contentViewController: NSHostingController(rootView: PillReviewRoster(settings: settings,
            onSettings: { window.makeKeyAndOrderFront(nil) })))
        roster.title = "Review Characters"
        roster.styleMask = [.titled]
        roster.isReleasedWhenClosed = false
        roster.setContentSize(CGSize(width: 390, height: 120))
        let screen = try #require(NSScreen.main?.visibleFrame)
        window.setFrameOrigin(CGPoint(x: screen.midX + 100, y: screen.midY - window.frame.height / 2))
        bar.setFrameOrigin(CGPoint(x: screen.midX - 420 - FloatingBar.margin, y: screen.midY - FloatingBar.margin))
        roster.setFrameOrigin(CGPoint(x: screen.midX - 480, y: screen.midY - 250))
        window.makeKeyAndOrderFront(nil); roster.orderFront(nil)
        bar.orderFrontRegardless(); bar.setCompanionVisible(true)
        if ProcessInfo.processInfo.environment["POMODORO_PILL_PANEL_ONLY"] == "1" {
            window.orderOut(nil); roster.orderOut(nil)
            settings.pillOrientation = .vertical
            settings.compactFloatingBar = true
            settings.characterIdleMode = .stroll
            controller.start()
            bar.makeKeyAndOrderFront(nil)
        }
        app.activate(ignoringOtherApps: true)
        let timeout = Timer.scheduledTimer(withTimeInterval: 600, repeats: false) { _ in
            MainActor.assumeIsolated { PillReviewDelegate.stop() }
        }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            RunLoop.main.perform {
                MainActor.assumeIsolated {
                    withExtendedLifetime(delegate) { app.run() }
                    continuation.resume()
                }
            }
        }
        timeout.invalidate()
        settings.onFloatingBarChange = nil; settings.onCompanionChange = nil
        controller.onUpdate = nil; controller.pause()
        bar.close(); roster.close(); window.close()
    }

    private func makeBar() -> (FloatingBar, PomodoroSettings, TimerController) {
        _ = NSApplication.shared
        let settings = PomodoroSettings(defaults: makeAppTestDefaults())
        let controller = TimerController(settings: settings, stats: StatsStore(fileURL: makeScratchStatsURL()),
                                         shared: makeAppTestSharedStore())
        let bar = FloatingBar(controller: controller, settings: settings)
        settings.onFloatingBarChange = { [weak bar] in
            guard let bar else { return }
            bar.setOrientation(settings.pillOrientation)
            bar.presentation.setCompactEnabled(settings.compactFloatingBar)
            if !settings.showFloatingBar { bar.orderOut(nil); bar.setCompanionVisible(false) }
        }
        return (bar, settings, controller)
    }

    @Test("The Settings preview has room for every selected pose in both layouts",
          arguments: PomodoroCharacter.allCases.filter { $0 != .none }, PillOrientation.allCases)
    func previewPlacement(character: PomodoroCharacter, orientation: PillOrientation) throws {
        let settings = PomodoroSettings(defaults: makeAppTestDefaults())
        settings.pillOrientation = orientation
        let preview = CompanionSettingsView(settings: settings)
        let kit = try #require(CompanionKit.load(for: character))
        for edge in StageEdge.allCases {
            let dock = CompanionDock.resolve(preferred: edge, position: 0.5,
                pill: preview.pill, screen: preview.previewBounds) { kit.metrics(for: $0) }
            #expect(dock.edge == edge, "Preview incorrectly falls back for \(character) / \(orientation) / \(edge)")
        }
    }

    @Test("Both layouts transpose dimensions, keep play/pause in compact, and route only the readout to drag")
    func nativeHitRouting() throws {
        _ = NSApplication.shared
        for orientation in PillOrientation.allCases {
            let layout = PillLayout(orientation: orientation)
            #expect(layout.size.width * layout.size.height == FloatingBar.size.width * FloatingBar.size.height)
            #expect(layout.compactFrame.contains(layout.controlFrame(index: 0)))
            let host = FloatingBarHostingView(rootView: Color.clear)
            host.frame = CGRect(origin: .zero, size: layout.panelSize)
            let geometry = BarGeometry()
            geometry.layout = layout
            host.geometry = geometry
            // hitTest's input lives in the unflipped parent coordinates.
            func point(_ rect: CGRect) -> CGPoint {
                let native = layout.nativeRect(rect)
                return CGPoint(x: native.midX, y: native.midY)
            }
            for compact in [false, true] {
                geometry.hitFrame = layout.visibleFrame(compact: compact)
                #expect(host.hitTest(point(layout.dragFrame)) is WindowDragView)
                for index in 0..<3 {
                    let hit = host.hitTest(point(layout.controlFrame(index: index)))
                    #expect(!(hit is WindowDragView))
                    if compact && index > 0 { #expect(hit == nil) }
                }
                #expect(host.hitTest(CGPoint(x: 5, y: 5)) == nil)
            }
        }
    }

    @Test("Orientation round-trips preserve the pill center and restore from its stored origin")
    func rotatesAndRestores() throws {
        let (bar, settings, _) = makeBar()
        defer { bar.close() }
        let bounds = try #require(NSScreen.main?.frame)
        bar.setFrameOrigin(CGPoint(x: bounds.midX - bar.layout.panelSize.width / 2,
                                  y: bounds.midY - bar.layout.panelSize.height / 2))
        let center = CGPoint(x: bar.pillOrigin.x + bar.layout.size.width / 2,
                             y: bar.pillOrigin.y + bar.layout.size.height / 2)
        for orientation in [PillOrientation.vertical, .horizontal, .vertical] {
            settings.pillOrientation = orientation
            #expect(bar.frame.size == bar.layout.panelSize)
            #expect(bar.contentView?.frame.size == bar.layout.panelSize)
            #expect(bar.pillOrigin.x + bar.layout.size.width / 2 == center.x)
            #expect(bar.pillOrigin.y + bar.layout.size.height / 2 == center.y)
            #expect(settings.floatingBarOrigin?.x == Double(bar.pillOrigin.x))
        }
        let restored = FloatingBar(controller: TimerController(settings: settings,
            stats: StatsStore(fileURL: makeScratchStatsURL()), shared: makeAppTestSharedStore()), settings: settings)
        defer { restored.close() }
        #expect(restored.layout.orientation == .vertical)
        #expect(restored.pillOrigin == bar.pillOrigin)
        // Clip a few points while keeping the pill's center on this display;
        // an adjacent display may begin immediately at bounds.maxX.
        bar.setFrameOrigin(CGPoint(x: bounds.maxX - bar.layout.size.width - FloatingBar.margin + 4,
                                  y: bounds.maxY - bar.layout.size.height - FloatingBar.margin + 4))
        settings.pillOrientation = .horizontal
        let actual = CGRect(origin: bar.pillOrigin, size: bar.layout.size)
        #expect(bounds.contains(actual))
    }

    @Test("Secondary click works on controls and readout, excludes margins and hidden compact controls")
    func secondaryClickRouting() throws {
        let (bar, settings, _) = makeBar()
        defer { bar.close() }
        for orientation in PillOrientation.allCases {
            settings.pillOrientation = orientation
            for compact in [false, true] {
                bar.geometry.hitFrame = bar.layout.visibleFrame(compact: compact)
                for index in -1..<3 {
                    let rect = index < 0 ? bar.layout.dragFrame : bar.layout.controlFrame(index: index)
                    let native = bar.layout.nativeRect(rect)
                    for type in [NSEvent.EventType.rightMouseDown, .leftMouseDown] {
                        let event = try #require(NSEvent.mouseEvent(with: type,
                            location: CGPoint(x: native.midX, y: native.midY),
                            modifierFlags: type == .leftMouseDown ? [.control] : [], timestamp: 0,
                            windowNumber: bar.windowNumber, context: nil, eventNumber: 1, clickCount: 1, pressure: 1))
                        #expect(bar.acceptsContextMenu(event) == (!compact || index < 1))
                    }
                }
                let margin = try #require(NSEvent.mouseEvent(with: .rightMouseDown, location: .zero,
                    modifierFlags: [], timestamp: 0, windowNumber: bar.windowNumber, context: nil,
                    eventNumber: 1, clickCount: 1, pressure: 1))
                #expect(!bar.acceptsContextMenu(margin))
            }
        }
    }

    @Test("Menu actions open settings, persist layout and hide without resetting a paused or running timer")
    func actionsPreserveSession() throws {
        let (bar, settings, controller) = makeBar()
        defer { bar.close(); controller.pause() }
        var opened = 0
        bar.onOpenSettings = { opened += 1 }
        var musicSignals: [Bool] = []
        controller.onFocusRunningChanged = { musicSignals.append($0) }
        // An unapplied duration edit reveals any accidental call to settingsChanged.
        let remaining = controller.remainingSeconds
        settings.focusMinutes = 45
        for running in [false, true] {
            if running { controller.start() }
            let menu = bar.makeContextMenu()
            #expect(menu.items.map(\.title) == ["Settings…", "Switch to \(settings.pillOrientation.opposite.title)", "", "Hide Floating Bar"])
            menu.performActionForItem(at: 0)
            #expect(opened == (running ? 2 : 1))
            let before = musicSignals
            menu.performActionForItem(at: 1)
            #expect(bar.layout.orientation == settings.pillOrientation)
            #expect(controller.remainingSeconds == remaining)
            #expect(controller.totalSeconds == 1500)
            #expect(controller.isRunning == running)
            menu.performActionForItem(at: 3)
            #expect(!settings.showFloatingBar && !bar.isVisible && !bar.stage.showsCompanion)
            #expect(controller.remainingSeconds == remaining && controller.isRunning == running)
            #expect(musicSignals == before)
            settings.showFloatingBar = true
        }
    }
}

private struct PillReviewRoster: View {
    @Bindable var settings: PomodoroSettings
    let onSettings: () -> Void
    var body: some View {
        VStack(spacing: 8) {
            let roster = PomodoroCharacter.allCases.filter { $0 != .none }
            ForEach(0..<2, id: \.self) { row in
                HStack {
                    ForEach(Array(roster[(row * 3)..<(row * 3 + 3)])) { character in
                        Button(character.displayName) { settings.character = character }
                    }
                }
            }
            HStack {
                Button("Settings…", action: onSettings)
                Button(settings.showFloatingBar ? "Hide Floating Bar" : "Show Floating Bar") {
                    settings.showFloatingBar.toggle()
                }
            }
        }.padding(12).pomodoroAppearance(settings.theme, inWindow: true)
    }
}

@MainActor
private final class PillReviewDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) { Self.stop() }
    static func stop() {
        let app = NSApplication.shared
        app.stop(nil)
        if let event = NSEvent.otherEvent(with: .applicationDefined, location: .zero, modifierFlags: [],
            timestamp: 0, windowNumber: 0, context: nil, subtype: 0, data1: 0, data2: 0) {
            app.postEvent(event, atStart: true)
        }
    }
}
