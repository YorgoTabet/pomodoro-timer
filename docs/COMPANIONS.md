# Hanging companion kits

All seven characters have hanging kits: Samurai, Ninja, Rabbit Suit Guy,
Power, The General, Boa Hancock, and Nel. Each has its own bottom hang, top peek,
side climb, and matching resting-expression frames. Right climbs are mirrored.
Off remains the default, and the original phase-change rigs and timelines are
unchanged. Persisted `calm` / `stroll` values still display as Idle / Lively.

## Adding artwork

The runtime is shared; a character supplies artwork and contact metadata rather
than its own placement logic or animation controller.

1. Author three transparent poses: bottom hang, top peek, and left climb. Right
   climb mirrors the left artwork automatically. Keep important asymmetric marks
   away from the climb pose if mirroring would be inappropriate.
2. Add a matching blink image for each pose. Only the eyelids should change;
   silhouettes, grips, costume, and pixel registration should remain identical.
3. Store all six images in a PNG atlas. Leave transparent padding around cells.
   The atlas layout is arbitrary: explicit crop rectangles describe each frame.
4. Add `<character-rawValue>-kit.json` and its atlas to
   `Sources/PomodoroUI/Resources/Companions`. The catalog discovers kits by the
   existing character identifier; no renderer switch or motion code is needed.
5. Inspect all edges at actual size, both appearances, screen corners, compact
   and expanded modes. Check hand contact and that controls stay unobstructed.

Use `hancock-kit.json` as the template. Schema version 1 accepts these fields:

| Field | Meaning |
| --- | --- |
| `atlas` | PNG basename, without extension; unique across the resource bundle |
| `edge` | `top`, `bottom`, or `leading` |
| `open`, `blink` | `[x, y, width, height]` in atlas pixels, measured from top left |
| `height` | Cropped frame height in logical points, including transparent padding |
| `grip` | `[x, y]` contact anchor, normalized within the crop |
| `sway` | Maximum resting rotation in degrees, 0–2 |

For top and bottom use the midpoint of the two hand contacts. For climbing use
the upper hand. Author the remaining hand and foot to follow a 46-point-high
capsule's curved end. Padding and fingers should extend slightly across the
contact line. The renderer occludes the interior of the pill while leaving a
2-point lip for grips. This mask also works during relocation and keeps timer
controls clear.

Character, mode, and placement edits use the presentation-only `onCompanionChange` callback;
they do not call the timer's duration-settings callback or reset a paused session.

Balance **visible alpha area**, not just frame dimensions. Each character's
three poses have similar visible area (within 15%). The roster targets about
1,130 square logical points of alpha-weighted artwork per pose. Top peeks have
larger heads and shorter frames than full-body hangs. Height includes tall ears,
horns, and helmet crests; do not force those shapes into identical boxes. The
artwork test checks balance within each kit and across the roster, transparency,
and that the resting-expression frames differ.

The General keeps his opaque aviators on: his alternate resting frame changes
the lens glint slightly rather than exposing eyes for a blink. Rabbit's sewn
mascot eyes stay delighted while the human occupant blinks.

## Shared behavior

Idle keeps the preferred edge and position with breathing, blinking, and tiny
sway around the grip. The position slider follows the long flat rim: top/bottom
in horizontal orientation, left/right in vertical orientation. Short ends center
the character on the curved cap. The Settings preview follows the selected bar
orientation, and all seven kits stay upright. Bounds correction first slides that
contact, then tries the opposite edge, then the remaining edges. It never clamps the body independently of its
grip. Negative display coordinates and compact widths are supported.

Lively demonstrates a relocation after 0.8 seconds on selection, then rests
26 seconds between relocations. It anticipates, tucks behind the capsule,
reappears at the next safe edge, and settles. The transition uses native layer
translation, rotation, squash, and occlusion; it is not a skeletal hand-over-hand
traversal along the entire pill. Only three rest poses are required per kit.

Reduce Motion disables resting movement, blinking, and relocations. Hidden bars,
sleep, and phase-change performances use the existing companion lifecycle.
Unmounting cancels relocation work and layer playback. Native hit testing always
returns nil. There is no per-frame SwiftUI timer or repeated rig rasterization.

