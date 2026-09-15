import Foundation

public struct SpaceInfo: Identifiable, Equatable {
    public let id: UInt64          // ManagedSpaceID from CGS
    public let uuid: String        // Space UUID
    public let displayUUID: String // Display Identifier from CGS
    public let index: Int          // 1-based index for display
    public var displayName: String // User-assigned name
    public let isCurrentSpace: Bool

    public init(id: UInt64, uuid: String, displayUUID: String, index: Int,
                displayName: String, isCurrentSpace: Bool) {
        self.id = id
        self.uuid = uuid
        self.displayUUID = displayUUID
        self.index = index
        self.displayName = displayName
        self.isCurrentSpace = isCurrentSpace
    }
}

public struct DisplayGroup: Identifiable, Equatable {
    public let id: String          // Display UUID
    public let displayName: String // Human-readable display name
    public let spaces: [SpaceInfo]

    public init(id: String, displayName: String, spaces: [SpaceInfo]) {
        self.id = id
        self.displayName = displayName
        self.spaces = spaces
    }
}
