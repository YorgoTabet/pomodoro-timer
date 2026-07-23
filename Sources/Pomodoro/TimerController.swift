import Foundation
import Observation
import PomodoroCore
import WidgetKit

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

    /// The length this phase actually started with.
    ///
    /// Deliberately *not* re-read from settings: editing "focus = 45" halfway
    /// through a 25-minute session must not make the ring jump backwards, or claim
    /// the session is 55% done when the countdown says two seconds. The new
    /// duration applies from the next phase.
    public private(set) var phaseTotalSeconds: Int

    // MARK: - Collaborators

    @ObservationIgnored private let settings: PomodoroSettings
    @ObservationIgnored private let stats: StatsStore
    @ObservationIgnored private let shared = SharedStore()
    @ObservationIgnored private var lastCommandID: UUID?
    @ObservationIgnored private var lastMirroredSignature: String?
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
        let focusDuration = PomodoroEngine.duration(of: .focus, settings: settings)
        self.remainingSeconds = focusDuration
        self.phaseTotalSeconds = focusDuration
        mirrorToWidget()
    }

    // MARK: - Derived

    public var totalSeconds: Int { phaseTotalSeconds }

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
        if remainingSeconds <= 0 {
            phaseTotalSeconds = PomodoroEngine.duration(of: phase, settings: settings)
            remainingSeconds = phaseTotalSeconds
        }
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
        phaseTotalSeconds = PomodoroEngine.duration(of: .focus, settings: settings)
        remainingSeconds = phaseTotalSeconds
        publish()
    }

    /// Re-read durations after the user edits settings. A phase that is already
    /// running keeps the length it started with; a stopped one adopts the new value
    /// straight away, since nothing is mid-flight to disturb.
    public func settingsChanged() {
        if !isRunning {
            phaseTotalSeconds = PomodoroEngine.duration(of: phase, settings: settings)
            remainingSeconds = phaseTotalSeconds
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
        phaseTotalSeconds = PomodoroEngine.duration(of: next, settings: settings)
        remainingSeconds = phaseTotalSeconds
        publish()
    }

    private func publish() {
        onUpdate?()
        mirrorToWidget()
    }

    // MARK: - Widget bridge

    /// Mirror state into the shared container so the widget can draw it, then ask
    /// WidgetKit to reload. The widget renders its own live countdown from
    /// `deadline`, so this only needs to run on real state changes — not on every
    /// tick of the clock.
    private func mirrorToWidget() {
        // The per-second countdown is not part of the signature: while running, the
        // widget derives it from `deadline`, so re-writing the file every second
        // would burn WidgetKit's reload budget for no visible change.
        let signature = "\(phase.rawValue)|\(isRunning)|\(deadline?.timeIntervalSince1970 ?? -1)|\(totalSeconds)|\(isRunning ? 0 : remainingSeconds)|\(completedFocusSessions)"
        guard signature != lastMirroredSignature else { return }
        lastMirroredSignature = signature

        shared.write(TimerSnapshot(
            phase: phase,
            isRunning: isRunning,
            deadline: deadline,
            remainingSeconds: remainingSeconds,
            totalSeconds: totalSeconds,
            completedToday: stats.stats().pomodoros,
            cyclePosition: completedFocusSessions % max(settings.pomodorosUntilLongBreak, 1),
            cycleLength: settings.pomodorosUntilLongBreak,
            updatedAt: Date()
        ))
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Apply a command the widget dropped in the shared container. Returns `false`
    /// if it was one we have already handled.
    @discardableResult
    public func applyPendingCommand() -> Bool {
        guard let pending = shared.readCommand(), pending.id != lastCommandID else { return false }
        lastCommandID = pending.id
        shared.clearCommand()

        switch pending.command {
        case .toggle: toggle()
        case .start: start()
        case .pause: pause()
        case .skip: skip()
        case .reset: reset()
        }
        return true
    }
}
