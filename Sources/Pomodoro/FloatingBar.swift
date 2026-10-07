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

    /// Every horizontal measurement in the pill, in one place and derived from each
    /// other rather than each written down.
    ///
    /// They were separate constants with the totals worked out in prose comments, and
    /// the prose had already drifted from the numbers. The reason to compute instead
    /// is that three of these values have to agree exactly or the design breaks in a
    /// way that is easy to miss: the row must come to `width` with no slack, so
    /// nothing shifts when the box opens; `compactWidth` must fall one trailing inset
    /// past the play button, or the collapsed pill either cuts through it or leaves a
    /// gap where the skip button used to be; and `tuck` must park a secondary control
    /// squarely *under* the play button rather than merely near it, which is what
    /// sells it as emerging from underneath.
    enum Metrics {
        static let height: CGFloat = 46

        static let leading: CGFloat = 11
        static let trailing: CGFloat = 10

        static let ring: CGFloat = 28
        static let ringGap: CGFloat = 9
        static let readout: CGFloat = 74
        static let readoutGap: CGFloat = 12

        /// The play/pause button, larger than the rest because it is the one control
        /// that is always there.
        static let primary: CGFloat = 28
        static let secondary: CGFloat = 26
        static let controlGap: CGFloat = 6

        /// The play button's leading edge, measured from the pill's own.
        static let primaryX = leading + ring + ringGap + readout + readoutGap

        /// The leading edge of the nth secondary control, counting outward from the
        /// play button.
        static func secondaryX(_ index: Int) -> CGFloat {
            primaryX + primary + controlGap + CGFloat(index) * (secondary + controlGap)
        }

        /// How far back the nth secondary control sits when parked, so its leading
        /// edge lands on the play button's.
        static func tuck(_ index: Int) -> CGFloat { primaryX - secondaryX(index) }

        /// Two secondary controls and the trailing inset past them.
        static let width = secondaryX(1) + secondary + trailing

        /// The collapsed form ends one trailing inset past the play button, which
        /// leaves it with exactly the air it has in the open pill — so the short bar
        /// is a real end to the layout rather than a crop through it.
        static let compactWidth = primaryX + primary + trailing
    }

    /// Sized to hold the hover-revealed controls without reflowing.
    ///
    /// This has to fit the *widest* state. Undersize it and the content silently
    /// overflows the frame, leaving the glass covering only part of the pill while
    /// the buttons sit on bare window — so it is computed from the row rather than
    /// written down beside it.
    static let size = NSSize(width: Metrics.width, height: Metrics.height)

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

    /// The collapsed form: the ring, the countdown, and play/pause.
    ///
    /// It used to stop after the countdown, and that was the one real mistake in the
    /// compact bar. Pausing is the only thing anybody does to a running timer, and
    /// putting it behind the hover morph meant every pause cost a reach, then a wait
    /// for a button to arrive under a cursor that was already there. The button is now
    /// in both forms, in the same place in both, so the morph no longer gates anything
    /// anyone needs — it reveals reset and skip, which are genuinely occasional.
    ///
    /// Height is the pill's own, which keeps this rect symmetric about the panel's
    /// vertical centre — what lets `hitTest` ignore whether its view is flipped.
    static let compactSize = NSSize(width: Metrics.compactWidth, height: Metrics.height)

    /// Both forms share their leading edge, so the collapse withdraws the trailing
    /// edge and moves nothing else.
    static var compactFrame: CGRect {
        CGRect(
            x: pillFrame.minX,
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
    static let morphDuration: Double = 0.55

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
        // Above the menu bar, not merely above other apps.
        //
        // `.floating` is level 3 and the menu bar is 24, so a pill dragged to the top
        // of the screen used to slide *behind* the menu bar and vanish. Since the
        // whole point of this window is that it is always visible, the top strip has
        // to be usable like any other part of the screen. Open menus are level 101 and
        // still draw over it, so pulling down a menu is unaffected.
        level = .statusBar
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

    /// Let the pill go anywhere on any display, and clamp the *pill* rather than the
    /// panel.
    ///
    /// AppKit's default keeps a dragged window inside `visibleFrame`, which is the
    /// screen minus the menu bar and the Dock — that is what stopped the bar reaching
    /// the top edge, and no amount of raising the window level would have helped,
    /// because the frame was never being allowed up there in the first place.
    ///
    /// Two things make the replacement behave. It constrains the pill's rect, not the
    /// panel's: the panel carries a transparent `margin` on every side for the
    /// character to emerge into, so clamping the panel would leave the pill stranded
    /// `margin` points short of every edge with nothing visible in the gap. And it asks
    /// whether the pill touches *any* display rather than the one AppKit hands us, so a
    /// drag toward a second screen isn't clamped back onto the first — only a pill that
    /// has left every screen entirely gets pulled back, onto the nearest one.
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        let pill = NSRect(
            x: frameRect.minX + Self.margin,
            y: frameRect.minY + Self.margin,
            width: Self.size.width,
            height: Self.size.height
        )

        // Already somewhere on a display: nothing to correct, including the top strip
        // and the two thirds of the pill that may be hanging off the side.
        if NSScreen.screens.contains(where: { !$0.frame.intersection(pill).isEmpty }) {
            return frameRect
        }

        // Fully off every display. Come back to the *nearest* one — measured centre to
        // centre — rather than to whichever screen happens to be first in the list,
        // which on a stacked two-display setup would drag a pill flicked off the top
        // of the upper screen all the way down to the primary.
        func distance(_ screen: NSScreen) -> CGFloat {
            let c = CGPoint(x: screen.frame.midX, y: screen.frame.midY)
            return hypot(c.x - pill.midX, c.y - pill.midY)
        }
        let nearest = NSScreen.screens.min { distance($0) < distance($1) }
        guard let bounds = (nearest ?? screen ?? self.screen ?? NSScreen.main)?.frame else {
            return frameRect
        }

        // Fully off every screen — put it back, still by the pill's own edges.
        let x = min(max(pill.minX, bounds.minX), bounds.maxX - pill.width)
        let y = min(max(pill.minY, bounds.minY), bounds.maxY - pill.height)
        return frameRect.offsetBy(dx: x - pill.minX, dy: y - pill.minY)
    }

    private func setPillOrigin(_ point: NSPoint) {
        setFrameOrigin(NSPoint(x: point.x - Self.margin, y: point.y - Self.margin))
    }

    var pillOrigin: NSPoint {
        NSPoint(x: frame.origin.x + Self.margin, y: frame.origin.y + Self.margin)
    }

    /// The pill's rect on screen, in top-left coordinates, for edge resolution.
    ///
    /// Flipped against the primary display (the one at the global origin), not
    /// `NSScreen.main`: with two displays `main` is whichever has focus, and the
    /// screen frame this is compared with must be flipped against the same height.
    var pillScreenFrameFlipped: CGRect {
        let screenHeight = NSScreen.screens.first?.frame.height ?? 0
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
    /// When the pill collapses its trailing edge withdraws past a stationary cursor.
    /// The view moved, the mouse did not, and AppKit does not reliably deliver `mouseExited`
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

    /// Read from the environment rather than from `NSWorkspace`, which is what it used
    /// to be. `accessibilityDisplayShouldReduceMotion` is a plain property with no
    /// publisher behind it as far as SwiftUI is concerned, so the view kept whichever
    /// value happened to be true when it was first evaluated: turning Reduce Motion on
    /// did nothing until the app was relaunched. The environment key is the same
    /// setting, observed properly.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var tint: Color { Theme.tint(for: controller.phase) }

    /// The raw pointer state, and the only thing left that uses it directly is the
    /// hover flourish. Everything else keys on the *form* the bar is in — see
    /// `controlsRevealed`. The comment here used to say this was debounced; it has not
    /// been for some time, and the morph absorbs a brushing cursor instead.
    private var hovering: Bool { presentation.policy.hovering }

    private var isCompact: Bool { presentation.mode == .compact }

    private typealias M = FloatingBar.Metrics

    /// Constant, and that is the point.
    ///
    /// While the collapsed form was a circle this had to interpolate 23 -> 15, and a
    /// continuous-corner path was being rebuilt every frame — for the clip and again
    /// for the glass, which re-rasterises whenever its shape changes. Now that the
    /// collapsed bar is a shorter pill rather than a circle, both forms want the same
    /// 15pt corner, so there is one shape for the whole morph and only the width
    /// moves.
    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
    }

    /// The only dimension that travels. Height is shared by both forms, so one
    /// animating number and one offset carry the whole change.
    private var pillWidth: CGFloat {
        isCompact ? FloatingBar.compactSize.width : FloatingBar.size.width
    }

    /// Under Reduce Motion the box does not travel — it swaps, and only the contents
    /// cross-fade.
    ///
    /// A spring rather than a timing curve: springs carry velocity through a
    /// reversal, so a flick that turns around mid-open becomes a close instead of
    /// snapping and replaying from the far end.
    ///
    /// Critically damped — `.smooth` is a spring with no bounce at all. Overshoot
    /// belongs on motion the user's own gesture threw; this is a reveal answering a
    /// pointer that has already arrived and stopped, and a box that springs past its
    /// width and comes back reads as slop.
    ///
    /// 0.42s, where it used to be 0.75s. The long version was justified as being its
    /// own debounce — a cursor that only brushes the bar reverses long before the
    /// spring settles, and because a spring re-targets from its current position and
    /// velocity rather than restarting, the reversal reads as the bar breathing once
    /// instead of as an open and a close. All of that is still true at 0.42s: a
    /// crossing cursor is on the bar for well under a tenth of a second and gets
    /// nowhere near the far end. What 0.75s also bought was three quarters of a second
    /// between reaching for a control and being able to press it, and that is Apple's
    /// own figure for a reposition (0.4s, critically damped) being ignored by roughly
    /// double.
    private var morph: Animation {
        reduceMotion ? .linear(duration: 0.01) : .smooth(duration: 0.42)
    }

    /// What the secondary controls ride out on: the box's own spring, unchanged.
    ///
    /// There used to be three lengths in this one gesture — 0.75s on the box, 0.32s on
    /// a content fade, and a 0.28s insertion inside the control row — and three start
    /// and end times for a single pointer event is exactly what reads as mechanical.
    /// The controls travel *with* the edge that reveals them, so they share its curve
    /// and there is one motion.
    ///
    /// Reduce Motion is the one case that still needs two, because there the box does
    /// not travel at all: a cross-fade is what is left to carry the change.
    private var reveal: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : morph
    }

    /// Whether the pill still does its little hover lift.
    ///
    /// Off once compact mode is on, because there the opening *is* the response to
    /// the pointer. Leaving it in put a 0.22s scale and opacity on the same glass
    /// surface as a 0.3s width change: two curves of different lengths, one of them
    /// forcing the glass to resample every frame, finishing at different moments.
    /// That was most of the roughness.
    private var hoverFlourish: Bool { !presentation.policy.compactEnabled }

    /// Hover and compactness are one event, so they get one animation scope.
    ///
    /// They used to have one each, and that was the bug behind every "the bar snaps
    /// open" report. `isCompact` is *derived from* `policy.hovering`, so the pointer
    /// arriving flips both in the same update — and nested `.animation(_:value:)`
    /// modifiers do not compose. The innermost one claims the whole subtree beneath
    /// it. A 0.22s hover flourish sitting under the morph therefore took ownership of
    /// the box's width, the only dimension that actually travels, every single time
    /// the bar opened. Slowing `morph` could not help: `morph` was never reaching the
    /// width.
    ///
    /// Measured off the presentation layer, the nested pair settled in 0.27s against
    /// the 0.83s the spring alone takes, and it front-loaded badly with it: 89% of the
    /// travel inside the first 0.15s. The tell, in hindsight, was the asymmetry.
    /// `controls` keeps its own inner `morph` scope, so the buttons were the one part
    /// still gliding while the ring and the readout — pinned to the leading edge back
    /// then, and so the whole of what the eye tracks on the left — were already there.
    ///
    /// Both halves of that are settled now. The one remaining nested scope is the
    /// secondary controls', and it carries the same spring as this one, so which of them
    /// claims the subtree no longer changes anything. And the ring and the readout do
    /// not travel at all: they are on the fixed leading edge, not pinned to a moving
    /// one, so there is nothing left for a stray curve to front-load.
    private struct PillPose: Equatable {
        var compact: Bool
        var hovering: Bool
    }

    private var pillPose: PillPose { PillPose(compact: isCompact, hovering: hovering) }

    /// One curve chosen up front rather than two racing to claim the subtree.
    ///
    /// The two states are mutually exclusive by construction: the flourish only exists
    /// while compact mode is off, and the morph only has anywhere to travel while it
    /// is on. So picking between them is a plain branch, and there is no longer any
    /// arrangement of modifiers in which one can silently shadow the other.
    private var pillAnimation: Animation {
        hoverFlourish ? .smooth(duration: 0.22) : morph
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
        // One layout, held at full width in both forms, revealed by the growing box
        // rather than re-flowed into it.
        //
        // Inserting the readout and controls on the way out is what made the first
        // attempt read as a replacement: SwiftUI re-ran the layout, so everything
        // arrived at once in a box that was still moving. Nothing here is ever laid
        // out twice — only the clip and one offset move.
        //
        // Spacing is per-item rather than one `spacing:` on the stack, and there is no
        // `Spacer`, because the row has to add up to `Metrics.width` exactly. Any slack
        // at all would be distributed by the layout, and then the position of every
        // control would depend on the box width instead of being fixed by it.
        HStack(spacing: 0) {
            phaseRing

            readout
                .padding(.leading, M.ringGap)

            // Present in both forms, and in the same place in both. Drawn last in
            // z-order so the secondaries pass underneath it rather than over.
            primaryControl
                .padding(.leading, M.readoutGap)
                .zIndex(2)

            // The only thing the collapse hides. Outside the clip once it has parked,
            // so the opacity is for the moment in between — when the box is still wide
            // enough to show them but the bar is on its way to not having them.
            Group {
                secondaryControl("forward.end.fill", label: "Skip", index: 0) {
                    controller.skip()
                }
                .zIndex(1)

                secondaryControl("arrow.counterclockwise", label: "Reset", index: 1) {
                    controller.reset()
                }
                .zIndex(0)
            }
            .padding(.leading, M.controlGap)
            // Its own scope, deliberately, and the only nested one left. The outer
            // animation on the pill governs the box; this governs what comes out of
            // it. They are the same spring, so the nesting no longer decides anything
            // — see `reveal`.
            .animation(reveal, value: isCompact)
        }
        .padding(.leading, M.leading)
        .padding(.trailing, M.trailing)
        .frame(width: M.width, height: M.height)
        // Both forms share their leading edge, and that is the whole point of this
        // arrangement: the ring, the countdown and the play button do not move at all
        // across a morph. Only the trailing edge travels, and only reset and skip
        // travel with it.
        //
        // It used to be centred, with the content pinned to the box's leading edge —
        // so the box grew both ways by half and dragged the entire contents sideways
        // with it. Every element the eye was already tracking slid 51pt on a collapse,
        // including the play button, for no reason other than that the box was
        // symmetric. Nothing about a reveal requires the thing already revealed to
        // move.
        .frame(width: pillWidth, height: M.height, alignment: .leading)
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
        // Holds the leading edge still while the box narrows around its own centre.
        //
        // An offset rather than moving `.position`, which is where this belongs on
        // paper: `.position` is a layout modifier, so animating it re-runs layout for
        // the whole subtree every frame, and this file has already been round that
        // loop once with the ring's `trim`. An offset is a render-time transform, and
        // it interpolates on the same curve as the width it is derived from, so the
        // two stay exactly in step and the edge does not wobble.
        .offset(x: (pillWidth - M.width) / 2)
        .opacity(hoverFlourish && !hovering ? 0.92 : 1)
        .scaleEffect(hoverFlourish && !hovering ? 0.99 : 1.0, anchor: .center)
        .onHover { presentation.setHovering($0) }
        .animation(pillAnimation, value: pillPose)
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
                // Deliberately *not* animated on `progress`.
                //
                // `trim` is the one thing here that Core Animation cannot interpolate
                // for us: every frame of a trim change rebuilds the stroked path on
                // the CPU, and because that path sits inside the pill's modifier
                // chain, each rebuild drags the whole bar through another layout pass.
                // A 0.6s curve on a value that ticks once a second therefore kept the
                // render loop hot for 60% of every second, sustained for the entire
                // length of a session. It is not separable from the readout's own
                // animation, so the cost is quoted once, on that one.
                //
                // What it bought was nothing anyone can see. On a 25-minute focus the
                // ring advances 1/1500th of its circumference per tick: 0.06pt of arc
                // on a 28pt dial, well under one pixel. The animation was smoothing a
                // step that is already smaller than the smallest thing the display can
                // draw.
                //
                // The jumps that *are* visible — a phase ending, a skip — all change
                // `phase` in the same update, and the `.animation(_:value:)` keyed on
                // it just below still carries the ring back to zero. Only a reset
                // inside the current phase snaps now, which is what a reset should do.
                .animation(nil, value: controller.progress)

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
        .frame(width: M.ring, height: M.ring)
        .animation(.smooth(duration: 0.4), value: controller.phase)
        .onAppear(perform: reconcileBreathing)
        .onChange(of: reduceMotion) { _, _ in reconcileBreathing() }
        .accessibilityLabel("\(controller.phase.title), \(controller.displayTime) remaining")
    }

    /// Starts or stops the glyph's breath, and is the reason it is 1.4s rather than
    /// the 1.9s it was.
    ///
    /// Two things were wrong. It ran under Reduce Motion, which a `repeatForever` on a
    /// window that sits over everything all day is the worst possible thing to do —
    /// this is the one animation with no end, so it is the one the setting most exists
    /// for. And at 1.9s per half cycle it oscillated once every 3.8 seconds, which is
    /// inside the band Apple explicitly warns off (around one cycle per five seconds,
    /// the range that reads as pulsing rather than as breathing and is a genuine
    /// trigger for motion sensitivity). Shortening it moves away from that band;
    /// lengthening it would have moved in.
    ///
    /// Restarting on the setting changing rather than only on appear, because the pill
    /// is never torn down: it is created once at launch and lives until the app quits,
    /// so an `onAppear`-only check would be answering a question the user asked months
    /// ago.
    private func reconcileBreathing() {
        guard !reduceMotion else {
            // No animation on the way out either — under Reduce Motion the glyph should
            // simply be at rest, not ease its way there.
            var transaction = Transaction(animation: nil)
            transaction.disablesAnimations = true
            withTransaction(transaction) { pulse = false }
            return
        }
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            pulse = true
        }
    }

    private var readout: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(controller.displayTime)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .monospacedDigit()
                // The roll is left in place but no longer triggered, because it was
                // the single most expensive thing the app did.
                //
                // Animating it runs a full SwiftUI render pass every frame for the
                // length of the transition, and the pass — not the text — is what
                // costs: the pill's modifier chain is deep enough that re-resolving
                // its layout dominates every frame regardless of what changed. On a
                // tick every second that held the render loop open more or less
                // continuously.
                //
                // The important part is that this animation and the ring's are not
                // additive, so neither can be fixed alone. Cumulative CPU over a 40s
                // window, release build, `animeGirl`, compact bar (see
                // `Scripts/`-style bench in the notes — timer started via an
                // env-gated hook, because `top` is far too noisy to compare these):
                //
                //     both animated ............. 15.3%
                //     ring silenced only ........ 10.0%
                //     digits silenced only ...... 10.5%
                //     both silenced ..............1.1%
                //
                // Either one on its own is enough to hold the loop open, and each
                // removal alone buys about a third of the cost. Only silencing both
                // collapses it, by better than 10x.
                //
                // Nothing cheaper was available for the digits. The cost is flat
                // across curves and durations — `.smooth(0.28)`, `.easeOut(0.20)`
                // and `.easeOut(0.12)` all landed within noise of each other —
                // because `.numericText` runs its own transition and the modifier
                // here only decides whether it runs at all.
                //
                // Keeping `contentTransition` means restoring the effect is a
                // one-line change back to `.smooth(duration: 0.28)`, at that price.
                .contentTransition(.numericText(countsDown: true))
                .animation(nil, value: controller.remainingSeconds)
                // Tracking is a function of size, not a constant, and monospaced digits
                // are set on a fixed advance that is generous by design — it has to fit
                // the widest glyph in the face. At 18pt that reads loose against the
                // 8pt label underneath it, which needs the opposite correction and gets
                // it. Small enough not to touch the alignment of the digits, since the
                // advance itself is unchanged.
                .tracking(-0.3)
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

    /// Play/pause. The one control that is in both forms.
    private var primaryControl: some View {
        control(
            controller.isRunning ? "pause.fill" : "play.fill",
            label: controller.isRunning ? "Pause" : "Start",
            tint: tint,
            size: M.primary
        ) { controller.toggle() }
    }

    /// A secondary action, parked under the play button until the pointer arrives.
    ///
    /// It slides out from underneath the play button and tucks back under it on exit —
    /// `zIndex` at the call site keeps it behind the whole way, so it reads as emerging
    /// from the primary control rather than as growing out of nothing beside it. It now
    /// travels the same direction the box opens, which it did not before: the tuck used
    /// to push these *outward* past the play button, so on a collapse the box withdrew
    /// leftward while its contents fled right.
    ///
    /// Always mounted and moved by an offset, never inserted and removed. That is what
    /// makes the whole bar interruptible: a transition runs on identity change and has
    /// no velocity, so reversing one halfway restarts it from the far end instead of
    /// turning it around. With no hover debounce left to keep a flicked cursor away
    /// from them, they had to become transforms like everything else.
    ///
    /// Which is also why there is no `glassGroup` here. A `GlassEffectContainer`
    /// harvests the shapes tagged for it and draws them itself, so an `.opacity`
    /// applied outside the glass effect never reaches them — hiding these while grouped
    /// left both glyphs stacked on the play button with its tint disc reduced to a
    /// ring. The container existed to make insertion look good, and there is no
    /// insertion any more.
    /// Out whenever the box is open, and only then — keyed on the form the bar is in
    /// rather than on the pointer.
    ///
    /// These are the same thing most of the time, because hover is what usually opens
    /// the box. They come apart in the three cases where something *else* holds it
    /// open: a stopped timer, a phase change nobody has looked at yet, and VoiceOver.
    /// Keyed on the pointer, those three produced an open box with the controls still
    /// parked — 74pt of empty glass past the play button, which is the whole trailing
    /// third of the pill reading as an unfinished layout. Keyed on the form, the box is
    /// wide exactly when there is something in the width, and the gap cannot occur.
    ///
    /// It also closes a hole the policy only looked like it had covered. VoiceOver
    /// vetoes the compact form so that "the controls stay reachable" — but reachable is
    /// hit testing and accessibility, and both of those were keyed on hover, so with
    /// VoiceOver running and the cursor elsewhere the bar opened and then hid reset and
    /// skip from the screen reader it had opened for.
    private var controlsRevealed: Bool { !isCompact }

    private func secondaryControl(
        _ symbol: String,
        label: String,
        index: Int,
        action: @escaping () -> Void
    ) -> some View {
        control(symbol, label: label, size: M.secondary, action: action)
            .offset(x: controlsRevealed ? 0 : M.tuck(index))
            .opacity(controlsRevealed ? 1 : 0)
            // Invisible is not absent: parked under the play button at zero opacity
            // these would still take the click, and VoiceOver would still offer them.
            .allowsHitTesting(controlsRevealed)
            .accessibilityHidden(!controlsRevealed)
    }

    private func control(
        _ symbol: String,
        label: String,
        tint: Color? = nil,
        size: CGFloat,
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
        .accessibilityLabel(label)
    }
}

