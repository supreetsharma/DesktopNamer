import Foundation

/// The preset accent colors offered for spaces, and hex parsing shared by
/// every surface that renders them (dropdown, menu bar, HUD, Mission Control).
public enum SpacePalette {
    /// Eight preset colors as RRGGBB hex strings (no alpha).
    public static let presets: [String] = [
        "FF453A", // red
        "FF9F0A", // orange
        "FFD60A", // yellow
        "32D74B", // green
        "64D2FF", // cyan
        "0A84FF", // blue
        "BF5AF2", // purple
        "FF375F", // pink
    ]

    /// Parses "RRGGBB" (optionally "#"-prefixed, any case) into 0...1 components.
    /// Returns nil for anything that is not exactly six hex digits.
    public static func rgbComponents(fromHex hex: String) -> (r: Double, g: Double, b: Double)? {
        let digits = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard digits.count == 6, let value = UInt32(digits, radix: 16) else { return nil }
        return (
            r: Double((value >> 16) & 0xFF) / 255.0,
            g: Double((value >> 8) & 0xFF) / 255.0,
            b: Double(value & 0xFF) / 255.0
        )
    }
}
