import Foundation

/// Per-space user settings. v2.1 uses only `name`; `colorHex`/`symbol` land in v2.2.
public struct SpaceSettings: Codable, Equatable {
    public var name: String?
    public var colorHex: String?
    public var symbol: String?

    public init(name: String? = nil, colorHex: String? = nil, symbol: String? = nil) {
        self.name = name
        self.colorHex = colorHex
        self.symbol = symbol
    }
}

/// Persists per-space settings as JSON in UserDefaults, keyed by space UUID.
/// Migrates from the legacy plain-name dictionary once; the legacy key is
/// deliberately never removed so older builds still find their data.
public final class SpaceSettingsStore {
    public static let settingsKey = "com.desktopnamer.spaceSettings"
    public static let legacyNamesKey = "com.desktopnamer.spaceNames"

    private let defaults: UserDefaults
    private var cache: [String: SpaceSettings]

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.settingsKey),
           let decoded = try? JSONDecoder().decode([String: SpaceSettings].self, from: data) {
            cache = decoded
        } else if let legacy = defaults.dictionary(forKey: Self.legacyNamesKey) as? [String: String] {
            cache = legacy.mapValues { SpaceSettings(name: $0) }
            persist()
        } else {
            cache = [:]
        }
    }

    public func settings(for uuid: String) -> SpaceSettings {
        cache[uuid] ?? SpaceSettings()
    }

    public var namesByUUID: [String: String] {
        cache.compactMapValues(\.name)
    }

    public func setName(_ name: String?, for uuid: String) {
        var settings = cache[uuid] ?? SpaceSettings()
        settings.name = (name?.isEmpty ?? true) ? nil : name
        cache[uuid] = settings == SpaceSettings() ? nil : settings
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(cache) else { return }
        defaults.set(data, forKey: Self.settingsKey)
    }
}
