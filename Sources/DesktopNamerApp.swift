import SwiftUI
import Sparkle

@main
struct DesktopNamerApp: App {
    @State private var spaceManager = SpaceManager()
    @State private var shortcutManager: KeyboardShortcutManager?
    @State private var showOnboarding = OnboardingView.shouldShowOnboarding

    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(spaceManager: spaceManager)

            Divider()

            Button("Check for Updates...") {
                updaterController.updater.checkForUpdates()
            }
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
                // Close the onboarding window
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

            // Show onboarding on first launch
            if OnboardingView.shouldShowOnboarding {
                NSApp.activate(ignoringOtherApps: true)
                // Open the onboarding window
                if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "onboarding" }) {
                    window.makeKeyAndOrderFront(nil)
                }
            }
        }
    }
}
