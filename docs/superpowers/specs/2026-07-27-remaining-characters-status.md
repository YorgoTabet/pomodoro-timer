# Character roster — status

**Date:** 2026-07-27

## Shipped

| Character | Paths | Rig parts | Verified |
|---|---|---|---|
| Samurai | 60 | 22 | offscreen render + live pose trace |
| Ninja | 55 | 18 | offscreen render + live pose trace |
| General | 52 | 17 | offscreen render + live pose trace |
| Rabbit-costume guy | 48 | 14 | offscreen render + live pose trace |

All four are selectable in Settings → Character, each with three performances.

## Not drawn

**Anime girl.** The 2026-07-27 art-direction pass returned her expressions,
timelines and silhouette test but **not her layer table or palette**, which are
the two things transcription actually needs. Re-run the art direction for her
alone before implementing — asking one agent for three characters is what
overran and lost them.

## The pipeline, now proven four times

1. `<Name>Art.swift` — palette, a `Part` enum conforming to `RigPart` (parents +
   pivots), and the layer table as SVG-style path strings.
2. `<Name>View.swift` — a `Pose` struct with one field per animated joint, plus a
   `PartExtras` modifier for anything moving by more than a rotation. The draw
   logic is inherited from `RigView`.
3. `<Name>Performance.swift` — three `KeyframeTrack` sets.
4. One case each in `CharacterStage.performance(_:)` and the three `CharacterPlan`
   switches; flip `isImplemented` in `PomodoroCharacter`.
5. Render the rest pose offscreen with `ImageRenderer` **before** wiring it into
   the app. All four transcribed correctly on the first render, which is the
   payoff for keeping the spec's own path strings rather than hand-converting
   them into Swift calls.

## Verification method

Screenshots of a 2–3 second performance are a coin flip. Tracing pose values
across view rebuilds is deterministic and works with the screen locked: each
character shows hundreds of rebuilds with its signature property sweeping its
full authored range — the ninja's backflip and the rabbit's spin both cover a
complete 360, the General's march drives his legs to -27 and his stick arm
to -122.
