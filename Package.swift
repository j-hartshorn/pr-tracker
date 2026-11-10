// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "gh-tracker",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(name: "GHTracker", dependencies: ["TrackerApp"]),
        .executableTarget(name: "Previews", dependencies: ["TrackerApp", "TrackerCore", "Hairline"]),
        .target(name: "TrackerApp", dependencies: ["TrackerCore", "Hairline"]),
        .target(name: "Hairline"),
        .target(name: "TrackerCore"),
        .testTarget(name: "TrackerCoreTests", dependencies: ["TrackerCore"]),
    ]
)
