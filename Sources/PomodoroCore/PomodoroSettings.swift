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
        case chimeVolume
        case focusChime
        case breakChime
        case controlMusic
        case resumeMusicOnFocusStart
        case showFloatingBar
        case launchAtLogin
        case character
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
            Key.chimeVolume.rawValue: 1.0,
            // "Hero" and "Blow" are the two loudest system sounds, and distinct
            // enough from each other to tell apart without looking.
            Key.focusChime.rawValue: "Hero",
            Key.breakChime.rawValue: "Blow",
            Key.controlMusic.rawValue: true,
            Key.resumeMusicOnFocusStart.rawValue: true,
            Key.showFloatingBar.rawValue: true,
            Key.launchAtLogin.rawValue: false,
            Key.character.rawValue: PomodoroCharacter.none.rawValue,
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

    /// 0…2, where 1.0 is the sample's own recorded level. Above 1.0 the chime is
    /// genuinely amplified — see `ChimePlayer`, which is why this isn't capped at 1.
    public var chimeVolume: Double {
        get {
            access(keyPath: \.chimeVolume)
            guard defaults.object(forKey: Key.chimeVolume.rawValue) != nil else { return 1.0 }
            return min(max(defaults.double(forKey: Key.chimeVolume.rawValue), 0), 2)
        }
        set { write(.chimeVolume, min(max(newValue, 0), 2), \.chimeVolume) }
    }

    public var focusChime: String {
        get { access(keyPath: \.focusChime); return defaults.string(forKey: Key.focusChime.rawValue) ?? "Hero" }
        set { write(.focusChime, newValue, \.focusChime) }
    }

    public var breakChime: String {
        get { access(keyPath: \.breakChime); return defaults.string(forKey: Key.breakChime.rawValue) ?? "Blow" }
        set { write(.breakChime, newValue, \.breakChime) }
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

    /// Who pops out from behind the pill on a phase change. `.none` means the whole
    /// feature is off and no stage is ever built.
    public var character: PomodoroCharacter {
        get {
            access(keyPath: \.character)
            let raw = defaults.string(forKey: Key.character.rawValue) ?? PomodoroCharacter.none.rawValue
            return PomodoroCharacter(rawValue: raw) ?? .none
        }
        set {
            // Not `write(_:_:_:)`: that infers its value type from the key path, and
            // what goes into `UserDefaults` here is the raw string, not the enum.
            withMutation(keyPath: \.character) {
                defaults.set(newValue.rawValue, forKey: Key.character.rawValue)
            }
            onChange?()
        }
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
