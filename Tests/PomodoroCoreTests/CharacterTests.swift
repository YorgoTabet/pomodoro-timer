import Foundation
import Testing
@testable import PomodoroCore

@Suite("CharacterCue")
struct CharacterCueTests {

    @Test("Entering focus always calls for the back-to-work performance")
    func focusStart() {
        #expect(CharacterCue.cue(finished: .shortBreak, next: .focus) == .focusStart)
        #expect(CharacterCue.cue(finished: .longBreak, next: .focus) == .focusStart)
    }

    @Test("Entering a short break calls for the rest performance")
    func breakStart() {
        #expect(CharacterCue.cue(finished: .focus, next: .shortBreak) == .breakStart)
    }

    @Test("Entering a long break calls for the celebration")
    func longBreak() {
        #expect(CharacterCue.cue(finished: .focus, next: .longBreak) == .longBreak)
    }

    @Test("The cue depends only on where you're going, not where you've been")
    func dependsOnNextOnly() {
        // A skipped focus session and an elapsed one both land on a break, and from
        // the user's point of view the same thing just happened.
        for finished in Phase.allCases {
            #expect(CharacterCue.cue(finished: finished, next: .focus) == .focusStart)
        }
    }
}

@Suite("StageEdge")
struct StageEdgeTests {

    /// A 2000×1200 screen with the pill floating comfortably in the middle.
    private let screen = CGRect(x: 0, y: 0, width: 2000, height: 1200)
    private let roomy = CGRect(x: 900, y: 500, width: 236, height: 46)
    private let needed = 64.0

    @Test("Opposites are symmetric")
    func opposites() {
        for edge in StageEdge.allCases {
            #expect(edge.opposite.opposite == edge)
        }
    }

    @Test("With room everywhere, the authored edge is honoured")
    func prefersAuthoredEdge() {
        for edge in StageEdge.allCases {
            #expect(StageEdge.resolve(preferred: edge, pill: roomy, screen: screen, needed: needed) == edge)
        }
    }

    @Test("Tucked under the menu bar, a top emergence flips to the bottom")
    func flipsWhenCramped() {
        // The app's own default placement: 12pt below the top of the visible frame.
        let underMenuBar = CGRect(x: 900, y: 12, width: 236, height: 46)
        #expect(StageEdge.resolve(preferred: .top, pill: underMenuBar, screen: screen, needed: needed) == .bottom)
    }

    @Test("Against the left edge, a leading emergence flips to trailing")
    func flipsHorizontally() {
        let hardLeft = CGRect(x: 4, y: 500, width: 236, height: 46)
        #expect(StageEdge.resolve(preferred: .leading, pill: hardLeft, screen: screen, needed: needed) == .trailing)
    }

    @Test("With no room either way vertically, it falls back to the roomiest edge")
    func verticalFallback() {
        // A screen short enough that neither above nor below the pill can fit the
        // character: 10pt of headroom, 44pt below.
        let shortScreen = CGRect(x: 0, y: 0, width: 2000, height: 100)
        let jammed = CGRect(x: 10, y: 10, width: 236, height: 46)
        let edge = StageEdge.resolve(preferred: .top, pill: jammed, screen: shortScreen, needed: needed)

        // Trailing has 1754pt — far more than the 10pt above or 44pt below.
        #expect(edge == .trailing)
    }

    @Test("Exactly enough room counts as enough")
    func boundaryIsInclusive() {
        // 64pt below the pill and only 10pt above: the flip to .bottom should be
        // taken rather than falling through to a sideways edge.
        let screen = CGRect(x: 0, y: 0, width: 2000, height: 120)
        let jammed = CGRect(x: 900, y: 10, width: 236, height: 46)
        #expect(StageEdge.resolve(preferred: .top, pill: jammed, screen: screen, needed: 64) == .bottom)
    }

    @Test("Room is measured from the pill's edge to the screen's")
    func roomMeasurement() {
        #expect(StageEdge.room(on: .top, pill: roomy, screen: screen) == 500)
        #expect(StageEdge.room(on: .bottom, pill: roomy, screen: screen) == 1200 - 546)
        #expect(StageEdge.room(on: .leading, pill: roomy, screen: screen) == 900)
        #expect(StageEdge.room(on: .trailing, pill: roomy, screen: screen) == 2000 - 1136)
    }

    @Test("Inward normals point away from the named edge")
    func normals() {
        #expect(StageEdge.top.inwardNormal == (0, -1))
        #expect(StageEdge.bottom.inwardNormal == (0, 1))
        #expect(StageEdge.leading.inwardNormal == (-1, 0))
        #expect(StageEdge.trailing.inwardNormal == (1, 0))
    }
}
