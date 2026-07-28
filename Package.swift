// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Pomodoro",
    platforms: [.macOS(.v14)],
    targets: [
        // Pure logic: state machine, settings, stats, and the app/widget bridge.
        .target(name: "PomodoroCore"),

        // SwiftUI shared by the app and the widget, so the floating bar and the
        // desktop widget can't drift apart visually.
        .target(name: "PomodoroUI", dependencies: ["PomodoroCore"]),

        .executableTarget(
            name: "Pomodoro",
            dependencies: ["PomodoroCore", "PomodoroUI"]
        ),

        // Built as a separate binary and assembled into Pomodoro.app/Contents/PlugIns
        // by Scripts/build.sh — SwiftPM has no notion of an app extension.
        .executableTarget(
            name: "PomodoroWidget",
            dependencies: ["PomodoroCore", "PomodoroUI"]
        ),

        // Animation authoring tool: `swift run RigStudio`. Deliberately a separate
        // executable rather than a debug window in the app — it is a workbench, not
        // a feature, and nothing it contains should ever ship in Pomodoro.app.
        .executableTarget(
            name: "RigStudio",
            dependencies: ["PomodoroCore", "PomodoroUI"]
        ),

        .testTarget(
            name: "PomodoroCoreTests",
            dependencies: ["PomodoroCore"]
        ),

        // Guards the path parser and the 60-path transcription, where a dropped
        // command would be a subtly wrong drawing rather than a crash.
        .testTarget(
            name: "PomodoroUITests",
            dependencies: ["PomodoroUI"]
        ),

        // Covers the app target's own logic. Testing an executable works because
        // `main.swift` runs only when the binary is launched, not when the test
        // bundle links against it.
        .testTarget(
            name: "PomodoroAppTests",
            dependencies: ["Pomodoro", "PomodoroCore"]
        ),
    ]
)
