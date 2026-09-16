import Foundation

/// One on-screen window owned by the Dock: its window layer and bounds size.
public struct DockWindowInfo: Equatable {
    public let layer: Int
    public let width: Double
    public let height: Double

    public init(layer: Int, width: Double, height: Double) {
        self.layer = layer
        self.width = width
        self.height = height
    }
}

/// Classifies whether Mission Control is currently presented, given the Dock's
/// on-screen windows and the connected screens' sizes.
///
/// Empirical basis (macOS 15): the Dock's persistent windows (wallpaper) sit at
/// hugely negative layers; while Mission Control is up the Dock additionally owns
/// SCREEN-SIZED windows at layers 18 and 20. Both conditions are required:
/// - layer >= 0 excludes wallpaper (and tolerates minor OS drift in 18/20);
/// - full-screen coverage excludes the Dock's other non-negative-layer windows —
///   the Dock bar itself when auto-hide is off (the macOS default), the Cmd-Tab
///   app switcher, and Dock icon context menus — none of which are screen-sized.
/// Known residual: Launchpad is Dock-owned and screen-sized (cosmetic, rare).
/// (The old com.apple.expose.front.awake notification no longer fires at all.)
public func isMissionControlActive(
    dockWindows: [DockWindowInfo],
    screenSizes: [(width: Double, height: Double)]
) -> Bool {
    dockWindows.contains { window in
        window.layer >= 0 && screenSizes.contains { screen in
            window.width >= screen.width - 1 && window.height >= screen.height - 1
        }
    }
}
