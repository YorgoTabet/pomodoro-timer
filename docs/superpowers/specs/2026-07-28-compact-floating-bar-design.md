# Compact floating bar

**Date:** 2026-07-28

An opt-in mode where the floating bar shrinks to a bare progress ring while the
timer runs, expands back to the full pill on hover, and expands again on its own
at every phase change so the character performance has a stage to play on.

The bar earns its place by being ignorable. Today it is quiet but not small: a
236pt pill with a countdown that changes every second sits on top of whatever you
are doing for the entire session. Compact mode removes the two things that pull
the eye — the moving digits and the width — and keeps the one thing worth
glancing at, which is how far through the phase you are.

## Behaviour

Compact when **all** of these hold:

- the setting is on, and
- the timer is running, and
- the cursor is not on the bar, and
- no phase change is awaiting acknowledgement, and
- VoiceOver is not running.

Expanded otherwise. That is the whole rule; everything below is how each input
is produced.

### Hover

Entering the compact circle expands the pill; leaving it collapses again. The
expanded rect strictly contains the compact one, so collapse can only fire once
the cursor is outside a region it was already outside — expand/collapse cannot
oscillate. This is a property worth preserving if the geometry is ever retuned.

**Both edges are debounced** — 110ms in, 120ms out — and a pending edge is
cancelled by its opposite.

The cancellation is the point, not the delay. A cursor flicked across the bar
produces an enter and a leave inside the window; they annihilate, and nothing
animates at all. Without it a flick drove a full open and close back to back, and
the secondary controls — which animate by insertion, not by a spring — restart
rather than reverse, so a flick looked broken. A deliberate hover outlives the
window and lands normally. Both values sit under the ~150ms that reads as a wait:
the delay exists to reject accidents, not to pace the interaction.

The exit was briefly 350ms, to stop a window drag collapsing the pill under the
user's grip. That fear was unfounded — a background drag moves the window *with*
the cursor, so hover never drops, and AppKit owns the drag session either way —
and what it bought was a third of a second of dead air on every leave. It read as
the bar being stuck, and it compounded: `controls` keys its `if hovering` off the
same debounced flag, so the secondary buttons did not begin leaving for 350ms and
then took 280ms to go.

Because a flick never sets `hovering` at all, it also cannot acknowledge a phase
change. Acknowledgement means a settled hover followed by a settled leave.

### Phase changes — the acknowledgement model

At every phase change the bar expands and stays expanded until the user has
actually looked at it. "Looked at it" means the cursor entered and then left the
bar. A transition is never missed because the timer ran out while attention was
elsewhere.

Because an unattended Mac would otherwise sit with the full bar up for a whole
25-minute session, a 30s backstop collapses it anyway. Whichever comes first
wins.

This flag deliberately outranks the running rule, which matters more than it
looks: `TimerController.transition(to:)` clears `isRunning` *before* the optional
auto-start, so at the instant of a phase change the running rule alone would
expand, then re-collapse a frame later — fighting the performance it is meant to
frame.

When no character is selected the bar still expands on a phase change. The phase
change is the thing worth seeing; the character is decoration on top of it.

### VoiceOver

Never collapse while VoiceOver is running. Collapsing removes Reset, Skip and
Play/Pause from the accessibility tree entirely, which is not a trade a
non-distraction feature gets to make.

### Reduce Motion

Cross-fade between the two forms rather than morphing, matching what
`CharacterStage` already does for the character performances.

## Architecture

### The policy is a value type, not view state

`Sources/PomodoroUI/BarPresentation.swift`, with no SwiftUI in it:

```swift
public enum BarMode: Equatable { case expanded, compact }

public struct BarPresentationPolicy: Equatable {
    public var compactEnabled: Bool
    public var isRunning: Bool
    public var hovering: Bool            // already debounced by the caller
    public var voiceOverRunning: Bool
    public var awaitingAcknowledgement: Bool

    public var mode: BarMode {
        guard compactEnabled, !voiceOverRunning, isRunning,
              !hovering, !awaitingAcknowledgement else { return .expanded }
        return .compact
    }
}
```

