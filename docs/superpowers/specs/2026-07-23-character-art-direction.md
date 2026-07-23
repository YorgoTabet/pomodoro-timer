# Character art direction — v1 (chibi)

**Date:** 2026-07-23
**Engineering design:** see `2026-07-23-character-overlay-design.md`
**Status:** the Samurai section here is SUPERSEDED by
`2026-07-23-samurai-art-direction-v2.md`, a far more detailed 60-path rig built
to a reference image. The other four characters below are still at this chibi
quality bar and will need re-specifying to match the Samurai before they are
drawn.

Every character lives in a 56×44pt box, origin (0,0) top-left. Positions are the
*centre* of the shape; sizes are width×height in points. The occluding pill edge is
the "horizon" at y=44. The whole character is one root group: at rest
`root.offset = 48` along the emergence normal (fully hidden), risen = `0`. Rotation
anchors are given in box coordinates.

> The art direction below was authored against an upward rise. The engineering design
> generalises `root.offset.y` to "offset along the emergence edge's inward normal";
> every timeline here survives that substitution unchanged.

**Global legibility rule.** Every character gets a 1.5pt outline stroke in `#262A33`
on its outermost silhouette shapes, plus a "rim backer" — the three largest
silhouette shapes duplicated behind everything, scaled 1.07, filled `#FFFFFF` at 28%.
The dark outline carries the read on light wallpapers; the white rim carries it on
dark ones. Neither animates independently; both inherit the root transform.

## Shared choreography principles

1. **One rise, one drop, one hero action.** Every animation is exactly: Standard Rise
   → a single in-character "hero beat" → Standard Drop. Never two competing gags.
2. **Standard Rise (R):** `root.offset 48→0` over 0.32s with
   `.spring(response: 0.32, dampingFraction: 0.68)`. The spring's ~3pt overshoot *is*
   the anticipation; do not add more. Personality lives in damping alone:
   samurai/general 0.75 (crisp), ninja 0.6 (snappy), rabbit/anime girl 0.55 (bouncy).
3. **Standard Drop (D):** a 2pt hop back (`0→-2`, 0.08s, `.easeOut`) then plunge
   (`-2→48`, 0.22s, `.easeInOut`). The little hop before dropping is the shared
   "goodbye" tell across all five — it is what makes the exit read as intentional
   rather than as a glitch.
4. **Follow-through on appendages.** Anything floppy — ears, twin tails, ahoge,
   helmet crest, band tails — starts moving 0.06–0.08s *after* the root and settles
   with `.spring(response: 0.4, dampingFraction: 0.55)`, rotating opposite to the root
   by 8–15°. This one rule is most of the "alive" feeling.
5. **At most two named parts animating at once** besides the root. At 44pt, more than
   two simultaneous motions reads as noise.
6. **Nothing meaningful below the waist.** All rotation anchors sit at y ≤ 42, so
   limbs always swing above the horizon and no keyframe depends on geometry the pill
   is covering.

## The pill's reaction

Whole pill `scaleEffect`, anchored centre. Starts at t=0.00, exactly with the
character's rise — the pill wakes as the puppet pushes up behind it, and they should
feel causally linked.

- **In:** `1.0 → 1.15` with `.spring(response: 0.35, dampingFraction: 0.6)`.
- **Hold** for the whole performance.
- **Out:** back to `1.0` over 0.45s `.smooth`, starting the moment the character's
  drop completes — the pill relaxing is the full stop at the end of the sentence.
- **Scale only.** Never rotate or translate the pill; it will look broken.

> The art direction originally recommended 1.03/1.04/1.055 per trigger. The chosen
> value is a flat 1.15 across all triggers, per the project owner. It lives in one
> constant so it can be retuned after seeing it on a real screen.

---

## 1. Samurai

### Construction (back → front)

