import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var settingsWindowController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Always start as accessory (no Dock icon, no menu bar) for toolbar-click use case
        NSApp.setActivationPolicy(.accessory)

        if let path = FinderBridge.currentPath() {
            TerminalLauncher.open(path: path)
            // Small delay so the terminal has time to receive the open event before we exit
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                NSApplication.shared.terminate(nil)
            }
        } else {
            // Launched directly (not via a Finder window) → show Settings
            showSettings()
        }
    }

    // MARK: - Settings

    @objc func showSettings() {
        NSApp.setActivationPolicy(.regular)
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Only quit after window closes when running in "settings mode"
        return settingsWindowController?.window?.isVisible == true
    }
}
