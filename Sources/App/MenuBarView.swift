import SwiftUI
import ServiceManagement

struct MenuBarView: View {
    @Bindable var spaceManager: SpaceManager
    @State private var renamingSpace: SpaceInfo?
    @State private var renameText = ""
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header
            Text("Desktops")
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 4)

            Divider()

            // Desktop list — grouped by display if multiple monitors
            if spaceManager.hasMultipleDisplays {
                ForEach(spaceManager.displayGroups) { group in
                    // Display header
                    HStack(spacing: 4) {
                        Image(systemName: "display")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(group.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 6)
                    .padding(.bottom, 2)

                    ForEach(group.spaces) { space in
                        desktopRow(for: space)
                    }

                    if group.id != spaceManager.displayGroups.last?.id {
                        Divider()
                            .padding(.vertical, 2)
                    }
                }
            } else {
                ForEach(spaceManager.spaces) { space in
                    desktopRow(for: space)
                }
            }

            Divider()

            // Settings section
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .toggleStyle(.checkbox)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
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

            Button("Refresh") {
                spaceManager.refresh()
            }
            .keyboardShortcut("r")
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            Divider()

            Button("Quit Desktop Namer") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .frame(width: 280)
    }

    @ViewBuilder
    private func desktopRow(for space: SpaceInfo) -> some View {
        DesktopRow(space: space, isRenaming: renamingSpace?.id == space.id, renameText: $renameText) {
            spaceManager.switchToSpaceByID(space.id)
        } onStartRename: {
            renamingSpace = space
            renameText = space.displayName
        } onCommitRename: {
            if let uuid = renamingSpace?.uuid {
                spaceManager.rename(spaceUUID: uuid, to: renameText)
            }
            renamingSpace = nil
        } onCancelRename: {
            renamingSpace = nil
        }
    }
}

struct DesktopRow: View {
    let space: SpaceInfo
    let isRenaming: Bool
    @Binding var renameText: String
    let onNavigate: () -> Void
    let onStartRename: () -> Void
    let onCommitRename: () -> Void
    let onCancelRename: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(space.isCurrentSpace ? Color.blue : Color.clear)
                .frame(width: 6, height: 6)

            if isRenaming {
                TextField("Desktop name", text: $renameText, onCommit: onCommitRename)
                    .textFieldStyle(.roundedBorder)
                    .onExitCommand(perform: onCancelRename)

                Button("Done") { onCommitRename() }
                    .buttonStyle(.borderless)
                    .font(.caption)
            } else {
                Button {
                    onNavigate()
                } label: {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(space.displayName)
                            .fontWeight(space.isCurrentSpace ? .semibold : .regular)

                        Text("Space \(space.index)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .help("Switch to \(space.displayName)")

                Spacer()

                Button {
                    onStartRename()
                } label: {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
