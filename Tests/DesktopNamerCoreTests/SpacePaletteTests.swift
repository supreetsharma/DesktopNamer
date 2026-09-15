import Foundation
import DesktopNamerCore

func runSpacePaletteTests(_ t: TestRun) {
    t.suite("SpacePalette") {
        t.expectEqual(SpacePalette.presets.count, 8, "eight preset colors")
        t.expect(SpacePalette.presets.allSatisfy { SpacePalette.rgbComponents(fromHex: $0) != nil },
                 "every preset parses")

        if let rgb = SpacePalette.rgbComponents(fromHex: "0A84FF") {
            t.expect(abs(rgb.r - 10.0 / 255.0) < 0.001, "red component of 0A84FF")
            t.expect(abs(rgb.g - 132.0 / 255.0) < 0.001, "green component of 0A84FF")
            t.expect(abs(rgb.b - 255.0 / 255.0) < 0.001, "blue component of 0A84FF")
        } else {
            t.expect(false, "0A84FF failed to parse")
        }

        t.expect(SpacePalette.rgbComponents(fromHex: "#32D74B") != nil, "leading # accepted")
        t.expect(SpacePalette.rgbComponents(fromHex: "ff375f") != nil, "lowercase accepted")
        t.expect(SpacePalette.rgbComponents(fromHex: "GGGGGG") == nil, "non-hex rejected")
        t.expect(SpacePalette.rgbComponents(fromHex: "FFF") == nil, "3-digit short form rejected")
    }
}
