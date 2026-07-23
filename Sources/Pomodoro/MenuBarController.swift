import AppKit
import PomodoroCore

/// The menu bar countdown and its menu.
///
/// The status item title is plain text rather than an image so it stays legible at
/// every menu bar height and in both appearances, and a monospaced-digit font stops
/// the item resizing on every tick.
@MainActor
final class MenuBarController {

    private let statusItem: NSStatusItem
    private let controller: TimerController
    private let settings: PomodoroSettings
    private let stats: StatsStore

    private let toggleItem = NSMenuItem(title: "Start", action: #selector(togglePressed), keyEquivalent: "s")
    private let skipItem = NSMenuItem(title: "Skip", action: #selector(skipPressed), keyEquivalent: "k")
    private let resetItem = NSMenuItem(title: "Reset", action: #selector(resetPressed), keyEquivalent: "r")
    private let floatingItem = NSMenuItem(title: "Show Floating Bar", action: #selector(floatingPressed), keyEquivalent: "f")
    private let statusHeader = NSMenuItem(title: "", action: nil, keyEquivalent: "")

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

        statusHeader.isEnabled = false
        menu.addItem(statusHeader)
        menu.addItem(.separator())

        for item in [toggleItem, skipItem, resetItem] {
            item.target = self
            menu.addItem(item)
        }

        menu.addItem(.separator())
        floatingItem.target = self
        menu.addItem(floatingItem)

        let statsItem = NSMenuItem(title: "Statistics…", action: #selector(statsPressed), keyEquivalent: "t")
        statsItem.target = self
        menu.addItem(statsItem)

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(settingsPressed), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit Pomodoro", action: #selector(quitPressed), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - Display

    func refresh() {
        guard let button = statusItem.button else { return }
        button.attributedTitle = NSAttributedString(
            string: "\(controller.phase.symbol) \(controller.displayTime)",
            attributes: [.font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)]
        )
        button.toolTip = "\(controller.phase.title) — \(controller.displayTime) remaining"

        toggleItem.title = controller.isRunning ? "Pause" : "Start"
        floatingItem.title = settings.showFloatingBar ? "Hide Floating Bar" : "Show Floating Bar"

        let done = stats.stats().pomodoros
        statusHeader.title = "\(controller.phase.title) · \(done) today"
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
