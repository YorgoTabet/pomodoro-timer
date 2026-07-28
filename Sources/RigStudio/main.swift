import AppKit
import SwiftUI

// `--filmstrip <dir>` renders contact sheets and exits without ever opening a
// window, so the performances can be inspected without a display.
if let flag = CommandLine.arguments.firstIndex(of: "--filmstrip") {
    let directory = CommandLine.arguments.count > flag + 1
        ? CommandLine.arguments[flag + 1]
        : FileManager.default.currentDirectoryPath
    FilmStrip.renderAll(into: directory)
    exit(0)
}

if CommandLine.arguments.contains("--audit") {
    MotionAudit.run()
    exit(0)
}

// A plain windowed tool, unlike the app it serves — RigStudio wants a Dock icon,
// a real title bar, and keyboard focus.
let app = NSApplication.shared
app.setActivationPolicy(.regular)

let delegate = StudioDelegate()
app.delegate = delegate
app.run()

final class StudioDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1120, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Rig Studio"
        window.contentView = NSHostingView(rootView: StudioView())
        window.center()
        window.makeKeyAndOrderFront(nil)
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
