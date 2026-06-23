// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TimerForTerry",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "TimerForTerry",
            path: "Sources/TimerForTerry"
        )
    ]
)
