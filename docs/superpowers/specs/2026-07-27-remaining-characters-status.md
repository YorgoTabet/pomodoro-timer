# Remaining characters — status

**Date:** 2026-07-27

## Shipped

| Character | Paths | Rig parts | Performances | Verified |
|---|---|---|---|---|
| Samurai | 60 | 22 | 3 | offscreen render + live pose trace |
| Ninja | 55 | 18 | 3 | offscreen render + live pose trace |

Both are selectable in Settings → Character.

## Not yet drawn

Rabbit-costume guy ("Mochi"), Anime girl ("Hoshi"), Army General.

An art-direction pass was run for all three on 2026-07-27 and **came back
truncated**. What survived:

- **General** — complete: 52-path layer table, 12-colour palette, 17-part rig,
  all three timelines, silhouette test. Transcribable as-is.
- **Anime girl (Hoshi)** — partial: expressions, all three timelines and the
  silhouette test arrived; **the layer table and palette did not**.
- **Rabbit (Mochi)** — nothing usable arrived.

## What transcription now costs

The pipeline is proven and mechanical, roughly two hours of careful work per
character:

1. Generate `<Name>Art.swift` — palette, `Part` enum conforming to `RigPart`
   (parents + pivots), and the layer table as SVG-style path strings.
2. Write `<Name>View.swift` — a `Pose` struct with one field per animated joint,
   plus a `PartExtras` modifier for anything moving by more than a rotation.
   The draw logic itself is inherited from `RigView`.
3. Write `<Name>Performance.swift` — three `KeyframeTrack` sets.
4. Add one case each to `CharacterStage.performance(_:)` and the three
   `CharacterPlan` switches, and flip `isImplemented` in `PomodoroCharacter`.
5. Verify offscreen with `ImageRenderer` before touching the running app.

Steps 4 and 5 are minutes. Steps 1–3 are the transcription.

## Before drawing the remaining three

Re-run the art direction for Mochi and Hoshi — the existing v1 chibi specs in
`2026-07-23-character-art-direction.md` are below the bar the Samurai and Ninja
set, and the 2026-07-27 pass did not fully land. Ask for one character per
agent run rather than three; the three-in-one request is what overran.
