import Foundation
import Testing
@testable import PomodoroCore

@Suite("StatsStore")
struct StatsStoreTests {

    private func makeStore() -> (StatsStore, URL) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomodoro-stats-\(UUID().uuidString).json")
        return (StatsStore(fileURL: url), url)
    }

    @Test("Recording accumulates within a day")
    func recordsWithinADay() {
        let (store, url) = makeStore()
        defer { try? FileManager.default.removeItem(at: url) }

        store.record(focusSeconds: 1500)
        store.record(focusSeconds: 1500)

        #expect(store.stats().pomodoros == 2)
        #expect(store.stats().focusSeconds == 3000)
    }

    @Test("Days are kept separate")
    func separatesDays() {
        let (store, url) = makeStore()
        defer { try? FileManager.default.removeItem(at: url) }

        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        store.record(focusSeconds: 1500, on: today)
        store.record(focusSeconds: 600, on: yesterday)

        #expect(store.stats(for: today).pomodoros == 1)
        #expect(store.stats(for: yesterday).pomodoros == 1)
        #expect(store.stats(for: yesterday).focusSeconds == 600)
    }

    @Test("Rolling totals sum the requested window and stop at its edge")
    func rollingTotals() {
        let (store, url) = makeStore()
        defer { try? FileManager.default.removeItem(at: url) }

        let today = Date()
        for offset in 0..<10 {
            let day = Calendar.current.date(byAdding: .day, value: -offset, to: today)!
            store.record(focusSeconds: 60, on: day)
        }

        let week = store.rollingTotals(days: 7)
        #expect(week.pomodoros == 7)
        #expect(week.focusSeconds == 420)
    }

    @Test("History skips empty days and is newest first")
    func history() {
        let (store, url) = makeStore()
        defer { try? FileManager.default.removeItem(at: url) }

        let today = Date()
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: today)!
        store.record(focusSeconds: 1500, on: today)
        store.record(focusSeconds: 1500, on: threeDaysAgo)

        let history = store.recentDays(limit: 14)
        #expect(history.count == 2)
        #expect(history[0].day > history[1].day)
    }

    @Test("Data survives a reload from disk")
    func persistence() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomodoro-stats-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }

        StatsStore(fileURL: url).record(focusSeconds: 1500)
        #expect(StatsStore(fileURL: url).stats().pomodoros == 1)
    }

    @Test("A corrupt file resets to empty instead of crashing")
    func corruptFile() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomodoro-stats-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data("this is not json".utf8).write(to: url)

        let store = StatsStore(fileURL: url)
        #expect(store.stats().pomodoros == 0)

        // And it recovers: the next write produces a valid file again.
        store.record(focusSeconds: 300)
        #expect(StatsStore(fileURL: url).stats().pomodoros == 1)
    }

    @Test("Reset clears everything")
    func reset() {
        let (store, url) = makeStore()
        defer { try? FileManager.default.removeItem(at: url) }

        store.record(focusSeconds: 1500)
        store.reset()

        #expect(store.stats().pomodoros == 0)
        #expect(store.recentDays().isEmpty)
    }
}
