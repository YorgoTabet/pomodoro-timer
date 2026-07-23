import Foundation

/// Development trace. Writes to /tmp/pomodoro-diag.txt so it survives launching
/// via `open`, where stdout and stderr go nowhere.
public func pomodoroDiag(_ message: String) {
    guard ProcessInfo.processInfo.environment["POMODORO_DIAG"] != nil else { return }
    let line = "\(Date().timeIntervalSince1970) \(message)\n"
    let url = URL(fileURLWithPath: "/tmp/pomodoro-diag.txt")
    if let handle = try? FileHandle(forWritingTo: url) {
        handle.seekToEndOfFile()
        handle.write(Data(line.utf8))
        try? handle.close()
    } else {
        try? Data(line.utf8).write(to: url)
    }
}
