import AppKit
import Combine
import DesktopNamerCore
import os

@Observable
final class SpaceManager {
    var spaces: [SpaceInfo] = []
    var displayGroups: [DisplayGroup] = []
    var currentSpaceID: UInt64 = 0

    private let connection: Int32
    private let settingsStore = SpaceSettingsStore()
    private let logger = Logger(subsystem: "com.desktopnamer", category: "SpaceManager")
    private var observer: Any?

    var currentDesktopName: String {
        spaces.first(where: { $0.id == currentSpaceID })?.displayName ?? "Desktop"
    }

    var hasMultipleDisplays: Bool {
        displayGroups.count > 1
    }

    init() {
        connection = CGSDefaultConnection()
        refresh()

        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }
    }

    deinit {
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    func refresh() {
        let activeSpace = CGSGetActiveSpace(connection)
        currentSpaceID = activeSpace

        guard let displaySpaces = CGSCopyManagedDisplaySpaces(connection) as? [[String: Any]] else {
            logger.error("CGSCopyManagedDisplaySpaces returned unexpected shape; keeping last-known spaces")
            return
        }

        let output = SpaceParser.parse(
            displaySpaces: displaySpaces,
            savedNames: settingsStore.namesByUUID,
            activeSpace: activeSpace,
            screenNames: buildScreenMap()
        )
        self.spaces = output.spaces
        self.displayGroups = output.groups
    }

    func rename(spaceUUID: String, to newName: String) {
        settingsStore.setName(newName, for: spaceUUID)
        refresh()
    }

    func nameFor(uuid: String) -> String? {
        settingsStore.settings(for: uuid).name
    }

    func switchToSpace(index: Int) {
        guard index >= 1, index <= spaces.count else { return }
        switchToSpaceByID(spaces[index - 1].id)
    }

    func switchToSpaceByID(_ spaceID: UInt64) {
        guard let target = spaces.first(where: { $0.id == spaceID }) else { return }

        NSApp.keyWindow?.close()
        NSApp.deactivate()
        performSwitch(to: target, attempt: 1)
    }

    func switchToNextSpace() {
        cycle(by: 1)
    }

    func switchToPreviousSpace() {
        cycle(by: -1)
    }

    private func cycle(by offset: Int) {
        guard !spaces.isEmpty,
              let current = spaces.firstIndex(where: { $0.id == currentSpaceID }) else { return }
        let next = (current + offset + spaces.count) % spaces.count
        switchToSpaceByID(spaces[next].id)
    }

    /// Issues the CGS switch on the next runloop turn (after deactivation settles),
    /// verifies it landed 150 ms later, and retries once. The retry is idempotent, so
    /// a false negative on multi-display setups (active space tracks the main display)
    /// is harmless.
    private func performSwitch(to target: SpaceInfo, attempt: Int) {
        DispatchQueue.main.async { [self] in
            CGSManagedDisplaySetCurrentSpace(connection, target.displayUUID as CFString, target.id)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
                if CGSGetActiveSpace(connection) != target.id, attempt < 2 {
                    logger.info("Space switch to \(target.id) not confirmed; retrying")
                    performSwitch(to: target, attempt: attempt + 1)
                } else {
                    refresh()
                }
            }
        }
    }

    // MARK: - Display Name Resolution

    private func buildScreenMap() -> [String: String] {
        var map: [String: String] = [:]
        for (i, screen) in NSScreen.screens.enumerated() {
            // Use CGSCopyBestManagedDisplayForRect to get the CGS display UUID
            // that matches what CGSCopyManagedDisplaySpaces returns
            let displayUUID = CGSCopyBestManagedDisplayForRect(connection, screen.frame) as String
            map[displayUUID] = screen.localizedName

            // Fallback: also map "Main" for the primary display
            if i == 0 {
                map["Main"] = screen.localizedName
            }
        }
        return map
    }
}
