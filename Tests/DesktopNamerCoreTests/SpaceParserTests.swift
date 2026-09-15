import Foundation
import DesktopNamerCore

func runSpaceParserTests(_ t: TestRun) {
    func space(_ id: UInt64, _ uuid: String, type: Int = 0) -> [String: Any] {
        ["ManagedSpaceID": id, "uuid": uuid, "type": type]
    }
    func display(_ id: String, _ spaces: [[String: Any]]) -> [String: Any] {
        ["Display Identifier": id, "Spaces": spaces]
    }

    t.suite("SpaceParser") {
        do { // single display parses spaces in order
            let out = SpaceParser.parse(
                displaySpaces: [display("D1", [space(101, "u1"), space(102, "u2")])],
                savedNames: ["u2": "Mail"],
                activeSpace: 102,
                screenNames: ["D1": "Built-in Display"])
            t.expectEqual(out.spaces.count, 2, "two spaces parsed")
            t.expectEqual(out.spaces[0].displayName, "Desktop 1", "default name used")
            t.expectEqual(out.spaces[1].displayName, "Mail", "saved name used")
            t.expect(!out.spaces[0].isCurrentSpace, "inactive space is not current")
            t.expect(out.spaces[1].isCurrentSpace, "active space is current")
            t.expectEqual(out.groups.count, 1, "one display group")
            t.expectEqual(out.groups[0].displayName, "Built-in Display", "screen name resolved")
        }

        do { // multi display grouping and global indexing
            let out = SpaceParser.parse(
                displaySpaces: [
                    display("D1", [space(101, "u1")]),
                    display("D2", [space(201, "u2"), space(202, "u3")]),
                ],
                savedNames: [:],
                activeSpace: 201,
                screenNames: ["D1": "Built-in Display"]) // D2 unresolved
            t.expectEqual(out.groups.count, 2, "two display groups")
            t.expectEqual(out.groups[1].displayName, "Display 2", "fallback display name")
            t.expectEqual(out.spaces.map(\.index), [1, 2, 3], "indexing is global, not per-display")
            t.expectEqual(out.spaces[2].displayName, "Desktop 3", "default names use global index")
        }

        do { // fullscreen spaces are filtered
            let out = SpaceParser.parse(
                displaySpaces: [display("D1", [space(101, "u1"), space(102, "u2", type: 4)])],
                savedNames: [:],
                activeSpace: 101,
                screenNames: [:])
            t.expectEqual(out.spaces.count, 1, "fullscreen space filtered out")
            t.expectEqual(out.spaces[0].uuid, "u1", "user space kept")
        }

        do { // malformed entries are skipped without crashing
            let out = SpaceParser.parse(
                displaySpaces: [
                    ["Spaces": [space(101, "u1")]],                    // missing Display Identifier
                    display("D2", [["uuid": "u2"], space(201, "u3")]), // space missing ManagedSpaceID
                    ["Display Identifier": "D3"],                      // missing Spaces array
                ],
                savedNames: [:],
                activeSpace: 201,
                screenNames: [:])
            t.expectEqual(out.spaces.map(\.uuid), ["u3"], "only the well-formed space is kept")
            t.expectEqual(out.groups.count, 1, "only the well-formed display is grouped")
        }

        do { // display with only fullscreen spaces produces no group
            let out = SpaceParser.parse(
                displaySpaces: [display("D1", [space(101, "u1", type: 4)])],
                savedNames: [:],
                activeSpace: 0,
                screenNames: [:])
            t.expect(out.spaces.isEmpty, "no spaces")
            t.expect(out.groups.isEmpty, "no groups")
        }
    }
}
