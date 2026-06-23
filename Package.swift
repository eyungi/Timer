// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Timer",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Timer",
            path: "Sources/Timer"
        )
    ]
)
