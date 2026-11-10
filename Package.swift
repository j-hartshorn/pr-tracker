// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "gh-tracker",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(name: "GHTracker", dependencies: ["TrackerApp"]),
        .target(name: "TrackerApp", dependencies: ["TrackerCore"]),
        .target(name: "TrackerCore"),
        .testTarget(name: "TrackerCoreTests", dependencies: ["TrackerCore"]),
    ]
)
