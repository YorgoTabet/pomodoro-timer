import AppKit
import ApplicationServices
import Foundation
import os

private let log = Logger(subsystem: "com.yorgotabet.pomodoro", category: "music")

/// Starts and stops whatever the user is listening to, alongside the focus timer.
///
/// The contract is deliberately narrow: never guess. Playback is only started when a
/// player can be *seen* to be sitting paused, or when this app is the one that paused
/// it. A blind toggle that might stop music the user just started is worse than doing
/// nothing at all.
public protocol MusicController {
    /// Pause any player that is currently playing. Returns `true` if something was paused.
    @discardableResult func pauseIfPlaying() -> Bool
    /// Start playback for a focus session. Returns `true` if a player was found to act on.
    @discardableResult func startForFocus() -> Bool
    /// Resume only what this controller paused.
    func resumeIfWePaused()
    /// Forget any pending resume (e.g. the user turned music control off).
    func forgetPaused()
}

// MARK: - AppleScript

/// Controls Music.app and Spotify.app directly.
///
/// Direct scripting is the accurate path: it can read real player state, so it knows
/// whether anything was playing and can resume exactly that. Its costs are a one-time
/// Automation permission prompt per app, and that it only covers these two players.
public final class ScriptedMusicController: MusicController {

    private struct Target {
        let bundleID: String
        let appName: String   // the name AppleScript addresses
    }

    private let targets = [
        Target(bundleID: "com.apple.Music", appName: "Music"),
        Target(bundleID: "com.spotify.client", appName: "Spotify"),
    ]

    private var paused: Set<String> = []
    private var permissionWarned: Set<String> = []

    public init() {}

    @discardableResult
    public func pauseIfPlaying() -> Bool {
        var didPause = false
        for target in targets where isRunning(target) {
            guard playerState(target) == "playing" else { continue }
            if run("tell application \"\(target.appName)\" to pause", target: target) != nil {
                paused.insert(target.bundleID)
                didPause = true
                log.notice("Paused \(target.appName, privacy: .public)")
            }
        }
        return didPause
    }

    /// Resume what we paused; failing that, start a player that is loaded and idle.
    ///
    /// Only a player reporting `paused` is started. A `stopped` player has no current
    /// track, so telling it to play would pick something at random — a surprise, not
    /// a focus soundtrack.
    @discardableResult
    public func startForFocus() -> Bool {
        if !paused.isEmpty {
            resumeIfWePaused()
            return true
        }

        for target in targets where isRunning(target) {
            switch playerState(target) {
            case "playing":
                // Already going. Nothing to do, and nothing for the fallback either.
                return true
            case "paused":
                guard run("tell application \"\(target.appName)\" to play", target: target) != nil else { continue }
                log.notice("Started \(target.appName, privacy: .public) for focus")
                return true
            default:
                continue
            }
        }
        return false
    }

    public func resumeIfWePaused() {
        for target in targets where paused.contains(target.bundleID) {
            // Don't relaunch a player the user has since quit.
            if isRunning(target) {
                _ = run("tell application \"\(target.appName)\" to play", target: target)
                log.notice("Resumed \(target.appName, privacy: .public)")
            }
            paused.remove(target.bundleID)
        }
    }

    public func forgetPaused() {
        paused.removeAll()
    }

    /// Whether *this* controller found something playing — used by the chain to
    /// decide whether the media-key fallback is needed.
    public func anythingPlaying() -> Bool {
        for target in targets {
            let running = isRunning(target)
            let state = running ? (playerState(target) ?? "<no answer>") : "<not running>"
            log.notice("\(target.appName, privacy: .public): running=\(running, privacy: .public) state=\(state, privacy: .public)")
            if running, state == "playing" { return true }
        }
        return false
    }

    // MARK: -

    private func isRunning(_ target: Target) -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: target.bundleID).isEmpty
    }

    private func playerState(_ target: Target) -> String? {
        run("tell application \"\(target.appName)\" to return player state as string", target: target)?
            .stringValue?
            .lowercased()
    }

    /// Runs a script, converting a permission failure into `nil` rather than an
    /// error the caller has to handle. Music control is best-effort: a denied
    /// Automation prompt must never stop the timer.
    private func run(_ source: String, target: Target) -> NSAppleEventDescriptor? {
        var error: NSDictionary?
        let result = NSAppleScript(source: source)?.executeAndReturnError(&error)
        if let error {
            if permissionWarned.insert(target.bundleID).inserted {
                log.warning("AppleScript for \(target.appName, privacy: .public) failed: \(error, privacy: .public)")
            }
            return nil
        }
        return result
    }
}

