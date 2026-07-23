# Pomodoro — macOS menu bar timer with floating bar and music control

**Date:** 2026-07-23
**Status:** Approved

## Purpose

A local, self-hosted replacement for the App Store app *Pomodoro Timer – Focus & Music*.
Runs entirely on this Mac, no account, no network, no App Store.

Core promises:

1. A pomodoro timer with configurable focus and break intervals.
2. Automatically pause the user's music when a focus session ends, and resume it when
   focus resumes.
3. A floating always-on-top bar showing the countdown, plus a menu bar countdown.

4. A desktop / Notification Center widget and a Control Center control that drive
   the same timer.

## Non-goals (v1)

- iCloud / cross-device sync
- Website or app blocking
- macOS Focus-mode filter integration (requires a provisioning profile)
- Distribution to other machines, notarization, App Store submission
- Stats export

## Architecture

Two SwiftPM targets:

- **`PomodoroCore`** — pure Swift, no AppKit. The state machine, settings model, and
  stats store. Fully unit-testable, no I/O beyond `UserDefaults` and one JSON file.
- **`Pomodoro`** — the executable. AppKit + SwiftUI. Owns all platform integration:
  menu bar, floating panel, notifications, music control, login item.

Assembled by `Scripts/build.sh` into a real `.app` bundle (`LSUIElement = true`,
ad-hoc signed) and installed to `/Applications`.

### Components

| Component | Target | Responsibility | Depends on |
|---|---|---|---|
| `Phase` | Core | `focus` / `shortBreak` / `longBreak`, plus duration lookup | `Settings` |
| `PomodoroEngine` | Core | Pure transition function: given current phase + completed count + settings, what is next? | nothing |
| `Settings` | Core | `@Observable`, `UserDefaults`-backed preferences | Foundation |
| `StatsStore` | Core | Per-day completed pomodoros and focus seconds, JSON on disk | Foundation |
| `TimerController` | App | Deadline-based ticking, drives the engine, fans out phase-change events | Core |
| `MusicController` | App | Protocol + scripted (Music/Spotify) and media-key implementations | AppKit |
| `MenuBarController` | App | `NSStatusItem` countdown and menu | `TimerController` |
| `FloatingBar` | App | `NSPanel` overlay, draggable, persisted position | `TimerController` |
| `Notifier` | App | Banner + chime on transition | UserNotifications |
| `LoginItem` | App | `SMAppService.mainApp` toggle | ServiceManagement |

### State machine

```
focus --(elapsed)--> shortBreak        if (completed + 1) % N != 0
focus --(elapsed)--> longBreak         if (completed + 1) % N == 0
shortBreak --(elapsed)--> focus
longBreak  --(elapsed)--> focus
```

`completed` increments only on a *fully elapsed* focus session. Skipping a focus
session does not count it. Skipping a break is allowed and does not count.

### Timing

`TimerController` stores an absolute `Date` deadline, not a decrementing counter. A
1-second `Timer` recomputes `remaining = deadline.timeIntervalSinceNow` for display.
This makes the timer immune to tick drift, CPU throttling, and system sleep: on wake,
the remaining time is already correct, and if the deadline passed while asleep the
transition fires immediately on wake.

Pausing stores the remaining interval; resuming rebuilds the deadline from `now`.

### Music control

`MusicController` is a protocol with `pauseIfPlaying() -> Bool` and `resumeIfWePaused()`.

Two implementations, tried in order:

1. **`ScriptedMusicController`** — `NSAppleScript` against Music.app and Spotify.app.
   Only targets apps that are already running (checked via
   `NSWorkspace.runningApplications`) so it never launches a player. Knows real player
   state, so resume restores exactly what was playing.
2. **`MediaKeyController`** — posts the system `NX_KEYTYPE_PLAY` key event. Works with
   any player including browser audio. Cannot read state, so it is a blind toggle.

`ChainedMusicController` runs scripted first; the media key is used only if no scripted
player reported that it was playing. Resume only ever fires for players *we* paused,
tracked in an in-memory set that is cleared on resume.

### Event flow

```
Timer tick -> TimerController.tick()
                 |
                 +-- remaining > 0 -> notify observers (menu bar, floating bar redraw)
                 |
                 +-- remaining <= 0 -> PomodoroEngine.next(...)
                                          |
                                          +-> StatsStore.record()      (focus only)
                                          +-> MusicController.pause/resume
                                          +-> Notifier.post()
                                          +-> observers redraw
                                          +-> auto-start next phase if configured
```

Views never mutate `TimerController` state directly; they call explicit intents
(`start`, `pause`, `skip`, `reset`).

## Settings

| Key | Default |
|---|---|
| Focus minutes | 25 |
| Short break minutes | 5 |
| Long break minutes | 15 |
| Pomodoros until long break | 4 |
| Auto-start breaks | on |
| Auto-start focus after break | off |
| Notifications | on |
| Chime | on |
| Control music | on |
| Resume music when focus starts | on |
| Show floating bar | on |
| Launch at login | off |

