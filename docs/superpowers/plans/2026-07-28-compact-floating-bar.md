# Compact Floating Bar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an opt-in mode where the floating bar shrinks to a bare progress ring while the timer runs, expands on hover, and expands on its own at every phase change.

**Architecture:** The NSPanel is never resized or moved — only its SwiftUI content changes, morphing between a 236x46 pill and a 44pt circle concentric with it. A pure `BarPresentationPolicy` value type decides which form is on screen from five booleans; an `@Observable` model owns the debounce and the acknowledgement timers around it. AppKit hit testing reads a shared mutable rect so clicks land on whatever is actually drawn.

**Tech Stack:** Swift 6, SwiftUI, AppKit (`NSPanel`, `NSHostingView`), swift-testing (`import Testing`, `@Suite`/`@Test`/`#expect`), SwiftPM.

Spec: `docs/superpowers/specs/2026-07-28-compact-floating-bar-design.md`

## Global Constraints

- **Swift tools version 6.0**, platform floor **macOS 14** (`Package.swift`). Anything macOS 26-only must sit behind `if #available(macOS 26.0, *)`.
- **Test framework is swift-testing, never XCTest.** `import Testing`, `@Suite("Name")`, `@Test("sentence describing the behaviour")`, `#expect(...)`.
- **Never add a `Co-Authored-By` trailer to any commit.**
- Target membership matters: `PomodoroCore` (pure logic), `PomodoroUI` (SwiftUI shared with the widget, depends on Core), `Pomodoro` (the app executable, depends on both). `PomodoroUITests` is the only test target with a direct `PomodoroUI` dependency.
- Comments in this codebase explain **why**, not what. Match that. Do not add narrating comments.
- The setting is **opt-in**: `compactFloatingBar` registers as `false`, and with it false every behaviour in this plan must be byte-for-byte the current behaviour.
- Build with `swift build`, test with `swift test`. Both must pass before every commit.

---

### Task 1: Move `CharacterStageModel` into its own file

Pure relocation, no behaviour change. `Sources/Pomodoro/FloatingBar.swift` is 436 lines and this feature adds to it; `CharacterStageModel` is a distinct concern that happens to live there.

**Files:**
- Create: `Sources/Pomodoro/CharacterStageModel.swift`
- Modify: `Sources/Pomodoro/FloatingBar.swift:376-436` (delete the moved block)

**Interfaces:**
- Consumes: nothing.
- Produces: `CharacterStageModel` unchanged — same name, same `internal` access level, same members (`character`, `cue`, `generation`, `foreground`, `edge`, `pillScale`, `static reactionScale`, `perform(_:character:edge:)`).

- [ ] **Step 1: Create the new file with the moved type**

Create `Sources/Pomodoro/CharacterStageModel.swift`. Cut lines 376 to the end of `Sources/Pomodoro/FloatingBar.swift` (from the `// MARK: - Character stage state` comment through the closing brace of `CharacterStageModel`) and paste them below this header, verbatim — including every existing comment:

```swift
import PomodoroCore
import SwiftUI

// MARK: - Character stage state

/// What the character is doing right now.
@Observable
@MainActor
final class CharacterStageModel {
    // ... the entire existing body, unchanged ...
}
```

- [ ] **Step 2: Delete the moved block from `FloatingBar.swift`**

Remove everything from `// MARK: - Character stage state` (line 376) to the end of the file. The file must now end with the closing brace of `FloatingBarHostingView`.

- [ ] **Step 3: Build and test**

Run: `swift build && swift test`
Expected: build succeeds, all existing tests pass. No source change other than the move, so nothing should go red.

- [ ] **Step 4: Commit**

```bash
git add Sources/Pomodoro/CharacterStageModel.swift Sources/Pomodoro/FloatingBar.swift
git commit -m "Move CharacterStageModel out of FloatingBar, ahead of the compact form"
```

---

### Task 2: The presentation policy

The whole compact-mode decision as a value type, so it can be exhaustively tested without a window.

**Files:**
- Create: `Sources/PomodoroUI/BarPresentation.swift`
- Test: `Tests/PomodoroUITests/BarPresentationTests.swift`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `public enum BarMode: Equatable, Sendable { case expanded, compact }`
  - `public struct BarPresentationPolicy: Equatable, Sendable` with `public var` properties `compactEnabled`, `isRunning`, `hovering`, `voiceOverRunning`, `awaitingAcknowledgement` (all `Bool`), a memberwise `public init` defaulting every one to `false`, and `public var mode: BarMode { get }`.

- [ ] **Step 1: Write the failing test**

Create `Tests/PomodoroUITests/BarPresentationTests.swift`:

