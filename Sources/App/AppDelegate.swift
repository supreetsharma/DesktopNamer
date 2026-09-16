import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let spaceManager = SpaceManager()
    let updateChecker = UpdateChecker()

    private var statusItemController: StatusItemController?
    private var shortcutManager: KeyboardShortcutManager?
    private var switchHUD: SwitchHUD?
    private var quickSwitcher: QuickSwitcher?
    private var onboardingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItemController = StatusItemController(spaceManager: spaceManager,
                                                    updateChecker: updateChecker)

        let manager = KeyboardShortcutManager(spaceManager: spaceManager)
        quickSwitcher = QuickSwitcher(spaceManager: spaceManager)
        manager.onQuickSwitcher = { [weak self] in
            self?.quickSwitcher?.toggle()
        }
        manager.start()
        shortcutManager = manager

        switchHUD = SwitchHUD(spaceManager: spaceManager)

        if OnboardingView.shouldShowOnboarding {
            showOnboardingWindow()
        }

        updateChecker.checkForUpdates(silent: true)
    }

    private func showOnboardingWindow() {
        let hosting = NSHostingController(rootView: OnboardingView { [weak self] in
            self?.onboardingWindow?.close()
            self?.onboardingWindow = nil
        })
        let window = NSWindow(contentViewController: hosting)
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.center()
        onboardingWindow = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
