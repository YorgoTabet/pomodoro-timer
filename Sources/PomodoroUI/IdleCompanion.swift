import AppKit
import QuartzCore
import PomodoroCore
import SwiftUI

/// Small, bounded movements. No phase-change timeline is reused or modified.
public struct IdleMotion: Equatable, Sendable {
    public var breath: Double = 0
    public var sway: Double = 0
    public var blink: Double = 0
    public var step: Double = 0
    /// A fraction of the available stroll distance, rather than screen coordinates.
    public var travel: Double = 0

    public static func sample(time: Double, mode: CharacterIdleMode, reduceMotion: Bool = false) -> Self {
        guard mode != .off, !reduceMotion else { return Self() }
        let t = max(0, time)
        var motion = Self()
        motion.breath = sin(t * .pi / 3)
        motion.sway = sin(t * .pi / 6)
        let blinkTime = t.truncatingRemainder(dividingBy: 12)
        if (8..<8.35).contains(blinkTime) {
            motion.blink = sin((blinkTime - 8) / 0.35 * .pi)
        }
        guard mode == .stroll else { return motion }

        // Start with a four-second walk so selecting Stroll previews it immediately.
        // Rest at the far end, walk home, then take a longer rest before repeating.
        // Smoothstep stops translation gently; the gait also settles at each end.
        let cycle = t.truncatingRemainder(dividingBy: 32)
        if (0..<4).contains(cycle) {
            let p = cycle / 4
            motion.travel = p * p * (3 - 2 * p)
            motion.step = sin(cycle * .pi * 2 / 1.2) * sin(p * .pi)
        } else if (4..<12).contains(cycle) {
            motion.travel = 1
        } else if (12..<16).contains(cycle) {
            let p = (cycle - 12) / 4
            motion.travel = 1 - p * p * (3 - 2 * p)
            motion.step = -sin((cycle - 12) * .pi * 2 / 1.2) * sin(p * .pi)
        }
        return motion
    }
}

/// Placement in the panel's top-left coordinates. The readout stays fixed in both
/// pill forms, so the companion never forces the compact bar open.
public enum IdleCompanionLayout {
    public static let height: CGFloat = 48
    public static let size = CGSize(width: 200 * height / 260, height: height)

    public static func frame(pill: CGRect, screen: CGRect, readoutCenterX: CGFloat, travel: Double) -> CGRect {
        let bounds = screen.isNull ? CGRect(x: -10_000, y: -10_000, width: 20_000, height: 20_000) : screen
        let above = pill.minY - bounds.minY
        let below = bounds.maxY - pill.maxY
        let placeAbove = above >= height || above >= below
        let y = placeAbove ? pill.minY - height : pill.maxY
        // The whole stroll stays over the readout, well clear of the controls.
        let x = readoutCenterX + CGFloat(min(1, max(0, travel))) * 22 - size.width / 2
        return CGRect(
            x: min(max(x, bounds.minX), max(bounds.minX, bounds.maxX - size.width)),
            y: min(max(y, bounds.minY), max(bounds.minY, bounds.maxY - height)),
            width: size.width, height: height
        )
    }
}

/// The existing drawings, with quiet new poses authored for each skeleton.
/// Kept separately from the full-size performances so Off preserves them exactly.
public enum IdlePoses {
    public static func samurai(_ m: IdleMotion) -> SamuraiPose {
        var p = SamuraiPose()
        p.emergence = 0
        p.torsoScaleY = 1 + m.breath * 0.006
        p.head = m.sway * 1.2
        p.kabuto = m.sway * 0.5
        p.eyeOpacity = 1 - m.blink
        p.legL = m.step * 5
        p.legR = -m.step * 5
        p.shinL = max(0, -m.step) * 7
        p.shinR = max(0, m.step) * 7
        p.sashTailL = m.sway * 1.5 + m.step
        p.sashTailR = -m.sway
        return p
    }

    public static func ninja(_ m: IdleMotion) -> NinjaPose {
        var p = NinjaPose()
        p.emergence = 0
        p.breath = 1 + m.breath * 0.008
        p.head = m.sway * 1.5
        p.eyesScaleY = 1 - m.blink * 0.95
        p.ribbonNear = m.sway * 2
        p.ribbonFar = -m.sway
        p.legFrontThigh = m.step * 5
        p.legBackThigh = -m.step * 5
        p.legFrontShin = max(0, -m.step) * 6
        p.legBackShin = max(0, m.step) * 6
        p.offArmUpper = -m.step * 3
        return p
    }

    public static func rabbit(_ m: IdleMotion) -> RabbitPose {
        var p = RabbitPose()
        p.emergence = 0
        p.figureScaleY = 1 + m.breath * 0.006
        p.head = m.sway * 1.5
        p.earL_tip = m.sway * 3
        p.earR_tip = -m.sway * 4
        p.blinkOpacity = m.blink
        p.figureLift = -abs(m.step) * 3
        p.legs = m.step * 3
        p.armL = m.step * 3
        p.armR = -m.step * 3
        return p
    }

