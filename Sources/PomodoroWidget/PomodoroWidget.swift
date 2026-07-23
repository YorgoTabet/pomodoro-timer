import AppIntents
import PomodoroCore
import SwiftUI
import WidgetKit

// MARK: - Timeline

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: TimerSnapshot
}

struct Provider: TimelineProvider {

    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: Date(), snapshot: TimerSnapshot())
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        completion(SnapshotEntry(date: Date(), snapshot: SharedStore().readSnapshot() ?? TimerSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let now = Date()
        let snapshot = SharedStore().readSnapshot() ?? TimerSnapshot()

        // Paused: nothing changes until the app tells us it did, so ask for no
        // refresh at all rather than burning budget on a still image.
        guard snapshot.isRunning, let deadline = snapshot.deadline, deadline > now else {
            completion(Timeline(entries: [SnapshotEntry(date: now, snapshot: snapshot)], policy: .never))
            return
        }

        // Running: the seconds are drawn by `Text(timerInterval:)`, which ticks on
        // its own without waking the extension. Only the *ring* needs new entries,
        // so one per minute is plenty — a 25-minute pomodoro costs 25 entries
        // instead of 1,500, and the ring still visibly advances while you watch it.
        var entries = [SnapshotEntry(date: now, snapshot: snapshot)]
        var cursor = Self.nextMinuteBoundary(after: now)
        while cursor < deadline, entries.count < Self.maxEntries {
            entries.append(SnapshotEntry(date: cursor, snapshot: snapshot))
            cursor.addTimeInterval(Self.step)
        }
        // Land exactly on the transition so the phase flips on time, not a minute late.
        entries.append(SnapshotEntry(date: deadline, snapshot: snapshot))

        completion(Timeline(entries: entries, policy: .after(deadline)))
    }

    private static let step: TimeInterval = 60
    /// Caps a pathological setting (a 4-hour focus session) at a sane timeline size.
    private static let maxEntries = 180

    private static func nextMinuteBoundary(after date: Date) -> Date {
        date.addingTimeInterval(step - date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: step))
    }
}

// MARK: - Widget

struct PomodoroWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PomodoroWidget", provider: Provider()) { entry in
            PomodoroWidgetView(snapshot: entry.snapshot, date: entry.date)
                .containerBackground(for: .widget) { WidgetBackground(phase: entry.snapshot.phase) }
        }
        .configurationDisplayName("Pomodoro")
        .description("Start, pause, and skip your pomodoro without leaving what you're doing.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct PomodoroWidgetBundle: WidgetBundle {
    var body: some Widget {
        PomodoroWidget()
        if #available(macOS 26.0, *) {
            PomodoroControl()
        }
    }
}

// MARK: - Control Center

/// A Control Center toggle. Controls arrived on the Mac in macOS 26, so this is
/// gated; on anything earlier the bundle simply doesn't vend it.
@available(macOS 26.0, *)
struct PomodoroControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "PomodoroControl") {
            ControlWidgetButton(action: ToggleTimerIntent()) {
                let snapshot = SharedStore().readSnapshot() ?? TimerSnapshot()
                Label(
                    snapshot.isRunning ? "Pause Pomodoro" : "Start Pomodoro",
                    systemImage: snapshot.isRunning ? "pause.fill" : "play.fill"
                )
            }
        }
        .displayName("Pomodoro")
        .description("Start or pause your focus timer.")
    }
}
