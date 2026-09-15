import AppKit
import SwiftUI
import DesktopNamerCore

/// Shows a transient center-screen badge with the destination desktop's name
/// (and color/icon) whenever the active space changes. Toggleable in Settings.
/// @MainActor: all AppKit work is main-thread; isolation makes the class Sendable.
@MainActor
final class SwitchHUD {
    static let enabledKey = "com.desktopnamer.showSwitchHUD"

    static var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    private weak var spaceManager: SpaceManager?
    private var window: NSWindow?
    private var hideWork: DispatchWorkItem?
    private var observer: NSObjectProtocol?
    private let connection = CGSDefaultConnection()

    init(spaceManager: SpaceManager) {
        self.spaceManager = spaceManager

        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Defer one runloop turn so SpaceManager's own observer refreshes first.
            DispatchQueue.main.async {
                self?.showForCurrentSpace()
            }
        }
    }

    deinit {
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    private func showForCurrentSpace() {
        guard Self.isEnabled,
              let spaceManager,
              let space = spaceManager.spaces.first(where: { $0.id == spaceManager.currentSpaceID })
        else { return }
        show(space: space)
    }

    private func show(space: SpaceInfo) {
        hideWork?.cancel()
        window?.close()
        window = nil

        let view = NSHostingView(rootView: HUDLabelView(
            name: space.displayName, colorHex: space.colorHex, symbol: space.symbol))
        let size = view.intrinsicContentSize
        guard let screen = screenFor(displayUUID: space.displayUUID) ?? NSScreen.main else { return }

        let frame = NSRect(
            x: screen.frame.midX - size.width / 2,
            y: screen.frame.midY - size.height / 2,
            width: size.width,
            height: size.height
        )

        let hud = NSWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
        hud.isOpaque = false
        hud.backgroundColor = .clear
        hud.hasShadow = false
        hud.ignoresMouseEvents = true
        hud.level = .statusBar
        hud.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        hud.isReleasedWhenClosed = false
        hud.contentView = view
        hud.alphaValue = 0
        hud.orderFrontRegardless()
        window = hud

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            hud.animator().alphaValue = 1
        }

        let work = DispatchWorkItem { [weak self] in self?.fadeOut() }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: work)
    }

    private func fadeOut() {
        guard let hud = window else { return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            hud.animator().alphaValue = 0
        }, completionHandler: { [weak self, weak hud] in
            Task { @MainActor in
                // Only close the window this fade-out animated: a rapid switch may
                // have replaced `window` with a newer badge while the 0.2 s fade was
                // in flight, and that badge must live out its own cycle.
                guard let self, self.window === hud else { return }
                self.window = nil
                hud?.close()
            }
        })
    }

    private func screenFor(displayUUID: String) -> NSScreen? {
        NSScreen.screens.first {
            CGSCopyBestManagedDisplayForRect(connection, $0.frame) as String == displayUUID
        }
    }
}

struct HUDLabelView: View {
    let name: String
    let colorHex: String?
    let symbol: String?

    var body: some View {
        HStack(spacing: 10) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .medium))
            }
            Text(name)
                .font(.system(size: 24, weight: .medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            Capsule().fill(
                SpaceStyle.color(fromHex: colorHex).map { AnyShapeStyle($0.opacity(0.85)) }
                    ?? AnyShapeStyle(Color.black.opacity(0.75))
            )
        )
    }
}
