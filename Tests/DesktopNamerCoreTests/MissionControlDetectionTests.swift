import Foundation
import DesktopNamerCore

func runMissionControlDetectionTests(_ t: TestRun) {
    t.suite("MissionControlDetection") {
        // Fixtures mirror a live probe on macOS 15: idle Dock owns only wallpaper
        // windows at hugely negative layers; Mission Control adds windows at 18/20.
        t.expect(!isMissionControlActive(dockWindowLayers: [-2147483624, -2147483624]),
                 "wallpaper-only layers are inactive")
        t.expect(isMissionControlActive(dockWindowLayers: [20, 20, 20, 18, 18, -2147483624, -2147483624]),
                 "Mission Control layers 18/20 are active")
        t.expect(!isMissionControlActive(dockWindowLayers: []),
                 "empty list is inactive")
        t.expect(!isMissionControlActive(dockWindowLayers: [-1]),
                 "negative layers are inactive")
        t.expect(isMissionControlActive(dockWindowLayers: [0]),
                 "boundary layer zero counts as active")
    }
}
