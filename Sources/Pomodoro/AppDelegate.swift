import AppKit
import os
import PomodoroCore
import PomodoroUI
import SwiftUI

/// Wires everything together and owns the windows.
///
/// This is the only place that knows about all the pieces; each component below it
/// depends only on the timer and settings, never on each other.
private let musicLog = Logger(subsystem: "com.yorgotabet.pomodoro", category: "music")

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private let settings = PomodoroSettings()
    private let stats = StatsStore()

    private var controller: TimerController!
    private var menuBar: MenuBarController!
    private var notifier: Notifier!
    private var music: MusicController = ChainedMusicController()

    private var floatingBar: FloatingBar?
    private var commandPoller: Timer?
    private var settingsWindow: NSWindow?
    private var statsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Two traces, not nine. A wedged App Group container once hung launch
        // before any UI existed, and step-by-step tracing to a file was the only
        // thing that found it — os_log and print both lied. These two bracket the
        // whole of launch, which is enough to catch a recurrence.
        pomodoroDiag("didFinishLaunching start")
        controller = TimerController(settings: settings, stats: stats)
        notifier = Notifier(settings: settings)
        menuBar = MenuBarController(controller: controller, settings: settings, stats: stats)

        controller.onUpdate = { [weak self] in self?.refreshViews() }
        controller.onPhaseElapsed = { [weak self] finished, next in
            self?.handlePhaseChange(finished: finished, next: next)
        }
        controller.onFocusRunningChanged = { [weak self] running in
            self?.handleFocusRunning(running)
        }

        settings.onChange = { [weak self] in
            guard let self else { return }
            controller.settingsChanged()
            floatingBar?.stage.character = settings.character
            floatingBar?.presentation.setCompactEnabled(settings.compactFloatingBar)
            syncFloatingBarVisibility()
            if !settings.controlMusic { music.forgetPaused() }
        }

        menuBar.onOpenSettings = { [weak self] in self?.showSettings() }
        menuBar.onOpenStats = { [weak self] in self?.showStats() }
        menuBar.onToggleFloatingBar = { [weak self] in
            guard let self else { return }
            settings.showFloatingBar.toggle()
        }

        LoginItem.reconcile(desired: settings.launchAtLogin)
        notifier.requestAuthorization()
        syncFloatingBarVisibility()
        startCommandPolling()
        startDemoIfRequested()
        pomodoroDiag("didFinishLaunching end; character=\(settings.character.rawValue) showBar=\(settings.showFloatingBar) barExists=\(floatingBar != nil)")
    }

    /// `POMODORO_DEMO=focusStart|breakStart|longBreak` plays a character cue shortly
    /// after launch. Verifying an animation otherwise means waiting out a real
    /// session; this makes the loop seconds instead of minutes.
    private func startDemoIfRequested() {
        guard let name = ProcessInfo.processInfo.environment["POMODORO_DEMO"],
              let cue = CharacterCue(rawValue: name) else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            self.performCharacter(cue)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Never leave the user's music paused because the app went away.
        music.resumeIfWePaused()
        floatingBar?.persistPosition(to: settings)
    }

    // MARK: - Phase changes

    private func handlePhaseChange(finished: Phase, next: Phase) {
        notifier.announce(finished: finished, next: next)

        let cue = CharacterCue.cue(finished: finished, next: next)

        guard let bar = floatingBar else {
            performCharacter(cue)
            return
        }

        let wasCompact = bar.presentation.mode == .compact
        bar.presentation.beginPhaseChange()

        guard wasCompact else {
            performCharacter(cue)
            return
        }

        // Let the pill finish opening before the character uses it as a stage.
        // `CharacterStage` places and masks against the expanded `pillFrame`, so a
        // cue fired mid-morph would emerge from a pill that is not there yet.
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(FloatingBar.morphDuration))
            self.performCharacter(cue)
        }
    }

    /// Music runs with the focus timer, not with the phase.
    ///
    /// Tied to the run state rather than to phase changes so that the soundtrack
    /// matches what the user is actually doing: it starts when they press play, and
    /// stops the moment focus stops — whether that is the timer elapsing, a pause,
    /// a skip, or a reset. A focus session queued but not started stays silent.
    private func handleFocusRunning(_ running: Bool) {
        musicLog.notice("focus running=\(running, privacy: .public), controlMusic=\(self.settings.controlMusic, privacy: .public)")
        guard settings.controlMusic else { return }

        if running {
            guard settings.resumeMusicOnFocusStart else { return }
            music.startForFocus()
        } else {
            music.pauseIfPlaying()
        }
    }

    /// Send the character on stage, if one is chosen and there is a pill for it to
    /// hide behind.
    func performCharacter(_ cue: CharacterCue) {
        guard settings.character != .none, let bar = floatingBar else { return }

        let edge = StageEdge.resolve(
            preferred: CharacterPlan.preferredEdge(for: cue, character: settings.character),
            pill: bar.pillScreenFrameFlipped,
            screen: flippedScreenFrame(of: bar.screen ?? NSScreen.main),
            needed: CharacterStage.margin
        )
        bar.stage.perform(cue, character: settings.character, edge: edge)
    }

    /// The visible area of the screen the pill is on, in top-left coordinates,
    /// matching the space `StageEdge` reasons in.
    ///
    /// It has to be the pill's own screen: measuring against `NSScreen.main` put
    /// a pill on a second display "above the top" of the main one, so every
    /// character was sent below the bar. Flipped against the primary display's
    /// height, the same reference `pillScreenFrameFlipped` uses.
    private func flippedScreenFrame(of screen: NSScreen?) -> CGRect {
        guard let screen else { return .zero }
        let primaryHeight = NSScreen.screens.first?.frame.height ?? screen.frame.height
        let visible = screen.visibleFrame
        return CGRect(
            x: visible.minX,
            y: primaryHeight - visible.maxY,
            width: visible.width,
            height: visible.height
        )
    }

    // MARK: - Views

    private func refreshViews() {
        // The floating bar is SwiftUI observing the controller directly, so only the
        // AppKit status item needs pushing.
        menuBar.refresh()

        // Compact mode's two ambient inputs. Both are polled from here rather than
        // observed: `publish` already fires on every state change and once a second
        // while running, and a VoiceOver notification observer would be more
        // machinery than a boolean read is worth.
        floatingBar?.presentation.setRunning(controller.isRunning)
        floatingBar?.presentation.setVoiceOverRunning(NSWorkspace.shared.isVoiceOverEnabled)
    }

    /// Pick up buttons pressed in the widget.
    ///
    /// The widget extension is sandboxed and can't call into this process, so it
    /// leaves a command file in the shared container. Polling once a second is the
    /// simplest reliable pickup — checking a file's mtime costs far less than the
    /// entitlements and failure modes of real IPC, and a widget button is not a
    /// latency-critical control.
    private func startCommandPolling() {
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.controller.pollForWidgetCommand() }
        }
        RunLoop.main.add(timer, forMode: .common)
        commandPoller = timer
    }

    private func syncFloatingBarVisibility() {
        if settings.showFloatingBar {
            if floatingBar == nil {
                floatingBar = FloatingBar(controller: controller, settings: settings)
                // The stage must know the chosen character before any cue fires —
                // relying on `perform` to set it left it `.none` at rest.
                floatingBar?.stage.character = settings.character
                floatingBar?.presentation.setCompactEnabled(settings.compactFloatingBar)
                floatingBar?.presentation.setRunning(controller.isRunning)
                observeFloatingBarMoves()
            }
            floatingBar?.orderFrontRegardless()
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

    private func showSettings() {
        if settingsWindow == nil {
            settingsWindow = makeWindow(
                title: "Pomodoro Settings",
                content: SettingsView(
                    settings: settings,
                    onChange: { [weak self] in self?.settings.onChange?() },
                    onPreview: { [weak self] cue in self?.performCharacter(cue) }
                )
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
