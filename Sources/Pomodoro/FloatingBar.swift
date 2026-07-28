import AppKit
import os
import PomodoroCore
import PomodoroUI
import SwiftUI

/// The always-on-top countdown pill.
///
/// An `NSPanel` rather than an `NSWindow`: a non-activating panel can be clicked
/// without stealing focus from whatever you are working in, and combined with
/// `.floating` level plus `[.canJoinAllSpaces, .fullScreenAuxiliary]` it stays
/// visible across Spaces and over fullscreen apps — which a normal window cannot do.
///
/// The contents are SwiftUI so the pill and the widget share one design layer and
/// pick up Liquid Glass from the same code path.
@MainActor
final class FloatingBar: NSPanel {

    /// Sized to hold the hover-revealed controls without reflowing.
    ///
    /// This has to fit the *widest* state: 12 + glyph 18 + 10 + readout 72 + gap +
    /// three 26–28pt controls with 5pt gaps + 8. Undersize it and the content
    /// silently overflows the frame, leaving the glass covering only part of the
    /// pill while the buttons sit on bare window.
    static let size = NSSize(width: 236, height: 46)

    /// Transparent room on every side, for the character to emerge into and for the
    /// pill's 15% reaction to grow into without being clipped by its own window.
    static let margin: CGFloat = CharacterStage.margin

    static var panelSize: NSSize {
        NSSize(width: size.width + margin * 2, height: size.height + margin * 2)
    }

    /// The pill's rect inside the panel, in SwiftUI's top-left coordinate space.
    static var pillFrame: CGRect {
        CGRect(x: margin, y: margin, width: size.width, height: size.height)
    }

    /// The collapsed form: a circle concentric with the pill.
    ///
    /// Concentric so that the pill grows symmetrically out of it — which is what
    /// leaves the pointer in the middle of the open bar. Whatever the cursor was
    /// resting on to trigger the expansion becomes the centre of what it expands
    /// into, so the pointer never ends up sitting on a control that swept underneath
    /// it, and every control is an equally short trip away.
    ///
    /// Square on the pill's own height, so the circle is exactly as tall as the bar
    /// it comes from. That also keeps this rect symmetric about the panel's centre
    /// in both axes, which is what lets `hitTest` ignore whether its view is flipped.
    static let compactSize = NSSize(width: 46, height: 46)

    static var compactFrame: CGRect {
        CGRect(
            x: pillFrame.midX - compactSize.width / 2,
            y: pillFrame.midY - compactSize.height / 2,
            width: compactSize.width,
            height: compactSize.height
        )
    }

    /// How long the two forms take to swap.
    ///
    /// Shared by the delay before the hit rect narrows and by the delay before a
    /// character is cued — they have to agree with the animation or a click lands in
    /// the gap. A spring has no exact duration, so this is its settling time rounded
    /// up: erring long is safe, since it only means the target stays large a moment
    /// past the animation rather than shrinking out from under a click.
    static let morphDuration: Double = 0.65

    /// Drives the character; owned here so the panel can hand it the same instance
    /// the SwiftUI tree observes.
    let stage = CharacterStageModel()

    /// Which form the bar is in, and the timers that decide.
    let presentation = BarPresentationModel()

    /// The pill's current hit rect, shared with AppKit hit testing.
    let geometry = BarGeometry()

