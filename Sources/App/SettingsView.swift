import SwiftUI
import ServiceManagement
import KeyboardShortcuts

struct SettingsView: View {
    @State private var shortcutsEnabled = KeyboardShortcutManager.shortcutsEnabled
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var showSwitchHUD = SwitchHUD.isEnabled
    @State private var updateChecker = UpdateChecker()

    var body: some View {
        Form {
            Section {
                Toggle("Enable desktop switching shortcuts", isOn: $shortcutsEnabled)
                    .onChange(of: shortcutsEnabled) { _, newValue in
                        KeyboardShortcutManager.shortcutsEnabled = newValue
                    }

                ForEach(Array(SpaceShortcuts.all.enumerated()), id: \.offset) { index, name in
                    KeyboardShortcuts.Recorder("Desktop \(index + 1):", name: name)
                        .disabled(!shortcutsEnabled)
                }

                KeyboardShortcuts.Recorder("Quick switcher:", name: .quickSwitcher)
            } header: {
                Text("Shortcuts")
            } footer: {
                Text("Click a field and press a key combination to change it. Press ⌫ to remove one.")
                    .foregroundStyle(.secondary)
            }

            Section("General") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }

                Toggle("Show name when switching desktops", isOn: $showSwitchHUD)
                    .onChange(of: showSwitchHUD) { _, newValue in
                        SwitchHUD.isEnabled = newValue
                    }
            }

            Section("Updates") {
                LabeledContent("Version",
                               value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—")
                Button("Check for Updates...") {
                    updateChecker.checkForUpdates()
                }
                .disabled(updateChecker.isChecking)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400)
        .fixedSize()
    }
}
