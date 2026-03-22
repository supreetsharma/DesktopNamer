# Desktop Namer

A lightweight macOS menu bar utility that lets you assign custom names to your virtual desktops (Spaces) and displays the current desktop name in the menu bar.

## Features

- **Named Desktops** — Assign custom names like "Code", "Email", "Music" to each desktop
- **Menu Bar Display** — Always see which desktop you're on at a glance
- **Inline Renaming** — Click the pencil icon next to any desktop to rename it
- **Keyboard Shortcuts** — Ctrl+1 through Ctrl+9 to switch desktops by number
- **Persistent Names** — Desktop names are saved and survive app restarts
- **Menu Bar Only** — No dock icon, stays out of your way

## Requirements

- macOS 14.0 (Sonoma) or later
- Accessibility permissions (for keyboard shortcut switching)

## Installation

### From DMG

1. Download `DesktopNamer.dmg` from the [Releases](../../releases) page
2. Open the DMG and drag **Desktop Namer** to the **Applications** folder
3. Launch from Applications or Spotlight

### From Source

```bash
git clone https://github.com/supreetsharma/DesktopNamer.git
cd DesktopNamer
bash build.sh
open .build/DesktopNamer.app
```

## Usage

1. Launch the app — it appears in the menu bar with a rectangle icon and your current desktop name
2. Click the menu bar item to see all your desktops
3. Click the pencil icon next to any desktop to rename it
4. Press Enter to confirm, Escape to cancel
5. The active desktop is marked with a blue dot

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl+1–9 | Switch to desktop by number |
| Cmd+R | Refresh desktop list (in menu) |
| Cmd+Q | Quit (in menu) |

> **Note:** Ctrl+N shortcuts require "Switch to Desktop N" to be enabled in **System Settings > Keyboard > Keyboard Shortcuts > Mission Control**.

## How It Works

macOS doesn't provide a public API for managing Spaces. Desktop Namer uses private CoreGraphics APIs (`CGSCopyManagedDisplaySpaces`, `CGSGetActiveSpace`) to detect and track virtual desktops — the same approach used by popular tools like Amethyst and yabai.

Desktop names are stored in `UserDefaults` and mapped to space UUIDs, so they persist even when spaces are reordered.

## Project Structure

```
Sources/
├── DesktopNamerApp.swift          # App entry point with MenuBarExtra
├── SpaceManager.swift             # Core space detection and naming logic
├── CGSPrivate.swift               # Private CoreGraphics API declarations
├── MenuBarView.swift              # SwiftUI menu bar dropdown UI
└── KeyboardShortcutManager.swift  # Global hotkey registration
```

## Building

```bash
# Debug build
swift build

# Release build + .app bundle
bash build.sh

# The .app bundle is created at .build/DesktopNamer.app
```

## License

MIT License. See [LICENSE](LICENSE) for details.