## Packaging and provenance

SwiftPM processes the resources into `Pomodoro_PomodoroUI.bundle`.
`Scripts/build.sh` copies that bundle into the app before signing; it preserves
the script's existing install/run/signing behavior. Runtime loads bundled files
only, with no service or network dependency.

`hancock-atlas.png` was created with the built-in image-generation tool from the
approved Boa hanging previews. The production prompt requested a transparent
3-column × 2-row atlas: bottom hang, face/hands top peek, side climb; eyes open
above, pixel-aligned blink below; consistent adult character, black hair, gold
earrings, red/gold gown and blue/ivory cape; crisp illustration; no pill, labels,
background, or extra objects. Crop rectangles, optical sizes, and grip anchors
are authored in the adjacent manifest. Full-size performance artwork is separate.

The other five atlases were created with the same built-in tool using each
character's original performance artwork as the identity/costume reference and
Boa's atlas as the pose/style reference. Their complete production prompts are
saved in [`companion-prompts`](companion-prompts). Atlas files and per-character
crop/grip/scale manifests are bundled in `Sources/PomodoroUI/Resources/Companions`.

Nel's kit follows her original Codex dot design; her full-size performances reuse
the original sprite sheet. See [Nel](NEL.md) for provenance, sequencing and theme.

## Verification

`swift test --filter HangingCompanion` checks all seven kits, optical balance,
edge fallback/contact, immediate Lively relocation, cancellation, character
replacement during a tuck, Reduce Motion, and native click passthrough. Mounted
native drag routing is also checked for all seven. Existing suites cover compact geometry,
performance yielding, and appearance propagation. `swift test` runs them all.

For a temporary native art review, run:

```sh
POMODORO_HANGING_REVIEW=1 swift test --filter HangingCompanionTests.nativeReview
```

The isolated review window has roster buttons, Idle/Lively and Light/Dark controls, closes
after ten minutes (or with its close button), and uses no production
preferences. Production review remains necessary: an art review window does not
prove the real floating panel's behavior.

## Production artwork prompt

Built-in image generation, transparent background enabled, with the three approved
Boa pose boards supplied as references:

> Use case: stylized-concept. Asset type: production transparent sprite atlas for a macOS hanging companion. Use the three references as approved exact visual design directions: miniature lower hang, face/hands top peek, compact side climb. Create ONE coherent Boa Hancock sprite atlas: landscape 1536x1024, exactly THREE equal columns and TWO equal rows, each cell 512x512, no borders, no labels, no timer, no background objects. Real transparent alpha background. TOP ROW: eyes-open rest sprites. BOTTOM ROW: identical copies of the corresponding top-row sprite with ONLY eyelids closed for a blink. Keep every other pixel/pose/size/placement identical between rows. Col1: compact fullbody hanging with both arms raised, two curled grips aligned on a horizontal invisible rim near cell y55, long black hair, gold earrings, closed red long-sleeve gown gold/green details, blue ivory cape, feet together and tucked. Entire silhouette within x145..370 y45..465. Col2: face with hair and gold earrings plus TWO curled gripping hands only, as top-peek reference. No shoulders, torso or legs. Her chin and both hands rest on invisible horizontal rim near cell y400; silhouette within x90..430 y120..415. Col3: side climber facing RIGHT, upper hand grips invisible top-right rim near x370 y130, lower hand at x340 y250, knee tucked and covered gown and tiny shoe braced toward right at x350 y400. Body left of grips, narrow compact silhouette within x120..390 y50..460. All six sprites depict exactly the SAME mature adult woman, same hair shape, confident gentle expression, same face design and modest opaque red gown. Clean crisp refined anime vector illustration with restrained shading, strong dark outlines, detailed gold earrings, matching or exceeding approved reference quality. No caricature baby proportions. Crooked fingers visibly curl over imaginary rim, not fists pointed at air. All body parts fully inside each cell with ample transparent margin. Bottom-row blink sprites must be exactly same position size costume silhouette and pose as row above: only eyes changed. Background truly transparent, no checkerboard baked into pixels, no shadows or text.
