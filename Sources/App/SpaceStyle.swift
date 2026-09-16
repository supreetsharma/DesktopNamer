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

    // MARK: - Menu bar background pill

    static let menuBarBackgroundKey = "com.desktopnamer.menuBarBackgroundHex"

    /// One global background color for the menu bar title pill; nil = no pill.
    /// Reads validate the stored hex so a corrupt value renders as "no pill".
    static var menuBarBackgroundHex: String? {
        get {
            guard let hex = UserDefaults.standard.string(forKey: menuBarBackgroundKey),
                  SpacePalette.rgbComponents(fromHex: hex) != nil else { return nil }
            return hex
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: menuBarBackgroundKey)
            } else {
                UserDefaults.standard.removeObject(forKey: menuBarBackgroundKey)
            }
        }
    }

    /// Renders the menu bar title as a capsule: background pill, optional
    /// per-space chip dot, and the name in auto-contrast text.
    static func menuBarTitleImage(name: String, chipHex: String?, backgroundHex: String) -> NSImage? {
        guard let background = nsColor(fromHex: backgroundHex) else { return nil }

        let textColor: NSColor = SpacePalette.isLight(hex: backgroundHex) ? .black : .white
        let font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        let text = NSAttributedString(string: name, attributes: [.font: font, .foregroundColor: textColor])
        let textSize = text.size()

        let chip = nsColor(fromHex: chipHex)
        let chipDiameter: CGFloat = chip == nil ? 0 : 7
        let chipSpacing: CGFloat = chip == nil ? 0 : 5
        let horizontalPadding: CGFloat = 8
        let height: CGFloat = 17
        let width = horizontalPadding + chipDiameter + chipSpacing + ceil(textSize.width) + horizontalPadding

        return NSImage(size: NSSize(width: width, height: height), flipped: false) { rect in
            let capsule = NSBezierPath(roundedRect: rect, xRadius: rect.height / 2, yRadius: rect.height / 2)
            background.setFill()
            capsule.fill()

            if let chip {
                let chipRect = NSRect(x: horizontalPadding,
                                      y: (rect.height - chipDiameter) / 2,
                                      width: chipDiameter, height: chipDiameter)
                chip.setFill()
                NSBezierPath(ovalIn: chipRect).fill()
            }

            text.draw(at: NSPoint(x: horizontalPadding + chipDiameter + chipSpacing,
                                  y: (rect.height - textSize.height) / 2))
            return true
        }
    }
}
