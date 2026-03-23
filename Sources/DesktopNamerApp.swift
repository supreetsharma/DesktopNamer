import SwiftUI

@main
struct DesktopNamerApp: App {
    @State private var spaceManager = SpaceManager()
    @State private var shortcutManager: KeyboardShortcutManager?
    @State private var missionControlOverlay: MissionControlOverlay?
    @State private var showOnboarding = OnboardingView.shouldShowOnboarding
    @State private var updateChecker = UpdateChecker()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(spaceManager: spaceManager)

            Divider()

            Button("Check for Updates...") {
                updateChecker.checkForUpdates()
            }
            .disabled(updateChecker.isChecking)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "rectangle.split.3x1")
                Text("**\(spaceManager.currentDesktopName)**")
            }
        }
        .menuBarExtraStyle(.window)

        // Onboarding window
        Window("Welcome to Desktop Namer", id: "onboarding") {
            OnboardingView {
                showOnboarding = false
                NSApp.windows.first { $0.identifier?.rawValue == "onboarding" }?.close()
            }
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .defaultPosition(.center)
    }

    init() {
        DispatchQueue.main.async { [self] in
            let manager = KeyboardShortcutManager(spaceManager: spaceManager)
            manager.start()
            shortcutManager = manager

            // Mission Control overlay labels
            missionControlOverlay = MissionControlOverlay(spaceManager: spaceManager)

            if OnboardingView.shouldShowOnboarding {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "onboarding" }) {
                    window.makeKeyAndOrderFront(nil)
                }
            }

            // Silent update check on launch
            updateChecker.checkForUpdates(silent: true)
        }
    }
}
