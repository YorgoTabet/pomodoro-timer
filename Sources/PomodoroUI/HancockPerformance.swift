import PomodoroCore
import SwiftUI

/// Boa Hancock's three performances.
///
/// Placeholders: each rises from behind the bar, holds her contrapposto rest
/// pose with a slow breath and a little hair drift, and sinks. The durations
/// are the final ones, so the stage and the audits are already right.
public enum HancockPerformance {

    public static func preferredEdge(for cue: CharacterCue) -> StageEdge { .top }

    /// The long break steps through the skirt slit, so it shows her legs and
    /// stands in front of the bar; the other two stay behind it.
    public static func comesForward(for cue: CharacterCue) -> Bool {
        cue == .longBreak
    }

    public static func duration(for cue: CharacterCue) -> Double {
        switch cue {
        case .focusStart: 2.80
        case .breakStart: 3.00
        case .longBreak: 3.40
        }
    }

    // MARK: - focusStart · "Looking down on you" (2.8s)

    @KeyframesBuilder<HancockPose>
    public static var lookingDown: some Keyframes<HancockPose> {
        placeholder(total: 2.8)
    }

    // MARK: - breakStart · "Love-struck" (3.0s)

    @KeyframesBuilder<HancockPose>
    public static var loveStruck: some Keyframes<HancockPose> {
        placeholder(total: 3.0)
    }

    // MARK: - longBreak · "Empress" (3.4s)

    @KeyframesBuilder<HancockPose>
    public static var empress: some Keyframes<HancockPose> {
        placeholder(total: 3.4)
    }

    /// Rise 0.5s, hold, sink 0.5s. Every track sums to `total`.
    @KeyframesBuilder<HancockPose>
    static func placeholder(total: Double) -> some Keyframes<HancockPose> {
        let hold = total - 1.0
        let rest = HancockPose()
        KeyframeTrack(\.emergence) {
            CubicKeyframe(0, duration: 0.5)
            Hold.moving(0, duration: hold, drift: 1.0)
            CubicKeyframe(200, duration: 0.5)
        }
        KeyframeTrack(\.chest) {
            Hold.moving(rest.chest, duration: 0.5, drift: 0.6)
            Hold.breathing(rest.chest, duration: hold, drift: 1.0)
            Hold.moving(rest.chest, duration: 0.5, drift: 0.6)
        }
        KeyframeTrack(\.hairMid) {
            Hold.moving(rest.hairMid, duration: 0.5, drift: 1.0)
            Hold.breathing(rest.hairMid, duration: hold, drift: 1.2)
            Hold.moving(rest.hairMid, duration: 0.5, drift: -1.0)
        }
        KeyframeTrack(\.hairTip) {
            Hold.moving(rest.hairTip, duration: 0.6, drift: 1.4)
            Hold.breathing(rest.hairTip, duration: hold - 0.1, drift: 1.4)
            Hold.moving(rest.hairTip, duration: 0.5, drift: -1.4)
        }
    }
}
