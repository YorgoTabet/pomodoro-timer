# Samurai art direction — v2 (detailed vector rig)

**Date:** 2026-07-23
**Supersedes:** the Samurai section of `2026-07-23-character-art-direction.md`
**Engineering design:** `2026-07-23-character-overlay-design.md`

Driven by a reference image: a polished cartoon-vector sticker — thick dark
outlines, flat colour with a few hard-edged shading planes, layered lacquered plate
armour, a menpo face mask, a kabuto with a big gold crescent maedate, a drawn
katana, layered kusazuri skirt plates, and a sheathed second sword.

## Where the authoritative data lives

**The 60 path definitions live in `Sources/PomodoroUI/SamuraiArt.swift`, not in this
document.** They are stored there as the original SVG-style command strings and
parsed by `VectorPath`, so the code *is* the spec — there is no second copy to drift
out of sync. This document records everything the code cannot express: why the rig
is shaped the way it is, the motion ranges, and the intent behind each performance.

## Canvas and conventions

- **200 × 260 design units**, origin top-left, +y down. Centreline x = 100.
- The occluding pill edge sits at **y = 196**, not at the canvas bottom. The last 64
  units are body that is meant to be hidden. `CharacterStage.groundInset` aligns that
  line to the pill's edge — get this wrong and he floats above the pill instead of
  standing behind it.
- Positive rotation is **clockwise on screen**.
- `emergence` is authored on a 0…200 scale where 200 is hidden. The stage maps that
  onto the real distance each edge needs, because "hidden" past the left edge is a
  different distance than past the top.
- Rendered at **150pt tall**. The v1 chibi was 44pt; this art carries far too much
  detail to read at that size, which is why the panel margin grew to 168pt.

## Why absolute paths, no `.position`

Every shape is absolute `Path` data in one flat coordinate space. This is not a
style preference. The v1 chibi was built from primitives placed with `.position`
inside nested `.frame`-constrained stacks, and mounting it in the live panel blanked
the *entire* hosting view — pill included — while rendering correctly through
`ImageRenderer`. A plain `Rectangle` in the same slot worked.

**That diagnosis was never conclusively proven.** A modal permission dialog was
later found to have been blocking the app's run loop during several of those tests,
and app-launch render latency (~3s) confounded others. The path-based architecture is
still the right choice on its own merits — it is how detailed vector art is authored
— but the original failure may have had a different cause. Anyone revisiting this
should re-test rather than trust the `.position` explanation.

## Stroke system

Two weights only: **3.0** for major silhouette forms, **1.8** for small details.
Shading planes and inset strips take no stroke. Every outlined path is filled, then
stroked with `OUTLINE`.

## Palette

| Role | Name | Hex |
|---|---|---|
| Outline ink | `OUTLINE` | `#2A1A16` |
| Armour lacquer red | `RED` | `#C13327` |
| Red shadow plane | `RED_SHADE` | `#8E2018` |
| Gold trim | `GOLD` | `#F0B84B` |
| Gold shade | `GOLD_SHADE` | `#C08A2A` |
| Iron / black lacquer | `IRON` | `#3B322E` |
| Cloth indigo | `INDIGO` | `#33475E` |
| Skin | `SKIN` | `#F0C49A` |
| Skin shade | `SKIN_SHADE` | `#CE9E72` |
| Blade steel | `STEEL` | `#C9D2D8` |
| Steel highlight | `STEEL_HILITE` | `#F4F8FA` |
| Leather | `LEATHER` | `#7A4E2C` |

Hard-edged shading planes (no outline): the `RED_SHADE` planes, the `SKIN_SHADE`
neck, the `STEEL_HILITE` hamon, the `GOLD_SHADE` tsuka wraps.

## The rig

22 parts. Pivots are in design units; the code converts them to `UnitPoint` by
dividing by the canvas size.