// MARK: - Media key

/// Posts the system Play/Pause key, the same event the F8 key sends.
///
/// Works with any player including browser audio, but it is a blind toggle: there is
/// no way to read play state, so this is only used when the scripted controller found
/// nothing, and resume only fires if we were the one who sent the pause.
public final class MediaKeyController: MusicController {

    private static let playPause: Int32 = 16   // NX_KEYTYPE_PLAY

    private var didPause = false
    private var didPrompt = false

    public init() {}

    @discardableResult
    public func pauseIfPlaying() -> Bool {
        // Posting a system-defined event needs Accessibility permission. Without it
        // the event is dropped silently — no error, no exception, nothing — so this
        // is logged rather than assumed.
        guard requestAccessibilityIfNeeded() else { return false }

        Self.postPlayPause()
        didPause = true
        return true
    }

    /// Only ever un-pauses our own pause.
    ///
    /// The key is a toggle with no readable state, so firing it speculatively at focus
    /// start is as likely to stop the user's music as to start it. When we did not
    /// pause anything, the honest answer is to do nothing.
    @discardableResult
    public func startForFocus() -> Bool {
        guard didPause else { return false }
        resumeIfWePaused()
        return true
    }

    public func resumeIfWePaused() {
        guard didPause else { return }
        Self.postPlayPause()
        didPause = false
    }

    public func forgetPaused() {
        didPause = false
    }

    /// Ask for Accessibility the first time we actually need it.
    ///
    /// Prompting at launch would be rude and unexplained; prompting here means the
    /// dialog appears at the exact moment the user's music failed to pause, which is
    /// when the request makes sense. Asked once per launch — a denied prompt must
    /// not turn into a dialog every 25 minutes.
    private func requestAccessibilityIfNeeded() -> Bool {
        if AXIsProcessTrusted() { return true }

        guard !didPrompt else {
            log.error("Media key dropped: Pomodoro is not trusted for Accessibility.")
            return false
        }
        didPrompt = true

        log.error("Media key dropped: requesting Accessibility permission.")
        // The literal key rather than `kAXTrustedCheckOptionPrompt`: that symbol is
        // a global mutable `var`, which Swift 6 strict concurrency rejects.
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    private static func postPlayPause() {
        post(down: true)
        post(down: false)
    }

    private static func post(down: Bool) {
        let state = down ? 0x0A : 0x0B
        let data1 = Int((playPause << 16) | Int32(state << 8))
        guard let event = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: UInt(state << 8)),
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: data1,
            data2: -1
        ) else { return }
        event.cgEvent?.post(tap: .cghidEventTap)
    }
}

// MARK: - Chain

/// Scripted control first, media key as the fallback.
///
/// If Music or Spotify was playing, we handled it precisely and stop there. Only when
/// neither reported playing do we fall back to the blind system toggle, which is what
/// catches browser audio, Podcasts, VLC, and everything else.
public final class ChainedMusicController: MusicController {

    private let scripted = ScriptedMusicController()
    private let mediaKey = MediaKeyController()

    public init() {}

    @discardableResult
    public func pauseIfPlaying() -> Bool {
        let scriptable = scripted.anythingPlaying()
        log.notice("pause requested: scriptedPlayerPlaying=\(scriptable, privacy: .public)")
        if scriptable {
            return scripted.pauseIfPlaying()
        }
        return mediaKey.pauseIfPlaying()
    }

    @discardableResult
    public func startForFocus() -> Bool {
        // The scripted players can be seen, so they answer first and definitively:
        // if one is playing, paused, or was paused by us, the media key must stay out
        // of it or it would toggle that same audio back off.
        if scripted.startForFocus() {
            log.notice("focus start handled by scripted player")
            return true
        }
        let handled = mediaKey.startForFocus()
        log.notice("focus start: mediaKeyResumed=\(handled, privacy: .public)")
        return handled
    }

    public func resumeIfWePaused() {
        scripted.resumeIfWePaused()
        mediaKey.resumeIfWePaused()
    }

    public func forgetPaused() {
        scripted.forgetPaused()
        mediaKey.forgetPaused()
    }
}
