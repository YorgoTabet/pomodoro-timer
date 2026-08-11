# Anime girl — adult proportions, idol outfit, perch-and-wave break

**Date:** 2026-08-11

The anime girl is re-authored from a schoolgirl chibi to an adult figure in
vocaloid-*inspired* stagewear: white crop top with a teal tie, blue pleated mini
skirt, detached navy forearm sleeves, over-knee boots with teal trim, long twin
tails from high roots. Inspired-by, not a copy — lavender hair, no headset, our
own face. The silhouette is natural and understated; the taper is anatomy, not
emphasis, and that restraint is deliberate.

The `breakStart` performance is replaced: instead of swaying behind the pill she
pops up in front of it, sits on its top edge, and waves.

## Why the first pass still read as a child

Worth recording, because the obvious lever was the wrong one. Head *count* was
never the problem — the chibi draft was already 5.53 heads, which is adult range.
Five other ratios were doing the work, and one dominated:

| ratio                  | chibi | now  | adult F | child |
|------------------------|-------|------|---------|-------|
| shoulders / head width | 1.03  | 1.70 | ~1.6    | ~1.1  |
| waist / shoulders      | 0.97  | 0.67 | ~0.70   | ~0.95 |
| leg fraction of height | 0.42  | 0.48 | ~0.47   | ~0.40 |
| face width : height    | 0.81  | 0.74 | ~0.72   | ~0.85 |
| eye height / face      | 0.21  | 0.16 | ~0.13   | ~0.22 |
| heads tall             | 5.53  | 5.85 | 6–7     | 4–5   |

Shoulders the same width as the head is a toddler's proportion, and no amount of
head-shrinking fixes it. A sixth, unmeasured factor mattered as much: the twin
tails ballooned the hair silhouette to 1.56 shoulder-widths, and an oversized
hair mass reads as an oversized head. They are ropes now, at 1.28.

Vertical landmarks, canvas units: skull 26.5, eye line 44, chin 62.8, shoulder
76, bust 93, waist 119, hip break 136, boot top 170, sole 239.

## How the sit works

There is no knee joint, so sitting is sold by placement and secondary motion:

1. `comesForward(.breakStart)` — drawn in front of the pill, unmasked.
2. The emergence track holds at **23** instead of 0. Through the top edge's
   mapping (`emergence/200 × (displayHeight + pillHeight)`) that is ≈45 design
   units of drop, putting her seat on the occluding edge (y=196) with the boots
   dangling over the glass.
3. A small `figureScaleY` squash absorbs the sit-down, and the legs kick
   alternately from the hip with uneven timing so it reads as idle swinging.

The 23 is calibrated against the nominal 46pt pill; re-derive it if the pill's
height changes materially.

## Three defects worth remembering

- **Elbow angles compound.** `armR_fore` is relative to `armR`, so a -155°
  shoulder with a -54° elbow totals -209° and folds the fist back *over* the
  head — the pose that read as a head-scratch. The elbow is -20° now, which
  keeps the fist at x≈136, and the bounce toward -4° straightens the arm, which
  is what actually drives the fist upward.
- **Arms draw behind the head.** Any gesture aimed "beside the head" has to
  clear the skull silhouette, and the clearance changes whenever the head is
  resized. Re-aim every raised-arm pose after a head change.
- **Sparkles orbit, and cubic overshoot widens the orbit.** The twirl rotates
  the sparkle group 90° about (100, 80); the rotation track enters its moving
  hold fast enough that the cubic tangent slings it past 90°. One sparkle's arc
  swept across the skirt mid-fade and read as a glitch. All three now start
  upper-left/right so the whole swept path — overshoot included — stays off the
  body. Check the swept path of an orbiting prop, not just its endpoints.
- **A 3pt stroke on a 4-unit shape is all stroke.** The side locks rendered as
  solid black bars down her cheeks. Widened to ~6.6 units at stroke 2.2.

## Contracts that did not change

- Occluding edge at y=196; sole at 239; canvas 200×260.
- The `Part` enum is untouched, so every existing keyframe track still drives a
  joint.
- Expression layer names (`mouth*`, `brows*`, `eyeWhite*`, `iris*`, `pupil*`,
  `hi*`, `lash*`, `closedEyesHappy`, `sparkle*`) are matched by string in
  `AnimeGirlPose.opacity(of:)`.
- Two-segment limbs: parent cut flat past the pivot, child's rounded cap centred
  on it — elbows and both tail joints.