| # | Part | Primitive | Size | Centre | Fill | Notes |
|---|---|---|---|---|---|---|
| 1 | `swordArm` (group) | — | — | anchor **(41, 36)** | — | contains 1a–1d; rest rotation **−15°** |
| 1a | arm | Capsule | 5×10 | (41, 31) | `#3B4A6B` | runs up from shoulder |
| 1b | tsuba | Circle | 5.5 | (41, 25) | `#F2B441` | |
| 1c | handle | Capsule | 3×7 | (41, 29.5) | `#C0392B` | behind tsuba |
| 1d | blade | Capsule | 3.5×22 | (41, 13.5) | vertical gradient `#F4F7FA→#D7DEE8` | tip at y≈2.5 |
| 2 | `body` | RoundedRect r7 | 26×16 | (26, 42) | `#3B4A6B` | bottom hidden |
| 3 | `leftSode` / `rightSode` | RoundedRect r3 | 10×8 | (13, 36) / (39, 36) | `#2E3A55` | rotated −10° / +10° |
| 4 | `head` | Circle | 22 | (26, 26) | `#F5C9A0` | |
| 5 | brows ×2 | Capsule | 5×1.5 | (21, 27.5) / (31, 27.5) | `#262A33` | rotated −18° / +18° (stern V) |
| 6 | eyes ×2 | Capsule (vertical) | 2×4 | (21, 30.5) / (31, 30.5) | `#262A33` | |
| 7 | mouth | Capsule | 4×1.5 | (26, 34.5) | `#262A33` | flat, resolute |
| 8 | `fukigaeshi` L/R | RoundedRect r3 | 8×10 | (12, 16) / (40, 16) | `#2E3A55` | rotated −18° / +18° |
| 9 | `helmet` | Circle | 26 | (26, 13) | `#2E3A55` | bottom edge sits just above brows |
| 10 | `crest` (group) | — | — | anchor **(26, 11)** | — | gold maedate |
| 10a | crest V ×2 | Capsule | 3×11 | (22, 7) / (30, 7) | `#F2B441` | rotated −28° / +28° |
| 10b | crest boss | Circle | 5 | (26, 11) | `#F2B441` | |

**Palette.** Armour `#3B4A6B` / `#2E3A55`; gold `#F2B441`; skin `#F5C9A0`; steel
`#E6EBF2`; handle red `#C0392B`; outline `#262A33`. On very light wallpapers the gold
washes out, so the outline on crest and tsuba is mandatory, not optional.

**Silhouette.** The kabuto bowl with V-crest antlers plus a diagonal blade breaking
the top-right of the box. No other character has hard geometry piercing the top edge
at an angle.

### focusStart — "Iai draw" (1.8s)

A single decisive slash: work has begun.

```
0.00→0.32  root       offset 48→0              .spring(0.32, 0.75)
0.10→0.32  crest      rotation 0→-10°→0        .spring(0.4, 0.55)    follow-through lag
0.32→0.44  swordArm   rotation -15°→-110°      .easeInOut            anticipation, blade cocked back
0.32→0.44  root       rotation 0→-4°           .easeInOut            leans into the wind-up
0.44→0.56  swordArm   rotation -110°→+42°      .easeOut              THE SLASH, overshoots
0.56→0.78  swordArm   rotation +42°→+30°       .spring(0.3, 0.6)     settle to extended pose
0.44→0.56  root       rotation -4°→+3°→0       .spring(0.3, 0.7)
0.60→0.75  blade      opacity 1→0.7→1          .easeInOut            one glint flicker
0.78→1.35  HOLD extended pose                                        stillness after the cut
1.35→1.50  swordArm   rotation +30°→-15°       .easeInOut            re-sheath
1.50→1.58  root       offset 0→-2              .easeOut
1.58→1.80  root       offset -2→48             .easeInOut
```

### breakStart — "Sheath and exhale" (2.0s)

Duty done; a slow bow.

```
0.00→0.32  root       offset 48→0              .spring(0.32, 0.75)
0.40→0.55  swordArm   rotation -15°→+8°        .easeInOut            lowers blade fully
0.60→1.00  root       rotation 0→+9°           .easeInOut            deep nod-bow, pivot (26,40)
0.60→1.00  crest      rotation 0→-8°           .spring(0.4, 0.55)    crest dips late
1.00→1.40  root       rotation +9°→0           .easeInOut
1.10→1.40  eyes       scale.y 1→0.25           .easeOut              content closed eyes
1.40→1.70  HOLD
1.70→1.78  root       offset 0→-2              .easeOut
1.78→2.00  root       offset -2→48             .easeInOut
```

