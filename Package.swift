// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DesktopNamer",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "DesktopNamer",
            path: "Sources",
            linkerSettings: [
                .unsafeFlags(["-framework", "CoreGraphics"]),
                .unsafeFlags(["-framework", "AppKit"]),
            ]
        )
    ]
)
