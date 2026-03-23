#!/usr/bin/env swift
// Generates DesktopNamer.icns from code
import AppKit

func createIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = size * 0.22

    // Background gradient — deep blue to purple
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    let gradient = NSGradient(
        starting: NSColor(red: 0.15, green: 0.25, blue: 0.75, alpha: 1.0),
        ending: NSColor(red: 0.45, green: 0.20, blue: 0.85, alpha: 1.0)
    )!
    gradient.draw(in: path, angle: -45)

    // Draw 3 desktop rectangles
    let margin = size * 0.15
    let spacing = size * 0.04
    let totalWidth = size - margin * 2
    let rectWidth = (totalWidth - spacing * 2) / 3
    let rectHeight = size * 0.35
    let rectY = size * 0.38

    for i in 0..<3 {
        let x = margin + CGFloat(i) * (rectWidth + spacing)
        let desktopRect = NSRect(x: x, y: rectY, width: rectWidth, height: rectHeight)
        let desktopPath = NSBezierPath(roundedRect: desktopRect, xRadius: size * 0.03, yRadius: size * 0.03)

        // Active desktop (middle) is brighter
        if i == 1 {
            NSColor(white: 1.0, alpha: 0.95).setFill()
        } else {
            NSColor(white: 1.0, alpha: 0.4).setFill()
        }
        desktopPath.fill()

        // Small lines inside to suggest content
        NSColor(white: 0.5, alpha: i == 1 ? 0.5 : 0.3).setFill()
        let lineY1 = rectY + rectHeight * 0.65
        let lineY2 = rectY + rectHeight * 0.4
        let lineWidth = rectWidth * 0.6
        let lineX = x + (rectWidth - lineWidth) / 2
        NSBezierPath(roundedRect: NSRect(x: lineX, y: lineY1, width: lineWidth, height: size * 0.02),
                     xRadius: 1, yRadius: 1).fill()
        NSBezierPath(roundedRect: NSRect(x: lineX, y: lineY2, width: lineWidth * 0.75, height: size * 0.02),
                     xRadius: 1, yRadius: 1).fill()
    }

    // "DN" text at bottom
    let fontSize = size * 0.14
    let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
    let text = "DN"
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(white: 1.0, alpha: 0.9),
    ]
    let textSize = text.size(withAttributes: attrs)
    let textX = (size - textSize.width) / 2
    let textY = size * 0.17
    text.draw(at: NSPoint(x: textX, y: textY), withAttributes: attrs)

    image.unlockFocus()
    return image
}

// Generate iconset
let sizes: [(CGFloat, String)] = [
    (16,   "icon_16x16.png"),
    (32,   "icon_16x16@2x.png"),
    (32,   "icon_32x32.png"),
    (64,   "icon_32x32@2x.png"),
    (128,  "icon_128x128.png"),
    (256,  "icon_128x128@2x.png"),
    (256,  "icon_256x256.png"),
    (512,  "icon_256x256@2x.png"),
    (512,  "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

let fm = FileManager.default
let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let projectDir = scriptDir.deletingLastPathComponent()
let iconsetDir = projectDir.appendingPathComponent("Resources/AppIcon.iconset")

try? fm.removeItem(at: iconsetDir)
try fm.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

for (size, filename) in sizes {
    let image = createIcon(size: size)
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to create \(filename)")
        continue
    }
    try png.write(to: iconsetDir.appendingPathComponent(filename))
    print("Created \(filename) (\(Int(size))x\(Int(size)))")
}

// Convert to .icns
let icnsPath = projectDir.appendingPathComponent("Resources/AppIcon.icns")
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetDir.path, "-o", icnsPath.path]
try process.run()
process.waitUntilExit()

if process.terminationStatus == 0 {
    print("Created AppIcon.icns")
    try? fm.removeItem(at: iconsetDir) // clean up iconset
} else {
    print("iconutil failed with status \(process.terminationStatus)")
}