```swift
import Testing
@testable import PomodoroUI

/// The compact-mode decision, exhaustively.
///
/// Worth enumerating rather than spot-checking: the rule is a conjunction of five
/// independent vetoes, and a dropped one fails silently — the bar simply collapses
/// at a moment it should not, which nobody notices until it hides the controls
/// during a break.
@Suite("Bar presentation policy")
struct BarPresentationPolicyTests {

    /// Every input in the position that permits a compact bar.
    private var allClear: BarPresentationPolicy {
        BarPresentationPolicy(
            compactEnabled: true,
            isRunning: true,
            hovering: false,
            voiceOverRunning: false,
            awaitingAcknowledgement: false
        )
    }

    @Test("All clear is the only way to reach the compact form")
    func allClearIsCompact() {
        #expect(allClear.mode == .compact)
    }

    @Test("A fresh policy shows the full pill")
    func defaultsToExpanded() {
        #expect(BarPresentationPolicy().mode == .expanded)
    }

    @Test("The feature being off vetoes compact on its own")
    func disabledVetoes() {
        var policy = allClear
        policy.compactEnabled = false
        #expect(policy.mode == .expanded)
    }

    @Test("A stopped timer vetoes compact on its own")
    func stoppedVetoes() {
        var policy = allClear
        policy.isRunning = false
        #expect(policy.mode == .expanded)
    }

    @Test("The cursor on the bar vetoes compact on its own")
    func hoverVetoes() {
        var policy = allClear
        policy.hovering = true
        #expect(policy.mode == .expanded)
    }

    @Test("VoiceOver vetoes compact on its own, so the controls stay reachable")
    func voiceOverVetoes() {
        var policy = allClear
        policy.voiceOverRunning = true
        #expect(policy.mode == .expanded)
    }

    @Test("An unacknowledged phase change vetoes compact on its own")
    func acknowledgementVetoes() {
        var policy = allClear
        policy.awaitingAcknowledgement = true
        #expect(policy.mode == .expanded)
    }

    @Test("With the feature off, no combination of the other four can collapse it")
    func disabledIsInert() {
        for running in [false, true] {
            for hovering in [false, true] {
                for voiceOver in [false, true] {
                    for awaiting in [false, true] {
                        let policy = BarPresentationPolicy(
                            compactEnabled: false,
                            isRunning: running,
                            hovering: hovering,
                            voiceOverRunning: voiceOver,
                            awaitingAcknowledgement: awaiting
                        )
                        #expect(policy.mode == .expanded)
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `swift test --filter "Bar presentation policy"`
Expected: compile failure — `cannot find 'BarPresentationPolicy' in scope`.

- [ ] **Step 3: Write the implementation**

Create `Sources/PomodoroUI/BarPresentation.swift`:

```swift
import Foundation

/// Which of the floating bar's two forms is on screen.
public enum BarMode: Equatable, Sendable {
    /// The full pill: ring, countdown, phase label, and the hover controls.
    case expanded
    /// A bare progress ring. The one thing worth glancing at mid-session.
    case compact
}

/// The whole compact-mode decision: five booleans in, one form out.
///
/// A value type rather than flags scattered through the view, because the
/// behaviour it encodes is otherwise only reachable by running the app and
/// waiting out a real session. Five independent vetoes, none of them ordered.
public struct BarPresentationPolicy: Equatable, Sendable {

    public var compactEnabled: Bool
    public var isRunning: Bool
    /// Already debounced by `BarPresentationModel`. Raw hover changes must not be
    /// written here — a cursor clipping the bar's corner would collapse it twice.
    public var hovering: Bool
    public var voiceOverRunning: Bool
    /// Set by every phase change, cleared once the user has looked at the bar or
    /// the backstop expires.
    ///
    /// Outranks `isRunning` deliberately. `TimerController.transition(to:)` clears
    /// `isRunning` *before* the optional auto-start, so at the instant of a phase
    /// change the running rule alone would expand and then re-collapse a frame
    /// later — fighting the performance it exists to frame.
    public var awaitingAcknowledgement: Bool

    public init(
        compactEnabled: Bool = false,
        isRunning: Bool = false,
        hovering: Bool = false,
        voiceOverRunning: Bool = false,
        awaitingAcknowledgement: Bool = false
    ) {
        self.compactEnabled = compactEnabled
        self.isRunning = isRunning
        self.hovering = hovering
        self.voiceOverRunning = voiceOverRunning
        self.awaitingAcknowledgement = awaitingAcknowledgement
    }

