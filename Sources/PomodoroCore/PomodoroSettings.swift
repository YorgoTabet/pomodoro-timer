import Foundation
import Observation

/// User preferences, persisted in `UserDefaults`.
///
/// `@Observable` so SwiftUI settings controls bind directly; AppKit consumers that
/// need to react to a change register a `onChange` callback instead.
@Observable
public final class PomodoroSettings {

    public enum Key: String, CaseIterable {
        case focusMinutes
        case shortBreakMinutes
        case longBreakMinutes
        case pomodorosUntilLongBreak
        case autoStartBreaks
        case autoStartFocus
        case notificationsEnabled
        case chimeEnabled
        case controlMusic
        case resumeMusicOnFocusStart
        case showFloatingBar
        case launchAtLogin
        case floatingBarX
        case floatingBarY
    }

    @ObservationIgnored private let defaults: UserDefaults

    /// Called after any stored value changes, so AppKit views can redraw.
    @ObservationIgnored public var onChange: (() -> Void)?

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.focusMinutes.rawValue: 25,
            Key.shortBreakMinutes.rawValue: 5,
            Key.longBreakMinutes.rawValue: 15,
            Key.pomodorosUntilLongBreak.rawValue: 4,
            Key.autoStartBreaks.rawValue: true,
            Key.autoStartFocus.rawValue: false,
            Key.notificationsEnabled.rawValue: true,
            Key.chimeEnabled.rawValue: true,
            Key.controlMusic.rawValue: true,
            Key.resumeMusicOnFocusStart.rawValue: true,
            Key.showFloatingBar.rawValue: true,
            Key.launchAtLogin.rawValue: false,
        ])
    }

    // MARK: - Durations

    /// Durations are clamped rather than validated at the call site: a settings
    /// field is a text box, and a 0-minute or 10-hour pomodoro is never intended.
    public var focusMinutes: Int {
        get { access(keyPath: \.focusMinutes); return clampedMinutes(.focusMinutes) }
        set { write(.focusMinutes, min(max(newValue, 1), 240), \.focusMinutes) }
    }

    public var shortBreakMinutes: Int {
        get { access(keyPath: \.shortBreakMinutes); return clampedMinutes(.shortBreakMinutes) }
        set { write(.shortBreakMinutes, min(max(newValue, 1), 240), \.shortBreakMinutes) }
    }

    public var longBreakMinutes: Int {
        get { access(keyPath: \.longBreakMinutes); return clampedMinutes(.longBreakMinutes) }
        set { write(.longBreakMinutes, min(max(newValue, 1), 240), \.longBreakMinutes) }
    }

    public var pomodorosUntilLongBreak: Int {
        get {
            access(keyPath: \.pomodorosUntilLongBreak)
            return min(max(defaults.integer(forKey: Key.pomodorosUntilLongBreak.rawValue), 1), 12)
        }
        set { write(.pomodorosUntilLongBreak, min(max(newValue, 1), 12), \.pomodorosUntilLongBreak) }
    }

    // MARK: - Behaviour

    public var autoStartBreaks: Bool {
        get { access(keyPath: \.autoStartBreaks); return defaults.bool(forKey: Key.autoStartBreaks.rawValue) }
        set { write(.autoStartBreaks, newValue, \.autoStartBreaks) }
    }

    public var autoStartFocus: Bool {
        get { access(keyPath: \.autoStartFocus); return defaults.bool(forKey: Key.autoStartFocus.rawValue) }
        set { write(.autoStartFocus, newValue, \.autoStartFocus) }
    }

    public var notificationsEnabled: Bool {
        get { access(keyPath: \.notificationsEnabled); return defaults.bool(forKey: Key.notificationsEnabled.rawValue) }
        set { write(.notificationsEnabled, newValue, \.notificationsEnabled) }
    }

    public var chimeEnabled: Bool {
        get { access(keyPath: \.chimeEnabled); return defaults.bool(forKey: Key.chimeEnabled.rawValue) }
        set { write(.chimeEnabled, newValue, \.chimeEnabled) }
    }

    public var controlMusic: Bool {
        get { access(keyPath: \.controlMusic); return defaults.bool(forKey: Key.controlMusic.rawValue) }
        set { write(.controlMusic, newValue, \.controlMusic) }
    }

    public var resumeMusicOnFocusStart: Bool {
        get { access(keyPath: \.resumeMusicOnFocusStart); return defaults.bool(forKey: Key.resumeMusicOnFocusStart.rawValue) }
        set { write(.resumeMusicOnFocusStart, newValue, \.resumeMusicOnFocusStart) }
    }

    public var showFloatingBar: Bool {
        get { access(keyPath: \.showFloatingBar); return defaults.bool(forKey: Key.showFloatingBar.rawValue) }
        set { write(.showFloatingBar, newValue, \.showFloatingBar) }
    }

    /// What the user asked for, which is not the same as what the system reports.
    /// `SMAppService.mainApp.status` returns `.enabled` for this app even when
    /// nothing is registered, so trusting it made the switch claim launch-at-login
    /// was on when it was not.
    public var launchAtLogin: Bool {
        get { access(keyPath: \.launchAtLogin); return defaults.bool(forKey: Key.launchAtLogin.rawValue) }
        set { write(.launchAtLogin, newValue, \.launchAtLogin) }
    }

    // MARK: - Floating bar position

    /// `nil` until the bar has been dragged at least once, which means "use the
    /// default top-right placement".
    public var floatingBarOrigin: (x: Double, y: Double)? {
        get {
            guard defaults.object(forKey: Key.floatingBarX.rawValue) != nil else { return nil }
            return (defaults.double(forKey: Key.floatingBarX.rawValue),
                    defaults.double(forKey: Key.floatingBarY.rawValue))
        }
        set {
            guard let newValue else { return }
            defaults.set(newValue.x, forKey: Key.floatingBarX.rawValue)
            defaults.set(newValue.y, forKey: Key.floatingBarY.rawValue)
        }
    }

    // MARK: - Plumbing

    private func clampedMinutes(_ key: Key) -> Int {
        min(max(defaults.integer(forKey: key.rawValue), 1), 240)
    }

    private func write<V>(_ key: Key, _ value: V, _ keyPath: KeyPath<PomodoroSettings, V>) {
        withMutation(keyPath: keyPath) {
            defaults.set(value, forKey: key.rawValue)
        }
        onChange?()
    }
}