### longBreak — "Blade to the sky" (2.6s)

Victory stance, triple glint.

```
0.00→0.32  root       offset 48→0              .spring(0.32, 0.68)
0.40→0.52  swordArm   rotation -15°→-95°       .easeInOut            wind-up down-across
0.52→0.70  swordArm   rotation -95°→+5°→-8°    .bouncy               blade thrust straight up
0.52→0.70  root       scale 1→1.08→1.0         .bouncy               chest-out swell, anchor (26,44)
0.80→1.90  root       offset 0→-2→0 ×3         .spring(0.35, 0.6)    three proud bounces, 0.37s apart
0.85/1.20/1.55  blade opacity 1→0.55→1 (0.12s) .easeInOut            glint per bounce apex
0.85/1.22/1.59  crest rotation 0→+7°→0         .spring(0.4, 0.55)    jiggles per bounce, 0.05s lag
1.90→2.25  swordArm   rotation -8°→-15°        .easeInOut            lower to rest
2.25→2.38  root       offset 0→-2              .easeOut
2.38→2.60  root       offset -2→48             .easeInOut
```

---

## 2. Ninja

### Construction (back → front)

| # | Part | Primitive | Size | Centre | Fill | Notes |
|---|---|---|---|---|---|---|
| 1 | `bandTailA` / `bandTailB` | Capsule | 3×9 | (16, 15) / (18, 13) | `#C0392B` | anchors **(19, 18)**; rest −55° / −30° |
| 2 | `throwArm` (group) | — | — | anchor **(17, 36)** | — | rest rotation **0°** |
| 2a | arm | Capsule | 5×9 | (15, 31) | `#33384A` | |
| 2b | hand | Circle | 4 | (14, 27) | `#33384A` | gloved |
| 2c | `shuriken` | 2× RoundedRect r1.5 crossed | 12×3.5 each | both (13, 24), at 45° and 135° | `#AEB6C2` | own anchor **(13, 24)** for spin; centre Circle 2.5 `#7E8794` |
| 3 | `body` | RoundedRect r7 | 22×16 | (28, 42) | `#33384A` | |
| 4 | belt | Capsule | 18×3.5 | (28, 37) | `#C0392B` | |
| 5 | `head` | Circle | 23 | (28, 24) | `#33384A` | the wrap *is* the head |
| 6 | `eyeSlit` | RoundedRect r3.5 | 17×7 | (28, 22) | `#E8B48C` | skin showing through |
| 7 | `eyes` ×2 | Circle | 3.5 | (23.5, 22) / (32.5, 22) | `#262A33` | 1.2pt white glint upper-right of each |

**Extra effect shape.** `smokePuff` = three Circles 6/8/6pt, `#9AA0AC`, centred
(28, 38), opacity 0 at rest. Pre-placed, never inserted mid-animation.

**Palette.** Wrap `#33384A`; skin `#E8B48C`; accent red `#C0392B`; steel `#AEB6C2`;
outline `#262A33`. The wrap is dark — on dark wallpapers the 28% white rim backer is
what saves it. Do not darken further.

**Silhouette.** A featureless dome broken by one horizontal slit, two ribbon tails
streaming off the back-left, and a four-point star held high.

### focusStart — "Smoke-bomb entrance" (1.6s)

Fastest entrance in the cast.

```
0.00→0.20  root       offset 48→0              .spring(0.24, 0.6)    2× speed, ninja privilege
0.00→0.35  smokePuff  opacity 0→0.8→0, scale 0.5→1.6   .easeOut      puff blooms at the horizon
0.05→0.30  bandTails  rotation +25° past rest→rest     .spring(0.4, 0.55)
0.30→0.42  shuriken   rotation 0→540°          .easeOut              1.5 fast spins in hand
0.30→0.40  eyes       scale.y 1→0.55           .easeOut              narrowed, game face
0.42→1.10  HOLD; at 0.70→0.85 shuriken 540°→585° .easeInOut          one slow menacing turn
1.10→1.18  root       offset 0→-2              .easeOut
1.18→1.38  root       offset -2→48             .easeInOut
1.38→1.60  smokePuff  opacity 0→0.6→0, scale 0.6→1.4   .easeOut      exit mirrors entrance
```