    init(controller: TimerController, settings: PomodoroSettings) {
        super.init(
            contentRect: NSRect(origin: .zero, size: Self.panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        backgroundColor = .clear
        isOpaque = false
        // Liquid Glass draws its own shadow and edge treatment; a second AppKit
        // shadow underneath it reads as a double border.
        hasShadow = false
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        isExcludedFromWindowsMenu = true

        let host = FloatingBarHostingView(rootView: FloatingBarView(
            controller: controller,
            stage: stage,
            presentation: presentation,
            geometry: geometry,
            onCollapsed: { [weak self] in self?.reconcileHover() }
        ))
        host.geometry = geometry
        host.frame = NSRect(origin: .zero, size: Self.panelSize)
        contentView = host

        restorePosition(settings: settings)
    }

    /// Borderless panels aren't key by default, which would stop the buttons
    /// showing hover state. `.nonactivatingPanel` means this still doesn't pull
    /// focus away from the app you're working in.
    override var canBecomeKey: Bool { true }

    // MARK: - Position

    /// The stored origin is the *pill's*, not the panel's.
    ///
    /// They used to be the same thing. Now that the panel carries a transparent
    /// margin they differ, and storing the pill's position means an existing dragged
    /// position keeps meaning what it always meant — nothing jumps when this ships.
    private func restorePosition(settings: PomodoroSettings) {
        if let origin = settings.floatingBarOrigin,
           screenContains(NSPoint(x: origin.x, y: origin.y)) {
            setPillOrigin(NSPoint(x: origin.x, y: origin.y))
        } else if let visible = NSScreen.main?.visibleFrame {
            // Default: upper-right, but left far enough below the menu bar that the
            // character has room to rise from the top. Tucking it against the menu
            // bar the way it used to would leave the top-reveal with nowhere to go.
            setPillOrigin(NSPoint(
                x: visible.maxX - Self.size.width - 24,
                y: visible.maxY - Self.size.height - Self.margin - 24
            ))
        }
    }

    private func setPillOrigin(_ point: NSPoint) {
        setFrameOrigin(NSPoint(x: point.x - Self.margin, y: point.y - Self.margin))
    }

    var pillOrigin: NSPoint {
        NSPoint(x: frame.origin.x + Self.margin, y: frame.origin.y + Self.margin)
    }

    /// The pill's rect on screen, in top-left coordinates, for edge resolution.
    var pillScreenFrameFlipped: CGRect {
        let screenHeight = NSScreen.main?.frame.height ?? 0
        return CGRect(
            x: pillOrigin.x,
            y: screenHeight - pillOrigin.y - Self.size.height,
            width: Self.size.width,
            height: Self.size.height
        )
    }

    /// Guard against restoring onto a display that is no longer connected.
    private func screenContains(_ point: NSPoint) -> Bool {
        NSScreen.screens.contains { $0.frame.insetBy(dx: -1, dy: -1).contains(point) }
    }

    func persistPosition(to settings: PomodoroSettings) {
        settings.floatingBarOrigin = (x: Double(pillOrigin.x), y: Double(pillOrigin.y))
    }

    /// Re-derive hover from where the cursor actually is.
    ///
    /// When the pill collapses it moves out from under a stationary cursor. The view
    /// moved, the mouse did not, and AppKit does not reliably deliver `mouseExited`
    /// for that — so SwiftUI's `onHover` can be left stuck true with the cursor
    /// nowhere near the ring. The mirror case is a cursor already parked on the bar
    /// when the timer starts, where it can be left stuck false.
    func reconcileHover() {
        let mouse = NSEvent.mouseLocation
        let local = NSPoint(x: mouse.x - frame.minX, y: mouse.y - frame.minY)
        presentation.setHovering(geometry.hitFrame.contains(local))
    }
}

// MARK: - Live geometry

/// The pill's hit rect right now.
///
/// Deliberately a plain class rather than `@Observable`: nothing observes it. It
/// exists so `FloatingBarHostingView.hitTest` — which runs in AppKit, outside any
/// SwiftUI update — can ask what shape is currently drawn.
///
/// The invariant its writer must keep: widen it the moment expansion begins, narrow
/// it only once the collapse has finished. Always the larger of the two while
/// anything is moving, so no click can fall into the gap between the animation and
/// the target.
@MainActor
final class BarGeometry {
    /// In the panel's own coordinates. Starts expanded, which is the bar's state
    /// before anything has had a chance to collapse it.
    var hitFrame: CGRect = FloatingBar.pillFrame
}

// MARK: - Contents

/// Observes `TimerController` directly, so the panel redraws itself and the app
/// delegate doesn't have to push updates into it.
///
/// At rest the pill is deliberately quiet — a glyph, a time, a progress rail. The
/// secondary controls only materialise on hover, because a bar that lives on top of
/// everything you do all day earns its place by being ignorable.
struct FloatingBarView: View {

    @Bindable var controller: TimerController
    @Bindable var stage: CharacterStageModel
    @Bindable var presentation: BarPresentationModel
    let geometry: BarGeometry
    /// Called once a collapse has finished, so the panel can re-derive hover from
    /// the cursor's real position.
    let onCollapsed: () -> Void

    @State private var pulse = false
    @Namespace private var glass

    private var tint: Color { Theme.tint(for: controller.phase) }

    /// Debounced, so the controls linger a moment after the cursor leaves rather
    /// than snapping away from under a hand that is still moving.
    private var hovering: Bool { presentation.policy.hovering }

    private var isCompact: Bool { presentation.mode == .compact }

    private var reduceMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    /// 23 on a 46pt box is a circle, so one shape serves both forms and the radius
    /// simply animates between them.
    private var shape: RoundedRectangle {
        RoundedRectangle(
            cornerRadius: isCompact ? FloatingBar.compactSize.height / 2 : 15,
            style: .continuous
        )
    }

    /// Leading inset, chosen so the ring lands dead centre of the compact circle
    /// once it has travelled: 9 + 28/2 == 23 == 46/2.
    private static let leadingPadding: CGFloat = 9

    /// The ring's diameter in the open pill.
    ///
    /// Note what `leadingPadding + ringSize / 2` comes to: 9 + 14 == 23, which is
    /// exactly half of the 46pt compact circle. Pin the content to the box's leading
    /// edge and the ring is dead centre of that circle for free — no offset, no
    /// correction, nothing to keep in sync if either number is ever retuned.
    private static let ringSize: CGFloat = 28

    /// The ring grows to fill the compact circle instead of floating inside it.
    ///
    /// Without this there are two circles, not one: the glass disc — which is really
    /// the pill closed down to 46pt — and a 28pt ring sitting in the middle of it at
    /// 61% of its width. On opening, the disc becomes the whole pill while the ring
    /// stays the size it was, so the object the eye was tracking has nothing to grow
    /// into. Letting the ring own the circle and shrink back into its slot is what
    /// makes the two states one object.
    ///
    /// A `scaleEffect`, deliberately, not a frame: the ring sits inside the layout
    /// the clip is revealing, and resizing it there would re-run that layout on every
    /// frame — the exact churn this whole design exists to avoid.
    private static let compactRingScale: CGFloat = 36 / ringSize

    /// The only dimension that travels. Height is shared by both forms, so one
    /// animating number and one offset carry the whole change.
    private var pillWidth: CGFloat {
        isCompact ? FloatingBar.compactSize.width : FloatingBar.size.width
    }

    /// Under Reduce Motion the box does not travel — it swaps, and only the contents
    /// cross-fade.
    ///
    /// A spring rather than a timing curve, and a slower one than this started out.
    /// Springs are the reason a flick that reverses mid-flight does not stutter: they
    /// carry their velocity through the reversal instead of restarting from zero, so
    /// an interrupted open turns into a close rather than snapping and replaying.
    /// The damping is just under critical, which gives the settle its weight without
    /// letting the pill visibly bounce.
    private var morph: Animation {
        reduceMotion
            ? .linear(duration: 0.01)
            : .spring(response: 0.58, dampingFraction: 0.88)
    }

    /// The readout and controls fade on the morph's own curve, just quicker.
    ///
    /// They cannot simply share `morph`: at the halfway point the box is half open
    /// and the text would be at half opacity, showing through a circle far too small
    /// to hold it. So it is the same curve, run at roughly half the length, with no
    /// delay in either direction — one motion that resolves early rather than a
    /// second motion that starts late.
    ///
    /// It used to carry an 0.08s delay on the way open. Together with `morph` and
    /// with `controls`' own 0.28s insertion that made three different start and end
    /// times for one gesture, which is what read as mechanical.
    private var contentFade: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .smooth(duration: 0.32)
    }

    /// Whether the pill still does its little hover lift.
    ///
    /// Off once compact mode is on, because there the opening *is* the response to
    /// the pointer. Leaving it in put a 0.22s scale and opacity on the same glass
    /// surface as a 0.3s width change: two curves of different lengths, one of them
    /// forcing the glass to resample every frame, finishing at different moments.
    /// That was most of the roughness.
    private var hoverFlourish: Bool { !presentation.policy.compactEnabled }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Drawn first so the pill occludes it — the character rises from behind.
            CharacterStage(
                character: stage.character,
                cue: stage.cue,
                generation: stage.generation,
                foreground: stage.foreground,
                edge: stage.edge,
                pillFrame: FloatingBar.pillFrame
            )
            // Normally behind the pill; in front for the cue that steps forward.
            .zIndex(stage.foreground ? 2 : 0)

            pill
                .scaleEffect(stage.pillScale, anchor: .center)
                .position(x: FloatingBar.pillFrame.midX, y: FloatingBar.pillFrame.midY)
                .zIndex(1)
        }
        .frame(width: FloatingBar.panelSize.width, height: FloatingBar.panelSize.height)
        .onChange(of: presentation.mode) { _, mode in
            guard mode == .compact else {
                // Widen the moment expansion begins, so a click during the morph
                // still lands.
                geometry.hitFrame = FloatingBar.pillFrame
                return
            }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(FloatingBar.morphDuration))
                // A hover during the collapse can have already reversed it.
                guard presentation.mode == .compact else { return }
                geometry.hitFrame = FloatingBar.compactFrame
                onCollapsed()
            }
        }
    }

    private var pill: some View {
        // One layout, held at full width in both forms, revealed by the growing box
        // rather than re-flowed into it.
        //
        // Inserting the readout and controls on the way out is what made the first
        // attempt read as a replacement: SwiftUI re-ran the layout, so everything
        // arrived at once in a box that was still moving. Nothing here is ever laid
        // out twice — only the clip and one offset move.
        HStack(spacing: 10) {
            phaseRing
                // Grows to own the circle. Visual only — a frame change here would
                // re-run the layout the clip is revealing.
                .scaleEffect(isCompact ? Self.compactRingScale : 1)

            Group {
                readout
                Spacer(minLength: 4)
                controls
            }
            .opacity(isCompact ? 0 : 1)
            .animation(contentFade, value: isCompact)
        }
        .padding(.leading, Self.leadingPadding)
        .padding(.trailing, 10)
        .frame(width: FloatingBar.size.width, height: FloatingBar.size.height)
        // The box is centred on screen — `.position` below pins it to the panel's
        // midpoint — so both its edges travel outward equally and the pointer that
        // opened it ends up in the middle of what opened.
        //
        // The *content* rides the leading edge rather than being centred in the box.
        // That is the difference between one motion and two: centred content left
        // only the ring free to slide, so a symmetric box had a single element
        // tracking leftward across it, and the eye read the whole thing as opening
        // to the left. Pinned to the edge, ring and readout and controls all travel
        // together as one block that the opening carries with it.
        .frame(width: pillWidth, height: FloatingBar.size.height, alignment: .leading)
        // The wash goes on *before* the clip rather than carrying a clip of its own.
        //
        // It still ends up cut to the pill — one `clipShape` below now takes the
        // content and the wash together. That is one fewer animated path per frame:
        // this shape has a continuous corner radius interpolating 23 -> 15, and it
        // was being rebuilt three times a frame (here, the clip, and the glass).
        .background {
            Theme.backdrop(for: controller.phase)
                .opacity(controller.isRunning ? 0.85 : 0.45)
                .animation(.smooth(duration: 0.5), value: controller.phase)
                .animation(.smooth(duration: 0.3), value: controller.isRunning)
        }
        // The content is wider than the box for the whole of the morph; this is what
        // turns the width change into a reveal.
        .clipShape(shape)
        .glassPanel(in: shape)
        .opacity(hoverFlourish && !hovering ? 0.92 : 1)
        .scaleEffect(hoverFlourish && !hovering ? 0.99 : 1.0, anchor: .center)
        .onHover { presentation.setHovering($0) }
        .animation(.smooth(duration: 0.22), value: hovering)
        .animation(morph, value: isCompact)
    }

    // MARK: - Pieces

    /// Progress wraps the phase glyph instead of running along the pill's bottom
    /// edge.
    ///
    /// A straight rail inside a 15pt-radius pill fights the rounded corners: it gets
    /// clipped at both ends, and at low progress the few pixels of fill land in the
    /// corner and read as a stray dot rather than a bar. A ring has no such conflict,
    /// is legible from 0% to 100%, and matches the dial the widget and the menu
    /// header already use.
    private var phaseRing: some View {
        ZStack {
            Circle()
                .stroke(.primary.opacity(0.14), lineWidth: 2.5)

            // Nothing is drawn below half a percent: a round line cap on a
            // zero-length arc still paints a dot at 12 o'clock, which reads as a
            // speck of dirt on the glass rather than "no progress yet".
            Circle()
                .trim(from: 0, to: controller.progress)
                .stroke(
                    LinearGradient(
                        colors: [Theme.highlight(for: controller.phase), tint],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .opacity(controller.progress > 0.005 ? 1 : 0)
                .animation(.smooth(duration: 0.6), value: controller.progress)

            Image(systemName: Theme.symbol(for: controller.phase))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(tint)
                .contentTransition(.symbolEffect(.replace))
                // A slow breath while running — opacity only. An earlier version
                // pulsed a coloured shadow, which at this size read as a smudge.
                .opacity(controller.isRunning ? (pulse ? 1.0 : 0.55) : 0.75)
        }
        // The layout size is fixed in both forms; the compact growth is a scale on
        // top, applied at the call site so nothing here re-lays out.
        .frame(width: Self.ringSize, height: Self.ringSize)
        .animation(.smooth(duration: 0.4), value: controller.phase)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        // Compact strips the countdown and the phase label off the screen. VoiceOver
        // never sees that form — the policy refuses to collapse while it is running —
        // but the tooltip is the sighted equivalent, and it costs nothing.
        .help(isCompact ? "\(controller.phase.title) — \(controller.displayTime) left" : "")
        .accessibilityLabel("\(controller.phase.title), \(controller.displayTime) remaining")
    }

    private var readout: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(controller.displayTime)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .monospacedDigit()
                // Digits roll rather than cut, which is what keeps a monospaced
                // countdown from looking like a flickering LED.
                .contentTransition(.numericText(countsDown: true))
                .animation(.smooth(duration: 0.28), value: controller.remainingSeconds)
                .foregroundStyle(controller.isRunning ? .primary : .secondary)
                .fixedSize()

            Text(controller.isRunning ? controller.phase.title : "Paused")
                .font(.system(size: 8, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(controller.isRunning ? tint : .secondary)
                .contentTransition(.opacity)
        }
        .frame(width: 74, alignment: .leading)
        .padding(.bottom, 3)
    }

    /// The secondary actions slide out from underneath the play/pause button and
    /// tuck back under it on exit — `zIndex` keeps them behind it the whole way, so
    /// they read as emerging from the primary control rather than shrinking into a
    /// dot beside it.
    ///
    /// Inserted and removed rather than parked at zero opacity, deliberately.
    ///
    /// Mounting them permanently and hiding them with `.opacity(0)` does not work:
    /// `glassGroup` is a `GlassEffectContainer`, and it harvests the shapes tagged by
    /// `glassMorphID` and draws them itself, so an opacity applied outside the glass
    /// effect never reaches them. What you get is the reset and skip glyphs stacked
    /// on top of the play button and its tint disc reduced to a ring.
    ///
    /// Insertion is also what the container is *for* — `glassMorphID` exists so these
    /// morph out of their neighbours instead of popping. Working with that costs a
    /// transition that cannot reverse mid-flight, which is what the hover debounce is
    /// there to keep a flicked cursor from ever reaching.
    private var controls: some View {
        HStack(spacing: 5) {
            if hovering {
                control("arrow.counterclockwise", label: "Reset", id: "reset") { controller.reset() }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .zIndex(0)
                control("forward.end.fill", label: "Skip", id: "skip") { controller.skip() }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .zIndex(1)
            }

            control(
                controller.isRunning ? "pause.fill" : "play.fill",
                label: controller.isRunning ? "Pause" : "Start",
                id: "toggle",
                tint: tint,
                size: 28
            ) { controller.toggle() }
            .zIndex(2)
        }
        .glassGroup(spacing: 5)
        // The same spring as the box, so hover drives one motion rather than two of
        // different lengths.
        .animation(morph, value: hovering)
    }


    /// Secondary actions get a glass circle; the primary one gets a solid tinted
    /// disc. Glass on glass is nearly invisible — the play button was reading as a
    /// bare triangle floating on the pill, with nothing to say it was a target.
    private func control(
        _ symbol: String,
        label: String,
        id: String,
        tint: Color? = nil,
        size: CGFloat = 26,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(tint == nil ? AnyShapeStyle(.secondary) : AnyShapeStyle(.white))
                .contentTransition(.symbolEffect(.replace))
                .modifier(ControlSurface(tint: tint, size: size))
        }
        .buttonStyle(AdaptiveGlassButtonStyle())
        .glassMorphID(id, in: glass)
        .accessibilityLabel(label)
    }
}

