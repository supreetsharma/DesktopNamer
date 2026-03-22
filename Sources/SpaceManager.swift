import AppKit
import Combine

struct SpaceInfo: Identifiable, Equatable {
    let id: UInt64          // ManagedSpaceID from CGS
    let uuid: String        // Space UUID
    let index: Int          // 1-based index for display
    var displayName: String // User-assigned name
    let isCurrentSpace: Bool
}

@Observable
final class SpaceManager {
    var spaces: [SpaceInfo] = []
    var currentSpaceID: UInt64 = 0

    private let connection: Int32
    private let userDefaultsKey = "com.desktopnamer.spaceNames"
    private var observer: Any?

    var currentDesktopName: String {
        spaces.first(where: { $0.id == currentSpaceID })?.displayName ?? "Desktop"
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

        var allSpaces: [SpaceInfo] = []
        var index = 1

        for display in displaySpaces {
            guard let spaces = display["Spaces"] as? [[String: Any]] else { continue }

            for space in spaces {
                guard let spaceID = space["ManagedSpaceID"] as? UInt64,
                      let uuid = space["uuid"] as? String else { continue }

                // Skip fullscreen spaces (type 4) — only include regular desktops (type 0)
                let type = space["type"] as? Int ?? 0
                if type != 0 { continue }

                let defaultName = "Desktop \(index)"
                let displayName = savedNames[uuid] ?? defaultName

                allSpaces.append(SpaceInfo(
                    id: spaceID,
                    uuid: uuid,
                    index: index,
                    displayName: displayName,
                    isCurrentSpace: spaceID == activeSpace
                ))
                index += 1
            }
        }

        self.spaces = allSpaces
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

    // MARK: - Persistence

    private func loadSavedNames() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: String] ?? [:]
    }

    private func saveSavedNames(_ names: [String: String]) {
        UserDefaults.standard.set(names, forKey: userDefaultsKey)
    }
}