### breakStart — "Guard down" (2.0s)

```
0.00→0.32  root       offset 48→0              .spring(0.32, 0.6)
0.45→0.65  throwArm   rotation 0→+50°          .easeInOut            shuriken lowered out of sight
0.70→0.85  eyes       scale.y 1→0.2            .easeOut              the slit smiles
0.70→0.90  root       rotation 0→+5°           .easeInOut            content head-cock
0.75→1.30  bandTails  rotation rest→rest-10°→rest ×2   .spring(0.5, 0.5)  gentle breeze sway
1.30→1.50  root       rotation +5°→0           .easeInOut
1.50→1.70  HOLD
1.70→1.78  root       offset 0→-2              .easeOut
1.78→2.00  root       offset -2→48             .easeInOut
```

### longBreak — "Backflip" (2.4s)

```
0.00→0.32  root       offset 48→0              .spring(0.32, 0.6)
0.45→0.58  root       scale.y 1→0.82, offset 0→+4      .easeInOut    deep squash, loading
0.58→0.72  root       scale.y 0.82→1.06, offset +4→-14 .easeOut      LAUNCH
0.58→1.02  root       rotation 0→-360°         .easeInOut            full backflip about (28,22)
0.72→1.02  root       offset -14→0             .easeInOut           falling through second half
1.02→1.14  root       scale.y 1.06→0.9→1       .spring(0.3, 0.55)    landing squash
1.02→1.30  bandTails  rotation rest+40°→rest   .spring(0.4, 0.5)     tails catch up violently
1.05→1.25  smokePuff  opacity 0→0.7→0, scale 0.6→1.3   .easeOut      landing poof
1.30→1.90  HOLD; eyes scale.y 1→0.55 at 1.35
1.90→1.98  root       offset 0→-2              .easeOut
1.98→2.20  root       offset -2→48             .easeInOut
```

---

## 3. Rabbit-costume guy

The comedic engine: **the costume is enthusiastic, the human face never is.** Eyes and
mouth stay fixed in every animation; all joy is expressed by ears and bounces.

### Construction (back → front)

| # | Part | Primitive | Size | Centre | Fill | Notes |
|---|---|---|---|---|---|---|
| 1 | `leftEar` (group) | — | — | anchor **(22, 15)** | — | rest rotation **−6°** |
| 1a | ear base | Capsule | 7×12 | (22, 9) | `#F4F1EC` | |
| 1b | inner pink | Capsule | 3×7 | (22, 9) | `#F2A7B8` | |
| 1c | `leftEarTip` | Capsule | 7×10 | (22, 0) | `#F4F1EC` | anchor **(22, 4)**; rest **−70°** (fully flopped) |
| 2 | `rightEar` (group) | — | — | anchor **(34, 15)** | — | rest rotation **+8°** |
| 2a | ear base | Capsule | 7×12 | (34, 9) | `#F4F1EC` | |
| 2b | inner pink | Capsule | 3×7 | (34, 9) | `#F2A7B8` | |
| 2c | `rightEarTip` | Capsule | 7×10 | (34, 0) | `#F4F1EC` | anchor **(34, 4)**; rest **+40°** |
| 3 | `body` | RoundedRect r8 | 24×14 | (28, 44) | `#F4F1EC` | belly Ellipse 14×10 `#FFFFFF` |
| 4 | `costumeHead` | Circle | 26 | (28, 26) | `#F4F1EC` | oversized mascot head |
| 5 | costume nose | Circle | 3 | (28, 18) | `#F2A7B8` | |
| 6 | `faceOpening` | Ellipse | 13×15 | (28, 28) | `#E5A87E` | + 1.5pt `#D8D3CC` rim |
| 7 | human eyes ×2 | Circle | 2.5 | (25, 26) / (31, 26) | `#262A33` | tiny, dead inside |
| 8 | human mouth | Capsule | 5×1.5 | (28, 32.5) | `#262A33` | perfectly flat, never smiles |
| 9 | `zipper` | Circle 2.5 + Rect 1×3 | — | (38, 37) | `#D9A441` | the costume tell |

