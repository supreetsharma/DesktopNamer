import AppKit
import SwiftUI

/// Manages floating label overlays that appear on top of Mission Control
/// desktop thumbnails, showing the user's custom desktop names.
final class MissionControlOverlay {
    private weak var spaceManager: SpaceManager?
    private var overlayWindows: [NSWindow] = []
    private var activationWork: DispatchWorkItem?
    private var awakeObserver: NSObjectProtocol?
    private var sleepObserver: NSObjectProtocol?

    init(spaceManager: SpaceManager) {
        self.spaceManager = spaceManager

        // Mission Control open
        awakeObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("com.apple.expose.front.awake"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.onMissionControlActivated()
        }

        // Mission Control close
        sleepObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("com.apple.expose.front.sleep"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.onMissionControlDeactivated()
        }
    }

    deinit {
        if let awakeObserver {
            DistributedNotificationCenter.default().removeObserver(awakeObserver)
        }
        if let sleepObserver {
            DistributedNotificationCenter.default().removeObserver(sleepObserver)
        }
        removeAllOverlays()
    }

    // MARK: - Mission Control Lifecycle

    private func onMissionControlActivated() {
        // Cancel any pending work from rapid toggling
        activationWork?.cancel()

        // Wait for the Mission Control animation to settle
        let work = DispatchWorkItem { [weak self] in
            self?.showOverlays()
        }
        activationWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    private func onMissionControlDeactivated() {
        activationWork?.cancel()
        activationWork = nil
        removeAllOverlays()
    }

    // MARK: - Overlay Creation

    private func showOverlays() {
        guard let spaceManager else { return }
        spaceManager.refresh()

        removeAllOverlays()

        // Try Accessibility-based positioning first, fall back to heuristic
        let positions = findThumbnailPositionsViaAccessibility()
            ?? calculateThumbnailPositions()

        for (space, frame) in positions {
            let window = createOverlayWindow(space: space, thumbnailFrame: frame)
            overlayWindows.append(window)
            window.orderFrontRegardless()
        }
    }

    private func removeAllOverlays() {
        for window in overlayWindows {
            window.orderOut(nil)
            window.close()
        }
        overlayWindows.removeAll()
    }

    private func createOverlayWindow(space: SpaceInfo, thumbnailFrame: NSRect) -> NSWindow {
        let labelView = OverlayLabelView(name: space.displayName)
        let hostingView = NSHostingView(rootView: labelView)
        let contentSize = hostingView.intrinsicContentSize

        // Position label centered below the thumbnail
        let labelWidth = max(contentSize.width, 60)
        let labelHeight = max(contentSize.height, 24)
        let labelX = thumbnailFrame.midX - labelWidth / 2
        let labelY = thumbnailFrame.minY - labelHeight - 4 // just below thumbnail

        let windowFrame = NSRect(x: labelX, y: labelY, width: labelWidth, height: labelHeight)

        let window = NSWindow(
            contentRect: windowFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
        window.ignoresMouseEvents = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenNone]
        window.contentView = hostingView

        return window
    }

    // MARK: - Accessibility-Based Positioning

    private func findThumbnailPositionsViaAccessibility() -> [(SpaceInfo, NSRect)]? {
        guard AXIsProcessTrusted() else { return nil }
        guard let spaceManager else { return nil }

        // Find the Dock process
        guard let dockApp = NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.apple.dock"
        ).first else { return nil }

        let dockElement = AXUIElementCreateApplication(dockApp.processIdentifier)

        // Get all AX children of the Dock
        var childrenRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(dockElement, kAXChildrenAttribute as CFString, &childrenRef) == .success,
              let children = childrenRef as? [AXUIElement] else { return nil }

        // Look for the Mission Control list/group containing space thumbnails
        var thumbnailElements: [AXUIElement] = []
        findSpaceThumbnails(in: children, results: &thumbnailElements, depth: 0)

        guard !thumbnailElements.isEmpty else { return nil }

        // Extract positions from thumbnail elements
        var positions: [(NSRect)] = []
        for element in thumbnailElements {
            if let frame = axFrame(of: element) {
                positions.append(frame)
            }
        }

        // We need at least as many positions as spaces
        let allSpaces = spaceManager.spaces
        guard positions.count >= allSpaces.count else { return nil }

        // Sort positions left-to-right, top-to-bottom (for multi-monitor)
        positions.sort { a, b in
            if abs(a.origin.y - b.origin.y) > 50 { // different rows = different monitors
                return a.origin.y > b.origin.y // higher Y first (macOS coords)
            }
            return a.origin.x < b.origin.x
        }

        // Pair spaces with positions
        var result: [(SpaceInfo, NSRect)] = []
        for (i, space) in allSpaces.enumerated() {
            if i < positions.count {
                result.append((space, positions[i]))
            }
        }

        return result.isEmpty ? nil : result
    }