Auto-start is two independent toggles, per the user's request that it be configurable.

## Error handling

- **Automation permission denied** — `NSAppleScript` returns an error dictionary; the
  scripted controller reports "not playing" and the chain falls through to the media
  key. The failure is logged once, never repeatedly, and never blocks the timer.
- **Notification authorization denied** — `Notifier` degrades to chime-only. The
  timer still transitions.
- **Not running from an `.app` bundle** — `UNUserNotificationCenter` traps in that
  situation, so `Notifier` checks `Bundle.main.bundleURL.pathExtension == "app"` and
  disables itself otherwise. This keeps `swift run` usable during development.
- **Stats file corrupt or unreadable** — decode failure resets to an empty store
  rather than crashing. Stats are convenience data, not source of truth.
- **`/Applications` not writable** — `build.sh` falls back to `~/Applications`.

## Testing

Unit tests cover `PomodoroCore` only, because that is where the logic lives:

- `PomodoroEngine`: the full transition table, including the long-break boundary at
  N, 2N, 3N, and the N = 1 edge case.
- `Settings`: round-trip through `UserDefaults` with a test suite name, and clamping
  of out-of-range durations.
- `StatsStore`: recording across day boundaries, week aggregation, corrupt-file
  recovery.

Platform integration (menu bar, panel, AppleScript, media keys) is verified manually
by running the built app — it is not meaningfully unit-testable without mocking all
of AppKit, which would test the mocks rather than the app.

## Known limitations

Consequences of running purely locally with no Apple Developer account:

- Ad-hoc signature. Runs indefinitely on this Mac; another Mac needs right-click →
  Open. No notarization, no App Store, no iCloud, no Focus filter.
- AppleScript control prompts once per target app for Automation permission.
- Posting media keys may require a one-time Accessibility grant on macOS 26.
- Browser audio is toggle-only; play state is unknowable.
- A session that elapses while the Mac is asleep notifies late (on wake).
- Menu bar text competes for space on notched displays.


## Addendum — widget and design pass (2026-07-23)

### Widget extension

`PomodoroWidget` is a second SwiftPM executable hand-assembled into
`Pomodoro.app/Contents/PlugIns/PomodoroWidget.appex` by `Scripts/build.sh`, since
SwiftPM has no concept of an app extension.

macOS force-sandboxes every app extension, so the extension cannot reach the app's
Application Support directory. Both processes therefore share an App Group container
(`group.com.yorgotabet.pomodoro`). This was verified to work under ad-hoc signing —
sandboxed and not — before any of it was written; without that, the whole feature
would have required a paid Apple Developer account.

Communication is two single-writer files in that container:

- `snapshot.json` — app writes, widget reads. Includes the absolute `deadline`, so
  the widget renders its own live per-second countdown via `Text(timerInterval:)`
  without the extension being woken.
- `command.json` — widget writes (from an `AppIntent` behind each button), app reads
  by polling once a second. Polling beats real IPC here: a widget button is not
  latency-critical, and cross-process notifications from a sandboxed extension need
  entitlements this app would otherwise not require.

The timeline emits one entry per minute while running — enough for the ring to
advance visibly, ~25 entries per pomodoro instead of 1,500. Anything derived from
elapsed time takes the entry's date as a parameter (`progress(at:)`), because a
timeline entry is rendered minutes before the moment it represents.

### Liquid Glass

`PomodoroUI` is a third target holding the SwiftUI shared by app and widget, so the
floating bar and the widget cannot drift apart. `glassPanel` applies
`glassEffect` on macOS 26 and falls back to `.regularMaterial` — the correct native
material for earlier systems, not a hand-rolled imitation.

Three findings that shaped the design, each from looking at the rendered result:

- **Tinted glass on a small control renders near-opaque.** A 28pt tinted circle reads
  as a coloured blob, not a button. Colour lives in the glyph; the primary control
  uses a solid tinted disc instead, because glass-on-glass gives a button no edge.
- **Changing a `glassEffect`'s tint changes view identity.** SwiftUI tears down and
  re-inserts the view, so a segmented picker built from per-item tinted glass
  re-animated every button on each selection. One glass surface with a
  `matchedGeometryEffect` selection fixes it.
- **A glass background is not a hit target.** Without an explicit `contentShape`,
  only the glyph or label text takes the click.

### Known limitations (additions)

- The widget must be added by hand once (Notification Center → Edit Widgets). A
  locally-built, non-notarized app registers with WidgetKit fine — verified via
  `pluginkit` — but nothing places the widget for you.
- Widget button presses land within about a second, not instantly, because the app
  polls for them. The widget updates its own display optimistically to hide most of
  that.
- The Control Center control requires macOS 26; the bundle simply doesn't vend it
  on earlier systems.
