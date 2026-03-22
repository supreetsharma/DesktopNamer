import SwiftUI

@main
struct DesktopNamerApp: App {
    @State private var spaceManager = SpaceManager()
    @State private var shortcutManager: KeyboardShortcutManager?

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(spaceManager: spaceManager)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "rectangle.split.3x1")
                Text(spaceManager.currentDesktopName)
            }
        }
        .menuBarExtraStyle(.window)
    }

    init() {
        // Schedule shortcut manager setup after init
        DispatchQueue.main.async { [self] in
            let manager = KeyboardShortcutManager(spaceManager: spaceManager)
            manager.start()
            shortcutManager = manager
        }
    }
}
