# Compact floating bar

**Date:** 2026-07-28

An opt-in mode where the floating bar sheds its controls while the timer runs,
expands back to the full pill on hover, and expands again on its own at every
phase change so the character performance has a stage to play on.

The bar earns its place by being ignorable. A 236pt pill carrying three buttons
sits on top of whatever you are doing for the entire session, and the buttons are
the part that pulls the eye — a row of targets reads as something wanting to be
used. Compact mode drops them, keeping the ring and the countdown at 133pt.

An earlier revision collapsed all the way to a 46pt ring, on the theory that the
changing digits were the distraction. In use that was too far: a timer that will
not tell you the time is a progress bar, and having to hover to read it defeats
the point of a bar that is always on screen. The seconds are the arguable half of
this; the controls are not.

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

Entering the collapsed bar expands it; leaving it collapses again. The
expanded rect strictly contains the compact one, so collapse can only fire once
the cursor is outside a region it was already outside — expand/collapse cannot
oscillate. This is a property worth preserving if the geometry is ever retuned.

**There is no hover debounce.** Entering and leaving both apply the instant they
arrive.

Absorbing a cursor that only brushes the bar is the *animation's* job, not a
timer's. The morph is a long, critically damped spring, so a flick barely gets
underway before the reversal re-targets it, and a spring re-targets from its
current position and velocity rather than restarting — the reversal reads as the
bar breathing once, not as an open followed by a close. That is the trade iOS makes
everywhere, and it is *why* those animations are as long as they are.

A debounce cannot do that job without also costing responsiveness, because the two
are the same number: every millisecond that rejects an accidental pass is a
millisecond of ignoring a deliberate one. This one went 350 -> 110/120 -> 90/50 ->
gone, getting better at each step, which is its own argument.

It only works if *everything* is interruptible — see the controls, below, which had
to stop being inserted and removed before the debounce could go.

One consequence: brushing the bar now counts as having looked at it, so it can
acknowledge a phase change. That is a fair reading of a cursor crossing the thing,
and the 30s backstop is the real guarantee anyway.

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

The compact form is a **133x46 pill concentric with the open one**, which grows
symmetrically out of it.

133 is the layout cut exactly where the readout ends: 11 leading + 28 ring + 10 gap
+ 74 readout + 10 trailing. Cutting there leaves the readout the same air it has in
the open pill, so the collapsed bar is a real end to the layout rather than a crop
through it.

Concentric is a pointer decision before it is an aesthetic one: whatever the cursor
was resting on to trigger the expansion becomes the centre of what it expands into,
so **the pointer ends up in the middle of the open bar**. It never lands on a
control that swept underneath it. Growing off a fixed leading edge instead would
sweep the whole pill out from under the cursor.

Height is the pill's own, which keeps the compact rect symmetric about the panel's
centre in both axes — what lets `FloatingBarHostingView.hitTest` go on ignoring
whether its view is flipped.

`StagePlacement` anchors the character to `pillFrame.midX`, which is unaffected:
the character only ever performs against the expanded pill.

### The morph is a reveal, not a re-layout

One layout, always at full width, with the box clipping it:

- The box is centred on screen and grows from its middle, but the **content is
  pinned to the box's leading edge**, so ring, readout and controls travel as one
  block that the opening carries with it.

  Centring the content instead left the ring as the only element free to move, and
  it had to be offset ~93pt to reach the middle of the collapsed bar. A symmetric
  box with a single element tracking leftward across it reads as opening *to the
  left*, not from the middle — two motions where there should be one.

- `phaseRing` and `readout` are a fixed 28pt and 74pt in both forms and are never
  hidden. The collapse simply stops short of the controls.
- The outer frame animates 236 -> 133 wide and `clipShape` turns that width change
  into a reveal.
- **The shape is constant, at a 15pt corner.** While the collapsed form was a
  circle this interpolated 23 -> 15, rebuilding a continuous-corner path every
  frame for the clip and again for the glass, which re-rasterises whenever its
  shape changes. A collapsed pill wants the same corner as an open one, so that
  cost is simply gone and only the width moves.

Conditionally inserting the readout is what made the first attempt read as a
replacement: SwiftUI re-ran the layout, so everything arrived at once in a box
that was still moving. Holding one fixed layout and moving only the clip means
nothing is ever laid out twice.

The whole morph runs on one critically damped spring, `.smooth(duration: 0.55)`,
shared by the box and the hover controls. Springs carry velocity through a
reversal, so an open interrupted halfway becomes a close rather than snapping and
replaying. Critically damped rather than springy: an earlier 0.88 damping was
chosen for weight and was wrong here, because the content rides the box's leading
edge and travels across the collapse, so even a small overshoot carried the ring
past its resting place and drew it back — which reads as the ring snapping into
position rather than arriving at it.

`glassPanel(in:)` takes the same constant `Shape` as the clip, so the glass is
configured once rather than reconfigured per frame.

### Everything is a transform

`controls` mounts Reset and Skip permanently and tucks them under the play button
with an `offset`, rather than inserting and removing them.

This is what lets the hover debounce go. A `.transition` runs on identity change
and has no velocity: reverse one halfway and it does not turn around, it restarts
from the far end. One non-interruptible element is enough to make a flick look
broken however well everything around it is tuned.

There is deliberately **no `glassGroup`** here any more. A `GlassEffectContainer`
harvests the shapes tagged by `glassMorphID` and draws them itself, so an
`.opacity` applied outside the glass effect never reaches them — an earlier attempt
at this left both glyphs stacked on the play button with its tint disc reduced to a
ring. The container existed to make insertion look good, and there is no insertion
any more. The cost is two glass circles that no longer blend into their neighbour.

Hidden is not absent: the tucked buttons carry `allowsHitTesting(false)` and
`accessibilityHidden(true)`, or they would take clicks from under the play button
and still be offered to VoiceOver.

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
- Clicking the collapsed bar as a shortcut. Reaching it means hovering, and
  hovering has already expanded the pill by the time a click lands.
