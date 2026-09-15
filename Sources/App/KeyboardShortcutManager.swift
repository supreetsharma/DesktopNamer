import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let switchToSpace1 = Self("switchToSpace1", default: .init(.one, modifiers: [.control]))
    static let switchToSpace2 = Self("switchToSpace2", default: .init(.two, modifiers: [.control]))
    static let switchToSpace3 = Self("switchToSpace3", default: .init(.three, modifiers: [.control]))
    static let switchToSpace4 = Self("switchToSpace4", default: .init(.four, modifiers: [.control]))
    static let switchToSpace5 = Self("switchToSpace5", default: .init(.five, modifiers: [.control]))
    static let switchToSpace6 = Self("switchToSpace6", default: .init(.six, modifiers: [.control]))
    static let switchToSpace7 = Self("switchToSpace7", default: .init(.seven, modifiers: [.control]))
    static let switchToSpace8 = Self("switchToSpace8", default: .init(.eight, modifiers: [.control]))
    static let switchToSpace9 = Self("switchToSpace9", default: .init(.nine, modifiers: [.control]))
}

enum SpaceShortcuts {
    /// Ordered: element at index i-1 switches to desktop i.
    static let all: [KeyboardShortcuts.Name] = [
        .switchToSpace1, .switchToSpace2, .switchToSpace3,
        .switchToSpace4, .switchToSpace5, .switchToSpace6,
        .switchToSpace7, .switchToSpace8, .switchToSpace9,
    ]
}

/// Registers desktop-switching hotkeys via Carbon RegisterEventHotKey
/// (through the KeyboardShortcuts package). Unlike the previous NSEvent
/// global monitor, these shortcuts consume the key event and require no
/// Accessibility permission.
final class KeyboardShortcutManager {
    private static let enabledKey = "com.desktopnamer.shortcutsEnabled"
    private weak var spaceManager: SpaceManager?

    static var shortcutsEnabled: Bool {
        get { UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true }
        set {
            UserDefaults.standard.set(newValue, forKey: enabledKey)
            if newValue {
                KeyboardShortcuts.enable(SpaceShortcuts.all)
            } else {
                KeyboardShortcuts.disable(SpaceShortcuts.all)
            }
        }
    }

    init(spaceManager: SpaceManager) {
        self.spaceManager = spaceManager
    }

    func start() {
        for (i, name) in SpaceShortcuts.all.enumerated() {
            KeyboardShortcuts.onKeyDown(for: name) { [weak self] in
                self?.spaceManager?.switchToSpace(index: i + 1)
            }
        }
        if !Self.shortcutsEnabled {
            KeyboardShortcuts.disable(SpaceShortcuts.all)
        }
    }
}
