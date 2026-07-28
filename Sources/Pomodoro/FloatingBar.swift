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

    /// The collapsed form: a bare ring, concentric with the pill.
    ///
    /// Centred rather than aligned to an edge for two reasons that both pay off
    /// elsewhere — the pill is already placed by its midpoint, so the frame can
    /// change without repositioning anything; and `StagePlacement` anchors the
    /// character to `pillFrame.midX`, so the character rises from the same point
    /// whichever form the bar is in.
    static let compactSize = NSSize(width: 44, height: 44)

    static var compactFrame: CGRect {
        CGRect(
            x: pillFrame.midX - compactSize.width / 2,
            y: pillFrame.midY - compactSize.height / 2,
            width: compactSize.width,
            height: compactSize.height
        )
    }

    /// How long the two forms take to swap. One constant, shared by the animation,
    /// by the delay before the hit rect narrows, and by the delay before a character
    /// is cued — they have to agree or a click lands in the gap.
    static let morphDuration: Double = 0.3

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

    /// 22 on a 44pt box is a circle, so one shape serves both forms and the radius
    /// simply animates between them.
    private var shape: RoundedRectangle {
        RoundedRectangle(
            cornerRadius: isCompact ? FloatingBar.compactSize.height / 2 : 15,
            style: .continuous
        )
    }

    private var pillSize: CGSize {
        isCompact
            ? CGSize(width: FloatingBar.compactSize.width, height: FloatingBar.compactSize.height)
            : CGSize(width: FloatingBar.size.width, height: FloatingBar.size.height)
    }

    /// Under Reduce Motion the box does not travel — it swaps, and only the contents
    /// cross-fade. A hair above zero rather than `nil` so the content transitions
    /// still have a parent animation to run inside.
    private var morph: Animation {
        reduceMotion ? .linear(duration: 0.01) : .smooth(duration: FloatingBar.morphDuration)
    }

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
        HStack(spacing: 10) {
            phaseRing

            if !isCompact {
                readout
                    .transition(.opacity.animation(.easeOut(duration: reduceMotion ? 0.2 : 0.12)))
                Spacer(minLength: 4)
                controls
                    .transition(.opacity.animation(.easeOut(duration: reduceMotion ? 0.2 : 0.12)))
            }
        }
        .padding(.leading, isCompact ? 0 : 11)
        .padding(.trailing, isCompact ? 0 : 10)
        .frame(width: pillSize.width, height: pillSize.height)
        // Clipped for the same reason the wash below is: mid-morph the contents are
        // briefly wider than the frame, and an unclipped overflow leaves the glass
        // covering only part of the pill.
        .clipShape(shape)
        // Order matters: the wash is clipped to the pill shape *before* the glass
        // goes over it. Backgrounding an unclipped gradient is what left a dark
        // rectangle hanging off the right-hand side.
        .background {
            Theme.backdrop(for: controller.phase)
                .opacity(controller.isRunning ? 0.85 : 0.45)
                .clipShape(shape)
                .animation(.smooth(duration: 0.5), value: controller.phase)
                .animation(.smooth(duration: 0.3), value: controller.isRunning)
        }
        .glassPanel(in: shape)
        .opacity(hovering ? 1 : 0.92)
        .scaleEffect(hovering ? 1.0 : 0.99, anchor: .center)
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
                .stroke(.primary.opacity(0.14), lineWidth: isCompact ? 3 : 2.5)

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
                    style: StrokeStyle(lineWidth: isCompact ? 3 : 2.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .opacity(controller.progress > 0.005 ? 1 : 0)
                .animation(.smooth(duration: 0.6), value: controller.progress)

            Image(systemName: Theme.symbol(for: controller.phase))
                .font(.system(size: isCompact ? 14 : 10, weight: .semibold))
                .foregroundStyle(tint)
                .contentTransition(.symbolEffect(.replace))
                // A slow breath while running — opacity only. An earlier version
                // pulsed a coloured shadow, which at this size read as a smudge.
                .opacity(controller.isRunning ? (pulse ? 1.0 : 0.55) : 0.75)
        }
        .frame(width: isCompact ? 40 : 28, height: isCompact ? 40 : 28)
        .animation(.smooth(duration: 0.4), value: controller.phase)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
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
        .animation(.smooth(duration: 0.28), value: hovering)
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
