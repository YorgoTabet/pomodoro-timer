import AppKit
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

    init(controller: TimerController, settings: PomodoroSettings) {
        super.init(
            contentRect: NSRect(origin: .zero, size: Self.size),
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

        let host = NSHostingView(rootView: FloatingBarView(controller: controller))
        host.frame = NSRect(origin: .zero, size: Self.size)
        contentView = host

        restorePosition(settings: settings)
    }

    /// Borderless panels aren't key by default, which would stop the buttons
    /// showing hover state. `.nonactivatingPanel` means this still doesn't pull
    /// focus away from the app you're working in.
    override var canBecomeKey: Bool { true }

    // MARK: - Position

    private func restorePosition(settings: PomodoroSettings) {
        if let origin = settings.floatingBarOrigin,
           screenContains(NSPoint(x: origin.x, y: origin.y)) {
            setFrameOrigin(NSPoint(x: origin.x, y: origin.y))
        } else if let visible = NSScreen.main?.visibleFrame {
            // Default: top-right, tucked just under the menu bar.
            setFrameOrigin(NSPoint(
                x: visible.maxX - frame.width - 24,
                y: visible.maxY - frame.height - 12
            ))
        }
    }

    /// Guard against restoring onto a display that is no longer connected.
    private func screenContains(_ point: NSPoint) -> Bool {
        NSScreen.screens.contains { $0.frame.insetBy(dx: -1, dy: -1).contains(point) }
    }

    func persistPosition(to settings: PomodoroSettings) {
        settings.floatingBarOrigin = (x: Double(frame.origin.x), y: Double(frame.origin.y))
    }
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

    @State private var hovering = false
    @State private var pulse = false
    @Namespace private var glass

    private var tint: Color { Theme.tint(for: controller.phase) }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
    }

    var body: some View {
        HStack(spacing: 10) {
            phaseRing
            readout
            Spacer(minLength: 4)
            controls
        }
        .padding(.leading, 11)
        .padding(.trailing, 10)
        .frame(width: FloatingBar.size.width, height: FloatingBar.size.height)
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
        .onHover { hovering = $0 }
        .animation(.smooth(duration: 0.22), value: hovering)
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
        .frame(width: 28, height: 28)
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
