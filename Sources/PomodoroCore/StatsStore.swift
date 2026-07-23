import Foundation

/// Completed focus work for a single calendar day.
public struct DayStats: Codable, Equatable, Sendable {
    public var day: String          // ISO "yyyy-MM-dd", local time
    public var pomodoros: Int
    public var focusSeconds: Int

    public init(day: String, pomodoros: Int = 0, focusSeconds: Int = 0) {
        self.day = day
        self.pomodoros = pomodoros
        self.focusSeconds = focusSeconds
    }
}

/// Local-only record of completed pomodoros, one JSON file in Application Support.
///
/// Stats are convenience data, not source of truth: a corrupt or unreadable file
/// resets to empty rather than blocking the app from starting.
public final class StatsStore {

    private let fileURL: URL
    private var days: [String: DayStats]
    private let calendar: Calendar

    public init(fileURL: URL? = nil, calendar: Calendar = .current) {
        self.calendar = calendar
        self.fileURL = fileURL ?? Self.defaultFileURL()
        self.days = Self.load(from: self.fileURL)
    }

    public static func defaultFileURL() -> URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Pomodoro", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("stats.json")
    }

    // MARK: - Recording

    /// Record one completed focus session.
    public func record(focusSeconds: Int, on date: Date = Date()) {
        let key = Self.dayKey(date, calendar: calendar)
        var entry = days[key] ?? DayStats(day: key)
        entry.pomodoros += 1
        entry.focusSeconds += focusSeconds
        days[key] = entry
        save()
    }

    // MARK: - Reading

    public func stats(for date: Date = Date()) -> DayStats {
        days[Self.dayKey(date, calendar: calendar)] ?? DayStats(day: Self.dayKey(date, calendar: calendar))
    }

    /// Totals for the last `dayCount` days including today.
    public func rollingTotals(days dayCount: Int, endingOn date: Date = Date()) -> (pomodoros: Int, focusSeconds: Int) {
        var pomodoros = 0
        var seconds = 0
        for offset in 0..<max(dayCount, 1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: date) else { continue }
            let entry = stats(for: day)
            pomodoros += entry.pomodoros
            seconds += entry.focusSeconds
        }
        return (pomodoros, seconds)
    }

    /// Most recent days first, only days with recorded work.
    public func recentDays(limit: Int = 14, endingOn date: Date = Date()) -> [DayStats] {
        (0..<max(limit, 1)).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: date) else { return nil }
            let entry = stats(for: day)
            return entry.pomodoros > 0 ? entry : nil
        }
    }

    public func reset() {
        days = [:]
        save()
    }

    // MARK: - Persistence

    private static func dayKey(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    private static func load(from url: URL) -> [String: DayStats] {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: DayStats].self, from: data)
        else { return [:] }
        return decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(days) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
