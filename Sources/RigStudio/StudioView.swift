import PomodoroCore
import PomodoroUI
import SwiftUI

/// The authoring workbench.
///
/// Every performance in this app was written by typing angles into a Swift file and
/// waiting for a pomodoro phase to fire. That loop cannot produce good animation:
/// arcs, spacing and overlap are judged by eye on a scrubbable timeline, and there
/// was no timeline. This window is that timeline.
///
/// The three overlays are the ones that pay for themselves:
/// - **pivots** show where each joint actually ends up, which is how you catch a part
///   detaching from its parent;
/// - **onion skin** shows the pose slightly before and after now, which is how you
///   read spacing — evenly spaced ghosts mean linear, lifeless motion;
/// - **arc** draws the curve a joint traces across the whole performance, which is
///   how you catch a limb sweeping a dead mechanical circle.
struct StudioView: View {

    @State private var character: PomodoroCharacter = .samurai
    @State private var cue: CharacterCue = .focusStart
    @State private var time: Double = 0
    @State private var playing = true
    @State private var speed: Double = 1
    @State private var zoom: Double = 2.4

    @State private var showPivots = false
    @State private var showOnion = false
    @State private var showArc = false
    @State private var showGround = true
    @State private var arcPart: String = ""

    private let tick = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    private var duration: Double { Facade.duration(character, cue) }

    var body: some View {
        HSplitView {
            controls
                .frame(minWidth: 300, idealWidth: 320, maxWidth: 400)
            stage
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 900, minHeight: 640)
        .onReceive(tick) { _ in
            guard playing, duration > 0 else { return }
            time += speed / 60.0
            if time > duration { time = 0 }          // loop, so a beat can be watched repeatedly
        }
        .onChange(of: character) { _, _ in resetForNewClip() }
        .onChange(of: cue) { _, _ in time = 0 }
    }

    private func resetForNewClip() {
        time = 0
        arcPart = Facade.partNames(character).first ?? ""
    }

    // MARK: - Controls

    private var controls: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                section("Character") {
                    Picker("", selection: $character) {
                        ForEach(PomodoroCharacter.allCases.filter { $0 != .none }) {
                            Text($0.displayName).tag($0)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.radioGroup)
                }

                section("Performance") {
                    Picker("", selection: $cue) {
                        ForEach(CharacterCue.allCases, id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.radioGroup)
                }

                section("Transport") {
                    transport
                }

                section("Overlays") {
                    Toggle("Joint pivots", isOn: $showPivots)
                    Toggle("Onion skin (±80ms)", isOn: $showOnion)
                    Toggle("Ground line", isOn: $showGround)
                    Toggle("Arc trace", isOn: $showArc)
                    if showArc {
                        Picker("Joint", selection: $arcPart) {
                            ForEach(Facade.partNames(character), id: \.self) {
                                Text($0).tag($0)
                            }
                        }
                    }
                    HStack {
                        Text("Zoom").font(.caption)
                        Slider(value: $zoom, in: 1...4)
                    }
                }

                section("Joint angles at \(fmt(time))s") {
                    AngleReadout(character: character, cue: cue, time: time)
                }
            }
            .padding(16)
        }
    }

    private var transport: some View {
        VStack(alignment: .leading, spacing: 8) {
            Slider(value: $time, in: 0...max(duration, 0.001))

            HStack(spacing: 10) {
                Button(playing ? "Pause" : "Play") { playing.toggle() }
                    .keyboardShortcut(.space, modifiers: [])
                Button("◀") { step(-1) }.help("Back one frame")
                Button("▶") { step(1) }.help("Forward one frame")
                Spacer()
                Text("\(fmt(time)) / \(fmt(duration))s")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Speed").font(.caption)
                Slider(value: $speed, in: 0.1...1.5)
                Text("\(speed, format: .number.precision(.fractionLength(2)))×")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Text("Frame \(Int((time * 60).rounded())) of \(Int((duration * 60).rounded())) @60fps")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
    }

    private func step(_ frames: Int) {
        playing = false
        time = min(max(0, time + Double(frames) / 60.0), duration)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func fmt(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    // MARK: - Stage

    @ViewBuilder
    private var stage: some View {
        ZStack {
            // A mid grey rather than the app's dark chrome: outlines are near-black
            // and light fills are near-white, and both have to stay legible.
            Color(nsColor: .init(white: 0.42, alpha: 1)).ignoresSafeArea()

            Group {
                switch character {
                case .samurai: rig(SamuraiSubject.self)
                case .ninja: rig(NinjaSubject.self)
                case .general: rig(GeneralSubject.self)
                case .rabbit: rig(RabbitSubject.self)
                case .animeGirl: rig(AnimeGirlSubject.self)
                case .hancock: rig(HancockSubject.self)
                case .none: EmptyView()
                }
            }
            .scaleEffect(zoom)
        }
    }

    private func rig<S: RigSubject>(_ subject: S.Type) -> some View {
        RigStage(
            subject: subject,
            cue: cue,
            time: time,
            showPivots: showPivots,
            showOnion: showOnion,
            showGround: showGround,
            showArc: showArc,
            arcPart: arcPart
        )
    }
}

/// Draws one character at one instant, plus the overlays.
struct RigStage<S: RigSubject>: View {

    let subject: S.Type
    let cue: CharacterCue
    let time: Double
    let showPivots: Bool
    let showOnion: Bool
    let showGround: Bool
    let showArc: Bool
    let arcPart: String

    /// The design-space line the art is authored against: everything below it is
    /// meant to be hidden behind the pill.
    private static var groundY: Double { 196 }

    var body: some View {
        let duration = S.duration(for: cue)
        let pose = S.pose(for: cue, at: time)
        // Resolved to plain poses here rather than handed to the builder as a
        // timeline: `KeyframeTimeline` is not `Sendable`, a `Pose` is.
        let past = time - 0.08 >= 0 ? S.pose(for: cue, at: time - 0.08) : nil
        let future = time + 0.08 <= duration ? S.pose(for: cue, at: time + 0.08) : nil

        ZStack(alignment: .topLeading) {
            if showGround {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: Self.groundY))
                    path.addLine(to: CGPoint(x: S.canvas.width, y: Self.groundY))
                }
                .stroke(Color.white.opacity(0.5), style: .init(lineWidth: 0.6, dash: [4, 3]))
            }

            if showOnion {
                // Past tinted cool, future warm, so the direction of travel reads at
                // a glance. Even spacing between the three silhouettes means linear
                // motion — the thing to hunt for.
                ghost(past, tint: .cyan)
                ghost(future, tint: .orange)
            }

            S.draw(pose)

            if showArc, let part = S.parts.first(where: { String(describing: $0) == arcPart }) {
                ArcTrace(points: S.arc(of: part, cue: cue))
                let head = S.worldPivot(of: part, in: pose)
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 4, height: 4)
                    .position(head)
            }

            if showPivots {
                ForEach(Array(S.parts.enumerated()), id: \.offset) { _, part in
                    let point = S.worldPivot(of: part, in: pose)
                    Circle()
                        .strokeBorder(Color.red.opacity(0.9), lineWidth: 0.7)
                        .frame(width: 5, height: 5)
                        .position(point)
                }
            }
        }
        .frame(width: S.canvas.width, height: S.canvas.height, alignment: .topLeading)
    }

    @ViewBuilder
    private func ghost(_ pose: S.Pose?, tint: Color) -> some View {
        if let pose {
            S.draw(pose)
                .opacity(0.28)
                .colorMultiply(tint)
        }
    }
}