/// The circular surface behind a pill control.
private struct ControlSurface: ViewModifier {
    let tint: Color?
    let size: CGFloat

    func body(content: Content) -> some View {
        if let tint {
            content
                .frame(width: size, height: size)
                .background {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [tint.opacity(0.95), tint],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: tint.opacity(0.45), radius: 4, y: 1)
                }
                .contentShape(Circle())
        } else {
            content.glassControl(size: size)
        }
    }
}


// MARK: - Hit testing

/// Refuses clicks that land in the transparent margin.
///
/// A borderless window still swallows every click inside its frame, so without this
/// the character's stage — four times the pill's area — would eat clicks meant for
/// whatever is behind it. Returning `nil` lets the event fall through to the app
/// underneath. It also confines window dragging to the pill, since background drags
/// begin with a hit test.
final class FloatingBarHostingView<Content: View>: NSHostingView<Content> {

    /// Assigned right after construction — `NSHostingView`'s designated initialiser
    /// takes only a root view, so this cannot be passed in.
    var geometry: BarGeometry?

    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        // Falls back to the full pill rather than to nothing: a missing geometry must
        // degrade to the old behaviour, not to a bar that ignores every click.
        //
        // Both forms are centred in the panel with equal margins, so their rects are
        // the same whether the view is flipped or not.
        let target = geometry?.hitFrame ?? FloatingBar.pillFrame
        guard target.contains(local) else { return nil }
        return super.hitTest(point)
    }
}
