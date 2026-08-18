import Foundation
import Observation

/// Which of the floating bar's two forms is on screen.
///
/// This is the bar's only presentation output, and deliberately so. The view used to
/// take the box width from here and the visibility of reset and skip from the raw hover
/// flag, which let the two disagree: every rule below except `hovering` opened the box
/// while leaving the controls parked, so the pill grew by a third and put nothing in it.
/// Reset and skip now follow the form, which is also what finally makes the VoiceOver
/// rule mean what it says.
public enum BarMode: Equatable, Sendable {
    /// The full pill: ring, countdown, phase label, play/pause, and reset and skip.
    case expanded
    /// The same bar cut off after play/pause: ring, countdown, phase label, play/pause.
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
    /// Applied raw, with no debounce. The morph is slow and interruptible enough
    /// to absorb a cursor that only brushes past — see `setHovering`.
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
/// The struct holds the decision; this holds the clock. One timer, now: the long
/// one that gives up waiting for the user to notice a phase change. Hover goes
/// straight through — see `setHovering` for why it no longer needs a timer of
/// its own.
@Observable
@MainActor
public final class BarPresentationModel {

    /// Injected so the lifecycle tests run in a second rather than in half a
    /// minute of real waiting.
    public struct Timings: Sendable {
        /// How long an unacknowledged phase change holds the bar open.
        public var acknowledgementBackstop: Duration

        public init(acknowledgementBackstop: Duration) {
            self.acknowledgementBackstop = acknowledgementBackstop
        }

        public static let standard = Timings(acknowledgementBackstop: .seconds(30))
    }

    public private(set) var policy = BarPresentationPolicy()

    public var mode: BarMode { policy.mode }

    @ObservationIgnored private let timings: Timings
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

    /// Applied the instant it arrives. There is no hover debounce.
    ///
    /// There used to be, to keep a cursor flicked across the bar from driving a full
    /// open and close. The animation absorbs that far better than a timer did: the
    /// morph is a slow, critically damped spring, so a flick barely gets underway
    /// before the reversal re-targets it, and the spring carries its velocity into
    /// the return rather than restarting. What it looks like is the bar breathing
    /// once, which is what happens on iOS and is *why* those animations are long.
    ///
    /// A debounce cannot do that job without also costing responsiveness, because
    /// the two are the same number: every millisecond that rejects an accidental
    /// pass is a millisecond of the bar ignoring a deliberate one.
    ///
    /// This does mean brushing the bar counts as having looked at it, so it can
    /// acknowledge a phase change. That is a fair reading of a cursor crossing the
    /// thing, and the 30s backstop is the real guarantee anyway.
    public func setHovering(_ hovering: Bool) {
        guard hovering != policy.hovering else { return }

        if hovering {
            sawHoverSincePhaseChange = true
        } else if sawHoverSincePhaseChange {
            // Having entered and left is the acknowledgement.
            clearAcknowledgement()
        }
        policy.hovering = hovering
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

    /// Waits for the acknowledgement backstop to finish, so a test can assert on the
    /// settled state instead of racing a wall clock.
    ///
    /// Sleeping for "long enough" is not good enough here: the timer resumes on the
    /// main actor, and the render tests hold it for whole seconds at a time, so a
    /// margin that passes alone fails in the full suite. Nothing in the app calls
    /// this — a cancelled backstop is nil by then, so there is never anything to
    /// await but live work.
    func settle() async {
        await backstopTask?.value
    }
}
