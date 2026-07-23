import Foundation
import Observation
import PomodoroCore

/// Drives the pomodoro cycle in real time.
///
/// Timing is deadline-based: the controller stores an absolute `Date` and derives
/// the remaining seconds from it on every tick. That makes it immune to tick drift
/// and to system sleep — on wake the remaining time is already correct, and a
/// deadline that passed while asleep fires immediately.
@Observable
@MainActor
public final class TimerController {

    // MARK: - Observable state

    public private(set) var phase: Phase = .focus
    public private(set) var isRunning = false
    public private(set) var remainingSeconds: Int
    public private(set) var completedFocusSessions = 0

    // MARK: - Collaborators

    @ObservationIgnored private let settings: PomodoroSettings
    @ObservationIgnored private let stats: StatsStore
    @ObservationIgnored private var ticker: Timer?
    @ObservationIgnored private var deadline: Date?

    /// Fired on every visible change so AppKit views can redraw. SwiftUI views use
    /// observation instead and ignore this.
    @ObservationIgnored public var onUpdate: (() -> Void)?

    /// Fired when a phase elapses naturally: `(finished, next)`.
    @ObservationIgnored public var onPhaseElapsed: ((Phase, Phase) -> Void)?

    public init(settings: PomodoroSettings, stats: StatsStore) {
        self.settings = settings
        self.stats = stats
        self.remainingSeconds = PomodoroEngine.duration(of: .focus, settings: settings)
    }

    // MARK: - Derived

    public var totalSeconds: Int {
        PomodoroEngine.duration(of: phase, settings: settings)
    }

    /// 0…1, how much of the current phase has elapsed.
    public var progress: Double {
        let total = totalSeconds
        guard total > 0 else { return 0 }
        return min(max(Double(total - remainingSeconds) / Double(total), 0), 1)
    }

    public var displayTime: String {
        let clamped = max(remainingSeconds, 0)
        return String(format: "%02d:%02d", clamped / 60, clamped % 60)
    }

    // MARK: - Intents

    public func toggle() {
        isRunning ? pause() : start()
    }

    public func start() {
        guard !isRunning else { return }
        if remainingSeconds <= 0 { remainingSeconds = totalSeconds }
        deadline = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        isRunning = true
        scheduleTicker()
        publish()
    }

    public func pause() {
        guard isRunning else { return }
        syncRemaining()
        isRunning = false
        deadline = nil
        stopTicker()
        publish()
    }

    /// Abandon the current phase and move to the next one without recording it.
    public func skip() {
        let finished = phase
        let next = PomodoroEngine.next(
            after: finished,
            completedFocusSessions: completedFocusSessions,
            pomodorosUntilLongBreak: settings.pomodorosUntilLongBreak
        )
        transition(to: next)
    }

    /// Back to a fresh, stopped focus session. Does not clear today's stats.
    public func reset() {
        stopTicker()
        isRunning = false
        deadline = nil
        phase = .focus
        completedFocusSessions = 0
        remainingSeconds = totalSeconds
        publish()
    }

    /// Re-read durations after the user edits settings. A running phase keeps its
    /// existing deadline; a stopped one snaps to the new duration.
    public func settingsChanged() {
        if !isRunning {
            remainingSeconds = totalSeconds
        }
        publish()
    }

    // MARK: - Ticking

    private func scheduleTicker() {
        stopTicker()
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        // .common so the countdown keeps updating while a menu is open.
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    private func syncRemaining() {
        guard let deadline else { return }
        remainingSeconds = max(Int(deadline.timeIntervalSinceNow.rounded(.up)), 0)
    }

    private func tick() {
        guard isRunning, let deadline else { return }

        if deadline.timeIntervalSinceNow <= 0 {
            elapse()
        } else {
            let previous = remainingSeconds
            syncRemaining()
            if remainingSeconds != previous { publish() }
        }
    }

    /// The current phase ran to completion.
    private func elapse() {
        let finished = phase

        if finished == .focus {
            completedFocusSessions += 1
            stats.record(focusSeconds: PomodoroEngine.duration(of: .focus, settings: settings))
        }

        let next = PomodoroEngine.next(
            after: finished,
            completedFocusSessions: completedFocusSessions - (finished == .focus ? 1 : 0),
            pomodorosUntilLongBreak: settings.pomodorosUntilLongBreak
        )

        transition(to: next)
        onPhaseElapsed?(finished, next)

        if PomodoroEngine.shouldAutoStart(after: finished, settings: settings) {
            start()
        }
    }

    private func transition(to next: Phase) {
        stopTicker()
        isRunning = false
        deadline = nil
        phase = next
        remainingSeconds = totalSeconds
        publish()
    }

    private func publish() {
        onUpdate?()
    }
}
