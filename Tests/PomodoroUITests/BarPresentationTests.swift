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
/// Most of this is now synchronous: hover is applied raw, so only the
/// acknowledgement backstop involves a clock at all.
///
/// That one is injected so the suite runs in milliseconds instead of half a minute,
/// and waited on through `settle()` rather than a wall clock. Not fastidiousness:
/// the timer resumes on the main actor, the render tests hold it for seconds at a
/// stretch, and margins generous enough to pass this suite alone failed in the
/// full run.
@Suite("Bar presentation model")
@MainActor
struct BarPresentationModelTests {

    private static let fast = BarPresentationModel.Timings(
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

    /// Hover is applied raw — there is no debounce left to wait out.
    ///
    /// Absorbing a cursor that only brushes the bar is the animation's job now: the
    /// morph is a long, critically damped spring, and a reversal re-targets it from
    /// its current position and velocity rather than restarting. None of that is
    /// visible from here, which is the point — the model got simpler because the
    /// problem moved somewhere better suited to it.
    @Test("Hovering expands immediately")
    func hoverExpandsImmediately() {
        let model = makeModel()
        model.setHovering(true)
        #expect(model.mode == .expanded)
    }

    @Test("Leaving collapses immediately")
    func hoverOutCollapsesImmediately() {
        let model = makeModel()
        model.setHovering(true)
        model.setHovering(false)
        #expect(model.mode == .compact)
    }

    @Test("Repeating the hover state it is already in changes nothing")
    func redundantHoverIsInert() {
        let model = makeModel()
        model.setHovering(true)
        model.setHovering(true)
        #expect(model.mode == .expanded)

        model.setHovering(false)
        model.setHovering(false)
        #expect(model.mode == .compact)
    }

    @Test("A phase change holds the bar open with the cursor nowhere near it")
    func phaseChangeHolds() {
        let model = makeModel()
        model.beginPhaseChange()
        #expect(model.mode == .expanded)
    }

    @Test("Entering and leaving the bar acknowledges the phase change")
    func hoverThenLeaveAcknowledges() {
        let model = makeModel()
        model.beginPhaseChange()

        model.setHovering(true)
        model.setHovering(false)

        #expect(!model.policy.awaitingAcknowledgement)
        #expect(model.mode == .compact)
    }

    /// Leaving without ever having arrived is not an acknowledgement.
    ///
    /// Asserts the flag rather than the mode, and does not `settle()`, because
    /// waiting would run the backstop out and clear it for a different reason.
    @Test("A stray leave with no matching enter acknowledges nothing")
    func leaveWithoutEnterDoesNotAcknowledge() {
        let model = makeModel()
        model.beginPhaseChange()

        model.setHovering(false)

        #expect(model.policy.awaitingAcknowledgement)
        #expect(model.mode == .expanded)
    }

    @Test("Hovering without leaving is not an acknowledgement")
    func hoverAloneDoesNotAcknowledge() async {
        let model = makeModel()
        model.beginPhaseChange()
        model.setHovering(true)

        // Runs the backstop right out: even once it gives up waiting, the cursor
        // still sitting on the bar keeps the pill open.
        await model.settle()
        #expect(model.mode == .expanded)
    }

    @Test("The backstop collapses a phase change nobody ever looked at")
    func backstopCollapses() async {
        let model = makeModel()
        model.beginPhaseChange()

        await model.settle()
        #expect(model.mode == .compact)
    }

    @Test("A second phase change restarts the hold rather than inheriting it")
    func secondPhaseChangeRestartsHold() async {
        let model = makeModel()
        model.beginPhaseChange()
        model.setHovering(true)
        model.setHovering(false)
        #expect(model.mode == .compact)

        // A fresh hold, not one inherited from the acknowledgement just given.
        model.beginPhaseChange()
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
