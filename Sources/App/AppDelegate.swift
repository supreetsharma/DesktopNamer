import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let spaceManager = SpaceManager()
    let updateChecker = UpdateChecker()

    private var statusItemController: StatusItemController?
    private var shortcutManager: KeyboardShortcutManager?
    private var missionControlOverlay: MissionControlOverlay?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItemController = StatusItemController(spaceManager: spaceManager,
                                                    updateChecker: updateChecker)

        let manager = KeyboardShortcutManager(spaceManager: spaceManager)
        manager.start()
        shortcutManager = manager

        missionControlOverlay = MissionControlOverlay(spaceManager: spaceManager)

        if OnboardingView.shouldShowOnboarding {
            NSApp.activate(ignoringOtherApps: true)
            if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "onboarding" }) {
                window.makeKeyAndOrderFront(nil)
            }
        }

        updateChecker.checkForUpdates(silent: true)
    }
}
