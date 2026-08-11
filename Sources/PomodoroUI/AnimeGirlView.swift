import CoreGraphics
import PomodoroCore
import SwiftUI

/// The animatable state of the anime girl's rig.
public struct AnimeGirlPose: Equatable, Sendable {

    /// Design units behind the pill edge. 200 hidden, 0 risen, negative overshoot.
    public var emergence: Double = 200

    public var figureRotation: Double = 0
    public var figureScale: Double = 1
    public var figureScaleX: Double = 1
    public var figureScaleY: Double = 1
    public var figureLift: Double = 0

    public var hips: Double = 0
    public var torso: Double = 0
    public var legL: Double = 0
    public var legR: Double = 0
    public var armL: Double = 0
    public var armR: Double = 0
    /// Elbows. Positive bends the hand away from the body.
    public var armL_fore: Double = 0
    public var armR_fore: Double = 0
    public var head: Double = 0

    public var eyesScale: Double = 1
    public var eyesLift: Double = 0
    /// The emotional seismograph — lags the head and overshoots everything.
    public var ahoge: Double = 0
    public var ahogeScaleY: Double = 1

    public var tailL_base: Double = 0
    public var tailL_tip: Double = 0
    public var tailR_base: Double = 0
    public var tailR_tip: Double = 0

    /// Expression cross-fades. Default is a soft smile with open eyes.
    public var happyOpacity: Double = 0
    public var determinedOpacity: Double = 0

    public var sparkleOpacity: Double = 0
    public var sparkleScale: Double = 0.4
    public var sparkleRotation: Double = 0

    public init() {}

    func rotation(of part: AnimeGirlArt.Part) -> Double {
        switch part {
        case .figure: figureRotation
        case .hips: hips
        case .torso: torso
        case .legL: legL
        case .legR: legR
        case .armL: armL
        case .armR: armR
        case .armL_fore: armL_fore
        case .armR_fore: armR_fore
        case .head: head
        case .ahoge: ahoge
        case .tailL_base: tailL_base
        case .tailL_tip: tailL_tip
        case .tailR_base: tailR_base
        case .tailR_tip: tailR_tip
        case .sparkles: sparkleRotation
        case .root, .eyes: 0
        }
    }

    func opacity(of layer: AnimeGirlArt.Layer) -> Double {
        // The default face yields to whichever alternate is fading in.
        let alternate = max(happyOpacity, determinedOpacity)
        // Explicit `return`: the `let` above makes this a multi-statement body, so
        // the switch is not an implicit return.
        return switch layer.name {
        case "mouthDefault", "browsDefault": 1 - alternate
        case "mouthHappy", "closedEyesHappy": happyOpacity
        case "mouthDetermined", "browsDetermined": determinedOpacity
        // Happy closes her eyes, so the whole open-eye cluster fades with it;
        // determined keeps them open.
        case "eyeWhiteL", "eyeWhiteR", "irisL", "irisR", "pupilL", "pupilR",
             "hiBigL", "hiBigR", "hiSmallL", "hiSmallR", "lashL", "lashR":
            1 - happyOpacity
        case "sparkleA", "sparkleB", "sparkleC": sparkleOpacity
        default: layer.restOpacity
        }
    }
}

/// The anime schoolgirl, drawn from `AnimeGirlArt`'s path data.
public struct AnimeGirlView: View {

    public static let canvas = AnimeGirlArt.canvas

    let pose: AnimeGirlPose
    /// Defaults to the shipped figure. Pass `AnimeGirlArt.build(other)` to draw
    /// a different set of proportions — this is the seam RigStudio's variant
    /// sheet uses, and the reason `build` is a pure function.
    let layers: [AnimeGirlArt.Layer]

    public init(pose: AnimeGirlPose, layers: [AnimeGirlArt.Layer] = AnimeGirlArt.layers) {
        self.pose = pose
        self.layers = layers
    }

    public var body: some View {
        RigView(
            layers: layers,
            pose: pose,
            outline: AnimeGirlArt.Ink.outline,
            rotation: { $0.rotation(of: $1) },
            opacity: { $0.opacity(of: $1) },
            extras: { view, part, pose in
                AnyView(view.modifier(AnimeGirlPartExtras(part: part, pose: pose)))
            }
        )
    }
}

/// Parts that move by more than a rotation.
///
/// Internal rather than private so render tests can compose a single rig part.
struct AnimeGirlPartExtras: ViewModifier {
    let part: AnimeGirlArt.Part
    let pose: AnimeGirlPose

    func body(content: Content) -> some View {
        switch part {
        case .figure:
            content
                .scaleEffect(x: pose.figureScaleX, y: pose.figureScaleY, anchor: .bottom)
                .scaleEffect(pose.figureScale, anchor: .bottom)
                .offset(y: pose.figureLift)
        case .eyes:
            content
                .scaleEffect(pose.eyesScale, anchor: AnimeGirlArt.Part.eyes.anchor)
                .offset(y: pose.eyesLift)
        case .ahoge:
            content.scaleEffect(y: pose.ahogeScaleY, anchor: AnimeGirlArt.Part.ahoge.anchor)
        case .sparkles:
            content.scaleEffect(pose.sparkleScale, anchor: AnimeGirlArt.Part.sparkles.anchor)
        default:
            content
        }
    }
}
