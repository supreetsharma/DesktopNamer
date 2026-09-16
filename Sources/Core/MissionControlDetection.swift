import Foundation

/// Classifies whether Mission Control is currently presented, given the window
/// layers of the Dock's on-screen windows.
///
/// Empirical basis (macOS 15): the Dock's persistent windows (wallpaper) sit at
/// hugely negative layers; while Mission Control is up the Dock additionally owns
/// screen-sized windows at layers 18 and 20. Any non-negative layer therefore
/// indicates Mission Control, tolerating minor OS drift in the exact values.
/// (The old com.apple.expose.front.awake notification no longer fires at all.)
public func isMissionControlActive(dockWindowLayers: [Int]) -> Bool {
    dockWindowLayers.contains { $0 >= 0 }
}
