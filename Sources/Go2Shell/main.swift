import Cocoa
import Foundation

// MARK: - Configuration

struct AppConfig: Codable {
    var terminalBundleId: String
    var terminalPath: String?

    static let `default` = AppConfig(
        terminalBundleId: "com.apple.Terminal",
        terminalPath: nil
    )
}

class ConfigManager {
    private let configKey = "terminalConfig"

    func getConfig() -> AppConfig {
        guard let data = UserDefaults.standard.data(forKey: configKey),
              let config = try? JSONDecoder().decode(AppConfig.self, from: data) else {
            return .default
        }
        return config
    }

    func saveConfig(_ config: AppConfig) {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: configKey)
        }
    }

    func getTerminalBundleId() -> String {
        return getConfig().terminalBundleId
    }
}

// MARK: - Finder Integration

class FinderPathExtractor {
    func getCurrentPath() -> String {
        let script = """
        tell application "Finder"
            activate
            set windowCount to count of windows
            if windowCount > 0 then
                set currentPath to target of front window as alias
                return POSIX path of currentPath
            else
                return ""
            end if
        end tell
        """

        var error: NSDictionary?
        let scriptObject = NSAppleScript(source: script)

        if let output = scriptObject?.executeAndReturnError(&error) {
            if let path = output.stringValue, !path.isEmpty {
                return path
            }
        }

        if let err = error {
            NSLog("Go2Shell AppleScript error: \(err)")
        }

        return NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first ?? NSHomeDirectory()
    }
}

// MARK: - Terminal Launcher

class TerminalLauncher {
    private let configManager = ConfigManager()

    func openTerminal(at path: String) {
        let bundleId = configManager.getTerminalBundleId()

        if bundleId == "com.apple.Terminal" {
            openTerminalApp(at: path)
        } else if bundleId == "com.googlecode.iterm2" {
            openITerm2(at: path)
        } else {
            // 其他终端，直接打开文件夹
            if let terminalURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                NSWorkspace.shared.open(
                    [URL(fileURLWithPath: path)],
                    withApplicationAt: terminalURL,
                    configuration: NSWorkspace.OpenConfiguration()
                )
            }
        }
    }

    private func openTerminalApp(at path: String) {
        // 创建临时脚本来启动 Terminal 并 cd
        let tempScriptContent = """
        #!/bin/bash
        cd "\(path)"
        exec bash
        """

        let tempDir = FileManager.default.temporaryDirectory
        let tempScriptURL = tempDir.appendingPathComponent("go2shell_\(UUID().uuidString).command")

        do {
            try tempScriptContent.write(to: tempScriptURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tempScriptURL.path)

            // 使用 open 命令打开 .command 文件，Terminal 会自动执行它
            NSWorkspace.shared.open([tempScriptURL], withApplicationAt: URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"), configuration: NSWorkspace.OpenConfiguration())

            // 延迟删除临时文件
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                try? FileManager.default.removeItem(at: tempScriptURL)
            }
        } catch {
            NSLog("Go2Shell error creating temp script: \(error.localizedDescription)")
        }
    }

    private func openITerm2(at path: String) {
        let script = """
        tell application "iTerm"
            activate
            if (count of windows) = 0 then
                create window with default profile
            end if
            tell current session of current window
                write text "cd \"\(path)\""
            end tell
        end tell
        """

        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)

        if let err = error {
            NSLog("Go2Shell iTerm2 error: \(err)")
        }
    }
}

// MARK: - Main App

class Go2ShellApp: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let finder = FinderPathExtractor()
        let launcher = TerminalLauncher()
        let path = finder.getCurrentPath()

        NSLog("Go2Shell: Opening terminal at: \(path)")

        launcher.openTerminal(at: path)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApp.terminate(nil)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showConfigWindow()
        return false
    }

    private func showConfigWindow() {
        let alert = NSAlert()
        alert.messageText = "Go2Shell 已安装"
        alert.informativeText = """
        使用方法：

        1. 在 Finder 窗口右上角，按住 ⌘ 键点击工具栏
        2. 选择"自定义工具栏..."
        3. 将 Go2Shell 图标拖到工具栏

        之后点击工具栏上的 Go2Shell 图标即可在当前文件夹打开终端。

        当前配置: \(ConfigManager().getConfig().terminalBundleId)
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "完成")
        alert.runModal()
    }
}

let app = NSApplication.shared
let delegate = Go2ShellApp()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
