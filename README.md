# Desktop Namer

A lightweight macOS menu bar utility that lets you assign custom names to your virtual desktops (Spaces) and displays the current desktop name in the menu bar.

## Features

- **Named Desktops** — Assign custom names like "Code", "Email", "Music" to each desktop
- **Menu Bar Display** — Always see which desktop you're on at a glance (bold label)
- **Click to Switch** — Click any desktop name in the dropdown to navigate to it
- **Inline Renaming** — Click the pencil icon next to any desktop to rename it
- **Multi-Monitor Support** — Desktops are grouped by display when multiple monitors are connected
- **Keyboard Shortcuts** — Ctrl+1 through Ctrl+9 to switch desktops by number
- **Launch at Login** — Toggle auto-start from the menu
- **Auto-Updates** — Built-in update checking via Sparkle
- **Persistent Names** — Desktop names are saved and survive app restarts
- **Menu Bar Only** — No dock icon, stays out of your way

## Requirements

- macOS 14.0 (Sonoma) or later
- Accessibility permissions (for keyboard shortcut switching)

## Installation

### From DMG

1. Download `DesktopNamer.dmg` from the [Releases](../../releases) page
2. Open the DMG and drag **Desktop Namer** to the **Applications** folder
3. **Important:** Before launching, open Terminal and run:
   ```bash
   xattr -cr /Applications/DesktopNamer.app
   ```
   This removes the macOS quarantine flag (required for unsigned apps downloaded from the internet).
4. Launch from Applications or Spotlight

> **Alternatively**, you can right-click the app > **Open** > click **Open** in the dialog. macOS will remember your choice for future launches.

### From Source

```bash
git clone https://github.com/supreetsharma/DesktopNamer.git
cd DesktopNamer
bash build.sh
open .build/DesktopNamer.app
```

## Usage

1. Launch the app — a welcome screen guides you through setup on first launch
2. The app appears in the menu bar with a rectangle icon and your current desktop name
3. Click the menu bar item to see all your desktops
4. Click a **desktop name** to switch to that desktop
5. Click the **pencil icon** next to any desktop to rename it
6. Press Enter to confirm, Escape to cancel
7. The active desktop is marked with a blue dot

### Multi-Monitor

When multiple displays are connected, desktops are automatically grouped by display with headers showing the monitor name.

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl+1–9 | Switch to desktop by number |
| Cmd+R | Refresh desktop list (in menu) |
| Cmd+Q | Quit (in menu) |

> **Note:** Ctrl+N shortcuts require "Switch to Desktop N" to be enabled in **System Settings > Keyboard > Keyboard Shortcuts > Mission Control**.

### Settings

- **Launch at Login** — Toggle in the menu dropdown to auto-start on boot
- **Check for Updates** — Manually check for new versions via the menu

## How It Works

macOS doesn't provide a public API for managing Spaces. Desktop Namer uses private CoreGraphics APIs (`CGSCopyManagedDisplaySpaces`, `CGSGetActiveSpace`, `CGSManagedDisplaySetCurrentSpace`) to detect, track, and switch between virtual desktops — the same approach used by popular tools like Amethyst and yabai.

Desktop names are stored in `UserDefaults` and mapped to space UUIDs, so they persist even when spaces are reordered.

## Project Structure

```
Sources/
├── DesktopNamerApp.swift          # App entry point with MenuBarExtra + Sparkle
├── SpaceManager.swift             # Core space detection, naming, and switching
├── CGSPrivate.swift               # Private CoreGraphics API declarations
├── MenuBarView.swift              # SwiftUI menu bar dropdown UI with display grouping
├── OnboardingView.swift           # First-launch welcome screen
└── KeyboardShortcutManager.swift  # Global hotkey registration
Scripts/
└── generate_icon.swift            # Generates AppIcon.icns programmatically
Resources/
├── Info.plist                     # App configuration (LSUIElement, Sparkle feed URL)
└── AppIcon.icns                   # App icon
```

## Building

```bash
# Debug build
swift build

# Release build + .app bundle + codesign
bash build.sh

# Regenerate the app icon
swift Scripts/generate_icon.swift
```

## Auto-Updates (Sparkle)

The app includes [Sparkle](https://sparkle-project.org/) for automatic update checking. To publish an update:

1. Bump `CFBundleVersion` in `Resources/Info.plist`
2. Run `bash build.sh` to create the new .app bundle
3. Create a new DMG and GitHub release
4. Add an `<item>` entry to `appcast.xml` with the new version details
5. Commit and push

## License

MIT License. See [LICENSE](LICENSE) for details.
