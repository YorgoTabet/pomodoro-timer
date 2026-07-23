import Foundation
import Testing
@testable import PomodoroCore

/// The app↔widget bridge, exercised against a throwaway App Group container.
///
/// On unsandboxed macOS, `containerURL(forSecurityApplicationGroupIdentifier:)`
/// resolves *any* group ID to `~/Library/Group Containers/<id>`, so a unique ID
/// per test gives real end-to-end file I/O without ever touching the app's real
/// container. Each test removes its container afterwards. If the OS ever starts
/// returning nil for unentitled IDs, `#require` fails these tests loudly rather
/// than silently writing into the real Application Support fallback.
@Suite("SharedStore bridge")
struct SharedStoreBridgeTests {

    private func makeIsolatedStore() throws -> (store: SharedStore, container: URL) {
        let groupID = "group.pomodoro.tests.\(UUID().uuidString)"
        let container = try #require(
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)
        )
        return (SharedStore(appGroupID: groupID), container)
    }

    @Test("A snapshot round-trips through the container byte-for-value")
    func snapshotRoundTrip() throws {
        let (store, container) = try makeIsolatedStore()
        defer { try? FileManager.default.removeItem(at: container) }

        // Empty container: nothing to read, no crash.
        #expect(store.readSnapshot() == nil)

        // Whole-second dates so Codable's Double representation stays exact.
        let ref = Date(timeIntervalSinceReferenceDate: 790_000_000)
        let snapshot = TimerSnapshot(
            phase: .shortBreak,
            isRunning: true,
            deadline: ref.addingTimeInterval(300),
            remainingSeconds: 300,
            totalSeconds: 300,
            completedToday: 5,
            cyclePosition: 1,
            cycleLength: 4,
            updatedAt: ref
        )
        store.write(snapshot)
        #expect(store.readSnapshot() == snapshot)

        // A newer write replaces, not merges: last writer wins.
        var second = snapshot
        second.phase = .focus
        second.isRunning = false
        store.write(second)
        #expect(store.readSnapshot() == second)
    }

    @Test("Commands arrive, carry fresh IDs, overwrite, and clear")
    func commandLifecycle() throws {
        let (store, container) = try makeIsolatedStore()
        defer { try? FileManager.default.removeItem(at: container) }

        #expect(store.readCommand() == nil)
        #expect(store.commandFileModified() == nil)

        store.send(.skip)
        let first = try #require(store.readCommand())
        #expect(first.command == .skip)
        #expect(store.commandFileModified() != nil)

        // A second press overwrites the file, and its ID differs — that ID is the
        // only thing that lets TimerController tell "new command" from "the one I
        // already handled", so two identical presses must not share one.
        store.send(.skip)
        let second = try #require(store.readCommand())
        #expect(second.command == .skip)
        #expect(second.id != first.id)

        store.clearCommand()
        #expect(store.readCommand() == nil)
        #expect(store.commandFileModified() == nil)
    }

    @Test("Corrupt or version-skewed files read as nil, and a write recovers")
    func corruptDataIsSurvivable() throws {
        let (store, container) = try makeIsolatedStore()
        defer { try? FileManager.default.removeItem(at: container) }

        let snapshotURL = container.appendingPathComponent("snapshot.json")
        let commandURL = container.appendingPathComponent("command.json")

        // Plain garbage in both files: both readers refuse quietly.
        try Data("not json at all".utf8).write(to: snapshotURL)
        try Data("{\"half\": ".utf8).write(to: commandURL)
        #expect(store.readSnapshot() == nil)
        #expect(store.readCommand() == nil)

        // Version skew: structurally valid JSON whose phase no other build knows.
        // A future build writing a new Phase case must degrade to nil here, not trap.
        let valid = try JSONEncoder().encode(TimerSnapshot(phase: .focus, updatedAt: Date(timeIntervalSinceReferenceDate: 790_000_000)))
        let skewed = String(decoding: valid, as: UTF8.self)
            .replacingOccurrences(of: "\"focus\"", with: "\"deepFocus\"")
        try Data(skewed.utf8).write(to: snapshotURL)
        #expect(store.readSnapshot() == nil)

        // And the bridge heals: the next honest write is readable again.
        let fresh = TimerSnapshot(phase: .longBreak, updatedAt: Date(timeIntervalSinceReferenceDate: 790_000_000))
        store.write(fresh)
        #expect(store.readSnapshot() == fresh)
    }
}
