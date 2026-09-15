import SwiftUI
import ServiceManagement
import DesktopNamerCore

struct MenuBarView: View {
    @Bindable var spaceManager: SpaceManager
    var updateChecker: UpdateChecker
    var dismiss: () -> Void = {}
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

            Button("Check for Updates...") {
                dismiss()
                updateChecker.checkForUpdates()
            }
            .disabled(updateChecker.isChecking)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            Divider()

            SettingsLink {
                Text("Settings...")
            }
            .keyboardShortcut(",")
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .simultaneousGesture(TapGesture().onEnded {
                dismiss()
                NSApp.activate(ignoringOtherApps: true)
            })

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
            dismiss()
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
        } onPickColor: { hex in
            spaceManager.setColorHex(hex, forUUID: space.uuid)
        } onPickSymbol: { symbol in
            spaceManager.setSymbol(symbol, forUUID: space.uuid)
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
    let onPickColor: (String?) -> Void
    let onPickSymbol: (String?) -> Void

    var body: some View {
        // The current-space dot stays visible (and keeps its indentation) in BOTH
        // states — rename mode must not hide which desktop is active.
        HStack(alignment: isRenaming ? .top : .center, spacing: 8) {
            Circle()
                .fill(space.isCurrentSpace ? Color.blue : Color.clear)
                .frame(width: 6, height: 6)
                .padding(.top, isRenaming ? 8 : 0)

            if isRenaming {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        TextField("Desktop name", text: $renameText, onCommit: onCommitRename)
                            .textFieldStyle(.roundedBorder)
                            .onExitCommand(perform: onCancelRename)

                        Button("Done") { onCommitRename() }
                            .buttonStyle(.borderless)
                            .font(.caption)
                    }

                    colorSwatchRow
                    symbolPickerRow
                }
            } else {
                Button {
                    onNavigate()
                } label: {
                    HStack(spacing: 6) {
                        spaceGlyph

                        VStack(alignment: .leading, spacing: 1) {
                            Text(space.displayName)
                                .fontWeight(space.isCurrentSpace ? .semibold : .regular)

                            Text("Space \(space.index)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
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

    /// The space's icon (tinted with its color) or a plain color dot; nothing when unset.
    @ViewBuilder
    private var spaceGlyph: some View {
        if let symbol = space.symbol {
            Image(systemName: symbol)
                .font(.system(size: 12))
                .foregroundStyle(SpaceStyle.color(fromHex: space.colorHex) ?? Color.secondary)
                .frame(width: 14)
        } else if let color = SpaceStyle.color(fromHex: space.colorHex) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
        }
    }

    private var colorSwatchRow: some View {
        HStack(spacing: 6) {
            swatch(nil)
            ForEach(SpacePalette.presets, id: \.self) { hex in
                swatch(hex)
            }
        }
    }

    private func swatch(_ hex: String?) -> some View {
        Button { onPickColor(hex) } label: {
            ZStack {
                if let color = SpaceStyle.color(fromHex: hex) {
                    Circle().fill(color)
                } else {
                    Circle().strokeBorder(.secondary, lineWidth: 1)
                    Image(systemName: "slash.circle")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 16, height: 16)
            .overlay {
                if space.colorHex == hex {
                    Circle().strokeBorder(.primary, lineWidth: 1.5).padding(-2.5)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var symbolPickerRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                symbolButton(nil)
                ForEach(SpaceStyle.symbols, id: \.self) { symbolButton($0) }
            }
        }
    }

    private func symbolButton(_ symbol: String?) -> some View {
        Button { onPickSymbol(symbol) } label: {
            Image(systemName: symbol ?? "slash.circle")
                .font(.system(size: 13))
                .foregroundStyle(space.symbol == symbol ? Color.primary : Color.secondary)
                .frame(width: 20, height: 20)
                .background {
                    if space.symbol == symbol {
                        RoundedRectangle(cornerRadius: 4).fill(.quaternary)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}
