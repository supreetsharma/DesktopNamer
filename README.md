# Desktop Namer

A lightweight macOS menu bar utility that lets you assign custom names to your virtual desktops (Spaces) and displays the current desktop name in the menu bar.

## Features

- **Named Desktops** — Assign custom names like "Code", "Email", "Music" to each desktop
- **Menu Bar Display** — Always see which desktop you're on at a glance (bold label)
- **Click to Switch** — Click any desktop name in the dropdown to navigate to it
- **Inline Renaming** — Click the pencil icon next to any desktop to rename it
- **Colors & Icons** — Give each desktop a color and an SF Symbol, shown in the menu, quick switcher, switch HUD, and Mission Control (the menu bar shows the color chip)
- **Quick Switcher** — Press ⌥Space and type a few letters to jump to any desktop by name
- **Switch HUD** — A brief center-screen badge confirms the desktop name on every switch
- **Multi-Monitor Support** — Desktops are grouped by display when multiple monitors are connected
- **Configurable Shortcuts** — Ctrl+1–9 by default; remap or disable each one in Settings
- **Scroll to Switch** — Scroll the mouse wheel over the menu bar item to cycle desktops
- **Launch at Login** — Toggle auto-start from the menu
- **Auto-Updates** — Built-in update checking via GitHub releases
- **Persistent Names** — Desktop names are saved and survive app restarts
- **Menu Bar Only** — No dock icon, stays out of your way

## Requirements

- macOS 14.0 (Sonoma) or later
- Accessibility permissions (optional; only used to position Mission Control labels precisely)

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
6. While renaming, pick a **color swatch** or **icon** below the name field — applied instantly
7. Press Enter to confirm, Escape to cancel
8. Press **⌥Space** anywhere to open the quick switcher: type to filter, ↑/↓ to select, Enter to switch
9. The active desktop is marked with a blue dot

### Multi-Monitor

When multiple displays are connected, desktops are automatically grouped by display with headers showing the monitor name.

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl+1–9 | Switch to desktop by number |
| ⌥Space | Open the quick switcher (remappable in Settings) |
| Cmd+R | Refresh desktop list (in menu) |
| Cmd+Q | Quit (in menu) |

> Shortcuts are captured globally and can be remapped or disabled per-desktop in **Settings...** (⌘, from the menu). No system Mission Control shortcuts or Accessibility permission required.

### Settings

- **Launch at Login** — Toggle in the menu dropdown to auto-start on boot
- **Shortcuts** — Remap or disable each desktop shortcut in Settings... (⌘,)
- **Quick Switcher shortcut** — Remap or clear it in Settings... (⌘,)
- **Switch HUD** — Toggle "Show name when switching desktops" in Settings > General
- **Check for Updates** — Manually check for new versions via the menu

## How It Works

macOS doesn't provide a public API for managing Spaces. Desktop Namer uses private CoreGraphics APIs (`CGSCopyManagedDisplaySpaces`, `CGSGetActiveSpace`, `CGSManagedDisplaySetCurrentSpace`) to detect, track, and switch between virtual desktops — the same approach used by popular tools like Amethyst and yabai.

Desktop names are stored in `UserDefaults` and mapped to space UUIDs, so they persist even when spaces are reordered.

## Project Structure

```
Sources/
├── App/
│   ├── DesktopNamerApp.swift          # App entry point (Settings + onboarding scenes)
│   ├── AppDelegate.swift              # Lifecycle: status item, shortcuts, overlay
│   ├── StatusItemController.swift     # NSStatusItem, popover, scroll-to-cycle
│   ├── SettingsView.swift             # Shortcut recorders, launch at login
│   ├── SpaceManager.swift             # Space state, switching with verify+retry
│   ├── SpaceStyle.swift               # Color/symbol rendering helpers
│   ├── CGSPrivate.swift               # Private CoreGraphics API declarations
│   ├── MenuBarView.swift              # Dropdown UI with display grouping
│   ├── MissionControlOverlay.swift    # Name labels over Mission Control
│   ├── SwitchHUD.swift                # Transient switch badge
│   ├── OnboardingView.swift           # First-launch welcome screen
│   ├── KeyboardShortcutManager.swift  # Hotkeys via KeyboardShortcuts package
│   ├── QuickSwitcher.swift            # ⌥Space fuzzy-find panel
│   └── UpdateChecker.swift            # GitHub-release update checks
└── Core/                              # Pure logic, unit-tested
│   ├── SpaceModels.swift              # SpaceInfo, DisplayGroup
│   ├── SpaceParser.swift              # CGS dictionary → models
│   ├── SpaceSettingsStore.swift       # Per-space settings + migration
│   ├── SpacePalette.swift             # Preset colors + hex parsing
│   ├── FuzzyMatch.swift               # Subsequence matching for the switcher
│   └── VersionCompare.swift           # Version string comparison
Scripts/
└── generate_icon.swift                # Generates AppIcon.icns programmatically
Resources/
├── Info.plist                         # App configuration (LSUIElement)
└── AppIcon.icns                       # App icon
Tests/
└── DesktopNamerCoreTests/             # swift run desktop-namer-tests
```

## Building

```bash
# Debug build
swift build

# Release build + .app bundle + codesign
bash build.sh

# Run unit tests
swift run desktop-namer-tests

# Regenerate the app icon
swift Scripts/generate_icon.swift
```

## Auto-Updates

The app checks the GitHub Releases API for newer versions and offers to download the DMG. To publish an update:

1. Bump `CFBundleVersion` in `Resources/Info.plist`
2. Run `bash build.sh` to create the new .app bundle
3. Create a new DMG and GitHub release
4. Commit and push

## License

MIT License. See [LICENSE](LICENSE) for details.
