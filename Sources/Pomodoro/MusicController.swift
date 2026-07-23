import AppKit
import CoreAudio
import Foundation
import os

private let log = Logger(subsystem: "com.yorgotabet.pomodoro", category: "music")

/// Pauses and resumes whatever the user is listening to.
///
/// The contract is deliberately narrow: only ever resume something this app paused.
/// If the user paused their own music mid-focus, we must not start it playing again.
public protocol MusicController {
    /// Pause any player that is currently playing. Returns `true` if something was paused.
    @discardableResult func pauseIfPlaying() -> Bool
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
                log.info("Paused \(target.appName, privacy: .public)")
            }
        }
        return didPause
    }

    public func resumeIfWePaused() {
        for target in targets where paused.contains(target.bundleID) {
            // Don't relaunch a player the user has since quit.
            if isRunning(target) {
                _ = run("tell application \"\(target.appName)\" to play", target: target)
                log.info("Resumed \(target.appName, privacy: .public)")
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
        targets.contains { isRunning($0) && playerState($0) == "playing" }
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

    public init() {}

    @discardableResult
    public func pauseIfPlaying() -> Bool {
        // The media key is a toggle, not a pause. Sending it when nothing is playing
        // would *start* whatever player last had focus — the exact opposite of what
        // the user asked for. So gate it on the audio device actually running.
        guard Self.isAudioPlaying() else { return false }
        Self.postPlayPause()
        didPause = true
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

    /// Whether the default output device is currently being driven by anything.
    ///
    /// This is the closest macOS gets to "is audio playing" without per-app
    /// scripting — it can't say *what* is playing, but it reliably distinguishes
    /// silence from sound, which is all the toggle needs to be safe.
    private static func isAudioPlaying() -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID
        ) == noErr else { return false }

        address.mSelector = kAudioDevicePropertyDeviceIsRunningSomewhere
        var running: UInt32 = 0
        size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(
            deviceID, &address, 0, nil, &size, &running
        ) == noErr else { return false }

        return running != 0
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
        if scripted.anythingPlaying() {
            return scripted.pauseIfPlaying()
        }
        return mediaKey.pauseIfPlaying()
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
