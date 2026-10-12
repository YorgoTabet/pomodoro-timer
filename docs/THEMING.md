# Appearance and customization

Open **Settings → Appearance**. Changes apply live and are stored locally in the
app's existing UserDefaults. Original / System is the default for existing and new
installs. No assets, services, packages, or network requests are needed.

## Color and surface map

| Surface | Theme-controlled pieces | Adaptive pieces |
| --- | --- | --- |
| Floating timer, horizontal/vertical, expanded/compact | Phase progress gradient, phase glyph and caption, primary Start/Pause button and shadow, glass color wash | Countdown, muted controls, ring track, control wells and borders |
| Floating bar context menu | Follows the pill's resolved System / Light / Dark appearance | Native menu rows, selection highlight and template icons |
| Menu header | Dial, phase label, bloom, cycle pips, background wash | Countdown, paused label, daily count |
| Settings | Cycle preview, duration dots and selected presets, chime preview icons, music icons, accent controls, backdrop | Body text, captions, dividers, native field and control surfaces |
| Appearance tab | Live timer preview, palette swatches and selection, native accent controls | Card borders, labels, descriptions |
| Statistics | Today/week/streak labels and tile washes, chart gradient, empty-state icon, background wash | Values, captions, axes and grid, destructive Reset action |
| Small and medium widgets | Dial, phase label, bloom, cycle pips, Start/Pause glyph and background wash | Countdown, secondary controls, labels and native glass |
| Menu bar item and native menu | System appearance | Template symbol, countdown and menu rows remain system-managed for wallpaper contrast |
| Notifications and Control Center | System appearance | OS owns presentation; phase labels and commands are unchanged |
| Mini companions and full performances | Matching presets borrow their art palettes | Artwork, proportions, poses and timing retain the character's original colors |
| App icon and RigStudio | Existing artwork | Static icon; RigStudio remains an independent animation workbench |

“Adaptive” text, tracks, dividers and wells use native semantic primary/secondary
colors. System / Light / Dark controls the app's content appearance; native macOS
chrome and widget tint modes remain subject to system rendering.

## Presets and editing

| Palette | Focus / short break / long break inspiration |
| --- | --- |
| Original | Existing coral, mint, blue |
| Samurai | Vermilion armor, gold crest, indigo steel |
| Ninja | Cool indigo, jade sash, silver smoke |
| Rabbit Suit Guy | Pink ears, cream suit, cocoa outlines |
| Power | Scarlet horns, amber eyes, navy jacket |
| The General | Olive coat, brass medals, slate lens |
| Boa Hancock | Crimson dress, gold jewelry, royal blue lining |
| Nel | `#52B8A8` | `#799D6E` | `#DFCDA4` | Mint hair, sage tunic, ivory skull and trim |

Character selection and theme selection are independent. **Match character** is an
explicit shortcut; choosing a palette never changes the character. Hover a palette
for its color description. Select a preview phase to inspect all three colors.

**Customize colors** exposes an opaque sRGB picker for each phase. Highlights are
derived so gradients remain coordinated. Surfaces can follow the current phase or
use one chosen tint; a 0–100% strength slider adjusts all background washes and
blooms. Native material, typography, layout, hit areas and animation speeds stay
consistent. Arbitrary text, per-button and artwork colors are intentionally omitted
to preserve readability and a coherent minimal UI.

Editing a phase or surface color starts Custom from the currently visible palette.
Custom colors survive switching to another preset and return when Custom is chosen.
Appearance and tint strength are independent of palette selection. Reset restores
Original / System / full tint and clears the saved custom palette.

## Implementation and compatibility

- `PomodoroCore/Appearance.swift` owns portable color values, palettes, presets,
  contrast handling and versioned configuration. Invalid or future configuration
  falls back to Original; unknown individual preset/appearance names fall back
  safely. Strength is bounded and colors cannot contain opacity or invalid RGB.
- `PomodoroSettings.theme` observes and stores a single JSON preference. Its separate
  appearance callback avoids applying timer-duration or music changes to a live
  session. Themes never change a paused countdown, deadline, phase or cycle count.
- `PomodoroUI/Theme.swift` resolves semantic tokens from the SwiftUI environment.
  `ThemedView` observes settings at the four app hosting boundaries. Views do not
  reach into global preferences, so previews and widgets can use explicit themes.
  For native windows, System resolves from `NSApplication.effectiveAppearance`,
  independent of a window's last override. The native window preference and the
  resolved SwiftUI scheme then agree, without forcing a previous window appearance
  back into System. An application-appearance observer updates already-open System windows.
  Widgets and offscreen previews use their host environment without changing windows.
- Shared timer snapshots carry optional appearance data. Legacy snapshots still
  decode; a malformed theme does not discard otherwise valid timer state. Theme
  changes participate in widget change detection, while ordinary countdown ticks
  still avoid per-second writes/reloads. Writes are ordered so rapid picker edits
  cannot leave an older theme in the file. WidgetKit controls when updates appear;
  macOS may also apply its own widget tint.
- Text on opaque accent buttons chooses black or white by contrast. Small colored
  labels adjust hue luminance for light/dark neutral surfaces. Custom gradients
  preserve readable ink at both stops. Decorative progress colors retain the exact
  user's choice. This is not a claim about every wallpaper behind translucent glass.
- Appearance edits preserve the timer, compact policy and original character
  performances. Layout and input behavior are described in
  [the floating bar guide](FLOATING-BAR.md); companion rendering is described in
  [the kit guide](COMPANIONS.md). No additional macOS permissions are requested.

The nearest sRGB byte represents the original theme's decimal color components;
the difference is below one RGB step.

Controller and bridge tests inject temporary directories. This removes the previous
test fixture's assumption that a fabricated App Group URL is writable and keeps
tests away from the user's widget snapshot. The app and widget still use the same
production App Group lookup, fallback and entitlements. A passing file-I/O test does
not prove system widget installation or App Group access on another Mac.