Five inputs, one output, no invalid states. The point is that the behaviour above
becomes a truth table a test can enumerate, rather than a scatter of `@State`
flags inside a view that can only be exercised by running the app and waiting
25 minutes.

The debounce, the 30s backstop and the acknowledgement lifecycle live in an
`@Observable @MainActor final class BarPresentationModel` alongside it, which owns
the timers and feeds the policy. The class is where the clock lives; the struct is
where the decision lives.

### Geometry: nothing resizes

`FloatingBar.panelSize` stays 456x266 — the pill (236x46) plus the 110pt
transparent margin the character emerges into. **The NSPanel is never resized and
never moved.** Only the SwiftUI content inside it changes.

That single decision removes most of the risk: no window-resize animation, no
change to what `floatingBarOrigin` means, no re-anchoring across displays, and no
migration for an already-dragged position.

The compact form is a **46pt circle concentric with the pill**, and the pill grows
symmetrically out of it.

Concentric is a pointer decision before it is an aesthetic one: whatever the cursor
was resting on to trigger the expansion becomes the centre of what it expands into,
so **the pointer ends up in the middle of the open bar**. It never lands on a
control that swept underneath it, and every control is an equally short trip away.
Growing off a fixed leading edge instead would sweep the whole pill out from under
the cursor.

46 is the pill's own height, so the circle is exactly as tall as the bar it comes
from. That also keeps the compact rect symmetric about the panel's centre in both
axes, which is what lets `FloatingBarHostingView.hitTest` go on ignoring whether
its view is flipped.

`StagePlacement` anchors the character to `pillFrame.midX`, which is unaffected:
the character only ever performs against the expanded pill.

### The morph is a reveal, not a re-layout

One layout, always at full width, with the box clipping it:

- The box is centred on screen and grows from its middle, but the **content is
  pinned to the box's leading edge**, so ring, readout and controls travel as one
  block that the opening carries with it.

  Centring the content instead left the ring as the only element free to move, and
  it had to be offset ~93pt to reach the middle of the circle. A symmetric box with
  a single element tracking leftward across it reads as opening *to the left*, not
  from the middle — two motions where there should be one. Pinning to the edge also
  deletes the offset outright: at 9pt padding plus a 28pt ring the ring's centre is
  at 23, exactly half the 46pt circle, so it lands centred for free.

- `phaseRing` is laid out at a fixed 28pt in both forms and scales to 36pt to fill
  the compact circle. A `scaleEffect`, so it never disturbs the layout underneath.

  The scale is not decoration. Without it there are two circles rather than one:
  the glass disc, which is really the pill closed down to 46pt, and a 28pt ring
  floating at 61% of its width. On opening, the disc becomes the whole pill while
  the ring stays the size it was — so the object the eye is tracking has nothing to
  grow into, and the change reads as two interfaces swapping even though the view
  tree is identical throughout. At 36pt the ring owns the circle and shrinks back
  into its slot, which is what ties the two states into one object.
- The readout and controls are **always mounted**, at their expanded positions.
  Only their opacity changes.
- The outer frame animates 236 -> 46 wide, centre-aligned, and `clipShape` turns
  that width change into a reveal.
- The `RoundedRectangle` radius animates 15 -> 23, a circle at 46pt.

Conditionally inserting the readout and controls is what made the first attempt
read as a replacement: SwiftUI re-ran the layout, so everything arrived at once in
a box that was still moving. Holding one fixed layout and moving only the clip and
one offset means nothing is ever laid out twice.

The content fade is deliberately **off** the width's curve — `easeOut(0.16)` with
a 0.11s delay on the way open, and no delay on the way closed. Opening, the pill
starts widening before the text arrives, so the text is never seen in a box too
small to hold it; closing, the text leaves first and the pill shuts on an empty
stage. Fading on the same curve as the width was the other half of the swap feel.

`glassPanel(in:)` takes any `Shape`, so the same call site serves both forms with
an animated radius.

### Hit testing has to become stateful

`FloatingBarHostingView.hitTest` currently rejects anything outside a hard-coded
236x46 rect. Left alone, a collapsed bar would swallow clicks across a region
where nothing is drawn; narrowed to the circle unconditionally, the expanded
controls would be unclickable.