    public static func power(_ m: IdleMotion) -> AnimeGirlPose {
        var p = AnimeGirlPose()
        p.emergence = 0
        p.figureScaleY = 1 + m.breath * 0.005
        p.head = m.sway * 2
        p.hips = m.sway
        p.torso = -m.sway
        p.eyesScale = 1 - m.blink * 0.95
        p.ahoge = m.sway * 2
        p.tailL_tip = m.sway * 2
        p.tailR_tip = -m.sway * 2
        p.legL = m.step * 6
        p.legR = -m.step * 6
        p.shinL = max(0, -m.step) * 7
        p.shinR = max(0, m.step) * 7
        p.armL = -m.step * 4
        p.armR = m.step * 4
        return p
    }

    public static func general(_ m: IdleMotion) -> GeneralPose {
        var p = GeneralPose()
        p.emergence = 0
        p.torsoScaleY = 1 + m.breath * 0.008
        p.head = m.sway * 1.3
        p.cap = -m.sway * 0.5
        p.stache = m.sway * 0.6
        p.medals = m.sway
        p.legNearLift = -max(0, m.step) * 4
        p.legFarLift = -max(0, -m.step) * 4
        p.legNearScaleY = 1 - max(0, m.step) * 0.025
        p.legFarScaleY = 1 - max(0, -m.step) * 0.025
        p.armNear = -m.step * 3
        p.armFar = m.step * 3
        return p
    }

    public static func hancock(_ m: IdleMotion) -> HancockPose {
        var p = HancockPose()
        p.emergence = 0
        p.chest += m.breath * 0.7
        p.head += m.sway
        p.hairMid = m.sway * 1.5
        p.hairTip = m.sway * 2
        p.earringL += m.sway
        p.earringR += m.sway
        p.winkOpacity = m.blink
        p.legL += m.step * 4
        p.legR -= m.step * 4
        p.shinL += max(0, -m.step) * 5
        p.shinR += max(0, m.step) * 5
        p.sashTail = m.sway + m.step
        return p
    }
}

public struct IdleCharacterDrawing: View {
    let character: PomodoroCharacter
    let motion: IdleMotion

    public init(character: PomodoroCharacter, motion: IdleMotion) {
        self.character = character
        self.motion = motion
    }

    public var body: some View {
        drawing
            .scaleEffect(IdleCompanionLayout.height / 260, anchor: .topLeading)
            .frame(width: IdleCompanionLayout.size.width, height: IdleCompanionLayout.height, alignment: .topLeading)
            // The artwork's soles sit a little above its canvas bottom.
            .offset(y: 1.5)
    }

    @ViewBuilder private var drawing: some View {
        switch character {
        case .samurai: SamuraiView(pose: IdlePoses.samurai(motion))
        case .ninja: NinjaView(pose: IdlePoses.ninja(motion))
        case .rabbit: RabbitView(pose: IdlePoses.rabbit(motion))
        case .animeGirl: AnimeGirlView(pose: IdlePoses.power(motion))
        case .general: GeneralView(pose: IdlePoses.general(motion))
        case .hancock: HancockView(pose: IdlePoses.hancock(motion))
        case .nel:
            NelSprite(frame: motion.blink > 0.5 ? 3 : (abs(motion.step) > 0.1 ? 9 : 0))
                .offset(y: -motion.breath)
        case .none: EmptyView()
        }
    }
}

public struct IdleCompanion: View {
    let character: PomodoroCharacter
    let mode: CharacterIdleMode
    let pill: CGRect
    let screen: CGRect
    let readoutCenterX: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sprites: IdleSprites?

    public init(character: PomodoroCharacter, mode: CharacterIdleMode, pill: CGRect,
                screen: CGRect, readoutCenterX: CGFloat) {
        self.character = character
        self.mode = mode
        self.pill = pill
        self.screen = screen
        self.readoutCenterX = readoutCenterX
    }