    public var mode: BarMode {
        guard compactEnabled,
              !voiceOverRunning,
              isRunning,
              !hovering,
              !awaitingAcknowledgement
        else { return .expanded }
        return .compact
    }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `swift test --filter "Bar presentation policy"`
Expected: PASS, 8 tests.

- [ ] **Step 5: Commit**

```bash
git add Sources/PomodoroUI/BarPresentation.swift Tests/PomodoroUITests/BarPresentationTests.swift
git commit -m "Add the bar presentation policy: five vetoes, one form"
```

---

### Task 3: The presentation model — debounce, acknowledgement, backstop

The clock around the policy. Hover in takes effect at once, hover out after a delay; a phase change holds the bar open until the cursor has entered and left, or 30 seconds pass.

**Files:**
- Modify: `Sources/PomodoroUI/BarPresentation.swift` (append)
- Modify: `Tests/PomodoroUITests/BarPresentationTests.swift` (append a second suite)

**Interfaces:**
- Consumes: `BarPresentationPolicy`, `BarMode` from Task 2.
- Produces:
  - `@Observable @MainActor public final class BarPresentationModel`
  - `public struct BarPresentationModel.Timings: Sendable` with `public var hoverExit: Duration`, `public var acknowledgementBackstop: Duration`, a memberwise `public init`, and `public static let standard`
  - `public init(timings: Timings = .standard)`
  - `public private(set) var policy: BarPresentationPolicy`
  - `public var mode: BarMode { get }`
  - `public func setCompactEnabled(_ enabled: Bool)`
  - `public func setRunning(_ running: Bool)`
  - `public func setVoiceOverRunning(_ running: Bool)`
  - `public func setHovering(_ hovering: Bool)`
  - `public func beginPhaseChange()`

- [ ] **Step 1: Write the failing tests**

Append to `Tests/PomodoroUITests/BarPresentationTests.swift`:

```swift
/// The timers around the policy.
///
/// Timings are injected so this suite runs in about a second instead of the half
/// minute the real backstop takes. The "not yet" assertions are safe against a
/// loaded machine: a timer can fire late, never early.
@Suite("Bar presentation model")
@MainActor
struct BarPresentationModelTests {

    private static let fast = BarPresentationModel.Timings(
        hoverExit: .milliseconds(20),
        acknowledgementBackstop: .milliseconds(300)
    )

    /// A model already in the state where compact is permitted.
    private func makeModel() -> BarPresentationModel {
        let model = BarPresentationModel(timings: Self.fast)
        model.setCompactEnabled(true)
        model.setRunning(true)
        return model
    }

    @Test("A running timer with the cursor away collapses")
    func collapsesWhileRunning() {
        #expect(makeModel().mode == .compact)
    }

    @Test("Hovering expands with no delay at all")
    func hoverExpandsImmediately() {
        let model = makeModel()
        model.setHovering(true)
        #expect(model.mode == .expanded)
    }

    @Test("Leaving the bar collapses it, but not instantly")
    func hoverOutIsDebounced() async throws {
        let model = makeModel()
        model.setHovering(true)
        model.setHovering(false)
        #expect(model.mode == .expanded)

        try await Task.sleep(for: .milliseconds(120))
        #expect(model.mode == .compact)
    }

    @Test("Re-entering inside the delay cancels the pending collapse")
    func hoverInCancelsPendingCollapse() async throws {
        let model = makeModel()
        model.setHovering(true)
        model.setHovering(false)
        model.setHovering(true)

        try await Task.sleep(for: .milliseconds(120))
        #expect(model.mode == .expanded)
    }

    @Test("A phase change holds the bar open with the cursor nowhere near it")
    func phaseChangeHolds() async throws {
        let model = makeModel()
        model.beginPhaseChange()
        #expect(model.mode == .expanded)

        try await Task.sleep(for: .milliseconds(100))
        #expect(model.mode == .expanded)
    }

    @Test("Entering and leaving the bar acknowledges the phase change")
    func hoverThenLeaveAcknowledges() async throws {
        let model = makeModel()
        model.beginPhaseChange()

        model.setHovering(true)
        model.setHovering(false)

        try await Task.sleep(for: .milliseconds(120))
        #expect(model.mode == .compact)
    }

    @Test("Hovering without leaving is not an acknowledgement")
    func hoverAloneDoesNotAcknowledge() async throws {
        let model = makeModel()
        model.beginPhaseChange()
        model.setHovering(true)

        try await Task.sleep(for: .milliseconds(120))
        #expect(model.mode == .expanded)
    }

    @Test("The backstop collapses a phase change nobody ever looked at")
    func backstopCollapses() async throws {
        let model = makeModel()
        model.beginPhaseChange()

        try await Task.sleep(for: .milliseconds(500))
        #expect(model.mode == .compact)
    }

    @Test("A second phase change restarts the hold rather than inheriting it")
    func secondPhaseChangeRestartsHold() async throws {
        let model = makeModel()
        model.beginPhaseChange()
        model.setHovering(true)
        model.setHovering(false)

        try await Task.sleep(for: .milliseconds(120))
        #expect(model.mode == .compact)

        model.beginPhaseChange()
        #expect(model.mode == .expanded)

        try await Task.sleep(for: .milliseconds(100))
        #expect(model.mode == .expanded)
    }

    @Test("Pausing expands even mid-hold, and resuming collapses again")
    func runningStateFlowsThrough() async throws {
        let model = makeModel()
        model.setRunning(false)
        #expect(model.mode == .expanded)

        model.setRunning(true)
        #expect(model.mode == .compact)
    }

    @Test("VoiceOver keeps the controls on screen no matter what")
    func voiceOverNeverCollapses() {
        let model = makeModel()
        model.setVoiceOverRunning(true)
        #expect(model.mode == .expanded)

        model.setVoiceOverRunning(false)
        #expect(model.mode == .compact)
    }

    @Test("Turning the feature off restores the pill at once")
    func disablingRestoresThePill() {
        let model = makeModel()
        #expect(model.mode == .compact)

        model.setCompactEnabled(false)
        #expect(model.mode == .expanded)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `swift test --filter "Bar presentation model"`
Expected: compile failure — `cannot find 'BarPresentationModel' in scope`.

- [ ] **Step 3: Write the implementation**

First add `import Observation` to the top of `Sources/PomodoroUI/BarPresentation.swift`, beside the existing `import Foundation` — `@Observable` is a macro from that module and `Foundation` does not bring it in.

Then append to the same file:

```swift
/// Drives `BarPresentationPolicy` in real time.
///
/// The struct holds the decision; this holds the clock. Two timers: a short one
/// that delays collapsing after the cursor leaves, and a long one that gives up
/// waiting for the user to notice a phase change.
@Observable
@MainActor
public final class BarPresentationModel {

    /// Injected so the lifecycle tests run in a second rather than in half a
    /// minute of real waiting.
    public struct Timings: Sendable {
        /// Long enough to survive a window drag, short enough not to feel sticky.
        /// `isMovableByWindowBackground` drags begin with a hit test, and a hover
        /// drop mid-drag would otherwise collapse the pill out from under the grip.
        public var hoverExit: Duration
        /// How long an unacknowledged phase change holds the bar open.
        public var acknowledgementBackstop: Duration

