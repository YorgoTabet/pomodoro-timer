import Foundation
import Observation

/// Which of the floating bar's two forms is on screen.
public enum BarMode: Equatable, Sendable {
    /// The full pill: ring, countdown, phase label, and the hover controls.
    case expanded
    /// A bare progress ring. The one thing worth glancing at mid-session.
    case compact
}

/// The whole compact-mode decision: five booleans in, one form out.
///
/// A value type rather than flags scattered through the view, because the
/// behaviour it encodes is otherwise only reachable by running the app and
/// waiting out a real session. Five independent vetoes, none of them ordered.
public struct BarPresentationPolicy: Equatable, Sendable {

    public var compactEnabled: Bool
    public var isRunning: Bool
    /// Already debounced by `BarPresentationModel`. Raw hover changes must not be
    /// written here — a cursor clipping the bar's corner would collapse it twice.
    public var hovering: Bool
    public var voiceOverRunning: Bool
    /// Set by every phase change, cleared once the user has looked at the bar or
    /// the backstop expires.
    ///
    /// Outranks `isRunning` deliberately. `TimerController.transition(to:)` clears
    /// `isRunning` *before* the optional auto-start, so at the instant of a phase
    /// change the running rule alone would expand and then re-collapse a frame
    /// later — fighting the performance it exists to frame.
    public var awaitingAcknowledgement: Bool

    public init(
        compactEnabled: Bool = false,
        isRunning: Bool = false,
        hovering: Bool = false,
        voiceOverRunning: Bool = false,
        awaitingAcknowledgement: Bool = false
    ) {
        self.compactEnabled = compactEnabled
        self.isRunning = isRunning
        self.hovering = hovering
        self.voiceOverRunning = voiceOverRunning
        self.awaitingAcknowledgement = awaitingAcknowledgement
    }

    public var mode: BarMode {
        guard compactEnabled,
              !voiceOverRunning,
              isRunning,
              !hovering,
              !awaitingAcknowledgement
        else { return .expanded }
        return .compact
    }
}

/// Drives `BarPresentationPolicy` in real time.
///
/// The struct holds the decision; this holds the clock. Two timers: a short one
/// that delays collapsing after the cursor leaves, and a long one that gives up
/// waiting for the user to notice a phase change.
@Observable
@MainActor
public final class BarPresentationModel {

    /// Injected so the lifecycle tests run in a second rather than in half a
    /// minute of real waiting.
    public struct Timings: Sendable {
        /// Long enough to survive a window drag, short enough not to feel sticky.
        /// `isMovableByWindowBackground` drags begin with a hit test, and a hover
        /// drop mid-drag would otherwise collapse the pill out from under the grip.
        public var hoverExit: Duration
        /// How long an unacknowledged phase change holds the bar open.
        public var acknowledgementBackstop: Duration

        public init(hoverExit: Duration, acknowledgementBackstop: Duration) {
            self.hoverExit = hoverExit
            self.acknowledgementBackstop = acknowledgementBackstop
        }

        public static let standard = Timings(
            hoverExit: .milliseconds(350),
            acknowledgementBackstop: .seconds(30)
        )
    }

    public private(set) var policy = BarPresentationPolicy()

    public var mode: BarMode { policy.mode }

    @ObservationIgnored private let timings: Timings
    @ObservationIgnored private var hoverExitTask: Task<Void, Never>?
    @ObservationIgnored private var backstopTask: Task<Void, Never>?
    /// Guards against a stray hover-false clearing an acknowledgement nobody saw:
    /// the rule is enter *then* leave, not leave alone.
    @ObservationIgnored private var sawHoverSincePhaseChange = false

    public init(timings: Timings = .standard) {
        self.timings = timings
    }

    // MARK: - Inputs

    public func setCompactEnabled(_ enabled: Bool) {
        policy.compactEnabled = enabled
    }

    public func setRunning(_ running: Bool) {
        policy.isRunning = running
    }

    public func setVoiceOverRunning(_ running: Bool) {
        policy.voiceOverRunning = running
    }

    /// Hover in lands at once; hover out is delayed.
    public func setHovering(_ hovering: Bool) {
        hoverExitTask?.cancel()
        hoverExitTask = nil

        if hovering {
            sawHoverSincePhaseChange = true
            policy.hovering = true
            return
        }

        // Leaving is the acknowledgement, and it clears immediately rather than
        // after the debounce: the debounce is about the collapse being twitchy,
        // not about whether the transition was seen.
        if sawHoverSincePhaseChange {
            clearAcknowledgement()
        }

        let delay = timings.hoverExit
        hoverExitTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            self?.policy.hovering = false
        }
    }

    /// A phase elapsed: show the full bar and hold it until it has been seen.
    public func beginPhaseChange() {
        sawHoverSincePhaseChange = false
        policy.awaitingAcknowledgement = true

        backstopTask?.cancel()
        let delay = timings.acknowledgementBackstop
        backstopTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            self?.clearAcknowledgement()
        }
    }

    private func clearAcknowledgement() {
        backstopTask?.cancel()
        backstopTask = nil
        policy.awaitingAcknowledgement = false
    }

    /// Waits for any pending timer to finish, so a test can assert on the settled
    /// state instead of racing a wall clock.
    ///
    /// Sleeping for "long enough" is not good enough here: these timers resume on
    /// the main actor, and the render tests hold it for whole seconds at a time, so
    /// a margin that passes alone fails in the full suite. Nothing in the app calls
    /// this — cancelled timers are nil by the time they are cancelled, so there is
    /// never anything to await but live work.
    func settle() async {
        await hoverExitTask?.value
        await backstopTask?.value
    }
}
