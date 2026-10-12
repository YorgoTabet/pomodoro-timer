# README feature images

Nel's `nel-companion-dark.png` and `nel-companion-light.png` show a native review
board using the production timer preview, hanging renderer and original sprite
performance stage. `nel-lively.gif` captures one relocation; `nel-longBreak.gif`
captures the original-art hop and wave. The board is a documentation fixture,
not an additional app screen. It uses scratch state and contains no session data.
Capture it with `POMODORO_README_SCENE=nel` and the existing capture host below.

The original hero and phase-change GIFs remain in `docs/images`. The `qol-*`
images show the new features using native app views, with scratch preferences
and timer storage. They do not contain the user's desktop, timer session or widget
data. The bar captures use a neutral canvas so glass stays readable on GitHub.

| File | Source |
| --- | --- |
| `qol-horizontal.png`, `qol-vertical.png` | Production `FloatingBar`, including its actual controls and hanging renderer |
| `qol-context-menu.png` | The floating panel's native AppKit context menu |
| `qol-appearance.png`, `qol-custom-colors.png` | Native `AppearanceSettingsView`, including segmented controls and color wells |
| `qol-companions.png`, `qol-lively.gif` | A documentation gallery using `ThemeTimerPreview` and the shared `HangingCompanion` renderer for all six kits |

The gallery is a preview layout, not an additional app screen. The Lively GIF
shows one real relocation, replayed as a short loop with longer holds on its first
and last frames. The app waits 26 seconds between completed relocations. The still
image offers an alternative to the animated preview.

## Refreshing captures

Build tests once with `swift test`, then open the capture host for one scene:

```sh
POMODORO_README_SCENE=bar swift test --filter DocumentationPreviewTests.nativeReview
POMODORO_README_SCENE=appearance swift test --filter DocumentationPreviewTests.nativeReview
POMODORO_README_SCENE=companions swift test --filter DocumentationPreviewTests.nativeReview
```

Run one command at a time. Capture the native window with your normal screenshot
tool. In the bar scene, use the real context menu to switch orientation; choose
Hide Floating Bar to close the capture host. Appearance and companion scenes close
with their window's close button. All hosts time out after ten minutes. These
opt-in helpers live in the test target and are absent from the production app.

For the companion animation, select Lively and capture numbered PNG frames from
the native window during the initial transition. Store ascending filenames in a
temporary directory, with `times.json` containing each frame's capture time in
seconds relative to the start. Then encode them with:

```sh
swift Scripts/make-doc-gif.swift <frames-directory> docs/images/qol-lively.gif
```

The encoder downsamples Retina captures to at most 1080 pixels across and keeps
the measured frame cadence, with bookend holds for readability. Frame recordings
and temporary capture applications belong in ignored build output, not the repository.

Inspect the final PNGs and the GIF before committing. SwiftUI `ImageRenderer`
cannot reproduce the AppKit-backed controls or native companion views; use native
window captures for these images.
