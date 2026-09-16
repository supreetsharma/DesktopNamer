import AppKit
import SwiftUI
import DesktopNamerCore

/// Owns the NSStatusItem: renders the current desktop name as a semibold
/// attributed title, shows the SwiftUI dropdown in a transient popover, and
/// cycles desktops on scroll-wheel events over the status item.
/// @MainActor: all AppKit work is main-thread, and actor isolation makes the
/// class Sendable so the @Sendable observation onChange closure can capture it.
@MainActor
final class StatusItemController {
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let spaceManager: SpaceManager
    private var scrollMonitor: Any?
    private var lastScrollSwitch = Date.distantPast
    private var defaultsObserver: NSObjectProtocol?

    init(spaceManager: SpaceManager, updateChecker: UpdateChecker) {
        self.spaceManager = spaceManager
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "rectangle.split.3x1",
                                   accessibilityDescription: "Desktop Namer")
            button.imagePosition = .imageLeading
            button.target = self
            button.action = #selector(togglePopover)
        }

        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView(
                spaceManager: spaceManager,
                updateChecker: updateChecker,
                dismiss: { [weak self] in self?.popover.performClose(nil) }
            )
        )

        observeTitle()
        installScrollMonitor()

        // Re-render when the pill setting changes in Settings (UserDefaults is
        // outside @Observable tracking).
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateTitle()
            }
        }
    }

    deinit {
        if let defaultsObserver {
            NotificationCenter.default.removeObserver(defaultsObserver)
        }
        if let scrollMonitor {
            NSEvent.removeMonitor(scrollMonitor)
        }
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    // MARK: - Title

    private func updateTitle() {
        let current = spaceManager.spaces.first { $0.id == spaceManager.currentSpaceID }
        let name = current?.displayName ?? "Desktop"

        if let backgroundHex = SpaceStyle.menuBarBackgroundHex,
           let pill = SpaceStyle.menuBarTitleImage(name: name,
                                                   chipHex: current?.colorHex,
                                                   backgroundHex: backgroundHex) {
            let attachment = NSTextAttachment()
            attachment.image = pill
            // Nudge the pill down so it centers against the menu bar's text line.
            attachment.bounds = NSRect(x: 0,
                                       y: (NSFont.systemFontSize - pill.size.height) / 2,
                                       width: pill.size.width,
                                       height: pill.size.height)
            let title = NSMutableAttributedString(string: " ")
            title.append(NSAttributedString(attachment: attachment))
            statusItem.button?.attributedTitle = title
            return
        }

        let title = NSMutableAttributedString()
        if let chipColor = SpaceStyle.nsColor(fromHex: current?.colorHex) {
            title.append(NSAttributedString(string: " ●", attributes: [
                .foregroundColor: chipColor,
                .font: NSFont.systemFont(ofSize: NSFont.systemFontSize - 3),
                .baselineOffset: 1,
            ]))
        }
        title.append(NSAttributedString(string: " \(name)", attributes: [
            .font: NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .semibold),
        ]))
        statusItem.button?.attributedTitle = title
    }

    /// Re-render the title whenever @Observable SpaceManager state it reads changes.
    private func observeTitle() {
        withObservationTracking {
            updateTitle()
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.observeTitle()
            }
        }
    }

    // MARK: - Popover

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else if let button = statusItem.button {
            spaceManager.refresh()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    // MARK: - Scroll to cycle

    private func installScrollMonitor() {
        // The status item's window belongs to this app, so a LOCAL monitor sees
        // scroll events over it. Local monitors observe without consuming.
        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self, event.window === self.statusItem.button?.window else { return event }
            self.handleScroll(deltaY: event.scrollingDeltaY)
            return nil
        }
    }

    private func handleScroll(deltaY: CGFloat) {
        guard abs(deltaY) > 0.5,
              Date().timeIntervalSince(lastScrollSwitch) > 0.25 else { return }
        lastScrollSwitch = Date()

        if deltaY > 0 {
            spaceManager.switchToPreviousSpace()
        } else {
            spaceManager.switchToNextSpace()
        }
    }
}