    /// Recursively search the AX tree for elements that look like space thumbnails
    private func findSpaceThumbnails(in elements: [AXUIElement], results: inout [AXUIElement], depth: Int) {
        guard depth < 8 else { return } // prevent infinite recursion

        for element in elements {
            var roleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
            let role = roleRef as? String ?? ""

            var descRef: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXDescriptionAttribute as CFString, &descRef)
            let desc = (descRef as? String ?? "").lowercased()

            var roleDescRef: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXRoleDescriptionAttribute as CFString, &roleDescRef)
            let roleDesc = (roleDescRef as? String ?? "").lowercased()

            // Look for elements that represent desktop spaces
            let isDesktopThumbnail =
                desc.contains("desktop") ||
                desc.contains("space") ||
                roleDesc.contains("desktop") ||
                (role == "AXButton" && desc.contains("desktop"))

            if isDesktopThumbnail && axFrame(of: element) != nil {
                results.append(element)
            }

            // Recurse into children
            var childrenRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef) == .success,
               let children = childrenRef as? [AXUIElement] {
                findSpaceThumbnails(in: children, results: &results, depth: depth + 1)
            }
        }
    }

    /// Get the frame (position + size) of an AX element in screen coordinates
    private func axFrame(of element: AXUIElement) -> NSRect? {
        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?

        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &posRef) == .success,
              AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef) == .success else {
            return nil
        }

        var point = CGPoint.zero
        var size = CGSize.zero

        guard AXValueGetValue(posRef as! AXValue, .cgPoint, &point),
              AXValueGetValue(sizeRef as! AXValue, .cgSize, &size) else {
            return nil
        }

        // AX uses top-left origin; convert to NSScreen bottom-left origin
        let screenHeight = NSScreen.main?.frame.height ?? 1080
        let flippedY = screenHeight - point.y - size.height

        return NSRect(x: point.x, y: flippedY, width: size.width, height: size.height)
    }

    // MARK: - Heuristic Fallback Positioning

    private func calculateThumbnailPositions() -> [(SpaceInfo, NSRect)] {
        guard let spaceManager else { return [] }

        var result: [(SpaceInfo, NSRect)] = []
        let connection = CGSDefaultConnection()

        for screen in NSScreen.screens {
            let displayUUID = CGSCopyBestManagedDisplayForRect(connection, screen.frame) as String

            // Find the display group for this screen
            guard let group = spaceManager.displayGroups.first(where: { $0.id == displayUUID }) else { continue }

            let spaces = group.spaces
            let n = spaces.count
            guard n > 0 else { continue }

            let screenFrame = screen.frame

            // Mission Control thumbnail strip: top ~13% of screen
            let stripHeight = screenFrame.height * 0.10
            let stripY = screenFrame.maxY - screenFrame.height * 0.13

            // Thumbnails distributed across ~80% of screen width
            let usableWidth = screenFrame.width * 0.75
            let leftMargin = screenFrame.minX + screenFrame.width * 0.125
            let thumbnailWidth = usableWidth / CGFloat(n)
            let thumbnailHeight = stripHeight

            for (i, space) in spaces.enumerated() {
                let thumbX = leftMargin + CGFloat(i) * thumbnailWidth
                let thumbFrame = NSRect(
                    x: thumbX,
                    y: stripY,
                    width: thumbnailWidth,
                    height: thumbnailHeight
                )
                result.append((space, thumbFrame))
            }
        }

        return result
    }
}

// MARK: - Overlay Label View

struct OverlayLabelView: View {
    let name: String

    var body: some View {
        Text(name)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(.black.opacity(0.75))
            )
    }
}
