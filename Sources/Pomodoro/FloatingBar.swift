import AppKit
import PomodoroCore

/// The always-on-top countdown pill.
///
/// An `NSPanel` rather than an `NSWindow`: a non-activating panel can be clicked
/// without stealing focus from whatever you are working in, and combined with
/// `.floating` level plus `[.canJoinAllSpaces, .fullScreenAuxiliary]` it stays
/// visible across Spaces and over fullscreen apps — which a normal window cannot do.
@MainActor
final class FloatingBar: NSPanel {

    private let content: FloatingBarView

    init(controller: TimerController, settings: PomodoroSettings) {
        content = FloatingBarView(controller: controller)

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: FloatingBarView.width, height: FloatingBarView.height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        // Keep it out of Mission Control's window list and the app switcher.
        isExcludedFromWindowsMenu = true

        contentView = content
        restorePosition(settings: settings)
    }

    /// Borderless panels are not key by default, which would break nothing here but
    /// does stop the hover cursor updating; allowing key without activating the app
    /// gives the buttons proper tracking.
    override var canBecomeKey: Bool { true }

    func refresh() {
        content.refresh()
    }

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

// MARK: - Content

@MainActor
final class FloatingBarView: NSView {

    static let width: CGFloat = 172
    static let height: CGFloat = 44

    private let controller: TimerController
    private let phaseLabel = NSTextField(labelWithString: "")
    private let timeLabel = NSTextField(labelWithString: "")
    private let playButton = NSButton()
    private let skipButton = NSButton()
    private let progressLayer = CAShapeLayer()

    init(controller: TimerController) {
        self.controller = controller
        super.init(frame: NSRect(x: 0, y: 0, width: Self.width, height: Self.height))
        wantsLayer = true
        setup()
        refresh()
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    private func setup() {
        let background = NSVisualEffectView(frame: bounds)
        background.autoresizingMask = [.width, .height]
        background.material = .hudWindow
        background.blendingMode = .behindWindow
        background.state = .active
        background.wantsLayer = true
        background.layer?.cornerRadius = 12
        background.layer?.masksToBounds = true
        addSubview(background)

        // A thin progress line along the bottom edge — visible at a glance without
        // adding another number to read.
        progressLayer.fillColor = NSColor.controlAccentColor.cgColor
        progressLayer.frame = CGRect(x: 0, y: 0, width: 0, height: 3)
        background.layer?.addSublayer(progressLayer)

        phaseLabel.font = .systemFont(ofSize: 9, weight: .semibold)
        phaseLabel.textColor = .secondaryLabelColor
        phaseLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(phaseLabel)

        timeLabel.font = .monospacedDigitSystemFont(ofSize: 18, weight: .medium)
        timeLabel.textColor = .labelColor
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(timeLabel)

        configure(playButton, symbol: "play.fill", action: #selector(togglePressed))
        configure(skipButton, symbol: "forward.end.fill", action: #selector(skipPressed))

        NSLayoutConstraint.activate([
            phaseLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            phaseLabel.topAnchor.constraint(equalTo: topAnchor, constant: 6),

            timeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 13),
            timeLabel.topAnchor.constraint(equalTo: phaseLabel.bottomAnchor, constant: -1),

            skipButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            skipButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            skipButton.widthAnchor.constraint(equalToConstant: 26),
            skipButton.heightAnchor.constraint(equalToConstant: 26),

            playButton.trailingAnchor.constraint(equalTo: skipButton.leadingAnchor, constant: -4),
            playButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 26),
            playButton.heightAnchor.constraint(equalToConstant: 26),
        ])
    }

    private func configure(_ button: NSButton, symbol: String, action: Selector) {
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        button.bezelStyle = .accessoryBarAction
        button.isBordered = false
        button.target = self
        button.action = action
        button.contentTintColor = .labelColor
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
    }

    @objc private func togglePressed() { controller.toggle() }
    @objc private func skipPressed() { controller.skip() }

    func refresh() {
        phaseLabel.stringValue = "\(controller.phase.symbol)  \(controller.phase.title.uppercased())"
        timeLabel.stringValue = controller.displayTime
        playButton.image = NSImage(
            systemSymbolName: controller.isRunning ? "pause.fill" : "play.fill",
            accessibilityDescription: controller.isRunning ? "Pause" : "Start"
        )

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        progressLayer.frame = CGRect(
            x: 0, y: 0,
            width: bounds.width * CGFloat(controller.progress),
            height: 3
        )
        progressLayer.fillColor = (controller.phase == .focus
            ? NSColor.controlAccentColor
            : NSColor.systemGreen).cgColor
        progressLayer.path = CGPath(rect: progressLayer.bounds, transform: nil)
        CATransaction.commit()
    }
}
