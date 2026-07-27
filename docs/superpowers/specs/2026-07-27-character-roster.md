# Character roster — complete

**Date:** 2026-07-27

All five characters are drawn, rigged, animated and selectable in
Settings → Character. Each has three performances: back-to-work, break, and the
rarer long-break celebration.

| Character | Paths | Rig parts | Signature move |
|---|---|---|---|
| Samurai | 60 | 22 | blade leveled at the viewer |
| Ninja | 55 | 18 | full backflip |
| General | 52 | 17 | four-step march, stick raised |
| Rabbit-costume guy | 48 | 14 | mascot-mode spin |
| Anime girl | 55 | 16 | twirl with sparkles |

215 hand-authored paths, zero image assets — everything is SwiftUI `Path` data.

## The pipeline, proven five times

1. `<Name>Art.swift` — palette, a `Part` enum conforming to `RigPart` (parents +
   pivots), and the layer table as SVG-style path strings.
2. `<Name>View.swift` — a `Pose` struct with one field per animated joint, plus a
   `PartExtras` modifier for anything moving by more than a rotation. The draw
   logic is inherited from `RigView`.
3. `<Name>Performance.swift` — three `KeyframeTrack` sets.
4. One case each in `CharacterStage.performance(_:)` and the three `CharacterPlan`
   switches; flip `isImplemented` in `PomodoroCharacter`.
5. Render the rest pose offscreen with `ImageRenderer` **before** wiring it in.

All fifteen performances (five characters x three cues) are verified running
live by pose trace, each showing ~300-400 view rebuilds with its authored
signature property sweeping the expected range.

All five transcribed correctly on the first render. That is the payoff for
keeping the spec's own path strings and parsing them, rather than hand-converting
several hundred coordinates into Swift calls: the risk lives in one small
tested parser instead of being spread across every number.

## What the process taught

**One character per art-direction run.** A single request covering three
characters overran its output limit and returned only one of them complete.
Split into individual runs, every subsequent spec arrived whole.

**Trace state, do not chase frames.** Screenshotting a 2–3 second performance is
a coin flip. Logging pose values across view rebuilds is deterministic and works
with the screen locked — each character shows ~400 rebuilds with its signature
property sweeping the full authored range.

**Verify that a test can fail.** The first rig test suite passed happily with
the transform-order bug reintroduced. So did the first render-based replacement,
because bounding-box coverage barely moves when a small part detaches. Measuring
whether a child still sits on its parent discriminates 2.8 units from 53.7.

## Adding a sixth character

`RigTests.allImplementedRigsAreCovered` fails if a character is implemented
without being added to the structural checks, so the test suite will tell you
what you forgot.
