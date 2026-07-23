import AppKit

// Menu-bar-only app: no Dock icon, no main menu window. `LSUIElement` in Info.plist
// covers this for the bundled app; setting the policy here also makes `swift run`
// behave the same during development.
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let delegate = AppDelegate()
app.delegate = delegate
app.run()
