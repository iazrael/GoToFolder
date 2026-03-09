# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
./build.sh                # Release build (universal: arm64 + x86_64)
./build.sh --debug        # Debug build with symbols
./build.sh --install      # Build + install to /Applications
```

**Requirements:** macOS 12+, Xcode Command Line Tools (`xcode-select --install`)

**Note:** `Package.swift` is for IDE/LSP support only. Use `build.sh` for actual .app bundle generation.

## Architecture

A macOS Finder toolbar utility that opens a terminal at the current Finder folder. Pure AppKit, no SwiftUI.

```
┌─────────────────────────────────────────────────────────┐
│  main.swift → AppDelegate                              │
│       │                                                 │
│       ├── FinderBridge.currentPath()                   │
│       │       │                                         │
│       │       ├── path found → TerminalLauncher.open() │
│       │       │                        → quit (0.8s)    │
│       │       │                                         │
│       │       └── nil → SettingsWindowController       │
│       │                   (launched directly)           │
└─────────────────────────────────────────────────────────┘
```

**Key Components:**

| File | Purpose |
|------|---------|
| `AppDelegate.swift` | Run mode decision: toolbar-click (launch terminal + quit) vs settings mode |
| `FinderBridge.swift` | AppleScript bridge to get front Finder window path |
| `TerminalLauncher.swift` | Multi-terminal support: Terminal.app, iTerm2, Warp, kitty, Alacritty, Ghostty |
| `SettingsWindowController.swift` | Pure AppKit preferences UI |

## Adding a New Terminal

Edit `TerminalLauncher.swift`:

1. Add case to `enum Terminal`
2. Add switch case in `open(path:)`
3. Implement launch method (AppleScript, URL scheme, or `Process`)

## Entitlements

No sandbox (`com.apple.security.app-sandbox: false`). Requires `com.apple.security.automation.apple-events` for AppleScript. Ad-hoc signed — not for App Store.