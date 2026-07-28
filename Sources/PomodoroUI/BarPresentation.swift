import Foundation

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
