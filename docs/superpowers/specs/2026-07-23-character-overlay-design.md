# Character overlay — engineering design

**Date:** 2026-07-23
**Status:** Approved
**Art direction:** `2026-07-23-samurai-art-direction-v2.md` (Samurai);
`2026-07-23-character-art-direction.md` (the other four, still at v1 quality)

## Purpose

When a phase changes, a small animated character pops out from behind the floating
pill, performs a short in-character move, and disappears. The pill itself swells
while this happens, as if woken up.

It is a flourish, not an alert. The notification banner and chime keep doing the
real work; if the user is looking away, nothing is lost.

## Decisions

| Question | Answer |
|---|---|
| Art source | Pure SwiftUI vector shapes. No images, no sprite sheets, no external assets. |
| Where it appears | From behind the floating pill, emerging past one of its four edges. |
| Which edge | Authored per variation; flipped to the opposite edge when the pill is too close to a screen edge. |
| Pill reaction | Scale to 1.15, anchored centre. |
| Variations | Three per character: `focusStart` (resume), `breakStart` (pause), `longBreak`. |
| Roster | Samurai, Ninja, Rabbit-costume guy, Anime girl, Army General. |
| Default | Off. Opt in from a new Character tab in Settings. |
| First build | Samurai, end to end, before the other four. |

## Non-goals

- Replacing the notification or chime.
- Sound effects for the character.
- Reacting to anything other than phase transitions (no idle animations, no
  hover-triggered cameos).

## Architecture

### The window