It reads its rect from a small shared `BarGeometry` reference instead. The rule
that keeps it safe through a transition:

> Widen the hit rect **immediately** when expansion begins. Narrow it **only
> after** the collapse animation completes.

Always the larger of the two while anything is in motion, so no click can fall
into a gap between the visual and the target.

### Phase-change sequencing

`AppDelegate.handlePhaseChange` expands first and cues the character second:

```swift
notifier.announce(finished: finished, next: next)
floatingBar?.presentation.beginPhaseChange()
// Only when it was actually compact. Otherwise perform immediately, so the
// timing is unchanged for anyone with the feature off.
if wasCompact { try? await Task.sleep(for: .seconds(0.3)) }
performCharacter(CharacterCue.cue(finished: finished, next: next))
```

This is what lets `CharacterStage.pillFrame` and `FloatingBar.pillScreenFrameFlipped`
stay constants. The character never observes compact geometry, so the stage's
placement, its mask, and `StageEdge.resolve`'s edge arithmetic need no changes at
all.

### The stuck-hover guard

When the pill collapses it moves out from under a stationary cursor. The view
moved, the mouse did not, and AppKit does not reliably deliver `mouseExited` for
that — a well-known tracking-area failure. After a collapse animation completes,
re-check `NSEvent.mouseLocation` against the compact frame and correct the hover
flag if it disagrees.

The mirror case is a cursor already parked on the bar when the timer starts, where
`onHover` may never fire true. The same check on entering compact mode covers it.

## Settings

New `PomodoroSettings.Key.compactFloatingBar`, registered default **false** — the
feature is opt-in and changes nothing for an existing install until asked for.

The toggle sits in the Timer section immediately under "Show floating bar",
disabled when the bar is hidden, with a one-line caption explaining that hovering
brings it back. It writes through like every other control there, and goes through
the existing `onChange` path so the bar picks it up live.

## Testing

`Tests/PomodoroUITests/BarPresentationTests.swift` — the policy lives in
`PomodoroUI`, and `PomodoroUITests` is the target with a direct dependency on it:

- The policy truth table: every input independently forces `.expanded`, and only
  the all-clear combination yields `.compact`.
- Acknowledgement lifecycle: set by a phase change; cleared by hover-enter
  followed by hover-leave; **not** cleared by hover-enter alone; cleared by the
  backstop with no hover at all.
- The debounce: hover-out does not take effect before the delay, does after it,
  and a hover-in inside the delay window cancels the pending collapse.
- Compact mode off is inert — the policy returns `.expanded` regardless of the
  other four inputs.

The policy being a plain value type is what makes these tests instant and
deterministic. The `BarPresentationModel` timings are injected as parameters so
the lifecycle tests do not sleep for 30 seconds.

## File-level changes

| File | Change |
|---|---|
| `Sources/PomodoroCore/PomodoroSettings.swift` | `compactFloatingBar` key, default false |
| `Sources/PomodoroUI/BarPresentation.swift` | **New** — policy + model |
| `Sources/Pomodoro/FloatingBar.swift` | Morph, `BarGeometry`, dynamic `hitTest` |
| `Sources/Pomodoro/CharacterStageModel.swift` | **Moved** out of `FloatingBar.swift` |
| `Sources/Pomodoro/AppDelegate.swift` | Phase-change sequencing, settings wiring |
| `Sources/Pomodoro/SettingsView.swift` | The toggle |
| `Tests/PomodoroUITests/BarPresentationTests.swift` | **New** |
| `Tests/PomodoroCoreTests/SettingsTests.swift` | Cover the new default |

`CharacterStageModel` is moved because `FloatingBar.swift` is already 436 lines
and this feature adds to it. The model is a distinct concern that happens to live
there; relocating it keeps the file roughly where it started rather than pushing it
past 550.

## Explicitly out of scope

- Compact while **paused or stopped**. A stopped timer needs its controls
  reachable, and the stated goal is not distracting *while the timer is on*.
- Any change to the menu bar item, the widget, or the character performances.
- A separate compact position. The bar has one position; the two forms share it.
- Clicking the compact circle as a shortcut. Reaching it means hovering, and
  hovering has already expanded the pill by the time a click lands.