**Palette.** Costume `#F4F1EC`; pink `#F2A7B8`; human skin `#E5A87E`; shade
`#D8D3CC`; zipper gold `#D9A441`; outline `#262A33`. Near-invisible on light
wallpapers without the outline — it is load-bearing here.

**Silhouette.** Two long ears at two *different* wrong angles on a head too big for
its body. The asymmetric flop is the whole character.

### focusStart — "Reluctant snap to attention" (2.0s)

```
0.00→0.40  root        offset 48→0             .spring(0.4, 0.8)     heavier, slower — he doesn't want to be here
0.10→0.45  earTips     rotation rest→rest+15°  .spring(0.5, 0.5)     ears sag further on the way up
0.55→0.75  HOLD                                                      a beat of visible reluctance
0.75→0.90  rightEarTip rotation +40°→+5°       .bouncy               right ear SNAPS almost upright
0.85→1.00  leftEarTip  rotation -70°→-15°→-25° .bouncy               left ear tries, never fully works
0.90→1.02  root        offset 0→-3→0           .spring(0.3, 0.55)    one dutiful hop
1.02→1.55  HOLD at attention, face unchanged
1.55→1.63  root        offset 0→-2             .easeOut
1.63→1.85  root        offset -2→48            .easeInOut
1.85→2.00  earTips     rotation → rest         .spring(0.4, 0.5)     re-flop as he sinks
```

### breakStart — "The costume celebrates" (2.2s)

```
0.00→0.32  root        offset 48→0             .spring(0.32, 0.55)
0.40→0.58  root        offset 0→-6→0           .spring(0.3, 0.5)     hop 1
0.46→0.70  leftEarTip  rotation -70°→-100°→-70°   .spring(0.35, 0.5) ears flap DOWN as he goes up
0.46→0.70  rightEarTip rotation +40°→+70°→+40°    .spring(0.35, 0.5)
0.62→0.80  root        offset 0→-6→0           .spring(0.3, 0.5)     hop 2, ears repeat 0.68→0.92
0.90→1.05  root        rotation 0→+6°          .easeInOut            pleased tilt, anchor (28,42)
1.05→1.60  HOLD tilted; mouth remains a flat line — the contrast is the joke
1.60→1.75  root        rotation +6°→0          .easeInOut
1.75→1.83  root        offset 0→-2             .easeOut
1.83→2.05  root        offset -2→48            .easeInOut
```

### longBreak — "Full mascot mode" (2.6s)

```
0.00→0.32  root        offset 48→0             .spring(0.32, 0.55)
0.45→1.35  root        three hops -8/-9/-8, 0.3s apart   .spring(0.28, 0.5)
           earTips     opposite-phase flap per hop, 0.07s lag  .spring(0.35, 0.5)
1.35→1.85  root        rotation3D(y) 0→360°, axis x=28   .easeInOut  flat-spin twirl
1.55→1.95  earTips     rotation rest→rest+35°→rest       .spring(0.4, 0.45)  flung outward
1.95→2.25  HOLD; at 2.0 zipper opacity 1→0.5→1 over 0.15s
2.25→2.33  root        offset 0→-2             .easeOut
2.33→2.55  root        offset -2→48            .easeInOut
```

---

## 4. Anime girl

The ahoge is her emotional seismograph — it reacts, with lag, to everything.

### Construction (back → front)