The floating pill's existing `NSPanel` gains a **168pt transparent margin on all four
sides**: 236×46 becomes 572×382. (This started at 64pt and grew when the Samurai was
redrawn at 150pt tall — the margin has to hold the character plus the pill's growth.) The margin serves two purposes at once — it is the
stage the character emerges into from any edge, and it is the room the pill needs to
grow 15% without being clipped by its own window.

Consequences that must be handled:

- **Stored position must be reinterpreted.** `floatingBarOrigin` currently holds the
  panel origin, which was also the pill's origin. Once the panel is larger these
  diverge. The stored value is treated as the *pill's* origin and the panel is placed
  at `pill − margin`, so an existing dragged position survives the change and nothing
  moves on screen.
- **Clicks must pass through the margin.** A borderless window still swallows clicks
  in transparent areas. The character and margin get `allowsHitTesting(false)` so
  `NSHostingView` reports no hit and the click falls through.
- **Dragging must stay confined to the pill.** `isMovableByWindowBackground` would
  otherwise let the user drag the window by its invisible halo. If that proves true
  on screen, the drag is reimplemented as a gesture on the pill itself.
- **The pill is translucent**, so a character behind it would ghost through the
  glass. The character is masked to the region beyond the pill's edge, which is also
  exactly the "rising from behind a fence" read.

### Emergence

```swift
enum StageEdge { case top, bottom, leading, trailing }
```

Each variation authors a preferred edge. At fire time `CharacterStage` checks whether
the pill is within the margin of that screen edge; if so it uses the opposite edge.
The choreography is identical either way.

**The character always stays upright.** Emerging from the leading edge means sliding
in horizontally, not lying on its side. The art direction's `root.offset.y 48→0`
therefore generalises to "translate `48pt` along the edge's inward normal". This is a
single substitution and every authored timeline survives it unchanged.

### Components

| Unit | Target | Responsibility |
|---|---|---|
| `Character` | Core | The roster, `Codable`, persisted by raw value. |
| `CharacterCue` | Core | `focusStart` / `breakStart` / `longBreak`, plus the mapping from a phase transition. Pure and unit-tested. |
| `CharacterStage` | App | Edge selection, flip-when-cramped, masking, running the clock, Reduce Motion fallback. Knows nothing about any particular character. |
| `SamuraiView` (and four more later) | App | Pure vector body. One `KeyframeAnimator` over a per-character `Pose` struct. |
| `PillReaction` | App | The 1.15 scale, driven by the same cue so it cannot drift out of sync. |

The boundary that matters: `CharacterStage` owns *when and where*, each character view
owns *what it looks like*. Adding a sixth character is one new file and one enum case.

### Cue mapping

```
finished .focus      -> next .longBreak  =>  .longBreak
finished .focus      -> next .shortBreak =>  .breakStart
finished .shortBreak -> next .focus      =>  .focusStart
finished .longBreak  -> next .focus      =>  .focusStart
```

Skipping a phase manually fires the same cue as elapsing it. Reset fires nothing.

### Animation runtime

Each character view is a `KeyframeAnimator` over a struct of animatable properties —
one field per named part in the art direction:

```swift
struct SamuraiPose {
    var emergence: Double = 200   // design units behind the occluding edge
    var rootLean, rootScaleY: Double
    var torso, head, kabuto, maedate: Double
    var sodeL, sodeR, swordArmUpper, swordFore, katana: Double
    var kusazuriL, kusazuriFL, kusazuriFR, kusazuriR: Double
    // …one field per rig joint, plus the expression cross-fade opacities
}
```

`emergence` is authored on a 0…200 scale; `CharacterStage` maps it onto the real
distance each edge needs, since hiding past the left edge is a different distance
than past the top.

The art direction's keyframe tables map one row to one `KeyframeTrack` entry, so the
spec is transcribed rather than reinterpreted.

## Settings

A fourth tab beside Timer / Music / Alerts:

| Key | Default |
|---|---|
| Character | `none` (feature off) |
| — | Preview button per variation |

The tab states plainly that the character requires the floating bar to be visible,
rather than silently doing nothing when it is hidden.

## Accessibility

If `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` is set, the character
does not leap, spin, or bounce. It fades in at its final pose, holds, and fades out,
and the pill's scale change is replaced with a brief opacity change. Honoring this is
cheap and ignoring it is wrong.

## Error handling

- **Floating bar hidden** — no stage exists, so the cue is dropped. Not an error.
- **Pill in a screen corner** — both the preferred edge and its opposite may be
  cramped. The stage falls back to whichever edge has the most room; there is always
  one, because the pill is smaller than the screen.
- **Character set to `none`** — `AppDelegate` never builds a stage, so the cost is
  zero rather than an invisible animation running every transition.

## Testing

- `CharacterCue` mapping: the full transition table, including that skip and elapse
  produce the same cue and that reset produces none. Unit-tested in `PomodoroCore`.
- `StageEdge` flipping: given a pill frame and a screen frame, the chosen edge. Pure
  geometry, unit-testable without any UI.
- The animations themselves are verified by screenshotting the running app at several
  points through each variation, using the preview buttons to fire them on demand.

## Verification status (2026-07-23)

Verified by offscreen `ImageRenderer`, which works with the display locked:

- All 60 paths transcribe correctly; the samurai renders as designed.
- The composed stage is correct — character behind the pill, feet occluded at the
  ground line, correct scale — at risen, hidden, and mid-emergence.
- `CharacterCue` mapping and `StageEdge` flipping are unit-tested.

**Not yet verified: the animation running in the live app.** Three false diagnoses
were made and later retracted during this work, all from bad observations rather
than bad reasoning:

1. "`.position` inside nested frames blanks the hosting view" — the evidence was a
   screenshot taken before the app had drawn (~3s after launch).
2. "Mounting `SamuraiView` blanks the panel" — an A/B that looked conclusive but was
   taken against a **locked screen**, where no window renders at all.
3. "The CoreAudio gate prevents starting music when nothing plays" — the property
   reads `true` in silence on this Mac, so the gate never fired.

The lesson worth keeping: before concluding anything from a screenshot, confirm the
screen is awake, the app has finished its first draw, and no modal is blocking the
run loop. A capture that shows nothing is not evidence that nothing was drawn.

One real bug *was* found and fixed: `KeyframeAnimator` only animates when its trigger
changes, and the stage created one at the moment of the cue — so it mounted with the
trigger already final, never ran, and rendered its initial (fully hidden) pose. The
animator is now always mounted with a generation counter as trigger.

Use `POMODORO_DEMO=focusStart|breakStart|longBreak` to play a cue ~1.5s after launch
rather than waiting out a real session.

## Limitations

- 1.15 is a bold scale — ~35pt of width on a 236pt pill. It is a single constant so
  it can be retuned in one line once seen on a real screen.
- Fifteen hand-authored timelines is genuinely a lot of work. Samurai is built and
  verified first so the other four are transcribed against proven machinery.
- The character cannot appear over a fullscreen app *if* the pill is hidden there —
  it inherits exactly the pill's visibility, no more.
