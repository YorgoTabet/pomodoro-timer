import CoreGraphics
import PomodoroCore
import SwiftUI

/// The animatable state of the ninja rig.
///
/// Parallels `SamuraiPose`: one field per joint the timelines move, plus the
/// figure-level transforms the backflip needs (`figureRotation`, `figureScaleY`).
public struct NinjaPose: Equatable, Sendable {

    /// Design units behind the pill edge. 200 = hidden, 0 = risen.
    public var emergence: Double = 200

    /// Whole-body transforms, applied at the `figure` wrapper so the emergence
    /// offset (on `root`) is not dragged into the flip.
    public var figureRotation: Double = 0
    public var figureScaleY: Double = 1
    public var figureScaleX: Double = 1
    /// Fades the whole body (not the smoke) for the teleport in and out.
    public var figureOpacity: Double = 1
    /// 1 while his feet are on the floor: the feet counter-rotate to stay flat and
    /// the body drops as the legs fold. 0 when airborne or seated.
    public var footPlant: Double = 1
    /// Chest scale, 1 at rest. Whole upper body, so the head and arms ride it.
    public var breath: Double = 1

    public var torso: Double = 0
    public var head: Double = 0
    public var eyesScaleY: Double = 1
    public var eyesOffsetX: Double = 0
    public var ribbonNear: Double = 0
    public var ribbonFar: Double = 0

    public var throwArmUpper: Double = 0
    public var throwForearm: Double = 0
    public var shuriken: Double = 0
    /// The star still in his hand.
    public var shurikenOpacity: Double = 1
    /// The star after release, drawn in world space so the recoiling hand cannot drag
    /// it. Offsets are from the star's resting spot in the hand (left/up negative).
    public var shurikenFlyOpacity: Double = 0
    public var shurikenFlyX: Double = 0
    public var shurikenFlyY: Double = 0
    public var offArmUpper: Double = 0
    public var offForearm: Double = 0
    public var ninjato: Double = 0
    public var sashTail: Double = 0

    public var legFrontThigh: Double = 0
    public var legFrontShin: Double = 0
    public var legBackThigh: Double = 0
    public var legBackShin: Double = 0

    /// Expression cross-fades. The eye slit does all the acting.
    public var alertOpacity: Double = 1     // whites + pupils + lids
    public var contentOpacity: Double = 0   // ∩ crescents
    public var sparkOpacity: Double = 0
    /// Opens the left eye alone while both are otherwise shut (0 shut, 1 open).
    public var leftEyeOpen: Double = 0

    /// The smoke-bomb burst.
    public var smokeOpacity: Double = 0
    public var smokeScale: Double = 0.5
    public var smokeOpacityB: Double = 0
    public var smokeScaleB: Double = 0.5
    public var smokeOpacityC: Double = 0
    public var smokeScaleC: Double = 0.5

    public init() {}

    /// How far the body sinks when the planted front leg folds, in design units.
    ///
    /// The drawn rest leg is slightly bent: the thigh leans 16.7 degrees and the shin
    /// -8.5, 34.9 and 32.7 units long, reaching 65.7 straight down. Folding the knee
    /// shortens that reach and the whole figure sinks by the difference so the planted
    /// foot stays on the floor.
    var stanceDrop: Double {
        guard footPlant > 0 else { return 0 }
        let thigh = (16.7 + legFrontThigh) * .pi / 180
        let shin = (-8.5 + legFrontThigh + legFrontShin) * .pi / 180
        return footPlant * max(0, 65.7 - (34.9 * cos(thigh) + 32.7 * cos(shin)))
    }

    func rotation(of part: NinjaArt.Part) -> Double {
        switch part {
        case .figure: figureRotation
        case .torso: torso
        case .head: head
        case .ribbonNear: ribbonNear
        case .ribbonFar: ribbonFar
        case .throwArmUpper: throwArmUpper
        case .throwForearm: throwForearm
        case .shuriken: shuriken
        case .offArmUpper: offArmUpper
        case .offForearm: offForearm
        case .ninjato: ninjato
        case .sashTail: sashTail
        case .legFrontThigh: legFrontThigh
        case .legFrontShin: legFrontShin
        case .legBackThigh: legBackThigh
        case .legBackShin: legBackShin
        case .footFront: -(legFrontThigh + legFrontShin) * footPlant
        case .footBack: -(legBackThigh + legBackShin) * footPlant
        case .shurikenFlight: shuriken
        case .root, .eyes, .smoke, .smokeB, .smokeC: 0
        }
    }

    func opacity(of layer: NinjaArt.Layer) -> Double {
        switch layer.name {
        case "puffA": return smokeOpacity
        case "puffB": return smokeOpacityB
        case "puffC": return smokeOpacityC
        case "flyStar", "flyHole": return shurikenFlyOpacity
        default: break
        }
        let own: Double = switch layer.name {
        case "eyeWhiteL", "pupilL", "lidL": max(alertOpacity, leftEyeOpen)
        case "eyeWhiteR", "pupilR", "lidR": alertOpacity
        case "contentEyeL": min(contentOpacity, 1 - leftEyeOpen)
        case "contentEyeR": contentOpacity
        case "sparkL", "sparkR": sparkOpacity
        case "shurikenStar", "shurikenHole": shurikenOpacity
        default: layer.restOpacity
        }
        return own * figureOpacity
    }
}

/// The ninja, drawn from `NinjaArt`'s path data. Structure mirrors `SamuraiView`.
public struct NinjaView: View {

    public static let canvas = NinjaArt.canvas

    let pose: NinjaPose

    public init(pose: NinjaPose) { self.pose = pose }

    public var body: some View {
        RigView(
            layers: NinjaArt.layers,
            pose: pose,
            outline: NinjaArt.Ink.outline,
            rotation: { $0.rotation(of: $1) },
            opacity: { $0.opacity(of: $1) },
            extras: { view, part, pose in
                AnyView(view.modifier(NinjaPartExtras(part: part, pose: pose)))
            }
        )
    }
}

/// Parts that move by more than a rotation.
/// Internal rather than private so render tests can compose a single rig part.
struct NinjaPartExtras: ViewModifier {
    let part: NinjaArt.Part
    let pose: NinjaPose

    func body(content: Content) -> some View {
        switch part {
        case .figure:
            // Squash and stretch pivot near the feet so a crouch lowers his head instead
            // of lifting his feet; the stance drop then sinks him as the knees fold.
            content
                .scaleEffect(x: pose.figureScaleX, y: pose.figureScaleY, anchor: UnitPoint(x: 0.5, y: 220 / 260))
                .offset(y: pose.stanceDrop)
        case .torso:
            content.scaleEffect(x: 1 + (1 - pose.breath) * 0.4, y: pose.breath, anchor: NinjaArt.Part.torso.anchor)
        case .eyes:
            content
                .scaleEffect(y: pose.eyesScaleY, anchor: NinjaArt.Part.eyes.anchor)
                .offset(x: pose.eyesOffsetX)
        case .smoke:
            content.scaleEffect(pose.smokeScale, anchor: NinjaArt.Part.smoke.anchor)
        case .smokeB:
            content.scaleEffect(pose.smokeScaleB, anchor: NinjaArt.Part.smokeB.anchor)
        case .smokeC:
            content.scaleEffect(pose.smokeScaleC, anchor: NinjaArt.Part.smokeC.anchor)
        case .shurikenFlight:
            // A child of `root`, so the offset is already in world space.
            content.offset(x: pose.shurikenFlyX, y: pose.shurikenFlyY)
        default:
            content
        }
    }
}
