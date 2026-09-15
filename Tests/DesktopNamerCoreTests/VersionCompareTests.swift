import Foundation
import DesktopNamerCore

func runVersionCompareTests(_ t: TestRun) {
    t.suite("VersionCompare") {
        t.expect(!isVersionNewer(remote: "2.1.0", current: "2.1.0"), "equal versions are not newer")
        t.expect(isVersionNewer(remote: "2.1.1", current: "2.1.0"), "patch bump is newer")
        t.expect(isVersionNewer(remote: "2.2", current: "2.1.9"), "minor bump is newer")
        t.expect(isVersionNewer(remote: "3.0", current: "2.9.9"), "major bump is newer")
        t.expect(!isVersionNewer(remote: "2.0.9", current: "2.1.0"), "older remote is not newer")
        t.expect(!isVersionNewer(remote: "2.1", current: "2.1.0"), "shorter equal version pads with zeros")
        t.expect(isVersionNewer(remote: "2.1.0.1", current: "2.1"), "longer newer version pads with zeros")
        // "2.1-beta".split → ["2", "1-beta"] → compactMap Int → [2]; treated as 2.0.0
        t.expect(!isVersionNewer(remote: "2.1-beta", current: "2.1.0"), "non-numeric segments are ignored")
    }
}