/// The curve a joint traces, drawn as a fading trail.
struct ArcTrace: View {
    let points: [CGPoint]

    var body: some View {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            for point in points.dropFirst() { path.addLine(to: point) }
        }
        .stroke(Color.yellow.opacity(0.85), style: .init(lineWidth: 0.8, lineCap: .round, lineJoin: .round))
    }
}

/// Live joint angles, so a number in the source can be matched to what's on screen.
struct AngleReadout: View {
    let character: PomodoroCharacter
    let cue: CharacterCue
    let time: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(Facade.angles(character, cue, time), id: \.name) { row in
                HStack(spacing: 6) {
                    Text(row.name)
                        .font(.system(size: 10, design: .monospaced))
                        .frame(width: 150, alignment: .leading)
                    Text(String(format: "%7.1f°", row.degrees))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(row.degrees == 0 ? .tertiary : .primary)
                }
            }
        }
    }
}

/// Non-generic access to the five subjects.
///
/// The sidebar needs durations, joint names and angles before it knows which
/// concrete `RigSubject` it is talking about, and a `switch` returning plain data is
/// less trouble than threading an existential through the whole view tree.
enum Facade {

    struct Angle: Hashable { let name: String; let degrees: Double }

    static func duration(_ character: PomodoroCharacter, _ cue: CharacterCue) -> Double {
        switch character {
        case .samurai: SamuraiSubject.duration(for: cue)
        case .ninja: NinjaSubject.duration(for: cue)
        case .general: GeneralSubject.duration(for: cue)
        case .rabbit: RabbitSubject.duration(for: cue)
        case .animeGirl: AnimeGirlSubject.duration(for: cue)
        case .hancock: HancockSubject.duration(for: cue)
        case .none: 0
        }
    }

    static func partNames(_ character: PomodoroCharacter) -> [String] {
        switch character {
        case .samurai: names(SamuraiSubject.self)
        case .ninja: names(NinjaSubject.self)
        case .general: names(GeneralSubject.self)
        case .rabbit: names(RabbitSubject.self)
        case .animeGirl: names(AnimeGirlSubject.self)
        case .hancock: names(HancockSubject.self)
        case .none: []
        }
    }

    static func angles(_ character: PomodoroCharacter, _ cue: CharacterCue, _ time: Double) -> [Angle] {
        switch character {
        case .samurai: angles(SamuraiSubject.self, cue, time)
        case .ninja: angles(NinjaSubject.self, cue, time)
        case .general: angles(GeneralSubject.self, cue, time)
        case .rabbit: angles(RabbitSubject.self, cue, time)
        case .animeGirl: angles(AnimeGirlSubject.self, cue, time)
        case .hancock: angles(HancockSubject.self, cue, time)
        case .none: []
        }
    }

    private static func names<S: RigSubject>(_ subject: S.Type) -> [String] {
        S.parts.map { String(describing: $0) }
    }

    private static func angles<S: RigSubject>(_ subject: S.Type, _ cue: CharacterCue, _ time: Double) -> [Angle] {
        let pose = S.pose(for: cue, at: time)
        return S.parts.map { Angle(name: String(describing: $0), degrees: S.angle(pose, $0)) }
    }
}
