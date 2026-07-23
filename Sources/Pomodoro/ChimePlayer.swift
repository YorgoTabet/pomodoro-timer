import AVFoundation
import AppKit
import os

private let log = Logger(subsystem: "com.yorgotabet.pomodoro", category: "chime")

/// Plays the transition chimes, with real gain control.
///
/// `NSSound.volume` tops out at 1.0 — the sample's own recorded level — so it can
/// only ever make a chime *quieter*. Routing through an `AVAudioEngine` with an EQ
/// node gives genuine amplification (its `globalGain` runs to +24 dB), which is what
/// makes "louder than default" possible at all. If the engine can't start for any
/// reason, playback falls back to `NSSound` and simply loses the boost.
@MainActor
final class ChimePlayer {

    static let shared = ChimePlayer()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let equalizer = AVAudioUnitEQ(numberOfBands: 0)

    private var buffers: [String: AVAudioPCMBuffer] = [:]
    /// Headroom in dB before each sound clips, from its measured peak.
    private var headroom: [String: Float] = [:]
    private var engineReady = false

    /// The system sounds available to choose from, loudest first — the ordering
    /// matters more than alphabetical here, since the reason to open this list is
    /// usually "I didn't hear it".
    static let availableSounds: [String] = {
        let known = ["Hero", "Blow", "Tink", "Bottle", "Morse", "Submarine", "Funk",
                     "Glass", "Basso", "Sosumi", "Purr", "Ping", "Frog", "Pop"]
        let installed = Set(
            (try? FileManager.default.contentsOfDirectory(atPath: "/System/Library/Sounds"))?
                .map { ($0 as NSString).deletingPathExtension } ?? []
        )
        let ordered = known.filter(installed.contains)
        // Anything Apple adds later still shows up, just at the end.
        return ordered + installed.subtracting(ordered).sorted()
    }()

    private init() {
        engine.attach(player)
        engine.attach(equalizer)
        engine.connect(player, to: equalizer, format: nil)
        engine.connect(equalizer, to: engine.mainMixerNode, format: nil)
    }

    /// - Parameter volume: 0…2, where 1.0 is the sample's own level and 2.0 is
    ///   roughly twice as loud (+6 dB).
    func play(_ name: String, volume: Double) {
        guard volume > 0.001 else { return }

        guard let buffer = buffer(for: name) else {
            playFallback(name, volume: volume)
            return
        }

        guard start() else {
            playFallback(name, volume: volume)
            return
        }

        // Decibels, not a linear multiplier: loudness is perceived logarithmically,
        // so a linear slider mapped straight to amplitude feels almost inert over
        // its upper half.
        //
        // Boosts are capped at each sound's own headroom. "Hero" peaks at 0.54, so
        // +6 dB would drive it past full scale and the extra loudness would arrive
        // as clipping distortion rather than volume.
        let requested = Float(20 * log10(volume))
        let ceiling = headroom[name] ?? 0
        equalizer.globalGain = min(max(requested, -60), max(ceiling, 0))
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        player.play()
    }

    /// Sample-accurate duplicate of the transition sound, for the preview buttons.
    func preview(_ name: String, volume: Double) {
        play(name, volume: volume)
    }

    // MARK: -

    private func start() -> Bool {
        if engineReady, engine.isRunning { return true }
        do {
            try engine.start()
            engineReady = true
            return true
        } catch {
            log.warning("Audio engine failed to start: \(error, privacy: .public)")
            engineReady = false
            return false
        }
    }

    private func buffer(for name: String) -> AVAudioPCMBuffer? {
        if let cached = buffers[name] { return cached }

        let url = URL(fileURLWithPath: "/System/Library/Sounds/\(name).aiff")
        guard let file = try? AVAudioFile(forReading: url),
              let buffer = AVAudioPCMBuffer(
                  pcmFormat: file.processingFormat,
                  frameCapacity: AVAudioFrameCount(file.length)
              ),
              (try? file.read(into: buffer)) != nil
        else {
            log.warning("Could not load sound \(name, privacy: .public)")
            return nil
        }

        buffers[name] = buffer
        headroom[name] = Self.headroomDB(of: buffer)
        return buffer
    }

    /// How much this sample can be boosted before its loudest peak hits full scale.
    private static func headroomDB(of buffer: AVAudioPCMBuffer) -> Float {
        guard let channels = buffer.floatChannelData else { return 0 }
        var peak: Float = 0
        for channel in 0..<Int(buffer.format.channelCount) {
            for frame in 0..<Int(buffer.frameLength) {
                peak = max(peak, abs(channels[channel][frame]))
            }
        }
        guard peak > 0.0001 else { return 0 }
        return -20 * log10(peak)
    }

    private func playFallback(_ name: String, volume: Double) {
        guard let sound = NSSound(named: name) else { return }
        sound.volume = Float(min(volume, 1.0))
        sound.play()
    }
}
