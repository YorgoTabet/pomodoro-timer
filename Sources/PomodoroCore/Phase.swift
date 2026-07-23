import Foundation

/// One leg of the pomodoro cycle.
public enum Phase: String, Codable, Sendable, CaseIterable {
    case focus
    case shortBreak
    case longBreak

    public var isBreak: Bool { self != .focus }

    public var title: String {
        switch self {
        case .focus: "Focus"
        case .shortBreak: "Short Break"
        case .longBreak: "Long Break"
        }
    }

    /// Menu bar glyph. SF Symbols would need an image; a character keeps the
    /// status item a plain string, which stays legible at every menu bar size.
    public var symbol: String {
        switch self {
        case .focus: "🍅"
        case .shortBreak: "☕️"
        case .longBreak: "🌿"
        }
    }
}
