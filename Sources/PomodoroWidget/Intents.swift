import AppIntents
import PomodoroCore
import WidgetKit

/// Widget buttons run these.
///
/// The extension is sandboxed and cannot reach into the app, so an intent does two
/// things: drop a command in the shared container, and optimistically update the
/// snapshot so the widget redraws instantly instead of waiting for the app's next
/// poll. The app is the authority — its own write lands within a second and
/// overwrites anything guessed wrong here.
struct ToggleTimerIntent: AppIntent {
    static let title: LocalizedStringResource = "Start or Pause"
    static let description = IntentDescription("Starts the pomodoro if it's paused, pauses it if it's running.")
    static let isDiscoverable = true

    func perform() async throws -> some IntentResult {
        let store = SharedStore()
        store.send(.toggle)

        if var snapshot = store.readSnapshot() {
            if snapshot.isRunning {
                snapshot.remainingSeconds = snapshot.liveRemainingSeconds
                snapshot.isRunning = false
                snapshot.deadline = nil
            } else {
                snapshot.isRunning = true
                snapshot.deadline = Date().addingTimeInterval(TimeInterval(snapshot.remainingSeconds))
            }
            snapshot.updatedAt = Date()
            store.write(snapshot)
        }

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct SkipPhaseIntent: AppIntent {
    static let title: LocalizedStringResource = "Skip"
    static let description = IntentDescription("Skips to the next phase without recording the current one.")
    static let isDiscoverable = true

    func perform() async throws -> some IntentResult {
        let store = SharedStore()
        store.send(.skip)
        // No optimistic update: the next phase depends on the long-break cycle,
        // which only the app knows. A short stale moment beats guessing wrong.
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct ResetTimerIntent: AppIntent {
    static let title: LocalizedStringResource = "Reset"
    static let description = IntentDescription("Returns to a fresh, stopped focus session.")
    static let isDiscoverable = true

    func perform() async throws -> some IntentResult {
        let store = SharedStore()
        store.send(.reset)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
