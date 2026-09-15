import AppKit
import SwiftUI
import DesktopNamerCore

/// Spotlight-style non-activating panel: type to fuzzy-filter desktop names,
/// ↑/↓ + Return to switch, Esc or focus loss to dismiss.
/// @MainActor: all AppKit work is main-thread; isolation makes the class Sendable.
@MainActor
final class QuickSwitcher: NSObject, NSWindowDelegate {
    private let spaceManager: SpaceManager
    private var panel: NSPanel?

    init(spaceManager: SpaceManager) {
        self.spaceManager = spaceManager
        super.init()
    }

    func toggle() {
        if panel != nil {
            close()
        } else {
            show()
        }
    }

    private func show() {
        spaceManager.refresh()

        let view = QuickSwitcherView(
            spaceManager: spaceManager,
            onSwitch: { [weak self] spaceID in
                self?.close()
                self?.spaceManager.switchToSpaceByID(spaceID)
            },
            onDismiss: { [weak self] in
                self?.close()
            }
        )

        let panel = KeyablePanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]
        panel.isReleasedWhenClosed = false
        panel.delegate = self
        panel.contentViewController = NSHostingController(rootView: view)

        if let screen = NSScreen.main {
            let size = panel.contentViewController?.view.fittingSize ?? NSSize(width: 420, height: 200)
            // Slightly above center, Spotlight-style.
            panel.setFrame(NSRect(
                x: screen.frame.midX - size.width / 2,
                y: screen.frame.midY - size.height / 2 + screen.frame.height * 0.1,
                width: size.width,
                height: size.height
            ), display: false)
        }

        self.panel = panel
        panel.makeKeyAndOrderFront(nil)
    }

    private func close() {
        panel?.delegate = nil
        panel?.close()
        panel = nil
    }

    func windowDidResignKey(_ notification: Notification) {
        close()
    }
}

/// Borderless NSPanels refuse key status by default; the switcher's text field
/// needs it, without activating the app (.nonactivatingPanel).
final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

struct QuickSwitcherView: View {
    @Bindable var spaceManager: SpaceManager
    let onSwitch: (UInt64) -> Void
    let onDismiss: () -> Void

    @State private var query = ""
    @State private var selection = 0
    @FocusState private var fieldFocused: Bool

    private var filtered: [SpaceInfo] {
        spaceManager.spaces.filter { fuzzyMatch(query: query, candidate: $0.displayName) }
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Switch to desktop...", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 18))
                .padding(14)
                .focused($fieldFocused)
                .onSubmit(switchToSelection)
                .onExitCommand(perform: onDismiss)
                .onKeyPress(.upArrow) { moveSelection(-1); return .handled }
                .onKeyPress(.downArrow) { moveSelection(1); return .handled }

            Divider()

            if filtered.isEmpty {
                Text("No matching desktops")
                    .foregroundStyle(.secondary)
                    .padding(14)
            } else {
                VStack(spacing: 2) {
                    ForEach(Array(filtered.enumerated()), id: \.element.id) { index, space in
                        row(space, isSelected: index == selection)
                            .onTapGesture { onSwitch(space.id) }
                    }
                }
                .padding(6)
            }
        }
        .frame(width: 420)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .onAppear { fieldFocused = true }
        .onChange(of: query) { _, _ in selection = 0 }
    }

    private func moveSelection(_ offset: Int) {
        guard !filtered.isEmpty else { return }
        selection = (selection + offset + filtered.count) % filtered.count
    }

    private func switchToSelection() {
        guard filtered.indices.contains(selection) else { return }
        onSwitch(filtered[selection].id)
    }

    private func row(_ space: SpaceInfo, isSelected: Bool) -> some View {
        HStack(spacing: 8) {
            if let symbol = space.symbol {
                Image(systemName: symbol)
                    .foregroundStyle(SpaceStyle.color(fromHex: space.colorHex) ?? Color.secondary)
                    .frame(width: 16)
            } else if let color = SpaceStyle.color(fromHex: space.colorHex) {
                Circle().fill(color).frame(width: 8, height: 8).frame(width: 16)
            } else {
                Color.clear.frame(width: 16, height: 8)
            }

            Text(space.displayName)
                .fontWeight(space.isCurrentSpace ? .semibold : .regular)

            Spacer()

            Text(spaceManager.hasMultipleDisplays
                 ? "Space \(space.index) · \(displayName(for: space))"
                 : "Space \(space.index)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            isSelected ? AnyShapeStyle(.selection) : AnyShapeStyle(.clear),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .contentShape(Rectangle())
    }

    private func displayName(for space: SpaceInfo) -> String {
        spaceManager.displayGroups.first { $0.id == space.displayUUID }?.displayName ?? ""
    }
}
