import Foundation
import ServiceManagement
import os

private let log = Logger(subsystem: "com.yorgotabet.pomodoro", category: "login")

/// Launch-at-login, via `SMAppService` — the modern replacement for the deprecated
/// `SMLoginItemSetEnabled`, which needed a separate helper bundle.
///
/// Registration only works from an `.app` bundle in a stable location, so this
/// reports `isAvailable == false` when running from the build directory.
enum LoginItem {

    static var isAvailable: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }

    /// Whether the system actually has a registration for us.
    ///
    /// Not usable as the switch's value: `SMAppService.mainApp.status` reports
    /// `.enabled` for this app even when `launchctl` knows nothing about it, so the
    /// stored preference is the source of truth for display and this is only used
    /// to reconcile that intent with reality at launch.
    static var isRegistered: Bool {
        guard isAvailable else { return false }
        return SMAppService.mainApp.status == .enabled
    }

    /// Re-apply the user's stored intent, in case a rebuild or a move dropped the
    /// registration.
    static func reconcile(desired: Bool) {
        guard isAvailable else { return }
        if desired && !isRegistered {
            setEnabled(true)
        } else if !desired && isRegistered {
            setEnabled(false)
        }
    }

    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        guard isAvailable else { return false }
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            log.warning("Login item \(enabled ? "register" : "unregister") failed: \(error, privacy: .public)")
            return false
        }
    }
}