/// The circular surface behind a pill control.
///
/// The primary one gets a solid tinted disc, because glass on glass is nearly
/// invisible — the play button was reading as a bare triangle floating on the pill,
/// with nothing to say it was a target.
///
/// The secondaries had the same problem and a worse fix: they were glass circles on the
/// pill's own glass, which is the one material combination that is actually ruled out
/// rather than merely unwise. Two translucent layers each sampling what is behind them
/// leaves neither with an edge, so a stack of them reads as a smudge on the pill
/// instead of as two buttons — and it was costing a second and third glass rasterisation
/// on a surface that already has one. They are opaque wells now: a faint fill and a
/// hairline, which is what a recessed control looks like on a material rather than what
/// a second pane of glass looks like on top of one.
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
            content
                .frame(width: size, height: size)
                .background {
                    Circle()
                        .fill(.primary.opacity(0.07))
                        .overlay {
                            // A bright hairline rather than a border: it is the light
                            // the pill's own top edge catches, continued around a
                            // smaller shape, which is what puts these on the material
                            // instead of in front of it.
                            Circle().stroke(.primary.opacity(0.10), lineWidth: 0.5)
                        }
                }
                .contentShape(Circle())
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
        // Both forms are the pill's full height and centred vertically in the panel, so
        // their rects are the same whether the view is flipped or not. Only their width
        // differs, and x is unaffected either way.
        let target = geometry?.hitFrame ?? FloatingBar.pillFrame
        guard target.contains(local) else { return nil }
        return super.hitTest(point)
    }
}