| # | Part | Primitive | Size | Centre | Fill | Notes |
|---|---|---|---|---|---|---|
| 1 | `leftTail` / `rightTail` | Capsule | 8×20 | (13, 27) / (43, 27) | `#8A5FD6` | anchors **(16, 18)** / **(40, 18)**; rest −15° / +15° |
| 1a | tail ties ×2 | Circle | 4 | (15.5, 18.5) / (40.5, 18.5) | `#F2B441` | gold scrunchies |
| 2 | `hairBack` | Circle | 25 | (28, 21) | `#8A5FD6` | |
| 3 | `body` | RoundedRect r7 | 20×14 | (28, 44) | `#3D4C7A` | navy blazer |
| 4 | bow | 2 triangles 5×4 + Circle 2.5 knot | — | (28, 38.5) | `#E8536B` | |
| 5 | `fistArm` | Capsule 5×10 + hand Circle 4 | — | anchor **(37, 41)**, arm (39, 36) | `#3D4C7A`, hand `#F7D3AE` | rest **+20°** |
| 6 | `head` | Circle | 23 | (28, 25) | `#F7D3AE` | |
| 7 | `bangs` | 3× Circle | 9 / 10 / 9 | (21, 17.5) / (28, 18.5) / (35, 17.5) | `#8A5FD6` | scalloped fringe |
| 8 | lash lines ×2 | Capsule | 6×1.5 | (23, 23.5) / (33, 23.5) | `#262A33` | rotated −6° / +6° |
| 9 | `eyes` ×2 | Ellipse | 6.5×8.5 | (23, 27) / (33, 27) | `#4A90D9` | THE feature |
| 9a | `glints` ×2 | Circle | 2.2 | (21.8, 24.8) / (31.8, 24.8) | `#FFFFFF` | never drop below full opacity |
| 10 | blush ×2 | Circle | 3.5 | (18.5, 31) / (37.5, 31) | `#F2A7B8` @45% | |
| 11 | mouth | Capsule | 3×2 | (28, 33) | `#D96A6A` | |
| 12 | `ahoge` | Path (27,11)→quadCurve(30,1) ctrl (24,3), 2.5pt round stroke | — | anchor **(27, 11)** | `#8A5FD6` | the antenna |

**Palette.** Hair `#8A5FD6`; iris `#4A90D9`; skin `#F7D3AE`; blazer `#3D4C7A`; bow
`#E8536B`; gold `#F2B441`. The white eye glints are what make the eyes read at 44pt
on any wallpaper — keep them at full opacity always.

**Silhouette.** Twin tails flaring past both edges of the box plus a question-mark
antenna on top: three hair spikes at ten, twelve, and two o'clock. The only cast
member breaking the box's left *and* right edges.

### focusStart — "Ganbatte! fist pump" (1.8s)

```
0.00→0.32  root      offset 48→0               .spring(0.32, 0.55)
0.08→0.42  tails     rotation rest∓12°→rest    .spring(0.4, 0.55)    trail the rise, flip up late
0.10→0.45  ahoge     rotation +20°→0           .spring(0.35, 0.5)
0.45→0.55  fistArm   rotation +20°→+45°        .easeInOut            wind-up
0.55→0.68  fistArm   rotation +45°→-115°→-100° .bouncy               PUMP, overshoots
0.55→0.68  root      offset 0→-3→0             .spring(0.3, 0.55)    body pops with it
0.62→0.80  ahoge     rotation 0→-25°→0         .spring(0.35, 0.45)   antenna whips
0.70→0.90  glints    scale 1→1.6→1             .easeInOut            eyes sparkle
0.90→1.35  HOLD fist up
1.35→1.50  fistArm   rotation -100°→+20°       .easeInOut
1.50→1.58  root      offset 0→-2               .easeOut
1.58→1.80  root      offset -2→48              .easeInOut
```

### breakStart — "Happy sway" (2.2s)

```
0.00→0.32  root      offset 48→0               .spring(0.32, 0.55)
0.45→0.60  eyes      scale.y 1→0.15            .easeOut              closed happy arcs; glints scale with them
0.45→0.60  blush     opacity 0.45→0.8          .easeOut
0.60→1.60  root      rotation 0→-6°→+6°→-6°→0  .easeInOut (0.25s legs)  metronome sway, anchor (28,42)
0.67→1.67  tails     counter-swing ±10°, 0.07s lag    .spring(0.45, 0.5)
0.67→1.67  ahoge     counter-swing ±14°, 0.09s lag    .spring(0.4, 0.45)
1.60→1.75  eyes      scale.y 0.15→1            .easeInOut
1.75→1.90  HOLD
1.90→1.98  root      offset 0→-2               .easeOut
1.98→2.20  root      offset -2→48              .easeInOut
```

### longBreak — "Idol twirl" (2.6s)

Extra shapes: four sparkle Circles 2pt `#FFF3B0`, opacity 0 at rest, at (10,8),
(46,6), (14,2), (44,16).

