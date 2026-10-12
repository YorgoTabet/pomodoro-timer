import AppKit
import ImageIO
import PomodoroCore
import SwiftUI

/// The original Codex companion pixels, cached once without redrawing her design.
@MainActor
enum NelSprites {
    static let frames: [Int: CGImage] = {
        let bundle = Bundle.main.url(forResource: "Pomodoro_PomodoroUI", withExtension: "bundle")
            .flatMap(Bundle.init(url:)) ?? Bundle.module
        guard let url = bundle.url(forResource: "nel-original", withExtension: "png"),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let atlas = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return [:] }
        var result: [Int: CGImage] = [:]
        for (row, count) in [6, 8, 8, 4, 5, 8, 6, 6, 6, 8, 8].enumerated() {
            for column in 0..<count {
                result[row * 8 + column] = atlas.cropping(to:
                    CGRect(x: column * 192, y: row * 208, width: 192, height: 208))
            }
        }
        return result
    }()
}

/// Uses the existing rigs' canvas and ground line so stage geometry stays shared.
public struct NelSprite: View {
    let frame: Int
    public init(frame: Int = 0) { self.frame = frame }
    public var body: some View {
        ZStack(alignment: .topLeading) {
            if let image = NelSprites.frames[frame] {
                Image(decorative: image, scale: 1)
                    .resizable().interpolation(.high)
                    .frame(width: 192, height: 208)
                    .offset(x: 4, y: -6)
            }
        }
        .frame(width: 200, height: 260, alignment: .topLeading)
        .accessibilityHidden(true)
    }
}

public struct NelPose: Sendable {
    public var emergence = 200.0
    public var seconds = 0.0
    public init() {}
}

/// Three short performances assembled from Nel's original nod, wave and hop.
/// No invented skeleton or independent transforms of facial features.
public enum NelPerformance {
    public static func duration(for cue: CharacterCue) -> Double { 3.3 }
    public static func preferredEdge(for cue: CharacterCue) -> StageEdge { .top }
    public static func comesForward(for cue: CharacterCue) -> Bool { false }

    public static func frame(for cue: CharacterCue, at seconds: Double) -> Int {
        let t = seconds.isFinite ? min(2.4, max(0, seconds - 0.45)) : 0
        let frames: [Int]
        switch cue {
        case .focusStart: frames = [56, 57, 58, 59, 60, 61, 64, 65, 66, 67, 68, 69]
        case .breakStart: frames = [24, 25, 26, 26, 25, 26, 26, 25, 27, 0, 3, 0]
        case .longBreak: frames = [32, 33, 34, 35, 36, 32, 33, 34, 35, 36, 26, 27]
        }
        let index = min(frames.count - 1, Int(min(t, 2.4) / 0.2))
        return frames[index]
    }

    @KeyframesBuilder<NelPose>
    public static var tracks: some Keyframes<NelPose> {
        KeyframeTrack(\.emergence) {
            CubicKeyframe(0, duration: 0.45)
            LinearKeyframe(0, duration: 2.4)
            CubicKeyframe(200, duration: 0.45)
        }
        KeyframeTrack(\.seconds) { LinearKeyframe(3.3, duration: 3.3) }
    }

    public static func timeline(for cue: CharacterCue) -> KeyframeTimeline<NelPose> {
        KeyframeTimeline(initialValue: NelPose()) { tracks }
    }
}
