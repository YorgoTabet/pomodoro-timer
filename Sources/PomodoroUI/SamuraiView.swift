import PomodoroCore
import SwiftUI

/// The animatable state of the samurai.
///
/// One field per named part in the art direction. Keyframe timelines interpolate
/// this struct, so a timeline row maps to a `KeyframeTrack` on one of these
/// properties and nothing has to be reinterpreted.
public struct SamuraiPose: Equatable {
    /// Displacement along the emergence edge's inward normal, in points.
    /// 48 = fully hidden behind the pill, 0 = fully risen.
    public var emergence: Double = 48
    public var rootRotation: Double = 0      // degrees
    public var rootScale: Double = 1
    public var swordArm: Double = -15        // degrees, rest pose
    public var crest: Double = 0             // degrees
    public var bladeOpacity: Double = 1
    public var eyeScaleY: Double = 1

    public init() {}
}

/// A samurai, drawn entirely from SwiftUI primitives.
///
/// Authored in a 56×44pt box with the origin at top-left and the pill's edge as the
/// "horizon" at y=44 — see the art-direction spec. Nothing below the waist is drawn
/// in detail, because the pill covers it.
public struct SamuraiView: View {

    public static let boxSize = CGSize(width: 56, height: 44)

    let pose: SamuraiPose

    public init(pose: SamuraiPose) {
        self.pose = pose
    }

    // Palette
    private let armor = Color(red: 0.231, green: 0.290, blue: 0.420)     // #3B4A6B
    private let armorDark = Color(red: 0.180, green: 0.227, blue: 0.333) // #2E3A55
    private let gold = Color(red: 0.949, green: 0.706, blue: 0.255)      // #F2B441
    private let skin = Color(red: 0.961, green: 0.788, blue: 0.627)      // #F5C9A0
    private let handleRed = Color(red: 0.753, green: 0.224, blue: 0.169) // #C0392B
    private let ink = Color(red: 0.149, green: 0.165, blue: 0.200)       // #262A33

    public var body: some View {
        ZStack(alignment: .topLeading) {
            swordArmGroup
            bodyGroup
            headGroup
            helmetGroup
        }
        .frame(width: Self.boxSize.width, height: Self.boxSize.height, alignment: .topLeading)
        .rotationEffect(.degrees(pose.rootRotation), anchor: anchor(26, 40))
        .scaleEffect(pose.rootScale, anchor: anchor(26, 44))
    }

    // MARK: - Sword arm

    private var swordArmGroup: some View {
        ZStack(alignment: .topLeading) {
            capsule(5, 10, at: (41, 31), armor)
            capsule(3, 7, at: (41, 29.5), handleRed)
            // Blade before guard so the tsuba reads as sitting in front of it.
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.957, green: 0.969, blue: 0.980),
                                 Color(red: 0.843, green: 0.871, blue: 0.910)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3.5, height: 22)
                .opacity(pose.bladeOpacity)
                .position(x: 41, y: 13.5)
            circle(5.5, at: (41, 25), gold)
        }
        .frame(width: Self.boxSize.width, height: Self.boxSize.height, alignment: .topLeading)
        // Anchor at the shoulder (41, 36) so the blade swings around the joint.
        .rotationEffect(.degrees(pose.swordArm), anchor: anchor(41, 36))
    }

    // MARK: - Body

    private var bodyGroup: some View {
        ZStack(alignment: .topLeading) {
            roundedRect(26, 16, radius: 7, at: (26, 42), armor)
            roundedRect(10, 8, radius: 3, at: (13, 36), armorDark).rotationEffect(.degrees(-10))
            roundedRect(10, 8, radius: 3, at: (39, 36), armorDark).rotationEffect(.degrees(10))
        }
        .frame(width: Self.boxSize.width, height: Self.boxSize.height, alignment: .topLeading)
    }

    // MARK: - Head

    private var headGroup: some View {
        ZStack(alignment: .topLeading) {
            circle(22, at: (26, 26), skin)

            // Stern V brows — the whole expression, since nothing else survives at
            // this size.
            capsule(5, 1.5, at: (21, 27.5), ink).rotationEffect(.degrees(-18))
            capsule(5, 1.5, at: (31, 27.5), ink).rotationEffect(.degrees(18))

            eye(at: (21, 30.5))
            eye(at: (31, 30.5))

            capsule(4, 1.5, at: (26, 34.5), ink)
        }
        .frame(width: Self.boxSize.width, height: Self.boxSize.height, alignment: .topLeading)
    }

    /// Squashes vertically to a closed, content eye.
    private func eye(at point: (Double, Double)) -> some View {
        Capsule()
            .fill(ink)
            .frame(width: 2, height: 4)
            .scaleEffect(y: pose.eyeScaleY)
            .position(x: point.0, y: point.1)
    }

    // MARK: - Helmet

    private var helmetGroup: some View {
        ZStack(alignment: .topLeading) {
            roundedRect(8, 10, radius: 3, at: (12, 16), armorDark).rotationEffect(.degrees(-18))
            roundedRect(8, 10, radius: 3, at: (40, 16), armorDark).rotationEffect(.degrees(18))
            circle(26, at: (26, 13), armorDark)

            ZStack(alignment: .topLeading) {
                capsule(3, 11, at: (22, 7), gold).rotationEffect(.degrees(-28))
                capsule(3, 11, at: (30, 7), gold).rotationEffect(.degrees(28))
                circle(5, at: (26, 11), gold)
            }
            .frame(width: Self.boxSize.width, height: Self.boxSize.height, alignment: .topLeading)
            .rotationEffect(.degrees(pose.crest), anchor: anchor(26, 11))
        }
        .frame(width: Self.boxSize.width, height: Self.boxSize.height, alignment: .topLeading)
    }

    // MARK: - Primitives

    /// Box coordinates to a `UnitPoint` of the 56×44 frame, since SwiftUI rotation
    /// anchors are fractions of the view's own bounds.
    private func anchor(_ x: Double, _ y: Double) -> UnitPoint {
        UnitPoint(x: x / Self.boxSize.width, y: y / Self.boxSize.height)
    }

    private func circle(_ diameter: Double, at point: (Double, Double), _ fill: Color) -> some View {
        Circle()
            .fill(fill)
            .frame(width: diameter, height: diameter)
            .position(x: point.0, y: point.1)
    }

    private func capsule(_ w: Double, _ h: Double, at point: (Double, Double), _ fill: Color) -> some View {
        Capsule()
            .fill(fill)
            .frame(width: w, height: h)
            .position(x: point.0, y: point.1)
    }

    private func roundedRect(
        _ w: Double, _ h: Double, radius: Double,
        at point: (Double, Double), _ fill: Color
    ) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(fill)
            .frame(width: w, height: h)
            .position(x: point.0, y: point.1)
    }
}
