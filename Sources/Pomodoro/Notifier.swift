import AppKit
import PomodoroCore
import UserNotifications
import os

private let log = Logger(subsystem: "com.yorgotabet.pomodoro", category: "notify")

/// Banner + chime when a phase ends.
///
/// `UNUserNotificationCenter` traps when the process is not an `.app` bundle, so the
/// whole banner path is disabled outside one. That keeps `swift run` usable during
/// development, where the chime alone is enough feedback.
@MainActor
public final class Notifier: NSObject, UNUserNotificationCenterDelegate {

    private let settings: PomodoroSettings
    private let isBundled: Bool
    private var authorized = false

    public init(settings: PomodoroSettings) {
        self.settings = settings
        self.isBundled = Bundle.main.bundleURL.pathExtension == "app"
            && Bundle.main.bundleIdentifier != nil
        super.init()
    }

    public func requestAuthorization() {
        guard isBundled else {
            log.info("Not running from an .app bundle — banners disabled, chime only.")
            return
        }
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, error in
            if let error { log.warning("Notification authorization failed: \(error, privacy: .public)") }
            Task { @MainActor in self?.authorized = granted }
        }
    }

    /// Announce that `finished` ended and `next` is up.
    public func announce(finished: Phase, next: Phase) {
        if settings.chimeEnabled { playChime(for: finished) }
        guard settings.notificationsEnabled, isBundled, authorized else { return }

        let content = UNMutableNotificationContent()
        content.title = finished == .focus ? "Pomodoro complete" : "\(finished.title) over"
        content.body = next == .focus
            ? "Back to focus — \(settings.focusMinutes) min."
            : "Time for a \(next.title.lowercased()) — \(minutes(of: next)) min."
        content.sound = nil   // we play our own, so the banner stays silent

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil   // deliver immediately
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func minutes(of phase: Phase) -> Int {
        PomodoroEngine.duration(of: phase, settings: settings) / 60
    }

    private func playChime(for finished: Phase) {
        // Two distinct sounds so focus-end and break-end are tellable apart without
        // looking at the screen.
        let name = finished == .focus ? settings.focusChime : settings.breakChime
        ChimePlayer.shared.play(name, volume: settings.chimeVolume)
    }

    // Show the banner even while Pomodoro is the frontmost app.
    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list]
    }
}
