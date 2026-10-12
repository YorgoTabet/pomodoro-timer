# Nel

Nel follows the user's existing Codex dot design: mint hair, brown eyes, an
ivory ram skull with curled segmented horns, sage tunic with ivory trim,
dark green shorts and stockings, and cuffed green boots.

## Original artwork and performances

`Sources/PomodoroUI/Resources/nel-original.png` is the preserved original Codex
sprite sheet: 1536 × 2288 pixels, 73 populated 192 × 208 cells. SHA-256:
`6b51ff242842d09c834acb789de0b8f08195e30f4be99e363e282f2c6bb1b565`.
It was copied from the existing Nel project's saved original, without changing
the active pet or downloading it again. The runtime crops and caches frames once.

| Timer cue | Performance | Original atlas rows (zero-based) |
| --- | --- | --- |
| Back to focus | Thoughtful expression, then a nod | 7, 8 |
| Break time | Friendly wave, then a relaxed blink | 3, 0 |
| Long break | Two happy hops and a wave | 4, 3 |

Each lasts 3.3 seconds, including a 0.45-second entrance and exit. Sequencing is
authored for the timer; the artwork remains original. Shared stage geometry,
masking and lifecycle handle placement and companion yielding. Reduce Motion
shows a static original frame with a fade. Existing rigs and timelines are unchanged.

RigStudio can scrub Nel's sprite performances. Joint/pivot controls apply to the
vector characters; a raster sheet has no editable skeleton.

## Hanging poses

`Sources/PomodoroUI/Resources/Companions/nel-atlas.png` contains a bottom hang,
top peek and side climb, plus resting-expression frames. The right climb mirrors
the left. These are newly authored adaptations, rather than original Codex pixels.
Built-in image generation used the original first-look image and sheet as identity
references and Boa's atlas as the pose/layout reference. A refinement restored
the bottom hang's horns and adjusted the peek. Both prompts are preserved in
[`companion-prompts/nel.txt`](companion-prompts/nel.txt).

The adjacent kit manifest defines crops, hand contacts and optical sizes. Each
open pose has approximately 1,130 alpha-weighted square logical points, matching
the roster. Generated RGBA pixels are preserved; cropping and logical scales
provide runtime frames. The shared renderer supplies Idle/Lively, breathing,
blinking, sway, safe-edge relocation and click passthrough in both orientations
and compact mode. No Nel-specific dock or motion controller is added.

## Theme

| Focus | Short break | Long break |
| --- | --- | --- |
| Mint `#52B8A8` | Sage `#799D6E` | Warm ivory `#DFCDA4` |

Choose **Nel** in Appearance or **Match character**. The shared theme system
derives highlights and contrasting ink, applies surface controls and propagates
widget snapshots. Selecting a character does not automatically change the theme.
Off and Original remain the defaults.

## Review

`swift test` checks original sprite coverage, transparency, rendering, distinct
cues, full retreat, palette coverage, all-kit geometry, Lively cancellation and
native dragging. `Scripts/build.sh --no-install` bundles both atlases and verifies
the signed application.

Open a native board with production views and scratch fixtures:

```sh
POMODORO_README_SCENE=nel swift test --filter DocumentationPreviewTests.nativeReview
```

Open the real panel and Settings with scratch storage:

```sh
POMODORO_PILL_LAYOUT_REVIEW=1 POMODORO_REVIEW_CHARACTER=nel \
  swift test --filter PillOrientationTests.nativeReview
```

These reviews close after ten minutes and leave production timer, widget and
character preferences untouched. User visual review precedes a pull request.

Nel is fan art of *Bleach* by Tite Kubo, unaffiliated with the rights holders
and excluded from this project's license as noted in the README.
