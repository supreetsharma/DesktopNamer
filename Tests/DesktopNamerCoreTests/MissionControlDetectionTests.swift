import Foundation
import DesktopNamerCore

func runMissionControlDetectionTests(_ t: TestRun) {
    // Sizes from a live probe on macOS 15 (two displays connected).
    let screens: [(width: Double, height: Double)] = [(3456, 2234), (2560, 1440)]
    func win(_ layer: Int, _ width: Double, _ height: Double) -> DockWindowInfo {
        DockWindowInfo(layer: layer, width: width, height: height)
    }

    t.suite("MissionControlDetection") {
        // Idle Dock (auto-hide on): wallpaper windows only, hugely negative layers.
        t.expect(!isMissionControlActive(
            dockWindows: [win(-2147483624, 2560, 1440), win(-2147483624, 3456, 2234)],
            screenSizes: screens),
            "wallpaper-only windows are inactive")
        // Mission Control up: screen-sized windows at layers 18/20 join the list.
        t.expect(isMissionControlActive(
            dockWindows: [win(20, 3456, 2234), win(20, 2560, 1440), win(18, 3456, 2234),
                          win(-2147483624, 2560, 1440), win(-2147483624, 3456, 2234)],
            screenSizes: screens),
            "screen-sized Mission Control windows at 18/20 are active")
        // The Dock bar itself (auto-hide OFF — the macOS default) is a screen-wide
        // strip at layer 20 but nowhere near screen height: must NOT trigger.
        t.expect(!isMissionControlActive(
            dockWindows: [win(20, 3456, 70)],
            screenSizes: screens),
            "visible Dock bar is inactive")
        // Cmd-Tab app switcher: Dock-owned, non-negative layer, small: must NOT trigger.
        t.expect(!isMissionControlActive(
            dockWindows: [win(20, 900, 240)],
            screenSizes: screens),
            "app switcher is inactive")
        t.expect(!isMissionControlActive(dockWindows: [], screenSizes: screens),
                 "empty window list is inactive")
        // Screen-sized but negative layer (wallpaper) stays inactive even at exact size.
        t.expect(!isMissionControlActive(
            dockWindows: [win(-1, 3456, 2234)],
            screenSizes: screens),
            "negative-layer screen-sized window is inactive")
        // Boundary: layer zero at screen size counts as active.
        t.expect(isMissionControlActive(
            dockWindows: [win(0, 2560, 1440)],
            screenSizes: screens),
            "boundary layer zero at screen size is active")
        // No screens reported: nothing can qualify as screen-sized.
        t.expect(!isMissionControlActive(
            dockWindows: [win(20, 3456, 2234)],
            screenSizes: []),
            "no screens means inactive")
    }
}
