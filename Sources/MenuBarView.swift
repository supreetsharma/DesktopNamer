import SwiftUI

struct MenuBarView: View {
    @Bindable var spaceManager: SpaceManager
    @State private var renamingSpace: SpaceInfo?
    @State private var renameText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header
            Text("Desktops")
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 4)

            Divider()

            // Desktop list
            ForEach(spaceManager.spaces) { space in
                DesktopRow(space: space, isRenaming: renamingSpace?.id == space.id, renameText: $renameText) {
                    // Start renaming
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

            Divider()

            // Refresh
            Button("Refresh") {
                spaceManager.refresh()
            }
            .keyboardShortcut("r")
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            Divider()

            // Quit
            Button("Quit Desktop Namer") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .frame(width: 260)
    }
}

struct DesktopRow: View {
    let space: SpaceInfo
    let isRenaming: Bool
    @Binding var renameText: String
    let onStartRename: () -> Void
    let onCommitRename: () -> Void
    let onCancelRename: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Active indicator
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
                VStack(alignment: .leading, spacing: 1) {
                    Text(space.displayName)
                        .fontWeight(space.isCurrentSpace ? .semibold : .regular)

                    Text("Space \(space.index)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

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
