# Anime girl — composed from parts, not transcribed

**Date:** 2026-08-11

The anime girl's art was ~60 hardcoded SVG path strings. She is now generated
from named numbers: `AnimeGirlProportions` → per-part builders → one layer table
baked at load.

## Why

"Her chin is too pointy" was a hunt through eight control points, and the only
way to see what an edit did was to render it. That is how a face that measured
correctly on every adult proportion ratio still came out gaunt — I could compute
the ratios but not *see* them, so I optimised the numbers and lost the drawing.

The same edit is now `chinTaper: 0.7`. More usefully, a dial can be **checked**:
`swift run RigStudio --proportions <dir>` renders every dial swept across its
range, so a value is judged by eye instead of argued about from a number.

## Shape

- `AnimeGirlProportions` — every dimension as a named number. Vertical landmarks
  (crown, chin, shoulder, waist, hip, bootTop, sole), head (headWidth,
  chinTaper, skullRound), eyes (eyeHeightRatio, eyeAspect, irisFill, lidWeight),
  hair (hairVolume, fringeDepth, tailWidth, tailFlare, tailCurl), body
  (ribWidth, waistWidth, deltoid, limb widths), outfit (topHem, skirtHem,
  pleats). Derived values — `faceHeight`, `eyeLine`, `browLine`, `shoulderSpan` —
  are computed, so they cannot drift from their inputs.
- `AnimeGirlParts` — `Head`, `Eyes`, `Hair`, `Torso`, `Limbs`, `Outfit`,
  `Sparkles`. Each is a pure function of the proportions returning its own
  `[Layer]`: shapes, fills, strokes and rig assignment together. Composition is
  concatenation, so swapping `Hair.tails` for a bob touches nothing else.
- `AnimeGirlArt` — palette, the `Part` skeleton, and `build(_:)`, which
  concatenates the parts in draw order and assigns layer ids. `layers` is
  `build(.standard)`, a stored constant, so draw-time cost is unchanged.
- `Sketch` / `PathSketch.swift` — a path as data rather than a string.

Nothing downstream changed: `RigView`, `RigSubject`, the rig tests and all three
performances are untouched. `AnimeGirlView` gained an optional `layers:`
parameter defaulting to the shipped table, which is the seam the variant sheet
uses.

## Two things this design buys beyond readability

**Pivots derive from the same numbers as the art.** `Part.pivot` reads
`AnimeGirlArt.shape`, so moving a landmark moves its joint with it. In the old
table pivots were literals that had to be remembered separately from the paths —
a silent-breakage bug waiting for the next redesign.

**Mirroring instead of hand-written pairs.** Every paired shape is authored once
on the left and reflected about the canvas midline. The old hand-mirrored pairs
had already drifted — her two hands sat 0.4 units apart in x for no reason. That
class of bug is now unrepresentable.

## Ratios the standard proportions hit

| ratio                  | value | adult F |
|------------------------|-------|---------|
| heads tall             | 5.85  | 6–7     |
| shoulders / head width | 1.64  | ~1.6    |
| waist / shoulders      | 0.67  | ~0.70   |
| leg fraction of height | 0.48  | ~0.47   |
| face width : height    | 0.75  | ~0.72   |
| eye height / face      | 0.195 | ~0.20   |

Shoulder span relative to head width is the strongest single cue — the first
draft had it at 1.03, which is a toddler's proportion, and no amount of
head-shrinking fixes that. The `deltoid` row of the proportion sheet shows it
directly.

## Caveats

- `build(_:)` is pure but not cheap enough for a per-frame call. It is fine for a
  tool rendering a static sheet; a live slider should debounce or cache.
- The proportion sheet renders the rest pose only. A dial that looks right
  standing still can still break a performance — the fist pump had to be re-aimed
  after the head shrank, because arms draw behind the head.
- Only the anime girl is converted. The other four characters keep their
  hardcoded tables.
