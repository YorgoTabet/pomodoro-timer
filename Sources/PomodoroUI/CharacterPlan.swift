import PomodoroCore
import SwiftUI

/// The per-character facts the app layer needs before a performance starts:
/// which edge to emerge from, whether it steps in front of the pill, and how long
/// to hold the stage open.
///
/// Exists so `AppDelegate` and `FloatingBar` never name a specific character.
/// Adding one is a case here plus a case in `CharacterStage.performance(_:)` —
/// not a hunt through the app layer for hardcoded `SamuraiPerformance` calls.
public enum CharacterPlan {

    public static func preferredEdge(for cue: CharacterCue, character: PomodoroCharacter) -> StageEdge {
        switch character {
        case .ninja: NinjaPerformance.preferredEdge(for: cue)
        case .general: GeneralPerformance.preferredEdge(for: cue)
        case .rabbit: RabbitPerformance.preferredEdge(for: cue)
        default: SamuraiPerformance.preferredEdge(for: cue)
        }
    }

    /// Whether the character steps in front of the pill instead of staying behind
    /// it. The stage skips its occlusion mask when this is true.
    public static func comesForward(for cue: CharacterCue, character: PomodoroCharacter) -> Bool {
        switch character {
        case .ninja: NinjaPerformance.comesForward(for: cue)
        case .general: GeneralPerformance.comesForward(for: cue)
        case .rabbit: RabbitPerformance.comesForward(for: cue)
        default: SamuraiPerformance.comesForward(for: cue)
        }
    }

    public static func duration(for cue: CharacterCue, character: PomodoroCharacter) -> Double {
        switch character {
        case .ninja: NinjaPerformance.duration(for: cue)
        case .general: GeneralPerformance.duration(for: cue)
        case .rabbit: RabbitPerformance.duration(for: cue)
        default: SamuraiPerformance.duration(for: cue)
        }
    }
}