    public var body: some View {
        Group {
            if reduceMotion {
                companion(.init())
            } else if let sprites {
                let home = IdleCompanionLayout.frame(pill: pill, screen: screen,
                                                      readoutCenterX: readoutCenterX, travel: 0)
                let away = IdleCompanionLayout.frame(pill: pill, screen: screen,
                                                      readoutCenterX: readoutCenterX, travel: 1)
                // Native layer playback avoids a SwiftUI render pass for every
                // idle frame, including costly glass re-rasterisation in the pill.
                IdleSpritePlayer(sprites: sprites, mode: mode, distance: away.minX - home.minX)
                    .frame(width: home.width, height: home.height)
                    .position(x: home.midX, y: home.midY)
            } else {
                companion(.init())
            }
        }
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            sprites = await IdleSpriteCache.frames(for: character)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func companion(_ motion: IdleMotion) -> some View {
        let frame = IdleCompanionLayout.frame(pill: pill, screen: screen,
                                               readoutCenterX: readoutCenterX, travel: motion.travel)
        return IdleCharacterDrawing(character: character, motion: motion)
            .position(x: frame.midX, y: frame.midY)
    }
}

private struct IdleSpritePlayer: NSViewRepresentable {
    let sprites: IdleSprites
    let mode: CharacterIdleMode
    let distance: CGFloat

    func makeNSView(context: Context) -> IdleSpriteView { IdleSpriteView() }

    func updateNSView(_ view: IdleSpriteView, context: Context) {
        view.play(sprites: sprites, mode: mode, distance: distance)
    }

    static func dismantleNSView(_ view: IdleSpriteView, coordinator: ()) {
        view.stop()
    }
}

@MainActor
private final class IdleSpriteView: NSView {
    private let sprite = CALayer()
    private var identity: CGImage?
    private var mode: CharacterIdleMode = .off
    private var distance: CGFloat = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        sprite.contentsScale = 2
        sprite.contentsGravity = .resizeAspect
        layer?.addSublayer(sprite)
        setAccessibilityElement(false)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        sprite.frame = bounds
        CATransaction.commit()
    }

    func stop() { sprite.removeAllAnimations() }

    func play(sprites: IdleSprites, mode: CharacterIdleMode, distance: CGFloat) {
        guard identity !== sprites.calm[0] || self.mode != mode || self.distance != distance else { return }
        identity = sprites.calm[0]
        self.mode = mode
        self.distance = distance
        stop()
        sprite.contents = sprites.calm[0]
        guard mode != .off else { return }

        let duration = mode == .stroll ? 32.0 : 12.0
        let count = mode == .stroll ? 384 : 48
        let contents = CAKeyframeAnimation(keyPath: "contents")
        contents.values = (0...count).map { index in
            let time = Double(index % count) / Double(count) * duration
            return sprites.image(time: time, motion: .sample(time: time, mode: mode))
        }
        contents.keyTimes = (0...count).map { NSNumber(value: Double($0) / Double(count)) }
        contents.calculationMode = .discrete
        contents.duration = duration
        contents.repeatCount = .infinity
        sprite.add(contents, forKey: "idleFrames")

        if mode == .stroll, distance > 0 {
            let walk = CAKeyframeAnimation(keyPath: "transform.translation.x")
            walk.values = (0...count).map { index in
                let time = Double(index % count) / Double(count) * duration
                return IdleMotion.sample(time: time, mode: mode).travel * Double(distance)
            }
            walk.keyTimes = contents.keyTimes
            walk.duration = duration
            walk.repeatCount = .infinity
            sprite.add(walk, forKey: "idleWalk")
        }
    }
}

/// Shared only in memory. Turning the feature off never creates images or a clock.
/// Calm needs four distinct poses per second; walking uses a short gait library.
/// Six complete sets occupy roughly 12 MB at Retina resolution.
@MainActor
struct IdleSprites {
    let calm: [CGImage]
    let walking: [CGImage]

    func image(time: Double, motion: IdleMotion) -> CGImage {
        if abs(motion.step) > 0.04 {
            let index = Int(((motion.step + 1) * 10).rounded())
            return walking[min(walking.count - 1, max(0, index))]
        }
        let index = Int(max(0, time).truncatingRemainder(dividingBy: 12) * 4)
        return calm[min(calm.count - 1, index)]
    }
}

@MainActor
enum IdleSpriteCache {
    private static var cache: [PomodoroCharacter: IdleSprites] = [:]

    static func frames(for character: PomodoroCharacter) async -> IdleSprites? {
        if let frames = cache[character] { return frames }
        var calm: [CGImage] = []
        var walking: [CGImage] = []
        for index in 0..<69 {
            guard !Task.isCancelled else { return nil }
            var motion = IdleMotion()
            if index < 48 {
                motion = .sample(time: Double(index) / 4, mode: .calm)
            } else {
                motion.step = Double(index - 48) / 10 - 1
            }
            let renderer = ImageRenderer(content: IdleCharacterDrawing(character: character, motion: motion))
            renderer.scale = 2
            guard let image = renderer.cgImage else { return nil }
            if index < 48 { calm.append(image) } else { walking.append(image) }
            // Populate cooperatively: dragging and buttons remain responsive while
            // a character's frames are rendered for the first time this launch.
            await Task.yield()
        }
        let frames = IdleSprites(calm: calm, walking: walking)
        cache[character] = frames
        return frames
    }
}
