import AppKit
import Combine

struct SpaceInfo: Identifiable, Equatable {
    let id: UInt64          // ManagedSpaceID from CGS
    let uuid: String        // Space UUID
    let displayUUID: String // Display Identifier from CGS
    let index: Int          // 1-based index for display
    var displayName: String // User-assigned name
    let isCurrentSpace: Bool
}

struct DisplayGroup: Identifiable, Equatable {
    let id: String          // Display UUID
    let displayName: String // Human-readable display name
    let spaces: [SpaceInfo]
}

@Observable
final class SpaceManager {
    var spaces: [SpaceInfo] = []
    var displayGroups: [DisplayGroup] = []
    var currentSpaceID: UInt64 = 0

    private let connection: Int32
    private let userDefaultsKey = "com.desktopnamer.spaceNames"
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

        let displaySpaces = CGSCopyManagedDisplaySpaces(connection) as! [[String: Any]]
        let savedNames = loadSavedNames()
        let screensByUUID = buildScreenMap()

        var allSpaces: [SpaceInfo] = []
        var groups: [DisplayGroup] = []
        var globalIndex = 1

        for display in displaySpaces {
            guard let spaces = display["Spaces"] as? [[String: Any]],
                  let displayID = display["Display Identifier"] as? String else { continue }

            var groupSpaces: [SpaceInfo] = []

            for space in spaces {
                guard let spaceID = space["ManagedSpaceID"] as? UInt64,
                      let uuid = space["uuid"] as? String else { continue }

                let type = space["type"] as? Int ?? 0
                if type != 0 { continue }

                let defaultName = "Desktop \(globalIndex)"
                let displayName = savedNames[uuid] ?? defaultName

                let info = SpaceInfo(
                    id: spaceID,
                    uuid: uuid,
                    displayUUID: displayID,
                    index: globalIndex,
                    displayName: displayName,
                    isCurrentSpace: spaceID == activeSpace
                )
                groupSpaces.append(info)
                allSpaces.append(info)
                globalIndex += 1
            }

            if !groupSpaces.isEmpty {
                let screenName = screensByUUID[displayID] ?? displayID
                groups.append(DisplayGroup(
                    id: displayID,
                    displayName: screenName,
                    spaces: groupSpaces
                ))
            }
        }

        self.spaces = allSpaces
        self.displayGroups = groups
    }

    func rename(spaceUUID: String, to newName: String) {
        var savedNames = loadSavedNames()
        savedNames[spaceUUID] = newName.isEmpty ? nil : newName
        saveSavedNames(savedNames)
        refresh()
    }

    func nameFor(uuid: String) -> String? {
        loadSavedNames()[uuid]
    }

    func switchToSpace(index: Int) {
        guard index >= 1, index <= spaces.count else { return }
        let target = spaces[index - 1]

        NSApp.keyWindow?.close()
        NSApp.deactivate()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            CGSManagedDisplaySetCurrentSpace(connection, target.displayUUID as CFString, target.id)
        }
    }

    func switchToSpaceByID(_ spaceID: UInt64) {
        guard let target = spaces.first(where: { $0.id == spaceID }) else { return }

        NSApp.keyWindow?.close()
        NSApp.deactivate()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            CGSManagedDisplaySetCurrentSpace(connection, target.displayUUID as CFString, target.id)
        }
    }

    // MARK: - Persistence

    private func loadSavedNames() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: String] ?? [:]
    }

    private func saveSavedNames(_ names: [String: String]) {
        UserDefaults.standard.set(names, forKey: userDefaultsKey)
    }

    // MARK: - Display Name Resolution

    private func buildScreenMap() -> [String: String] {
        var map: [String: String] = [:]
        for (i, screen) in NSScreen.screens.enumerated() {
            let name = screen.localizedName
            let key = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
            if let key {
                map[String(key)] = name
            }
            // Also map by index as fallback
            if i == 0 {
                map["Main"] = name
            }
        }
        return map
    }
}
