import Testing
@testable import PomodoroUI

/// The compact-mode decision, exhaustively.
///
/// Worth enumerating rather than spot-checking: the rule is a conjunction of five
/// independent vetoes, and a dropped one fails silently — the bar simply collapses
/// at a moment it should not, which nobody notices until it hides the controls
/// during a break.
@Suite("Bar presentation policy")
struct BarPresentationPolicyTests {

    /// Every input in the position that permits a compact bar.
    private var allClear: BarPresentationPolicy {
        BarPresentationPolicy(
            compactEnabled: true,
            isRunning: true,
            hovering: false,
            voiceOverRunning: false,
            awaitingAcknowledgement: false
        )
    }

    @Test("All clear is the only way to reach the compact form")
    func allClearIsCompact() {
        #expect(allClear.mode == .compact)
    }

    @Test("A fresh policy shows the full pill")
    func defaultsToExpanded() {
        #expect(BarPresentationPolicy().mode == .expanded)
    }

    @Test("The feature being off vetoes compact on its own")
    func disabledVetoes() {
        var policy = allClear
        policy.compactEnabled = false
        #expect(policy.mode == .expanded)
    }

    @Test("A stopped timer vetoes compact on its own")
    func stoppedVetoes() {
        var policy = allClear
        policy.isRunning = false
        #expect(policy.mode == .expanded)
    }

    @Test("The cursor on the bar vetoes compact on its own")
    func hoverVetoes() {
        var policy = allClear
        policy.hovering = true
        #expect(policy.mode == .expanded)
    }

    @Test("VoiceOver vetoes compact on its own, so the controls stay reachable")
    func voiceOverVetoes() {
        var policy = allClear
        policy.voiceOverRunning = true
        #expect(policy.mode == .expanded)
    }

    @Test("An unacknowledged phase change vetoes compact on its own")
    func acknowledgementVetoes() {
        var policy = allClear
        policy.awaitingAcknowledgement = true
        #expect(policy.mode == .expanded)
    }

    @Test("With the feature off, no combination of the other four can collapse it")
    func disabledIsInert() {
        for running in [false, true] {
            for hovering in [false, true] {
                for voiceOver in [false, true] {
                    for awaiting in [false, true] {
                        let policy = BarPresentationPolicy(
                            compactEnabled: false,
                            isRunning: running,
                            hovering: hovering,
                            voiceOverRunning: voiceOver,
                            awaitingAcknowledgement: awaiting
                        )
                        #expect(policy.mode == .expanded)
                    }
                }
            }
        }
    }
}

/// The timers around the policy.
///
/// Timings are injected so this suite runs in about a second instead of the half
/// minute the real backstop takes. The "not yet" assertions are safe against a
/// loaded machine: a timer can fire late, never early.
@Suite("Bar presentation model")
@MainActor
struct BarPresentationModelTests {

    private static let fast = BarPresentationModel.Timings(
        hoverExit: .milliseconds(20),
        acknowledgementBackstop: .milliseconds(300)
    )

    /// A model already in the state where compact is permitted.
    private func makeModel() -> BarPresentationModel {
        let model = BarPresentationModel(timings: Self.fast)
        model.setCompactEnabled(true)
        model.setRunning(true)
        return model
    }

    @Test("A running timer with the cursor away collapses")
    func collapsesWhileRunning() {
        #expect(makeModel().mode == .compact)
    }

    @Test("Hovering expands with no delay at all")
    func hoverExpandsImmediately() {
        let model = makeModel()
        model.setHovering(true)
        #expect(model.mode == .expanded)
    }

    @Test("Leaving the bar collapses it, but not instantly")
    func hoverOutIsDebounced() async throws {
        let model = makeModel()
        model.setHovering(true)
        model.setHovering(false)
        #expect(model.mode == .expanded)

        try await Task.sleep(for: .milliseconds(120))
        #expect(model.mode == .compact)
    }

    @Test("Re-entering inside the delay cancels the pending collapse")
    func hoverInCancelsPendingCollapse() async throws {
        let model = makeModel()
        model.setHovering(true)
        model.setHovering(false)
        model.setHovering(true)

        try await Task.sleep(for: .milliseconds(120))
        #expect(model.mode == .expanded)
    }

    @Test("A phase change holds the bar open with the cursor nowhere near it")
    func phaseChangeHolds() async throws {
        let model = makeModel()
        model.beginPhaseChange()
        #expect(model.mode == .expanded)

        try await Task.sleep(for: .milliseconds(100))
        #expect(model.mode == .expanded)
    }

    @Test("Entering and leaving the bar acknowledges the phase change")
    func hoverThenLeaveAcknowledges() async throws {
        let model = makeModel()
        model.beginPhaseChange()

        model.setHovering(true)
        model.setHovering(false)

        try await Task.sleep(for: .milliseconds(120))
        #expect(model.mode == .compact)
    }

    @Test("Hovering without leaving is not an acknowledgement")
    func hoverAloneDoesNotAcknowledge() async throws {
        let model = makeModel()
        model.beginPhaseChange()
        model.setHovering(true)

        try await Task.sleep(for: .milliseconds(120))
        #expect(model.mode == .expanded)
    }

    @Test("The backstop collapses a phase change nobody ever looked at")
    func backstopCollapses() async throws {
        let model = makeModel()
        model.beginPhaseChange()

        try await Task.sleep(for: .milliseconds(500))
        #expect(model.mode == .compact)
    }

    @Test("A second phase change restarts the hold rather than inheriting it")
    func secondPhaseChangeRestartsHold() async throws {
        let model = makeModel()
        model.beginPhaseChange()
        model.setHovering(true)
        model.setHovering(false)

        try await Task.sleep(for: .milliseconds(120))
        #expect(model.mode == .compact)

        model.beginPhaseChange()
        #expect(model.mode == .expanded)

        try await Task.sleep(for: .milliseconds(100))
        #expect(model.mode == .expanded)
    }

    @Test("Pausing expands even mid-hold, and resuming collapses again")
    func runningStateFlowsThrough() {
        let model = makeModel()
        model.setRunning(false)
        #expect(model.mode == .expanded)

        model.setRunning(true)
        #expect(model.mode == .compact)
    }

    @Test("VoiceOver keeps the controls on screen no matter what")
    func voiceOverNeverCollapses() {
        let model = makeModel()
        model.setVoiceOverRunning(true)
        #expect(model.mode == .expanded)

        model.setVoiceOverRunning(false)
        #expect(model.mode == .compact)
    }

    @Test("Turning the feature off restores the pill at once")
    func disablingRestoresThePill() {
        let model = makeModel()
        #expect(model.mode == .compact)

        model.setCompactEnabled(false)
        #expect(model.mode == .expanded)
    }
}
