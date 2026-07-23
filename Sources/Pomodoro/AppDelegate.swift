import AppKit
import PomodoroCore
import SwiftUI

/// Wires everything together and owns the windows.
///
/// This is the only place that knows about all the pieces; each component below it
/// depends only on the timer and settings, never on each other.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private let settings = PomodoroSettings()
    private let stats = StatsStore()

    private var controller: TimerController!
    private var menuBar: MenuBarController!
    private var notifier: Notifier!
    private var music: MusicController = ChainedMusicController()

    private var floatingBar: FloatingBar?
    private var settingsWindow: NSWindow?
    private var statsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        controller = TimerController(settings: settings, stats: stats)
        notifier = Notifier(settings: settings)
        menuBar = MenuBarController(controller: controller, settings: settings, stats: stats)

        controller.onUpdate = { [weak self] in self?.refreshViews() }
        controller.onPhaseElapsed = { [weak self] finished, next in
            self?.handlePhaseChange(finished: finished, next: next)
        }

        settings.onChange = { [weak self] in
            guard let self else { return }
            controller.settingsChanged()
            syncFloatingBarVisibility()
            if !settings.controlMusic { music.forgetPaused() }
        }

        menuBar.onOpenSettings = { [weak self] in self?.showPomodoroSettings() }
        menuBar.onOpenStats = { [weak self] in self?.showStats() }
        menuBar.onToggleFloatingBar = { [weak self] in
            guard let self else { return }
            settings.showFloatingBar.toggle()
        }

        notifier.requestAuthorization()
        syncFloatingBarVisibility()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Never leave the user's music paused because the app went away.
        music.resumeIfWePaused()
        floatingBar?.persistPosition(to: settings)
    }

    // MARK: - Phase changes

    private func handlePhaseChange(finished: Phase, next: Phase) {
        notifier.announce(finished: finished, next: next)

        guard settings.controlMusic else { return }
        if finished == .focus {
            music.pauseIfPlaying()
        } else if next == .focus, settings.resumeMusicOnFocusStart {
            music.resumeIfWePaused()
        }
    }

    // MARK: - Views

    private func refreshViews() {
        menuBar.refresh()
        floatingBar?.refresh()
    }

    private func syncFloatingBarVisibility() {
        if settings.showFloatingBar {
            if floatingBar == nil {
                floatingBar = FloatingBar(controller: controller, settings: settings)
                observeFloatingBarMoves()
            }
            floatingBar?.orderFrontRegardless()
            floatingBar?.refresh()
        } else {
            floatingBar?.persistPosition(to: settings)
            floatingBar?.orderOut(nil)
        }
        menuBar.refresh()
    }

    /// Persist the pill's position as soon as the user finishes dragging it, so it
    /// survives a crash or a force-quit, not just a clean exit.
    private func observeFloatingBarMoves() {
        guard let bar = floatingBar else { return }
        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: bar,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                bar.persistPosition(to: self.settings)
            }
        }
    }

    // MARK: - Windows

    private func showPomodoroSettings() {
        if settingsWindow == nil {
            settingsWindow = makeWindow(
                title: "Pomodoro Settings",
                content: SettingsView(settings: settings) { [weak self] in
                    self?.settings.onChange?()
                }
            )
        }
        present(settingsWindow)
    }

    private func showStats() {
        if statsWindow == nil {
            statsWindow = makeWindow(title: "Statistics", content: StatsView(stats: stats))
        }
        present(statsWindow)
    }

    private func makeWindow(title: String, content: some View) -> NSWindow {
        let hosting = NSHostingController(rootView: content)
        let window = NSWindow(contentViewController: hosting)
        window.title = title
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }

    /// This is an accessory app with no Dock icon, so it must activate itself to
    /// bring a window forward — ordering front alone would leave it behind.
    private func present(_ window: NSWindow?) {
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
