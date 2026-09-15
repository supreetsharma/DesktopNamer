import Foundation

/// Pure parsing of the dictionary array returned by CGSCopyManagedDisplaySpaces.
public enum SpaceParser {
    public struct Output: Equatable {
        public let spaces: [SpaceInfo]
        public let groups: [DisplayGroup]

        public init(spaces: [SpaceInfo], groups: [DisplayGroup]) {
            self.spaces = spaces
            self.groups = groups
        }
    }

    public static func parse(
        displaySpaces: [[String: Any]],
        savedNames: [String: String],
        activeSpace: UInt64,
        screenNames: [String: String]
    ) -> Output {
        var allSpaces: [SpaceInfo] = []
        var groups: [DisplayGroup] = []
        var globalIndex = 1

        for (displayIndex, display) in displaySpaces.enumerated() {
            guard let spaces = display["Spaces"] as? [[String: Any]],
                  let displayID = display["Display Identifier"] as? String else { continue }

            var groupSpaces: [SpaceInfo] = []

            for space in spaces {
                guard let spaceID = space["ManagedSpaceID"] as? UInt64,
                      let uuid = space["uuid"] as? String else { continue }

                let type = space["type"] as? Int ?? 0
                if type != 0 { continue } // 0 = user space; others are fullscreen/system

                let info = SpaceInfo(
                    id: spaceID,
                    uuid: uuid,
                    displayUUID: displayID,
                    index: globalIndex,
                    displayName: savedNames[uuid] ?? "Desktop \(globalIndex)",
                    isCurrentSpace: spaceID == activeSpace
                )
                groupSpaces.append(info)
                allSpaces.append(info)
                globalIndex += 1
            }

            if !groupSpaces.isEmpty {
                groups.append(DisplayGroup(
                    id: displayID,
                    displayName: screenNames[displayID] ?? "Display \(displayIndex + 1)",
                    spaces: groupSpaces
                ))
            }
        }

        return Output(spaces: allSpaces, groups: groups)
    }
}
