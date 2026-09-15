// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DesktopNamer",
    platforms: [.macOS(.v14)],
    dependencies: [
        // Pinned: 1.16.0+ contains #Preview macros that cannot compile without Xcode.app
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", exact: "1.15.0"),
    ],
    targets: [
        .target(
            name: "DesktopNamerCore",
            path: "Sources/Core"
        ),
        .executableTarget(
            name: "DesktopNamer",
            dependencies: [
                "DesktopNamerCore",
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
            ],
            path: "Sources/App",
            linkerSettings: [
                .unsafeFlags(["-framework", "CoreGraphics"]),
                .unsafeFlags(["-framework", "AppKit"]),
            ]
        ),
        // Executable test runner: XCTest is unavailable under Command Line Tools
        .executableTarget(
            name: "desktop-namer-tests",
            dependencies: ["DesktopNamerCore"],
            path: "Tests/DesktopNamerCoreTests"
        ),
    ]
)
