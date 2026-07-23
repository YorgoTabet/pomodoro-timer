import PomodoroCore
import SwiftUI

/// The run-up to the next long break, as a row of pips.
///
/// This is the piece of state a bare countdown can't tell you: not "how long is
/// left" but "where am I in the set". The final pip is drawn wider and in the
/// long-break colour so the reward at the end of the cycle is visible from the
/// first session.
public struct CyclePips: View {

    let position: Int
    let length: Int
    let phase: Phase
    let size: CGFloat

    public init(position: Int, length: Int, phase: Phase, size: CGFloat = 6) {
        self.position = position
        self.length = max(length, 1)
        self.phase = phase
        self.size = size
    }

    public var body: some View {
        HStack(spacing: size * 0.7) {
            ForEach(0..<length, id: \.self) { index in
                Capsule()
                    .fill(fill(for: index))
                    .frame(width: width(for: index), height: size)
                    .overlay {
                        // The session you're in gets a ring rather than a fill, so
                        // "done" and "doing" never read as the same state.
                        if index == position, phase == .focus {
                            Capsule()
                                .stroke(Theme.tint(for: .focus), lineWidth: 1.2)
                        }
                    }
                    .animation(.smooth(duration: 0.4), value: position)
            }
        }
    }

    private func width(for index: Int) -> CGFloat {
        index == length - 1 ? size * 2.4 : size
    }

    private func fill(for index: Int) -> Color {
        if index < position {
            return Theme.tint(for: index == length - 1 ? .longBreak : .focus)
        }
        return .primary.opacity(0.16)
    }
}
