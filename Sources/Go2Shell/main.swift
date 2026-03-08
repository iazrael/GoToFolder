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

    func getTerminalURL() -> URL? {
        let config = getConfig()

        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: config.terminalBundleId) {
            return appURL
        }

        if let customPath = config.terminalPath {
            return URL(fileURLWithPath: customPath)
        }

        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal")
    }
}

// MARK: - Finder Integration

class FinderPathExtractor {
    func getCurrentPath() -> String {
        let script = """
        tell application "Finder"
            if (count of windows) > 0 then
                return POSIX path of (target of front window as alias)
            else
                return POSIX path of (path to desktop folder as alias)
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

        return NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first ?? NSHomeDirectory()
    }
}

// MARK: - Terminal Launcher

class TerminalLauncher {
    private let configManager = ConfigManager()

    func openTerminal(at path: String) {
        guard let terminalURL = configManager.getTerminalURL() else {
            return
        }

        let config = NSWorkspace.OpenConfiguration()
        config.activates = true

        NSWorkspace.shared.open(
            [URL(fileURLWithPath: path)],
            withApplicationAt: terminalURL,
            configuration: config
        ) { runningApp, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Main App

class Go2ShellApp: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 检查是否有特殊标志（比如双击 Dock 图标或从 Launchpad 打开）
        // 如果是从工具栏点击，直接执行并退出

        let finder = FinderPathExtractor()
        let launcher = TerminalLauncher()
        let path = finder.getCurrentPath()

        // 打开终端
        launcher.openTerminal(at: path)

        // 延迟退出，确保终端已启动
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApp.terminate(nil)
        }
    }

    // 当应用被双击打开时（首次安装配置）
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

// 创建并运行应用
let app = NSApplication.shared
let delegate = Go2ShellApp()
app.delegate = delegate

// 设置应用为后台应用（不显示 Dock 图标）
// 如果用户双击 .app 文件，会显示配置窗口
app.setActivationPolicy(.accessory)

app.run()
