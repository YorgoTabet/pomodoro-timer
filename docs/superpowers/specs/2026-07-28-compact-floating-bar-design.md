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

Hover is debounced by 0.35s on the way **out** only, never on the way in. The
delay exists for dragging: `isMovableByWindowBackground` drags begin with a hit
test, and a hover drop mid-drag would otherwise collapse the pill out from under
the user's grip. It also absorbs a cursor clipping the corner of the bar on its
way somewhere else.

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

The compact form is a 44pt circle **concentric with the expanded pill**. Two
things fall out of centring it rather than aligning it to an edge:

- `pill` is already placed with `.position(x: pillFrame.midX, y: pillFrame.midY)`,
  so changing its frame keeps it centred for free.
- `StagePlacement` anchors the character to `pillFrame.midX`, so the character
  rises from the same point in both forms.

It also keeps true the existing comment on `FloatingBarHostingView.hitTest` that
the pill's rect reads the same whether the view is flipped or not.

### The morph is one view, not two

`phaseRing` stays mounted across the transition and grows 28 -> 40pt. The readout
and controls leave the `HStack`; the frame width animates 236 -> 44 and the
`RoundedRectangle` corner radius animates 15 -> 22, which is a circle at 44pt.

The readout fades faster than the width shrinks, so the digits never visibly
squash — the existing frame is sized to the widest state precisely because
content that overflows it silently breaks the glass treatment.

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
