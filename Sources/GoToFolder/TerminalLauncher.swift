import Cocoa

/// Supported terminal applications.
enum Terminal: String, CaseIterable {
    case terminal  = "Terminal"
    case iterm2    = "iTerm2"
    case warp      = "Warp"
    case kitty     = "kitty"
    case alacritty = "Alacritty"
    case ghostty   = "Ghostty"

    var displayName: String { rawValue }

    /// The defaults key used to persist the user's choice.
    static let defaultsKey = "preferredTerminal"

    static var preferred: Terminal {
        let raw = UserDefaults.standard.string(forKey: defaultsKey) ?? Terminal.terminal.rawValue
        return Terminal(rawValue: raw) ?? .terminal
    }
}

enum TerminalLauncher {

    static func open(path: String) {
        // Sanitise: escape single-quotes so the shell doesn't choke on them
        let escaped = path.replacingOccurrences(of: "'", with: "'\\''")

        switch Terminal.preferred {
        case .terminal:  openTerminalApp(escaped)
        case .iterm2:    openITerm2(escaped)
        case .warp:      openWarp(escaped)
        case .kitty:     openKitty(escaped)
        case .alacritty: openAlacritty(escaped)
        case .ghostty:   openGhostty(escaped)
        }
    }

    // MARK: - Terminal.app

    private static func openTerminalApp(_ path: String) {
        // Open a new window; if one already exists, do script opens a new tab.
        let script = """
        tell application "Terminal"
            activate
            do script "cd '\(path)' && clear"
        end tell
        """
        runAppleScript(script)
    }

    // MARK: - iTerm2

    private static func openITerm2(_ path: String) {
        let script = """
        tell application "iTerm2"
            activate
            set newWindow to (create window with default profile)
            tell current session of newWindow
                write text "cd '\(path)' && clear"
            end tell
        end tell
        """
        runAppleScript(script)
    }

    // MARK: - Warp (URL scheme: warp://action/new_tab?path=…)

    private static func openWarp(_ path: String) {
        let allowed = CharacterSet.urlQueryAllowed
        guard let encoded = path.addingPercentEncoding(withAllowedCharacters: allowed),
              let url = URL(string: "warp://action/new_tab?path=\(encoded)") else {
            fallbackShell(path)
            return
        }
        NSWorkspace.shared.open(url)
    }

    // MARK: - kitty

    private static func openKitty(_ path: String) {
        // kitty supports --directory flag when invoked via open
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-na", "kitty", "--args", "--directory", path]
        try? task.run()
    }

    // MARK: - Alacritty

    private static func openAlacritty(_ path: String) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-na", "Alacritty", "--args", "--working-directory", path]
        try? task.run()
    }

    // MARK: - Ghostty

    private static func openGhostty(_ path: String) {
        // Ghostty supports the same --working-directory flag as kitty
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-na", "Ghostty", "--args", "--working-directory=\(path)"]
        try? task.run()
    }

    // MARK: - Helpers

    /// Last-resort fallback: open a plain shell script via Terminal.app.
    private static func fallbackShell(_ path: String) {
        let script = """
        tell application "Terminal"
            activate
            do script "cd '\(path)'"
        end tell
        """
        runAppleScript(script)
    }

    @discardableResult
    private static func runAppleScript(_ source: String) -> String? {
        var errDict: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let result = script.executeAndReturnError(&errDict)
        if let err = errDict {
            NSLog("[GoToFolder] AppleScript error: %@", err.description)
        }
        return result.stringValue
    }
}
