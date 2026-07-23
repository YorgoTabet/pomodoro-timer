import Foundation
import Testing
@testable import PomodoroCore

/// `TimerSnapshot` is the widget's whole view of the timer, and everything it
/// draws is *derived* from `deadline` at an injected date. These tests pin that
/// derivation down with fixed dates — no real clock — including the case the
/// design exists for: a machine that slept straight through the deadline.
@Suite("TimerSnapshot time derivation")
struct SnapshotTimeTests {

    /// A fixed instant, whole seconds so encode/decode comparisons stay exact.
    private let ref = Date(timeIntervalSinceReferenceDate: 790_000_000)

    private func running(total: Int, deadlineIn seconds: Double) -> TimerSnapshot {
        TimerSnapshot(
            phase: .focus,
            isRunning: true,
            deadline: ref.addingTimeInterval(seconds),
            remainingSeconds: total,   // deliberately stale: must be ignored while running
            totalSeconds: total
        )
    }

    @Test("Paused reads the stored value; running derives from the deadline, rounding up")
    func pausedVersusRunning() {
        let paused = TimerSnapshot(isRunning: false, remainingSeconds: 900, totalSeconds: 1500)
        // A paused snapshot must be frozen: any render date gives the same answer.
        #expect(paused.remainingSeconds(at: ref) == 900)
        #expect(paused.remainingSeconds(at: ref.addingTimeInterval(86_400)) == 900)

        // A corrupt negative store clamps to zero rather than going backwards.
        let negative = TimerSnapshot(isRunning: false, remainingSeconds: -5, totalSeconds: 1500)
        #expect(negative.remainingSeconds(at: ref) == 0)

        // Running but with no deadline (a malformed snapshot) falls back to the
        // frozen value instead of misbehaving.
        let noDeadline = TimerSnapshot(isRunning: true, deadline: nil, remainingSeconds: 42, totalSeconds: 1500)
        #expect(noDeadline.remainingSeconds(at: ref) == 42)

        // Running: derived, and partial seconds round *up* so the countdown never
        // shows 0 while time actually remains.
        let live = running(total: 90, deadlineIn: 90)
        #expect(live.remainingSeconds(at: ref) == 90)
        #expect(live.remainingSeconds(at: ref.addingTimeInterval(0.2)) == 90)   // 89.8 → 90
        #expect(live.remainingSeconds(at: ref.addingTimeInterval(89.5)) == 1)   // 0.5 → 1
        #expect(live.remainingSeconds(at: ref.addingTimeInterval(90)) == 0)
    }

    @Test("A deadline slept through reads as finished, not negative")
    func sleepWakeGap() {
        // The widget renders this snapshot three hours after the phase should have
        // ended — the classic laptop-lid scenario. Everything must saturate.
        let slept = running(total: 1500, deadlineIn: 0)
        let wake = ref.addingTimeInterval(3 * 3600)

        #expect(slept.remainingSeconds(at: wake) == 0)
        #expect(slept.progress(at: wake) == 1)
        #expect(slept.displayTime(at: wake) == "00:00")
    }

    @Test("Progress clamps to 0…1 and survives a zero total")
    func progressClamping() {
        // totalSeconds == 0 must not divide by zero.
        let empty = TimerSnapshot(isRunning: false, remainingSeconds: 0, totalSeconds: 0)
        #expect(empty.progress(at: ref) == 0)

        // Stored remaining exceeding the total (stale or corrupt) clamps low.
        let overfull = TimerSnapshot(isRunning: false, remainingSeconds: 2000, totalSeconds: 1500)
        #expect(overfull.progress(at: ref) == 0)

        // And a healthy running snapshot lands exactly where it should.
        let half = running(total: 1500, deadlineIn: 750)
        #expect(half.progress(at: ref) == 0.5)
    }

    @Test("Display time is mm:ss, zero-padded, and does not truncate long phases")
    func displayTimeFormat() {
        func time(_ seconds: Int) -> String {
            TimerSnapshot(isRunning: false, remainingSeconds: seconds, totalSeconds: seconds)
                .displayTime(at: ref)
        }
        #expect(time(25 * 60) == "25:00")
        #expect(time(61) == "01:01")
        #expect(time(0) == "00:00")
        // A 100-minute phase (settings allow up to 240) needs three digits.
        #expect(time(6000) == "100:00")
    }

    @Test("Snapshots round-trip through Codable, deadline present or nil")
    func codableRoundTrip() throws {
        let full = TimerSnapshot(
            phase: .longBreak,
            isRunning: true,
            deadline: ref.addingTimeInterval(600),
            remainingSeconds: 600,
            totalSeconds: 900,
            completedToday: 7,
            cyclePosition: 3,
            cycleLength: 4,
            updatedAt: ref
        )
        let decodedFull = try JSONDecoder().decode(TimerSnapshot.self, from: JSONEncoder().encode(full))
        #expect(decodedFull == full)

        let pausedNoDeadline = TimerSnapshot(phase: .shortBreak, isRunning: false, deadline: nil,
                                             remainingSeconds: 300, totalSeconds: 300, updatedAt: ref)
        let decodedPaused = try JSONDecoder().decode(TimerSnapshot.self, from: JSONEncoder().encode(pausedNoDeadline))
        #expect(decodedPaused == pausedNoDeadline)
        #expect(decodedPaused.deadline == nil)
    }

    @Test("The live ring interval spans exactly the phase and vanishes when stale or paused")
    func runningInterval() {
        // `runningInterval` reads the real clock internally (it exists for live
        // widget rendering), so use a deadline a full hour out to stay deterministic.
        let deadline = Date().addingTimeInterval(3600)
        let live = TimerSnapshot(isRunning: true, deadline: deadline, remainingSeconds: 1500, totalSeconds: 1500)
        let interval = live.runningInterval
        #expect(interval?.upperBound == deadline)
        #expect(interval?.lowerBound == deadline.addingTimeInterval(-1500))

        let paused = TimerSnapshot(isRunning: false, deadline: deadline, remainingSeconds: 1500, totalSeconds: 1500)
        #expect(paused.runningInterval == nil)

        // A deadline already in the past (slept through) offers nothing to animate.
        let stale = TimerSnapshot(isRunning: true, deadline: Date().addingTimeInterval(-10),
                                  remainingSeconds: 0, totalSeconds: 1500)
        #expect(stale.runningInterval == nil)
    }
}
