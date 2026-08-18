# Pomodoro

A menu bar pomodoro timer for macOS, with a floating glass bar and a small cast of
characters who turn up when a session ends.

No Dock icon, no window to manage. The countdown lives in the menu bar; a floating
pill sits wherever you drop it and can shrink to a ring while you work.

## What it does

- **The cycle.** Focus, short break, long break, with the long break arriving every
  *n* pomodoros. Every duration and the cycle length are adjustable (1–240 minutes).
  Breaks and the next focus session can each auto-start, independently.
- **The menu bar.** A live countdown with start/pause, skip and reset, plus keyboard
  equivalents.
- **The floating bar.** A draggable pill showing a progress ring, the countdown and
  the phase, with play/pause always available and reset and skip on hover. It can
  collapse to a compact form while a timer runs and expand again when you approach
  it or when the phase changes.
- **Characters.** A samurai, a ninja, a rabbit-suit guy, an anime girl and a general.
  One pops out from behind the bar when the phase changes, does a short animated
  move, and leaves. Purely decorative — the notification and chime do the real work.
- **Music.** Pauses Music.app or Spotify when focus ends and resumes when it starts
  again. It never guesses: playback is only started when a player can be seen sitting
  paused, or when this app is the one that paused it.
- **Alerts.** A notification banner and a system chime at each transition, with
  separate sounds for focus and break, and a volume control.
- **A desktop widget.** Small and medium sizes, with start/pause and skip
  buttons wired through App Intents.
- **Stats.** Completed pomodoros and focus time per day, kept in a local JSON file.
  Nothing leaves your machine.

## Requirements

- macOS 14 or later
- A Swift 6 toolchain (Xcode 16 or later)

## Build and install

```bash
./Scripts/build.sh
```

This builds the app and the widget in release mode, assembles them into
`Pomodoro.app`, generates the icon, signs the bundle, and copies it to
`/Applications` (or `~/Applications` if the first is not writable).

To build the bundle without installing it:

```bash
./Scripts/build.sh --no-install
```

### A note on signing

The build script looks for a real code signing certificate and falls back to an
ad-hoc signature if it can't find one. Ad-hoc builds run fine, but macOS ties the
permissions you grant — Accessibility, Notifications, Automation — to the app's
signature, and an ad-hoc signature changes on every build. The practical effect is
that media keys, notifications and Music control silently stop working after each
rebuild until you re-grant them.

If you have a certificate, point the script at it:

```bash
CODESIGN_IDENTITY="Apple Development: you@example.com (XXXXXXXXXX)" ./Scripts/build.sh
```

The app is deliberately not sandboxed. Controlling Music and Spotify over AppleScript
and posting media keys are both blocked inside the sandbox.

## Run from source

```bash
swift run Pomodoro
```

Useful for iterating on the UI. Notification banners are disabled outside a real
`.app` bundle — the API traps otherwise — so you get the chime and nothing else.

## Tests

```bash
swift test
```

## RigStudio

The characters are drawn from vector paths and animated by a small joint rig. Judging
that by reading keyframes doesn't work, so the animation gets its own workbench, built
as a separate executable that never ships inside the app:

```bash
swift run RigStudio
```

It also runs headless:

| Command | What it does |
| --- | --- |
| `swift run RigStudio --filmstrip <dir>` | Renders a contact sheet per performance, so a move can be inspected frame by frame without a display |
| `swift run RigStudio --proportions <dir>` | Sweeps each of the anime girl's proportion dials across its range, so a value can be judged by eye instead of from its number |
| `swift run RigStudio --audit` | Reports joints a performance never moves, and joints that sit mathematically still for over 0.9s mid-performance — a held pose is fine, a frozen one reads as a paused video |

## Layout

| Target | What lives there |
| --- | --- |
| `PomodoroCore` | The cycle rules, settings, stats, and the shared store the widget reads. No AppKit, no timers, no I/O beyond its own files |
| `PomodoroUI` | SwiftUI shared by the app and the widget, so the floating bar and the desktop widget can't drift apart visually. Character art, the rig and the performances live here |
| `Pomodoro` | The app itself: menu bar, floating bar, settings, notifications, music control |
| `PomodoroWidget` | The widget extension. Built as an ordinary executable and hand-assembled into the bundle, since SwiftPM has no notion of an app extension |
| `RigStudio` | The animation workbench described above |

Design notes and specs are in [`docs/`](docs/).

## License

MIT — see [LICENSE](LICENSE).
