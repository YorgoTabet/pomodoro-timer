import Foundation

/// What the widget needs to draw the timer.
///
/// `deadline` is the key field: when the timer is running, the widget renders a
/// live-counting `Text(timerInterval:)` from it, so the countdown ticks every second
/// on screen without WidgetKit having to wake the extension. Timeline refreshes are
/// then only needed on *phase* changes, not on every tick — which is what keeps a
/// second-resolution widget inside the system's refresh budget.
public struct TimerSnapshot: Codable, Sendable, Equatable {
    public var phase: Phase
    public var isRunning: Bool
    /// Absolute end time, set only while running.
    public var deadline: Date?
    /// Frozen remaining time, meaningful only while paused.
    public var remainingSeconds: Int
    public var totalSeconds: Int
    public var completedToday: Int
    /// Focus sessions finished so far in the current run-up to a long break.
    public var cyclePosition: Int
    /// Focus sessions per long break, i.e. how many pips to draw.
    public var cycleLength: Int
    public var updatedAt: Date

    public init(
        phase: Phase = .focus,
        isRunning: Bool = false,
        deadline: Date? = nil,
        remainingSeconds: Int = 25 * 60,
        totalSeconds: Int = 25 * 60,
        completedToday: Int = 0,
        cyclePosition: Int = 0,
        cycleLength: Int = 4,
        updatedAt: Date = Date()
    ) {
        self.phase = phase
        self.isRunning = isRunning
        self.deadline = deadline
        self.remainingSeconds = remainingSeconds
        self.totalSeconds = totalSeconds
        self.completedToday = completedToday
        self.cyclePosition = cyclePosition
        self.cycleLength = cycleLength
        self.updatedAt = updatedAt
    }

    /// Seconds left at `date`, derived rather than stored so a stale snapshot still
    /// reads correctly.
    ///
    /// The date is a parameter because a widget timeline is built ahead of time: an
    /// entry scheduled for 14:32 is rendered minutes earlier, so anything computed
    /// from `Date()` at render time would be wrong by exactly that lead.
    public func remainingSeconds(at date: Date) -> Int {
        guard isRunning, let deadline else { return max(remainingSeconds, 0) }
        return max(Int(deadline.timeIntervalSince(date).rounded(.up)), 0)
    }

    public func progress(at date: Date) -> Double {
        guard totalSeconds > 0 else { return 0 }
        return min(max(Double(totalSeconds - remainingSeconds(at: date)) / Double(totalSeconds), 0), 1)
    }

    public func displayTime(at date: Date) -> String {
        let s = remainingSeconds(at: date)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    public var liveRemainingSeconds: Int { remainingSeconds(at: Date()) }
    public var displayTime: String { displayTime(at: Date()) }

    /// When the timer is running, the window the widget animates a live ring across.
    public var runningInterval: ClosedRange<Date>? {
        guard isRunning, let deadline, deadline > Date() else { return nil }
        return deadline.addingTimeInterval(-Double(totalSeconds))...deadline
    }

    public var progress: Double { progress(at: Date()) }
}

/// A control the widget sends back to the app.
public enum PomodoroCommand: String, Codable, Sendable {
    case toggle, start, pause, skip, reset
}

public struct PendingCommand: Codable, Sendable, Equatable {
    public var id: UUID
    public var command: PomodoroCommand
    public var issuedAt: Date

    public init(command: PomodoroCommand) {
        self.id = UUID()
        self.command = command
        self.issuedAt = Date()
    }
}

/// The one channel between the app and the widget extension.
///
/// Two files in the shared App Group container: the app owns `snapshot.json` and only
/// writes it; the widget owns `command.json` and only writes it. Single-writer per
/// file means no locking is needed, and an atomic write means a reader never sees a
/// half-written file.
///
/// The widget extension is force-sandboxed by macOS, so the App Group container is
/// the only place both processes can reach. If the group is unavailable — which is
/// what happens when running unbundled during development — this falls back to
/// Application Support, where the app still works and the widget simply has nothing
/// to read.
public struct SharedStore: Sendable {

    public static let appGroupID = "group.com.yorgotabet.pomodoro"

    private let directory: URL

    public init(appGroupID: String = SharedStore.appGroupID) {
        if let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            directory = container
        } else {
            directory = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Pomodoro", isDirectory: true)
        }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// `false` when the App Group isn't reachable, meaning the widget can't see us.
    public var isShared: Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupID) != nil
    }

    private var snapshotURL: URL { directory.appendingPathComponent("snapshot.json") }
    private var commandURL: URL { directory.appendingPathComponent("command.json") }

    // MARK: - Snapshot (app writes, widget reads)

    public func write(_ snapshot: TimerSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: snapshotURL, options: .atomic)
    }

    public func readSnapshot() -> TimerSnapshot? {
        guard let data = try? Data(contentsOf: snapshotURL) else { return nil }
        return try? JSONDecoder().decode(TimerSnapshot.self, from: data)
    }

    // MARK: - Commands (widget writes, app reads)

    public func send(_ command: PomodoroCommand) {
        guard let data = try? JSONEncoder().encode(PendingCommand(command: command)) else { return }
        try? data.write(to: commandURL, options: .atomic)
    }

    public func readCommand() -> PendingCommand? {
        guard let data = try? Data(contentsOf: commandURL) else { return nil }
        return try? JSONDecoder().decode(PendingCommand.self, from: data)
    }

    /// Cheap change detection: the app polls once a second, and reading an mtime is
    /// far cheaper than decoding JSON on every poll.
    public func commandFileModified() -> Date? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: commandURL.path) else { return nil }
        return attributes[.modificationDate] as? Date
    }

    public func clearCommand() {
        try? FileManager.default.removeItem(at: commandURL)
    }
}
