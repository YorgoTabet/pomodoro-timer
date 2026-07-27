import CoreGraphics
import Foundation

/// Who pops out from behind the floating pill when a phase changes.
///
/// Named `PomodoroCharacter` rather than `Character` because the latter is a
/// Swift standard-library type; shadowing it produces baffling type errors at
/// every use site.
public enum PomodoroCharacter: String, Codable, Sendable, CaseIterable, Identifiable {
    case none
    case samurai
    case ninja
    case rabbit
    case animeGirl
    case general

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .none: "None"
        case .samurai: "Samurai"
        case .ninja: "Ninja"
        case .rabbit: "Rabbit Suit Guy"
        case .animeGirl: "Anime Girl"
        case .general: "The General"
        }
    }

    /// Whether this character has been drawn yet. The roster is declared up front so
    /// the settings UI can show what's coming, but only some are implemented.
    public var isImplemented: Bool {
        switch self {
        case .none, .samurai, .ninja, .general, .rabbit: true
        case .animeGirl: false
        }
    }
}

/// Which of a character's three performances to play.
public enum CharacterCue: String, Codable, Sendable, CaseIterable {
    /// A break ended — back to work.
    case focusStart
    /// A focus session ended — time to rest.
    case breakStart
    /// A full cycle finished — the rare, fancier one.
    case longBreak

    public var displayName: String {
        switch self {
        case .focusStart: "Back to focus"
        case .breakStart: "Break time"
        case .longBreak: "Long break"
        }
    }

    /// Which performance a phase transition calls for.
    ///
    /// Driven by the phase being *entered*, not the one being left: what the
    /// character is reacting to is what you're about to do. A manual skip produces
    /// the same cue as a phase running out, because from the user's point of view
    /// the same thing just happened.
    public static func cue(finished: Phase, next: Phase) -> CharacterCue {
        switch next {
        case .focus: .focusStart
        case .shortBreak: .breakStart
        case .longBreak: .longBreak
        }
    }
}

/// Which side of the pill the character emerges past.
public enum StageEdge: String, Codable, Sendable, CaseIterable {
    case top, bottom, leading, trailing

    public var opposite: StageEdge {
        switch self {
        case .top: .bottom
        case .bottom: .top
        case .leading: .trailing
        case .trailing: .leading
        }
    }

    /// The direction the character travels as it emerges, in SwiftUI's coordinate
    /// space where +y is down. A character hidden behind the pill starts displaced
    /// along the negative of this and slides back to zero.
    public var inwardNormal: (x: Double, y: Double) {
        switch self {
        case .top: (0, -1)
        case .bottom: (0, 1)
        case .leading: (-1, 0)
        case .trailing: (1, 0)
        }
    }

    /// Pick where the character can actually fit.
    ///
    /// Tries the authored edge, then its opposite, then whichever remaining edge has
    /// the most room. There is always an answer, because the pill is smaller than the
    /// screen — so this never has to fail or skip the performance.
    public static func resolve(
        preferred: StageEdge,
        pill: CGRect,
        screen: CGRect,
        needed: Double
    ) -> StageEdge {
        if room(on: preferred, pill: pill, screen: screen) >= needed { return preferred }
        if room(on: preferred.opposite, pill: pill, screen: screen) >= needed { return preferred.opposite }
        return allCases.max { room(on: $0, pill: pill, screen: screen) < room(on: $1, pill: pill, screen: screen) }
            ?? preferred
    }

    /// Available space between the pill's edge and the screen's, in points.
    ///
    /// Uses a top-left origin (SwiftUI/screencapture convention), not AppKit's
    /// bottom-left — callers must convert before calling.
    static func room(on edge: StageEdge, pill: CGRect, screen: CGRect) -> Double {
        switch edge {
        case .top: pill.minY - screen.minY
        case .bottom: screen.maxY - pill.maxY
        case .leading: pill.minX - screen.minX
        case .trailing: screen.maxX - pill.maxX
        }
    }
}