```
0.00→0.32  root      offset 48→0               .spring(0.32, 0.55)
0.45→0.55  root      scale.y 1→0.88, offset 0→+3      .easeInOut     crouch
0.55→0.70  root      scale.y 0.88→1.04, offset +3→-10 .easeOut       leap
0.55→1.15  root      rotation3D(y) 0→360°, axis x=28  .easeInOut     the twirl
0.62→1.20  tails     rotation rest∓18°         .easeOut              centrifugal flare
0.85→1.15  root      offset -10→0              .easeInOut            land during final quarter
1.15→1.28  root      scale.y 1.04→0.92→1       .spring(0.3, 0.55)    landing squash
1.15→1.45  tails     rotation → rest           .spring(0.4, 0.5)
1.15→1.40  ahoge     rotation +30°→0           .spring(0.35, 0.45)
1.30→1.85  sparkles  each opacity 0→1→0, scale 0.5→1.3, 0.12s stagger  .easeOut
1.35→1.50  glints    scale 1→1.7→1.2           .easeOut              mega-sparkle, holds enlarged
1.85→2.25  HOLD; one last offset 0→-2→0 bounce at 2.0  .spring(0.3, 0.5)
2.25→2.33  root      offset 0→-2               .easeOut
2.33→2.60  root      offset -2→48              .easeInOut
```

---

## 5. Army General

**Guardrails honoured:** no insignia, no national symbols, no rank iconography.
Identity comes entirely from cap, sunglasses, moustache, and abstract gold circles.
The prop is a swagger baton, not a weapon.

### Construction (back → front)

| # | Part | Primitive | Size | Centre | Fill | Notes |
|---|---|---|---|---|---|---|
| 1 | `commandArm` (group) | — | — | anchor **(41, 40)** | — | rest rotation **+15°** |
| 1a | arm | Capsule | 5×11 | (41, 35) | `#5C5D40` | |
| 1b | hand | Circle | 4 | (41, 29.5) | `#F0C29B` | |
| 1c | baton | Capsule | 2.5×12 | (41, 24) | `#8A5A33` | gold tip Circle 2 `#D9A441` at (41, 18.5) |
| 2 | `body` | RoundedRect r6 | 26×16 | (28, 45) | `#5C5D40` | olive drab |
| 3 | shoulder boards ×2 | Capsule | 8×3 | (15, 38) / (41, 38) | `#D9A441` | rotated −20° / +20°; plain gold, nothing on them |
| 4 | `medals` ×3 | Circle | 3 each | (21, 39.5) / (26, 40.5) / (31, 39.5) | `#D9A441` | plain discs, each on a 3×1.5 `#C0392B` ribbon. Abstract only |
| 5 | ears ×2 | Circle | 4 | (16.5, 27) / (39.5, 27) | `#F0C29B` | |
| 6 | `head` | Circle | 22 | (28, 26) | `#F0C29B` | |
| 7 | jowl shade | Ellipse | 14×5 | (28, 35) @20% | `#C99B72` | one flat shading shape, max |
| 8 | `moustache` | 2× Capsule | 9×4 each | (24, 32.5) +12° / (32, 32.5) −12° | `#DAD5C6` | anchor **(28, 31.5)**; walrus-grade |
| 9 | `shoutMouth` | Ellipse | 5×4 | (28, 36.5) | `#7A3B3B` | opacity 0 at rest |
| 10 | `sunglasses` | 2× RoundedRect r2.5 9×6.5 + bridge Capsule 4×1.5 | — | (23, 26) / (33, 26), bridge (28, 25) | `#23262B` | oversized aviator |
| 11 | `cap` (group) | — | — | anchor **(28, 16)** | — | |
| 11a | crown | Ellipse | 28×12 | (28, 12) | `#6E6F4E` | comically tall and wide |
| 11b | band | Rect | 26×4 | (28, 18) | `#4A4B35` | |
| 11c | band button | Circle | 3 | (28, 18) | `#D9A441` | one plain gold dot — all the cap gets |
| 11d | visor | Capsule | 22×5 | (28, 21.5) | `#2F3028` | |

