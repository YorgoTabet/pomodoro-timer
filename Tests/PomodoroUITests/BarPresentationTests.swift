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
