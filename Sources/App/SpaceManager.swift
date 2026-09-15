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

        guard let displaySpaces = CGSCopyManagedDisplaySpaces(connection) as? [[String: Any]] else {
            logger.error("CGSCopyManagedDisplaySpaces returned unexpected shape; keeping last-known spaces")
            return
        }

        currentSpaceID = activeSpace

        let output = SpaceParser.parse(
            displaySpaces: displaySpaces,
            savedSettings: settingsStore.settingsByUUID,
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

    func setColorHex(_ colorHex: String?, forUUID uuid: String) {
        settingsStore.setColorHex(colorHex, for: uuid)
        refresh()
    }

    func setSymbol(_ symbol: String?, forUUID uuid: String) {
        settingsStore.setSymbol(symbol, for: uuid)
        refresh()
    }

    func switchToSpace(index: Int) {
        guard index >= 1, index <= spaces.count else { return }
        switchToSpaceByID(spaces[index - 1].id)
    }

    func switchToSpaceByID(_ spaceID: UInt64) {
        guard let target = spaces.first(where: { $0.id == spaceID }) else { return }

        NSApp.keyWindow?.close()
        NSApp.deactivate()
        switchGeneration += 1
        performSwitch(to: target, attempt: 1, generation: switchGeneration)
    }

    func switchToNextSpace() {
        cycle(by: 1)
    }

    func switchToPreviousSpace() {
        cycle(by: -1)
    }

    private func cycle(by offset: Int) {
        guard spaces.count > 1,
              let current = spaces.firstIndex(where: { $0.id == currentSpaceID }) else { return }
        let next = (current + offset + spaces.count) % spaces.count
        switchToSpaceByID(spaces[next].id)
    }

    /// Monotonically increasing token; each new switch request invalidates the
    /// pending verification/retry of any earlier one, so a stale retry can never
    /// yank the user back to a previously requested space during rapid switching.
    private var switchGeneration = 0

    /// Issues the CGS switch on the next runloop turn (after deactivation settles),
    /// verifies it landed 150 ms later, and retries once. Retries are abandoned if a
    /// newer switch request superseded this one (generation check); a false negative
    /// on multi-display setups (active space tracks the main display) only causes one
    /// harmless idempotent retry.
    private func performSwitch(to target: SpaceInfo, attempt: Int, generation: Int) {
        DispatchQueue.main.async { [self] in
            guard generation == switchGeneration else { return }
            CGSManagedDisplaySetCurrentSpace(connection, target.displayUUID as CFString, target.id)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
                guard generation == switchGeneration else { return }
                if CGSGetActiveSpace(connection) != target.id, attempt < 2 {
                    logger.info("Space switch to \(target.id) not confirmed; retrying")
                    performSwitch(to: target, attempt: attempt + 1, generation: generation)
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
