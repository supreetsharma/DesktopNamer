import AppKit
import Carbon.HIToolbox

final class KeyboardShortcutManager {
    private var monitors: [Any] = []
    private weak var spaceManager: SpaceManager?

    init(spaceManager: SpaceManager) {
        self.spaceManager = spaceManager
    }

    func start() {
        // Global monitor for Ctrl+1 through Ctrl+9 to switch desktops
        let monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
        if let monitor { monitors.append(monitor) }

        // Local monitor for when the app itself has focus
        let localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKeyEvent(event) == true {
                return nil // consume the event
            }
            return event
        }
        if let localMonitor { monitors.append(localMonitor) }
    }

    func stop() {
        for monitor in monitors {
            NSEvent.removeMonitor(monitor)
        }
        monitors.removeAll()
    }

    @discardableResult
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        // Check for Ctrl modifier (without Cmd/Option/Shift)
        guard event.modifierFlags.contains(.control),
              !event.modifierFlags.contains(.command),
              !event.modifierFlags.contains(.option) else {
            return false
        }

        // Map key codes for number keys 1-9
        let keyCode = event.keyCode
        let numberKeys: [UInt16: Int] = [
            18: 1, 19: 2, 20: 3, 21: 4, 23: 5,
            22: 6, 26: 7, 28: 8, 25: 9
        ]

        guard let desktopIndex = numberKeys[keyCode],
              let spaceManager else { return false }

        let spaces = spaceManager.spaces
        guard desktopIndex <= spaces.count else { return false }

        _ = spaces[desktopIndex - 1]
        switchToSpace(index: desktopIndex)
        return true
    }

    private func switchToSpace(index: Int) {
        // Use keyboard shortcut simulation via Ctrl+Arrow keys with CGEvent
        // macOS supports switching spaces via Ctrl+Left/Right arrow
        // We'll use AppleScript to trigger Mission Control keyboard shortcuts
        let script = """
        tell application "System Events"
            key code \(17 + index) using control down
        end tell
        """

        // Note: Direct space switching via Ctrl+Number requires the user to have
        // enabled "Switch to Desktop N" shortcuts in System Preferences >
        // Keyboard > Shortcuts > Mission Control
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }

    deinit {
        stop()
    }
}
