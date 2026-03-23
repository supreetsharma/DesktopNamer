// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DesktopNamer",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0"),
    ],
    targets: [
        .executableTarget(
            name: "DesktopNamer",
            dependencies: ["Sparkle"],
            path: "Sources",
            linkerSettings: [
                .unsafeFlags(["-framework", "CoreGraphics"]),
                .unsafeFlags(["-framework", "AppKit"]),
            ]
        )
    ]
)
