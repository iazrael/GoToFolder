import Cocoa

/// Fetches the POSIX path of the front Finder window using AppleScript.
enum FinderBridge {

    /// Returns the POSIX path of the frontmost Finder window, or nil if none exists.
    static func currentPath() -> String? {
        let source = """
        tell application "Finder"
            if (count of Finder windows) > 0 then
                set theTarget to (target of front Finder window) as alias
                return POSIX path of theTarget
            end if
        end tell
        """
        return runScript(source)
    }

    // MARK: - Private

    @discardableResult
    private static func runScript(_ source: String) -> String? {
        var errorDict: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let output = script.executeAndReturnError(&errorDict)
        guard errorDict == nil else {
            if let err = errorDict {
                NSLog("[GoToFolder] AppleScript error: %@", err.description)
            }
            return nil
        }
        let raw = output.stringValue ?? ""
        let path = raw.hasSuffix("/") ? raw : raw + "/"
        return raw.isEmpty ? nil : path
    }
}