**Palette.** Olive `#5C5D40` / cap `#6E6F4E`; skin `#F0C29B`; moustache `#DAD5C6`;
gold `#D9A441`; ribbon `#C0392B`; sunglasses `#23262B`. Olives go muddy on dark
wallpapers, so the gold carries the read there — keep every gold element outlined so
it doesn't bloom on light ones.

**Silhouette.** A too-tall cap over two big rectangular lenses over an even bigger
moustache: three stacked horizontal masses of decreasing altitude and increasing
width.

### focusStart — "BACK TO WORK, SOLDIER!" (1.8s)

```
0.00→0.32  root        offset 48→0             .spring(0.32, 0.75)   rigid, no-nonsense
0.40→0.50  root        scale 1→1.1             .easeInOut            chest inflates, anchor (28,44)
0.50→0.62  commandArm  rotation +15°→-105°→-95°   .bouncy            baton snaps to point
0.50→0.62  shoutMouth  opacity 0→1, scale 0.5→1.3→1  .easeOut        mouth flies open
0.52→0.66  moustache   scale.x 1→1.25→1        .spring(0.25, 0.5)    bristles with the shout
0.52→0.68  cap         offset 0→-2.5→0         .spring(0.3, 0.55)    cap pops and resettles
0.62→0.72  root        scale 1.1→1.02          .easeInOut
0.72→1.25  HOLD the point; shoutMouth opacity 1→0 at 1.0 over 0.15s
1.25→1.40  commandArm  rotation -95°→+15°      .easeInOut
1.40→1.48  root        offset 0→-2             .easeOut
1.48→1.70  root        offset -2→48            .easeInOut            scale 1.02→1 during drop, .smooth
```

### breakStart — "At ease" (2.0s)

```
0.00→0.32  root        offset 48→0             .spring(0.32, 0.75)
0.45→0.58  commandArm  rotation +15°→-148°→-140°  .easeOut           snap salute, baton along forearm
0.45→0.55  root        scale.y 1→1.04          .easeOut              stands extra tall
0.58→0.90  HOLD salute
0.90→1.15  commandArm  rotation -140°→+15°     .easeInOut            arm floats down slowly
0.90→1.15  root        scale.y 1.04→0.96→1     .spring(0.4, 0.6)     the exhale
1.10→1.30  moustache   rotation 0→+3°→0        .spring(0.4, 0.5)     one contented settle
1.30→1.70  HOLD, relaxed
1.70→1.78  root        offset 0→-2             .easeOut
1.78→2.00  root        offset -2→48            .easeInOut
```

### longBreak — "Medal ceremony (self-awarded)" (2.6s)

```
0.00→0.32  root        offset 48→0             .spring(0.32, 0.75)
0.45→0.60  root        scale 1→1.12→1.06       .bouncy               max chest puff, medals ride into view
0.60→0.72  medal 1     scale 1→1.6→1           .spring(0.25, 0.5)
0.74→0.86  medal 2     scale 1→1.6→1           .spring(0.25, 0.5)
0.88→1.00  medal 3     scale 1→1.6→1           .spring(0.25, 0.5)
           each ping pairs with opacity 1→0.6→1 over 0.1s
1.05→1.75  root        offset 0→-2→0 ×2        .spring(0.35, 0.6)    rocking on his heels
1.10→1.80  moustache   rotation -4°→+4°→-4°→0  .easeInOut            waggle of deep self-satisfaction
1.75→2.05  HOLD; commandArm +15°→-30°→+15° at 1.8  .easeInOut        modest baton twirl
2.05→2.20  root        scale 1.06→1            .smooth
2.20→2.28  root        offset 0→-2             .easeOut
2.28→2.55  root        offset -2→48            .easeInOut
```

---

## Implementation notes

- Build each character as one `ZStack` in a 56×44 frame. Named parts are sub-stacks
  with their own `rotationEffect(_:anchor:)`; convert the box-coordinate anchors above
  to `UnitPoint` of the *part's own* frame.
- Drive timelines with `KeyframeAnimator`; each row above maps to one `KeyframeTrack`
  entry.
- Mask the character to the region beyond the pill's edge — the pill is translucent,
  so plain z-ordering would ghost the hidden body through the glass.
- All effect shapes (smoke, sparkles) are pre-placed at opacity 0, never inserted or
  removed mid-animation, so the view tree stays stable.
