// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Pomodoro",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "PomodoroCore"),
        .executableTarget(
            name: "Pomodoro",
            dependencies: ["PomodoroCore"]
        ),
        .testTarget(
            name: "PomodoroCoreTests",
            dependencies: ["PomodoroCore"]
        ),
    ]
)