        public init(hoverExit: Duration, acknowledgementBackstop: Duration) {
            self.hoverExit = hoverExit
            self.acknowledgementBackstop = acknowledgementBackstop
        }

        public static let standard = Timings(
            hoverExit: .milliseconds(350),
            acknowledgementBackstop: .seconds(30)
        )
    }

    public private(set) var policy = BarPresentationPolicy()

    public var mode: BarMode { policy.mode }

    @ObservationIgnored private let timings: Timings
    @ObservationIgnored private var hoverExitTask: Task<Void, Never>?
    @ObservationIgnored private var backstopTask: Task<Void, Never>?
    /// Guards against a stray hover-false clearing an acknowledgement nobody saw:
    /// the rule is enter *then* leave, not leave alone.
    @ObservationIgnored private var sawHoverSincePhaseChange = false

    public init(timings: Timings = .standard) {
        self.timings = timings
    }

    // MARK: - Inputs

    public func setCompactEnabled(_ enabled: Bool) {
        policy.compactEnabled = enabled
    }

    public func setRunning(_ running: Bool) {
        policy.isRunning = running
    }

    public func setVoiceOverRunning(_ running: Bool) {
        policy.voiceOverRunning = running
    }

    /// Hover in lands at once; hover out is delayed.
    public func setHovering(_ hovering: Bool) {
        hoverExitTask?.cancel()
        hoverExitTask = nil

        if hovering {
            sawHoverSincePhaseChange = true
            policy.hovering = true
            return
        }

        // Leaving is the acknowledgement, and it clears immediately rather than
        // after the debounce: the debounce is about the collapse being twitchy,
        // not about whether the transition was seen.
        if sawHoverSincePhaseChange {
            clearAcknowledgement()
        }

        let delay = timings.hoverExit
        hoverExitTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            self?.policy.hovering = false
        }
    }

