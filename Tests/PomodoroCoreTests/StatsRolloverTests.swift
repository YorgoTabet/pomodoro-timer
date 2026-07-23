import Foundation
import Testing
@testable import PomodoroCore

/// Day bucketing with a *fixed* calendar and fixed dates — no `Date()` — so
/// midnight and DST behaviour is pinned regardless of when or where the suite
/// runs. America/New_York is used because its 2026 transitions are known:
/// March 8 is a 23-hour day (spring forward), November 1 a 25-hour day (fall back).
@Suite("StatsStore day rollover")
struct StatsRolloverTests {

    private static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        return cal
    }()

    private func makeStore() -> (StatsStore, URL) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomodoro-rollover-\(UUID().uuidString).json")
        return (StatsStore(fileURL: url, calendar: Self.calendar), url)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, _ second: Int = 0) -> Date {
        Self.calendar.date(from: DateComponents(
            year: year, month: month, day: day, hour: hour, minute: minute, second: second
        ))!
    }

    @Test("Two seconds apart across midnight land in different days")
    func midnightRollover() {
        let (store, url) = makeStore()
        defer { try? FileManager.default.removeItem(at: url) }

        let lateNight = date(2026, 6, 1, 23, 59, 59)
        let earlyMorning = date(2026, 6, 2, 0, 0, 1)
        store.record(focusSeconds: 1500, on: lateNight)
        store.record(focusSeconds: 1500, on: earlyMorning)

        #expect(store.stats(for: lateNight).day == "2026-06-01")
        #expect(store.stats(for: lateNight).pomodoros == 1)
        #expect(store.stats(for: earlyMorning).day == "2026-06-02")
        #expect(store.stats(for: earlyMorning).pomodoros == 1)

        // A 1-day window ending on June 2 must not leak the June 1 session in.
        let today = store.rollingTotals(days: 1, endingOn: date(2026, 6, 2, 12, 0))
        #expect(today.pomodoros == 1)
        #expect(today.focusSeconds == 1500)
    }

    @Test("DST transitions neither split nor double-count a day")
    func dstTransitions() {
        let (store, url) = makeStore()
        defer { try? FileManager.default.removeItem(at: url) }

        // Spring forward, March 8 2026: sessions either side of the skipped
        // 2 AM hour are still the same day, and stepping back one calendar day
        // from noon crosses the 23-hour day cleanly.
        store.record(focusSeconds: 60, on: date(2026, 3, 7, 22, 0))
        store.record(focusSeconds: 60, on: date(2026, 3, 8, 1, 59))
        store.record(focusSeconds: 60, on: date(2026, 3, 8, 3, 1))

        #expect(store.stats(for: date(2026, 3, 8, 12, 0)).pomodoros == 2)
        #expect(store.stats(for: date(2026, 3, 8, 12, 0)).day == "2026-03-08")
        let springWindow = store.rollingTotals(days: 2, endingOn: date(2026, 3, 8, 12, 0))
        #expect(springWindow.pomodoros == 3)

        // Fall back, November 1 2026: a session in the repeated small hours (EDT)
        // and one after the change (EST) are the same 25-hour day.
        store.record(focusSeconds: 60, on: date(2026, 10, 31, 21, 0))
        store.record(focusSeconds: 60, on: date(2026, 11, 1, 0, 30))
        store.record(focusSeconds: 60, on: date(2026, 11, 1, 3, 0))
        store.record(focusSeconds: 60, on: date(2026, 11, 2, 9, 0))

        #expect(store.stats(for: date(2026, 11, 1, 12, 0)).pomodoros == 2)
        let threeDays = store.rollingTotals(days: 3, endingOn: date(2026, 11, 2, 12, 0))
        #expect(threeDays.pomodoros == 4)
        #expect(threeDays.focusSeconds == 240)
        // And the window edge is exact: two days excludes October 31.
        #expect(store.rollingTotals(days: 2, endingOn: date(2026, 11, 2, 12, 0)).pomodoros == 3)
    }

    @Test("Sparse history is newest-first, keyed correctly, and bounded by the limit")
    func sparseHistory() {
        let (store, url) = makeStore()
        defer { try? FileManager.default.removeItem(at: url) }

        let base = date(2026, 6, 15, 12, 0)
        // Work on scattered days: offsets 0, -2, -5, -13 are inside a 14-day
        // window (offsets 0…13); -20 is outside and must not appear.
        for offset in [0, -2, -5, -13, -20] {
            let day = Self.calendar.date(byAdding: .day, value: offset, to: base)!
            store.record(focusSeconds: 300, on: day)
        }

        let history = store.recentDays(limit: 14, endingOn: base)
        #expect(history.map(\.day) == ["2026-06-15", "2026-06-13", "2026-06-10", "2026-06-02"])
        // Keys are zero-padded ISO strings, so string order is date order.
        for pair in zip(history, history.dropFirst()) {
            #expect(pair.0.day > pair.1.day)
        }
    }
}
