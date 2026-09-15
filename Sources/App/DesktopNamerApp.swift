import SwiftUI

@main
struct DesktopNamerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }

        Window("Welcome to Desktop Namer", id: "onboarding") {
            OnboardingView {
                NSApp.windows.first { $0.identifier?.rawValue == "onboarding" }?.close()
            }
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .defaultPosition(.center)
    }
}