    /// A phase elapsed: show the full bar and hold it until it has been seen.
    public func beginPhaseChange() {
        sawHoverSincePhaseChange = false
        policy.awaitingAcknowledgement = true

        backstopTask?.cancel()
        let delay = timings.acknowledgementBackstop
        backstopTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            self?.clearAcknowledgement()
        }
    }

    private func clearAcknowledgement() {
        backstopTask?.cancel()
        backstopTask = nil
        policy.awaitingAcknowledgement = false
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `swift test --filter "Bar presentation"`
Expected: PASS, 20 tests across both suites.

- [ ] **Step 5: Commit**

```bash
git add Sources/PomodoroUI/BarPresentation.swift Tests/PomodoroUITests/BarPresentationTests.swift
git commit -m "Drive the bar policy: debounced hover, acknowledged phase changes"
```

---

### Task 4: The setting and its toggle

**Files:**
- Modify: `Sources/PomodoroCore/PomodoroSettings.swift` (the `Key` enum, the `register(defaults:)` call, a new property)
- Modify: `Sources/Pomodoro/SettingsView.swift:199` and `:216-219`
- Test: `Tests/PomodoroCoreTests/SettingsTests.swift` (append)

**Interfaces:**
- Consumes: nothing.
- Produces: `PomodoroSettings.Key.compactFloatingBar` and `public var compactFloatingBar: Bool` on `PomodoroSettings`, registered default `false`.

- [ ] **Step 1: Write the failing test**

Append to `Tests/PomodoroCoreTests/SettingsTests.swift`, inside `struct SettingsTests`:

```swift
    @Test("The compact bar is off until it's asked for, then round-trips")
    func compactFloatingBarIsOptIn() {
        let defaults = makeDefaults()
        let settings = PomodoroSettings(defaults: defaults)
        #expect(!settings.compactFloatingBar)

        settings.compactFloatingBar = true
        #expect(PomodoroSettings(defaults: defaults).compactFloatingBar)
    }
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `swift test --filter "Settings"`
Expected: compile failure — `value of type 'PomodoroSettings' has no member 'compactFloatingBar'`.

- [ ] **Step 3: Add the setting**

In `Sources/PomodoroCore/PomodoroSettings.swift`, add a case to the `Key` enum immediately after `case showFloatingBar`:

```swift
        case compactFloatingBar
```

In the same file, add a line to the `defaults.register(defaults:)` dictionary immediately after the `showFloatingBar` entry:

```swift
            Key.compactFloatingBar.rawValue: false,
```

And add the property immediately after `showFloatingBar`:

```swift
    /// Shrink the bar to a bare progress ring while the timer runs.
    ///
    /// Opt-in: an existing install keeps the full pill until it is asked for.
    public var compactFloatingBar: Bool {
        get { access(keyPath: \.compactFloatingBar); return defaults.bool(forKey: Key.compactFloatingBar.rawValue) }
        set { write(.compactFloatingBar, newValue, \.compactFloatingBar) }
    }
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `swift test --filter "Settings"`
Expected: PASS.

- [ ] **Step 5: Add the toggle to the Timer section**

In `Sources/Pomodoro/SettingsView.swift`, replace this single line inside `timerSection` (currently line 199):

```swift
            Toggle("Show floating bar", isOn: $settings.showFloatingBar)
```

with:

```swift
            Toggle("Show floating bar", isOn: $settings.showFloatingBar)

            Toggle("Shrink it to a ring while running", isOn: $settings.compactFloatingBar)
                .disabled(!settings.showFloatingBar)
            if settings.compactFloatingBar {
                caption("While the timer runs the bar becomes a bare progress ring. Point at it to bring the controls back — and it opens on its own when a phase ends.")
            }
```

In the same view, add one line to the modifier chain at the bottom of `timerSection`, immediately after the existing `.onChange(of: settings.showFloatingBar)`:

```swift
        .onChange(of: settings.compactFloatingBar) { _, _ in onChange() }
```

- [ ] **Step 6: Build and verify by hand**

Run: `swift build && swift test`
Expected: build succeeds, all tests pass.

Then build and launch the real app — `swift build` alone produces no bundle, and the floating panel needs one:

```bash
./Scripts/build.sh && open ~/Applications/Pomodoro.app
```

Open Settings → Timer. Confirm: the new toggle appears under "Show floating bar", is off, greys out when "Show floating bar" is turned off, and reveals the caption when switched on. Nothing about the bar's appearance changes yet — that is Tasks 5 and 6.

- [ ] **Step 7: Commit**

```bash
git add Sources/PomodoroCore/PomodoroSettings.swift Sources/Pomodoro/SettingsView.swift Tests/PomodoroCoreTests/SettingsTests.swift
git commit -m "Add the compact floating bar setting, off by default"
```

---

### Task 5: Compact geometry and stateful hit testing

`FloatingBarHostingView.hitTest` currently rejects anything outside a hard-coded 236x46 rect. It has to read the shape that is actually on screen, or a collapsed bar swallows clicks across a region where nothing is drawn.

This task changes no visuals — the hit rect stays at the expanded pill until Task 6 gives it a reason to move.

**Files:**
- Modify: `Sources/Pomodoro/FloatingBar.swift`

**Interfaces:**
- Consumes: `BarPresentationModel` from Task 3.
- Produces, on `FloatingBar`:
  - `static let compactSize: NSSize` (44x44)
  - `static var compactFrame: CGRect`
  - `static let morphDuration: Double` (0.3)
  - `let geometry: BarGeometry`
  - `let presentation: BarPresentationModel`
  - `func reconcileHover()`
- Produces `@MainActor final class BarGeometry` with `var hitFrame: NSRect`.
- Produces `var geometry: BarGeometry?` on `FloatingBarHostingView`.

- [ ] **Step 1: Add the compact geometry constants**

In `Sources/Pomodoro/FloatingBar.swift`, immediately after the existing `static var pillFrame: CGRect` computed property, add:

```swift
    /// The collapsed form: a bare ring, concentric with the pill.
    ///
    /// Centred rather than aligned to an edge for two reasons that both pay off
    /// elsewhere — `pill` is already placed by its midpoint, so the frame can change
    /// without repositioning anything; and `StagePlacement` anchors the character to
    /// `pillFrame.midX`, so the character rises from the same point in both forms.
    static let compactSize = NSSize(width: 44, height: 44)

    static var compactFrame: CGRect {
        CGRect(
            x: pillFrame.midX - compactSize.width / 2,
            y: pillFrame.midY - compactSize.height / 2,
            width: compactSize.width,
            height: compactSize.height
        )
    }

    /// How long the two forms take to swap. One constant, shared by the animation,
    /// by the delay before the hit rect narrows, and by the delay before a
    /// character is cued — they have to agree or a click lands in the gap.
    static let morphDuration: Double = 0.3
```

- [ ] **Step 2: Add the shared state to the panel**

In the same file, immediately after the existing `let stage = CharacterStageModel()`, add:

```swift
    /// Which form the bar is in, and the timers that decide.
    let presentation = BarPresentationModel()

    /// The pill's current hit rect, shared with AppKit hit testing.
    let geometry = BarGeometry()
```

- [ ] **Step 3: Add `BarGeometry` and the hover reconciliation**

At the end of `Sources/Pomodoro/FloatingBar.swift`, after `FloatingBarHostingView`, add:

```swift
// MARK: - Live geometry

/// The pill's hit rect right now.
///
/// Deliberately a plain class rather than `@Observable`: nothing observes it. It
/// exists so `FloatingBarHostingView.hitTest` — which runs in AppKit, outside any
/// SwiftUI update — can ask what shape is currently drawn.
///
/// The invariant its writer must keep: widen it the moment expansion begins, narrow
/// it only once the collapse has finished. Always the larger of the two while
/// anything is moving, so no click can fall into the gap between the animation and
/// the target.
@MainActor
final class BarGeometry {
    /// In the panel's own coordinates. Starts expanded, which is the bar's state
    /// before anything has had a chance to collapse it.
    var hitFrame: NSRect = FloatingBar.pillFrame
}
```

And add this method to `FloatingBar`, immediately after `persistPosition(to:)`:

```swift
    /// Re-derive hover from where the cursor actually is.
    ///
    /// When the pill collapses it moves out from under a stationary cursor. The view
    /// moved, the mouse did not, and AppKit does not reliably deliver `mouseExited`
    /// for that — so SwiftUI's `onHover` can be left stuck true with the cursor
    /// nowhere near the ring. The mirror case is a cursor already parked on the bar
    /// when the timer starts, where it can be left stuck false.
    func reconcileHover() {
        let mouse = NSEvent.mouseLocation
        let local = NSPoint(x: mouse.x - frame.minX, y: mouse.y - frame.minY)
        presentation.setHovering(geometry.hitFrame.contains(local))
    }
```

- [ ] **Step 4: Make hit testing read the live rect**

Replace the body of `FloatingBarHostingView` with:

```swift
final class FloatingBarHostingView<Content: View>: NSHostingView<Content> {

    /// Assigned right after construction — `NSHostingView`'s designated initialiser
    /// takes only a root view, so this cannot be passed in.
    var geometry: BarGeometry?

    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        // Falls back to the full pill rather than to nothing: a missing geometry
        // must degrade to today's behaviour, not to a bar that ignores every click.
        //
        // Both forms are centred in the panel, so their rects read the same whether
        // the view is flipped or not.
        let target = geometry?.hitFrame ?? FloatingBar.pillFrame
        guard target.contains(local) else { return nil }
        return super.hitTest(point)
    }
}
```

Keep the existing doc comment above the class unchanged.

- [ ] **Step 5: Hand the geometry to the hosting view**

In `FloatingBar.init`, replace these two lines:

```swift
        let host = FloatingBarHostingView(rootView: FloatingBarView(controller: controller, stage: stage))
        host.frame = NSRect(origin: .zero, size: Self.panelSize)
```

with:

```swift
        let host = FloatingBarHostingView(rootView: FloatingBarView(controller: controller, stage: stage))
        host.geometry = geometry
        host.frame = NSRect(origin: .zero, size: Self.panelSize)
```

- [ ] **Step 6: Build and verify nothing regressed**

Run: `swift build && swift test`
Expected: build succeeds, all tests pass.

Launch the app. The bar looks and behaves exactly as before: hover reveals Reset/Skip/Play, all three are clickable, the bar drags by its background, and clicks in the transparent margin still fall through to the app underneath.

- [ ] **Step 7: Commit**

```bash
git add Sources/Pomodoro/FloatingBar.swift
git commit -m "Give the floating bar a live hit rect and a compact geometry"
```

---

### Task 6: The morph

**Files:**
- Modify: `Sources/Pomodoro/FloatingBar.swift` (`FloatingBarView`, and the `FloatingBarView(...)` call in `FloatingBar.init`)

**Interfaces:**
- Consumes: `FloatingBar.compactSize`, `FloatingBar.compactFrame`, `FloatingBar.morphDuration`, `BarGeometry`, `BarPresentationModel` from Task 5.
- Produces: `FloatingBarView.init(controller:stage:presentation:geometry:onCollapsed:)` — the memberwise initialiser of the new stored properties `@Bindable var presentation: BarPresentationModel`, `let geometry: BarGeometry`, `let onCollapsed: () -> Void`.

- [ ] **Step 1: Replace the view's hover state with the model**

In `FloatingBarView`, replace:

```swift
    @Bindable var controller: TimerController
    @Bindable var stage: CharacterStageModel

    @State private var hovering = false
    @State private var pulse = false
    @Namespace private var glass
```

with:

```swift
    @Bindable var controller: TimerController
    @Bindable var stage: CharacterStageModel
    @Bindable var presentation: BarPresentationModel
    let geometry: BarGeometry
    /// Called once a collapse has finished, so the panel can re-derive hover from
    /// the cursor's real position.
    let onCollapsed: () -> Void

    @State private var pulse = false
    @Namespace private var glass

    /// Debounced, so the controls linger a moment after the cursor leaves rather
    /// than snapping away under a hand that is still moving.
    private var hovering: Bool { presentation.policy.hovering }

    private var isCompact: Bool { presentation.mode == .compact }

    private var reduceMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }
```

- [ ] **Step 2: Make the shape and size follow the form**

Replace:

```swift
    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
    }
```

with:

```swift
    /// 22 on a 44pt box is a circle, so one shape serves both forms and the radius
    /// simply animates between them.
    private var shape: RoundedRectangle {
        RoundedRectangle(
            cornerRadius: isCompact ? FloatingBar.compactSize.height / 2 : 15,
            style: .continuous
        )
    }

    private var pillSize: CGSize {
        isCompact
            ? CGSize(width: FloatingBar.compactSize.width, height: FloatingBar.compactSize.height)
            : CGSize(width: FloatingBar.size.width, height: FloatingBar.size.height)
    }

    /// Under Reduce Motion the box does not travel — it swaps, and only the contents
    /// cross-fade. A hair above zero rather than `nil` so the content transitions
    /// still have a parent animation to run inside.
    private var morph: Animation {
        reduceMotion ? .linear(duration: 0.01) : .smooth(duration: FloatingBar.morphDuration)
    }
```

- [ ] **Step 3: Morph the pill**

Replace the whole `pill` computed property with:

```swift
    private var pill: some View {
        HStack(spacing: 10) {
            phaseRing

            if !isCompact {
                readout
                    .transition(.opacity.animation(.easeOut(duration: reduceMotion ? 0.2 : 0.12)))
                Spacer(minLength: 4)
                controls
                    .transition(.opacity.animation(.easeOut(duration: reduceMotion ? 0.2 : 0.12)))
            }
        }
        .padding(.leading, isCompact ? 0 : 11)
        .padding(.trailing, isCompact ? 0 : 10)
        .frame(width: pillSize.width, height: pillSize.height)
        // Clipped before the glass, for the same reason the wash below is: mid-morph
        // the contents are briefly wider than the frame, and an unclipped overflow
        // leaves the glass covering only part of the pill.
        .clipShape(shape)
        .background {
            Theme.backdrop(for: controller.phase)
                .opacity(controller.isRunning ? 0.85 : 0.45)
                .clipShape(shape)
                .animation(.smooth(duration: 0.5), value: controller.phase)
                .animation(.smooth(duration: 0.3), value: controller.isRunning)
        }
        .glassPanel(in: shape)
        .opacity(hovering ? 1 : 0.92)
        .scaleEffect(hovering ? 1.0 : 0.99, anchor: .center)
        .onHover { presentation.setHovering($0) }
        .animation(.smooth(duration: 0.22), value: hovering)
        .animation(morph, value: isCompact)
    }
```

- [ ] **Step 4: Grow the ring in the compact form**

In `phaseRing`, replace the two `lineWidth: 2.5` occurrences with `lineWidth: isCompact ? 3 : 2.5`, replace the glyph's `.font(.system(size: 10, weight: .semibold))` with `.font(.system(size: isCompact ? 14 : 10, weight: .semibold))`, and replace `.frame(width: 28, height: 28)` with:

```swift
        .frame(width: isCompact ? 40 : 28, height: isCompact ? 40 : 28)
```

- [ ] **Step 5: Drive the hit rect from the form**

Add these modifiers to the `body`'s outermost `ZStack`, after the existing `.frame(width:height:)`:

```swift
        .onChange(of: presentation.mode) { _, mode in
            guard mode == .compact else {
                // Widen the moment expansion begins.
                geometry.hitFrame = FloatingBar.pillFrame
                return
            }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(FloatingBar.morphDuration))
                // A hover during the collapse can have already reversed it.
                guard presentation.mode == .compact else { return }
                geometry.hitFrame = FloatingBar.compactFrame
                onCollapsed()
            }
        }
```

- [ ] **Step 6: Pass the new dependencies in**

In `FloatingBar.init`, replace:

```swift
        let host = FloatingBarHostingView(rootView: FloatingBarView(controller: controller, stage: stage))
```

with:

```swift
        let host = FloatingBarHostingView(rootView: FloatingBarView(
            controller: controller,
            stage: stage,
            presentation: presentation,
            geometry: geometry,
            onCollapsed: { [weak self] in self?.reconcileHover() }
        ))
```

- [ ] **Step 7: Build and verify by hand**

Run: `swift build && swift test`
Expected: build succeeds, all tests pass.

Launch the app and, with the setting **off**, confirm the bar is unchanged in every respect. Then turn "Shrink it to a ring while running" on and press Start. Confirm:

1. The pill collapses to a ring roughly in the middle of where it was.
2. Pointing at the ring expands it; the controls appear and are clickable.
3. Moving away collapses it again after a short beat.
4. Clicking in the empty space where the expanded pill *used to be*, while collapsed, passes through to the window underneath.
5. Pausing expands it and it stays expanded.
6. Dragging the bar by its background still works and does not collapse mid-drag.
7. Leaving the cursor motionless where the ring is not, after a collapse, does not leave it stuck expanded.

- [ ] **Step 8: Commit**

```bash
git add Sources/Pomodoro/FloatingBar.swift
git commit -m "Morph the floating bar between the pill and a bare ring"
```

---

### Task 7: Wire it to the timer and the phase changes

The last piece: feed the model the run state, the setting and VoiceOver, and open the bar before a character performs.

**Files:**
- Modify: `Sources/Pomodoro/AppDelegate.swift:47-53` (`settings.onChange`), `:90-93` (`handlePhaseChange`), `:143-147` (`refreshViews`), `:164-179` (`syncFloatingBarVisibility`)

**Interfaces:**
- Consumes: `FloatingBar.presentation`, `FloatingBar.morphDuration`, `BarPresentationModel` from Tasks 3, 5 and 6.
- Produces: nothing consumed by a later task.

- [ ] **Step 1: Feed the setting through**

In `applicationDidFinishLaunching`, inside the `settings.onChange` closure, add one line after the existing `floatingBar?.stage.character = settings.character`:

```swift
            floatingBar?.presentation.setCompactEnabled(settings.compactFloatingBar)
```

- [ ] **Step 2: Feed the run state and VoiceOver through**

Replace `refreshViews()` with:

```swift
    private func refreshViews() {
        // The floating bar is SwiftUI observing the controller directly, so only the
        // AppKit status item needs pushing.
        menuBar.refresh()

        // Compact mode's two ambient inputs. Both are polled from here rather than
        // observed: `publish` already fires on every state change and once a second
        // while running, and a VoiceOver notification observer would be more
        // machinery than a boolean read is worth.
        floatingBar?.presentation.setRunning(controller.isRunning)
        floatingBar?.presentation.setVoiceOverRunning(NSWorkspace.shared.isVoiceOverEnabled)
    }
```

- [ ] **Step 3: Seed the model when the bar is created**

In `syncFloatingBarVisibility()`, inside the `if floatingBar == nil` block, add these two lines immediately after the existing `floatingBar?.stage.character = settings.character`:

```swift
                floatingBar?.presentation.setCompactEnabled(settings.compactFloatingBar)
                floatingBar?.presentation.setRunning(controller.isRunning)
```

- [ ] **Step 4: Open the bar before the character performs**

Replace `handlePhaseChange(finished:next:)` with:

```swift
    private func handlePhaseChange(finished: Phase, next: Phase) {
        notifier.announce(finished: finished, next: next)

        let cue = CharacterCue.cue(finished: finished, next: next)

        guard let bar = floatingBar else {
            performCharacter(cue)
            return
        }

        let wasCompact = bar.presentation.mode == .compact
        bar.presentation.beginPhaseChange()

        guard wasCompact else {
            performCharacter(cue)
            return
        }

        // Let the pill finish opening before the character uses it as a stage.
        // `CharacterStage` places and masks against the expanded `pillFrame`, so a
        // cue fired mid-morph would emerge from a pill that is not there yet.
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(FloatingBar.morphDuration))
            self.performCharacter(cue)
        }
    }
```

- [ ] **Step 5: Build and test**

Run: `swift build && swift test`
Expected: build succeeds, all tests pass.

- [ ] **Step 6: Verify the phase change by hand**

Set Focus to 1 minute and Short break to 1 minute in Settings → Timer, pick a character in Settings → Character, and turn the compact toggle on. Start the timer and let it elapse. Confirm:

1. The bar collapses to a ring shortly after Start.
2. When focus ends, the bar opens back to the full pill *first*, and only then does the character rise from behind it — the character is not clipped or misplaced.
3. With `autoStartBreaks` on, the break starts and the bar **stays** expanded.
4. Pointing at the bar and moving away collapses it.
5. Repeat without touching the bar: it collapses on its own after about 30 seconds.
6. Set Character to None and repeat: the bar still opens on the phase change and still waits to be acknowledged.
7. Turn the compact setting off mid-session: the pill returns immediately.

- [ ] **Step 7: Commit**

```bash
git add Sources/Pomodoro/AppDelegate.swift
git commit -m "Open the compact bar for every phase change, and hold it until seen"
```

---

### Task 8: Accessibility pass

**Files:**
- Modify: `Sources/Pomodoro/FloatingBar.swift` (`phaseRing`)

**Interfaces:**
- Consumes: `FloatingBarView.isCompact` from Task 6.
- Produces: nothing.

- [ ] **Step 1: Label the ring for VoiceOver and for tooltips**

In `FloatingBarView.phaseRing`, add these modifiers to the outer `ZStack`, after the existing `.onAppear { ... }`:

```swift
        // Compact strips the countdown and the phase label off the screen. VoiceOver
        // never sees the compact form — the policy refuses to collapse while it is
        // running — but the tooltip is the sighted equivalent, and it costs nothing.
        .help(isCompact ? "\(controller.phase.title) — \(controller.displayTime) left" : "")
        .accessibilityLabel("\(controller.phase.title), \(controller.displayTime) remaining")
```

- [ ] **Step 2: Build and test**

Run: `swift build && swift test`
Expected: build succeeds, all tests pass.

- [ ] **Step 3: Verify by hand**

With the compact setting on and the timer running, hold the cursor still over the ring long enough for a tooltip. Confirm it names the phase and the time left.

Then turn VoiceOver on (Cmd-F5) with the timer running and confirm the bar **does not** collapse, and that Reset, Skip and Play/Pause are all still reachable. Turn VoiceOver off and confirm it collapses again within a second.

- [ ] **Step 4: Commit**

```bash
git add Sources/Pomodoro/FloatingBar.swift
git commit -m "Name the compact ring for VoiceOver and for the tooltip"
```

---

### Task 9: Full regression pass with the feature off

The whole feature is opt-in, so the most important property is that nothing changed for anyone who does not turn it on.

**Files:** none.

**Interfaces:**
- Consumes: everything above.
- Produces: nothing.

- [ ] **Step 1: Run the full suite**

Run: `swift build && swift test`
Expected: every test passes, including the pre-existing `PomodoroCoreTests`, `PomodoroUITests` and `PomodoroAppTests`.

- [ ] **Step 2: Verify the default install**

Delete the app's defaults so it launches as a fresh install:

```bash
defaults delete com.yorgotabet.pomodoro 2>/dev/null; true
```

Launch the app and confirm, without touching the new setting:

1. The bar is the full pill and never collapses, running or not.
2. Hover reveals Reset/Skip/Play; all three work.
3. Clicks in the transparent margin fall through to the app underneath.
4. Dragging the bar moves it, and the position survives a relaunch.
5. A character still performs on a phase change, rising from the same place and at the same moment as before.

- [ ] **Step 3: Commit nothing, or commit the fix**

If steps 1 and 2 pass, there is nothing to commit — the work is done. If anything regressed, fix it and commit with a message naming the regression.

---

## Notes for the implementer

**Why the panel is never resized.** `FloatingBar.panelSize` is 456x266: the 236x46 pill plus a 110pt transparent margin the character emerges into. The compact form fits inside that margin with room to spare, so no `NSWindow` frame ever changes. That is what keeps `floatingBarOrigin`'s meaning, multi-display restoration, and `StageEdge.resolve`'s edge arithmetic all untouched.

**Why the character never sees the compact geometry.** `CharacterStage` and `StagePlacement` position and mask against `FloatingBar.pillFrame`, a constant. Task 7's rule — always expand, wait `morphDuration`, then cue — is what lets that constant stay a constant. If a future change ever cues a character without expanding first, the mask will cut in the wrong place.

**The hit-rect invariant.** Widen immediately, narrow only after the collapse animation finishes. If `FloatingBar.morphDuration` is retuned, the animation and the `Task.sleep` in Task 6 Step 5 both read it, so they cannot drift apart.

**Hover flicker is impossible by construction.** The expanded rect strictly contains the compact one, so a collapse can only fire once the cursor is outside a region it was already outside. Preserve that containment if the geometry is ever retuned.
