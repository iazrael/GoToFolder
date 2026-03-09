# GoToFolder  >\_<

A lightweight macOS utility that adds a **Finder toolbar button** to instantly open any terminal at the current folder — a modern, fully-compatible replacement for the defunct Go2Shell.

---

## Features

| | |
|---|---|
| 🖱  One click | Click the `>_<` button in the Finder toolbar |
| 📂 Always correct path | Reads the frontmost Finder window via AppleScript |
| 🖥  Multi-terminal | Terminal.app · iTerm2 · Warp · kitty · Alacritty · Ghostty |
| ⚙️  Preferences | Launch the app directly to open the Settings window |
| 🪶 Tiny footprint | < 500 KB, no background process, quits after launching terminal |
| 🔒 No sandbox required | Ad-hoc signed, no App Store, no notarisation hoops |

---

## Quick Start

```bash
# 1. Clone / download the project
git clone https://github.com/iazrael/GoToFolder

# 2. Build + install in one step
cd GoToFolder
chmod +x build.sh
./build.sh --install
```

Then in Finder:

1. Open any Finder window  
2. Hold **⌘ Command** and **drag** `GoToFolder.app` from `/Applications` into the Finder toolbar  
3. Release when you see the green **+** indicator  
4. Click the **`>_<`** button — done ✅

---

## Build Options

```bash
./build.sh                # Universal binary (arm64 + x86_64), release
./build.sh --debug        # Debug symbols, no optimisation
./build.sh --install      # Build + copy to /Applications automatically
```

**Requirements:** macOS 12 Monterey or later, Xcode Command Line Tools (`xcode-select --install`).

---

## Project Layout

```
GoToFolder/
├── Sources/
│   └── GoToFolder/
│       ├── main.swift                  Entry point
│       ├── AppDelegate.swift           Launch logic; decides run vs settings mode
│       ├── FinderBridge.swift          AppleScript bridge → current Finder path
│       ├── TerminalLauncher.swift      Opens Terminal/iTerm2/Warp/kitty/…
│       └── SettingsWindowController.swift  Preferences UI (pure AppKit)
├── Resources/
│   ├── Info.plist                      Bundle metadata + privacy strings
│   └── GoToFolder.entitlements         Apple Events permission (no sandbox)
├── Scripts/
│   └── generate_icon.sh               Renders the >_< icon with Pillow
├── build.sh                            One-shot build + bundle + sign script
├── Package.swift                       For IDE / LSP support only
└── README.md
```

---

## How It Works

```
User clicks toolbar button
        │
        ▼
 AppDelegate.applicationDidFinishLaunching
        │
        ├─ FinderBridge.currentPath()  ←── AppleScript: "target of front Finder window"
        │        │
        │        ├─ path found ──► TerminalLauncher.open(path:) ──► quit
        │        │
        │        └─ nil (no Finder window / launched directly)
        │                 │
        └─────────────────► SettingsWindowController.showWindow()
```

### Why AppleScript instead of Accessibility API?

AppleScript's `tell application "Finder" … target of front window` is the most reliable and sandboxing-friendly way to obtain the actual directory path. The Accessibility API requires a broader `AXUIElement` permission that is harder to grant and more fragile across macOS versions.

### Toolbar integration — the ⌘-drag trick

macOS Finder has supported **Command-dragging** applications into the toolbar since OS X 10.3. When clicked, Finder simply launches that application (passing no arguments). GoToFolder detects the frontmost window via AppleScript at launch time, so no special arguments are needed. This mechanism still works on macOS Ventura, Sonoma, and Sequoia (tested on 14.x).

---

## Adding a Terminal

Edit `TerminalLauncher.swift`:

```swift
enum Terminal: String, CaseIterable {
    // … add your terminal here
    case myTerm = "MyTerm"
}

// Then add a case in TerminalLauncher.open(path:):
case .myTerm: openMyTerm(path)

// And implement:
private static func openMyTerm(_ path: String) {
    // Use AppleScript, URL scheme, or Process() as appropriate
}
```

---

## Privacy & Permissions

On first use, macOS will show a dialog:

> *"GoToFolder" wants access to control "Finder".*

Click **OK**. This is a one-time permission stored in System Settings → Privacy & Security → Automation. GoToFolder reads **only** the window path — it never modifies files or folders.

---

## Removing the Toolbar Button

Hold **⌘ Command** and **drag** the `>_<` button **off** the toolbar. The button disappears with a puff animation.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Nothing happens on click | Make sure GoToFolder.app is in `/Applications` (not Downloads) |
| "Not allowed to send Apple Events" | System Settings → Privacy & Security → Automation → enable GoToFolder → Finder |
| Wrong terminal opened | Launch GoToFolder.app directly (from /Applications) to open Settings |
| Button disappeared | Re-do the ⌘-drag step |
| "damaged and can't be opened" | Run `xattr -cr /Applications/GoToFolder.app` in Terminal |

---

## License

MIT — do whatever you like with it.