| Part | Parent | Pivot | Range | Squash/stretch | Secondary lag |
|---|---|---|---|---|---|
| `root` | — | (100, 260) | offset −14…+200; lean ±4° | y 0.90…1.06, bottom anchor | — |
| `legL` | root | (90, 196) | ±25° | — | — |
| `legR` | root | (110, 196) | ±25° | — | — |
| `torso` | root | (100, 163) | ±8° | y 0.94…1.05 at (100,168) | — |
| `head` | torso | (100, 113) | ±15°; scale …1.06 | takes only | — |
| `kabuto` | head | (100, 80) | ±6°; offset.y −4…0 | — | 70 ms |
| `maedate` | kabuto | (100, 64) | ±12° | — | **90 ms — the showpiece** |
| `sodeL` | torso | (70, 117) | −28…+22° | — | 80 ms |
| `sodeR` | torso | (130, 117) | −22…+28° | — | 80 ms |
| `offArmUpper` | torso | (76, 124) | −45…+85° | — | — |
| `offArmFore` | offArmUpper | (64, 147) | −5…+115° | — | — |
| `swordArmUpper` | torso | (122, 124) | −130…+40° | — | — |
| `swordFore` | swordArmUpper | (135, 151) | −135…+15° | — | — |
| `katana` | swordFore | (150, 164.5) | ±20° | — | 60 ms |
| `chestCord` | torso | (100, 128) | ±12° | — | 80 ms |
| `sashTailL` | torso | (97, 169) | ±22° | — | 120 ms |
| `sashTailR` | torso | (103, 169) | ±22° | — | 120 ms |
| `kusazuriL` | torso | (74, 168) | ±14° | — | 60 ms |
| `kusazuriFL` | torso | (92, 168) | ±10° | — | 80 ms |
| `kusazuriFR` | torso | (108, 168) | ±10° | — | 100 ms |
| `kusazuriR` | torso | (126, 168) | ±14° | — | 120 ms |
| `scabbard` | torso | (80, 163) | −8…+14° | — | 90 ms |

**Draw order is global and independent of the hierarchy.** `shikoro` belongs to
`kabuto` but is drawn third, behind the body. The implementation therefore composes
each layer's transform from its ancestor chain rather than nesting groups.

**The staggered kusazuri lags (60/80/100/120 ms, left to right) are the point.**
Firing the skirt plates simultaneously kills the cascade that makes the armour feel
like separate hanging pieces.

## Expression

The menpo permanently hides the mouth, so brows, eye whites and pupils do all the
acting. Three pre-drawn states, cross-faded over 0.2s — never run partial opacities
of two brow states except during that fade.

- **Fierce (default)** — heavy wedge brows diving inward, angular eye whites.
- **Content** — soft raised arcs, pupils dropped 1.2 units, head +3°.
- **Triumphant** — everything fades to upside-down happy arcs, head −8° chin up,
  kabuto tipping back a beat later on its 70 ms lag.

## The three performances

Full keyframe tables live in `Sources/PomodoroUI/SamuraiPerformance.swift`. Intent:

- **`focusStart` — "Snap to guard" (2.4s).** Horns peek first as a beat, then the
  body lands, a windup dips the sword, and it snaps to a raised jōdan guard with the
  blade dragging 60 ms behind the arm. Chin-down glare, one controlled breath, lower
  to ready, drop.
- **`breakStart` — "Exhale" (2.8s).** A gentle rise with almost no overshoot. Brows
  soften, shoulders drop, the torso actually contracts on the exhale, the katana
  relaxes to a lazy trailing angle, then two slow sways with everything
  counter-swinging on its own lag. A contented nod, and away.
- **`longBreak` — "Triumph" (3.4s).** Horns only, a comic pause, then a real leap
  with launch squash and air stretch. Blade thrust skyward, expression flips to
  triumphant, the cap pops, the crest whips. Two victory sways, a fist pump from the
  off arm, and a drop where everything streams upward.

**Pill reaction:** scales to 1.15 throughout, starting with the rise and settling
only once the character has finished dropping — the pill relaxing is the full stop
at the end of the sentence. Scale only; never rotate or translate it.

## Silhouette test

Four features carry the read at 150pt in solid black, each on a different edge: the
**twin-horned gold crescent** breaking the top; the **flared fukigaeshi** plus wide
**shikoro** giving a head far wider at the jaw than the crown; the **katana** cutting
a long thin diagonal off the right shoulder — the strongest "samurai, armed" cue and
the one that survives when the lower body is behind the pill; and the **flared
kusazuri hem** stepping outward at the waist, opposed by the scabbard's diagonal off
the left hip. Cropped at the pill line it still cannot be read as knight or ninja.

## Not yet done

- The animation has never been confirmed running on screen. See the engineering
  design's testing notes.
- The other four characters remain at the v1 chibi quality bar and need
  re-specifying to this standard before they are drawn.
