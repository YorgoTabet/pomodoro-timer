import PomodoroCore
import SwiftUI

/// Colour and material choices shared by the app and the widget, so the floating
/// bar and the desktop widget can't drift apart.
public enum Theme {

    public static func tint(for phase: Phase) -> Color {
        switch phase {
        case .focus: Color(red: 0.91, green: 0.30, blue: 0.26)
        case .shortBreak: Color(red: 0.20, green: 0.66, blue: 0.53)
        case .longBreak: Color(red: 0.24, green: 0.51, blue: 0.85)
        }
    }

    /// The lighter end of each phase's gradient — the leading edge of the ring and
    /// the rail, so progress reads as movement rather than a flat block of colour.
    public static func highlight(for phase: Phase) -> Color {
        switch phase {
        case .focus: Color(red: 0.98, green: 0.55, blue: 0.36)
        case .shortBreak: Color(red: 0.42, green: 0.86, blue: 0.66)
        case .longBreak: Color(red: 0.47, green: 0.74, blue: 0.98)
        }
    }

    /// Backdrop for a surface showing this phase. Two stops of the phase colour at
    /// low opacity — enough for glass to have something to bend, not so much that
    /// the countdown loses contrast.
    public static func backdrop(for phase: Phase) -> LinearGradient {
        LinearGradient(
            colors: [
                tint(for: phase).opacity(0.34),
                highlight(for: phase).opacity(0.10),
                tint(for: phase).opacity(0.04),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public static func symbol(for phase: Phase) -> String {
        switch phase {
        case .focus: "timer"
        case .shortBreak: "cup.and.saucer.fill"
        case .longBreak: "figure.walk"
        }
    }
}

// MARK: - Liquid Glass

/// Applies the macOS 26 Liquid Glass material, falling back to the older blurred
/// material on earlier systems.
///
/// The fallback is not a lookalike — `.regularMaterial` is the previous generation's
/// vibrancy, which is the correct native answer on those systems. Chasing the glass
/// look with hand-rolled gradients would age badly and look wrong against real
/// system chrome.
public struct GlassPanel<S: Shape>: ViewModifier {
    let shape: S
    let tint: Color?
    let interactive: Bool

    public func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.glassEffect(glass, in: shape)
        } else {
            content
                .background(.regularMaterial, in: shape)
                .overlay(
                    shape.stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                )
        }
    }

    @available(macOS 26.0, *)
    private var glass: Glass {
        var glass = Glass.regular
        if let tint { glass = glass.tint(tint) }
        if interactive { glass = glass.interactive() }
        return glass
    }
}

public extension View {
    /// Liquid Glass on macOS 26, `.regularMaterial` before it.
    func glassPanel(
        in shape: some Shape = Capsule(),
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        modifier(GlassPanel(shape: shape, tint: tint, interactive: interactive))
    }

    /// Groups nearby glass elements so they blend and refract as one surface
    /// rather than as separate stacked panes. A no-op before macOS 26.
    @ViewBuilder
    func glassGroup(spacing: CGFloat = 12) -> some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) { self }
        } else {
            self
        }
    }
}

public extension View {
    /// Tags a glass element so it morphs into its neighbours when they appear and
    /// disappear, instead of popping. The whole point of grouping glass — without
    /// an identity, two controls fading in look like two separate panes.
    /// A no-op before macOS 26.
    @ViewBuilder
    func glassMorphID(_ id: String, in namespace: Namespace.ID) -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffectID(id, in: namespace)
        } else {
            self
        }
    }
}

/// The Liquid Glass button style, degrading to a plain bordered button.
public struct AdaptiveGlassButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.55 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

public extension View {
    /// A circular control that is glass on macOS 26 and a subtle material before it.
    ///
    /// Note the deliberate absence of a tint: a tinted Liquid Glass circle renders
    /// close to opaque, which on a 26pt control reads as a solid coloured blob
    /// rather than a button. Colour belongs in the glyph, where it stays legible.
    func glassControl(size: CGFloat = 30) -> some View {
        frame(width: size, height: size)
            .glassPanel(in: Circle(), interactive: true)
            // The glass is a background, so without an explicit content shape only
            // the glyph itself takes the click — the ring around it looks like part
            // of the button but isn't.
            .contentShape(Circle())
    }
}
