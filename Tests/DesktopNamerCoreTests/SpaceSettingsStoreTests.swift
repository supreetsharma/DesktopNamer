import Foundation
import DesktopNamerCore

func runSpaceSettingsStoreTests(_ t: TestRun) {
    let suiteName = "com.desktopnamer.tests"
    func freshDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    t.suite("SpaceSettingsStore") {
        do { // empty store returns defaults
            let defaults = freshDefaults()
            let store = SpaceSettingsStore(defaults: defaults)
            t.expectEqual(store.settings(for: "uuid-1"), SpaceSettings(), "empty store returns default settings")
            t.expect(store.namesByUUID.isEmpty, "empty store has no names")
        }

        do { // set name persists across instances
            let defaults = freshDefaults()
            SpaceSettingsStore(defaults: defaults).setName("Code", for: "uuid-1")
            let reloaded = SpaceSettingsStore(defaults: defaults)
            t.expectEqual(reloaded.settings(for: "uuid-1").name, "Code", "name persists across instances")
            t.expectEqual(reloaded.namesByUUID, ["uuid-1": "Code"], "namesByUUID reflects saved name")
        }

        do { // setting empty or nil name clears the entry
            let defaults = freshDefaults()
            let store = SpaceSettingsStore(defaults: defaults)
            store.setName("Code", for: "uuid-1")
            store.setName("", for: "uuid-1")
            t.expect(store.settings(for: "uuid-1").name == nil, "empty name clears the entry")
            store.setName("Mail", for: "uuid-2")
            store.setName(nil, for: "uuid-2")
            t.expect(store.namesByUUID.isEmpty, "nil name clears the entry")
        }

        do { // migrates legacy names on first launch
            let defaults = freshDefaults()
            defaults.set(["uuid-1": "Code", "uuid-2": "Mail"],
                         forKey: SpaceSettingsStore.legacyNamesKey)
            let store = SpaceSettingsStore(defaults: defaults)
            t.expectEqual(store.namesByUUID, ["uuid-1": "Code", "uuid-2": "Mail"], "legacy names migrate")
            t.expect(defaults.dictionary(forKey: SpaceSettingsStore.legacyNamesKey) != nil,
                     "legacy key survives migration (safe downgrade)")
            t.expect(defaults.data(forKey: SpaceSettingsStore.settingsKey) != nil,
                     "migration writes the new key")
        }

        do { // new key wins over legacy key
            let defaults = freshDefaults()
            defaults.set(["uuid-1": "Old"], forKey: SpaceSettingsStore.legacyNamesKey)
            SpaceSettingsStore(defaults: defaults).setName("New", for: "uuid-1") // migrates, then renames
            let second = SpaceSettingsStore(defaults: defaults)
            t.expectEqual(second.settings(for: "uuid-1").name, "New", "new key wins over legacy")
        }

        do { // corrupted settings data falls back to legacy, then empty — never crashes
            let defaults = freshDefaults()
            defaults.set(Data("not json".utf8), forKey: SpaceSettingsStore.settingsKey)
            defaults.set(["uuid-1": "Code"], forKey: SpaceSettingsStore.legacyNamesKey)
            let store = SpaceSettingsStore(defaults: defaults)
            t.expectEqual(store.namesByUUID, ["uuid-1": "Code"], "corrupted data falls back to legacy")

            defaults.removeObject(forKey: SpaceSettingsStore.legacyNamesKey)
            defaults.set(Data("not json".utf8), forKey: SpaceSettingsStore.settingsKey)
            let store2 = SpaceSettingsStore(defaults: defaults)
            t.expect(store2.namesByUUID.isEmpty, "corrupted data with no legacy starts empty")
        }

        do { // color and symbol persist and coexist with name
            let defaults = freshDefaults()
            let store = SpaceSettingsStore(defaults: defaults)
            store.setName("Code", for: "uuid-1")
            store.setColorHex("0A84FF", for: "uuid-1")
            store.setSymbol("hammer", for: "uuid-1")
            let reloaded = SpaceSettingsStore(defaults: defaults)
            t.expectEqual(reloaded.settings(for: "uuid-1"),
                          SpaceSettings(name: "Code", colorHex: "0A84FF", symbol: "hammer"),
                          "name, color and symbol persist together")
            t.expectEqual(reloaded.settingsByUUID["uuid-1"],
                          SpaceSettings(name: "Code", colorHex: "0A84FF", symbol: "hammer"),
                          "settingsByUUID exposes the full entry")
        }

        do { // clearing the only field removes the entry entirely
            let defaults = freshDefaults()
            let store = SpaceSettingsStore(defaults: defaults)
            store.setColorHex("FF453A", for: "uuid-1")
            store.setColorHex(nil, for: "uuid-1")
            t.expect(store.settingsByUUID.isEmpty, "clearing the only field removes the entry")
        }

        do { // color survives renames and name clearing
            let defaults = freshDefaults()
            let store = SpaceSettingsStore(defaults: defaults)
            store.setColorHex("FF9F0A", for: "uuid-1")
            store.setName("Mail", for: "uuid-1")
            t.expectEqual(store.settings(for: "uuid-1").colorHex, "FF9F0A", "color survives a rename")
            store.setName(nil, for: "uuid-1")
            t.expectEqual(store.settings(for: "uuid-1").colorHex, "FF9F0A", "color survives clearing the name")
        }

        UserDefaults(suiteName: suiteName)!.removePersistentDomain(forName: suiteName)
    }
}
