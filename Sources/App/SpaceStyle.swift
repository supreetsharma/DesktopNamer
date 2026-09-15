import AppKit
import SwiftUI
import DesktopNamerCore

/// App-side rendering helpers for the Core palette, plus the curated symbol set.
enum SpaceStyle {
    static func color(fromHex hex: String?) -> Color? {
        guard let hex, let rgb = SpacePalette.rgbComponents(fromHex: hex) else { return nil }
        return Color(red: rgb.r, green: rgb.g, blue: rgb.b)
    }

    static func nsColor(fromHex hex: String?) -> NSColor? {
        guard let hex, let rgb = SpacePalette.rgbComponents(fromHex: hex) else { return nil }
        return NSColor(srgbRed: rgb.r, green: rgb.g, blue: rgb.b, alpha: 1)
    }

    /// Curated SF Symbols offered in the per-space icon picker.
    static let symbols: [String] = [
        "laptopcomputer", "terminal", "hammer", "envelope", "message",
        "calendar", "music.note", "headphones", "globe", "book",
        "doc.text", "folder", "gamecontroller", "paintbrush", "camera",
        "chart.bar", "cart", "house", "star", "safari",
    ]
}
