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

    static var isEnabled: Bool {
        guard isAvailable else { return false }
        return SMAppService.mainApp.status == .enabled
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
