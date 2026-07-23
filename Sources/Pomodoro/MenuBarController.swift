import AppKit
import PomodoroCore
import PomodoroUI
import SwiftUI

/// The menu bar countdown and its menu.
///
/// The status item pairs a template SF Symbol with monospaced-digit text: the symbol
/// so it adapts to light, dark, and reduced-transparency menu bars the way system
/// items do, and the digits so the item doesn't resize on every tick.
@MainActor
final class MenuBarController {

    private let statusItem: NSStatusItem
    private let controller: TimerController
    private let settings: PomodoroSettings
    private let stats: StatsStore

    private let headerItem = NSMenuItem()
    private let toggleItem = NSMenuItem(title: "Start", action: #selector(togglePressed), keyEquivalent: "s")
    private let skipItem = NSMenuItem(title: "Skip", action: #selector(skipPressed), keyEquivalent: "k")
    private let resetItem = NSMenuItem(title: "Reset", action: #selector(resetPressed), keyEquivalent: "r")
    private let floatingItem = NSMenuItem(title: "Show Floating Bar", action: #selector(floatingPressed), keyEquivalent: "f")

    /// Set by the app delegate; the menu bar doesn't own the windows.
    var onOpenSettings: (() -> Void)?
    var onOpenStats: (() -> Void)?
    var onToggleFloatingBar: (() -> Void)?

    init(controller: TimerController, settings: PomodoroSettings, stats: StatsStore) {
        self.controller = controller
        self.settings = settings
        self.stats = stats
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        buildMenu()
        refresh()
    }

    // MARK: - Menu

    private func buildMenu() {
        let menu = NSMenu()

        let header = NSHostingView(rootView: MenuHeaderView(
            controller: controller,
            settings: settings,
            completedToday: stats.stats().pomodoros
        ))
        header.frame = NSRect(x: 0, y: 0, width: 258, height: 90)
        headerItem.view = header
        menu.addItem(headerItem)
        menu.addItem(.separator())

        for (item, symbol) in [(toggleItem, "play.fill"), (skipItem, "forward.end.fill"), (resetItem, "arrow.counterclockwise")] {
            item.target = self
            item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
            menu.addItem(item)
        }

        menu.addItem(.separator())

        floatingItem.target = self
        floatingItem.image = NSImage(systemSymbolName: "rectangle.topthird.inset.filled", accessibilityDescription: nil)
        menu.addItem(floatingItem)

        addItem(to: menu, "Statistics…", symbol: "chart.bar.fill", key: "t", action: #selector(statsPressed))
        addItem(to: menu, "Settings…", symbol: "gearshape.fill", key: ",", action: #selector(settingsPressed))

        menu.addItem(.separator())
        addItem(to: menu, "Quit Pomodoro", symbol: "power", key: "q", action: #selector(quitPressed))

        statusItem.menu = menu
    }

    private func addItem(to menu: NSMenu, _ title: String, symbol: String, key: String, action: Selector) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        menu.addItem(item)
    }

    // MARK: - Display

    func refresh() {
        guard let button = statusItem.button else { return }

        let symbol = NSImage(
            systemSymbolName: Theme.symbol(for: controller.phase),
            accessibilityDescription: controller.phase.title
        )
        // Template rendering lets the menu bar tint it, which is what keeps it
        // legible against a wallpaper in both appearances.
        symbol?.isTemplate = true
        button.image = symbol
        button.imagePosition = .imageLeading

        button.attributedTitle = NSAttributedString(
            string: " \(controller.displayTime)",
            attributes: [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 12.5, weight: .regular),
                // Paused reads as dimmed, so a glance distinguishes "counting" from
                // "waiting for me" without reading the number twice.
                .foregroundColor: controller.isRunning
                    ? NSColor.labelColor
                    : NSColor.secondaryLabelColor,
            ]
        )
        button.toolTip = "\(controller.phase.title) — \(controller.displayTime) remaining"

        toggleItem.title = controller.isRunning ? "Pause" : "Start"
        toggleItem.image = NSImage(
            systemSymbolName: controller.isRunning ? "pause.fill" : "play.fill",
            accessibilityDescription: nil
        )
        floatingItem.title = settings.showFloatingBar ? "Hide Floating Bar" : "Show Floating Bar"

        // The header is SwiftUI observing the controller, so it redraws itself; only
        // today's count has to be pushed, since it lives in the stats store.
        if let host = headerItem.view as? NSHostingView<MenuHeaderView> {
            host.rootView = MenuHeaderView(
                controller: controller,
                settings: settings,
                completedToday: stats.stats().pomodoros
            )
        }
    }

    // MARK: - Actions

    @objc private func togglePressed() { controller.toggle() }
    @objc private func skipPressed() { controller.skip() }
    @objc private func resetPressed() { controller.reset() }
    @objc private func floatingPressed() { onToggleFloatingBar?() }
    @objc private func statsPressed() { onOpenStats?() }
    @objc private func settingsPressed() { onOpenSettings?() }
    @objc private func quitPressed() { NSApp.terminate(nil) }
}
