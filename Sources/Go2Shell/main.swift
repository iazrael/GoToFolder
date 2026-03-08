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

        // 尝试通过 Bundle ID 查找
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: config.terminalBundleId) {
            return appURL
        }

        // 尝试自定义路径
        if let customPath = config.terminalPath {
            return URL(fileURLWithPath: customPath)
        }

        // 回退到系统 Terminal
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

        // 回退到桌面
        return NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first ?? NSHomeDirectory()
    }
}

// MARK: - Terminal Launcher

class TerminalLauncher {
    private let configManager = ConfigManager()

    func openTerminal(at path: String) {
        guard let terminalURL = configManager.getTerminalURL() else {
            showError("无法找到终端应用")
            return
        }

        let config = NSWorkspace.OpenConfiguration()
        config.activates = true

        // 使用 open withApplicationAt 打开文件夹
        NSWorkspace.shared.open(
            [URL(fileURLWithPath: path)],
            withApplicationAt: terminalURL,
            configuration: config
        ) { runningApp, error in
            if let error = error {
                print("Error opening terminal: \(error.localizedDescription)")
            }
        }
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Go2Shell"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }
}

// MARK: - URL Scheme Handler

class URLSchemeHandler: NSObject {
    private let finderExtractor = FinderPathExtractor()
    private let launcher = TerminalLauncher()

    @objc func handle(_ event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
        let path = finderExtractor.getCurrentPath()
        launcher.openTerminal(at: path)
    }
}

// MARK: - Main App

class Go2ShellApp: NSObject, NSApplicationDelegate {
    private var urlSchemeHandler: URLSchemeHandler!

    func applicationDidFinishLaunching(_ notification: Notification) {
        urlSchemeHandler = URLSchemeHandler()

        // 注册 URL Scheme 处理
        let eventMask = AEEventClass(kCoreEventClass) | AEEventID(kAEOpenDocuments)
        NSAppleEventManager.shared().setEventHandler(
            urlSchemeHandler!,
            andSelector: #selector(URLSchemeHandler.handle(_:replyEvent:)),
            forEventClass: eventMask,
            andEventID: AEEventID(kAEOpenDocuments)
        )

        // 如果没有参数，显示配置窗口
        let arguments = CommandLine.arguments
        if arguments.count == 1 {
            showConfigWindow()
        }
    }

    private func showConfigWindow() {
        let alert = NSAlert()
        alert.messageText = "欢迎使用 Go2Shell"
        alert.informativeText = """
        1. 请将 Resources/ToolbarScript.applescript 拖到 Finder 工具栏
        2. 点击工具栏按钮即可在当前文件夹打开终端

        当前配置的终端: \(ConfigManager().getConfig().terminalBundleId)
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "完成")
        alert.runModal()

        // 退出应用
        NSApp.terminate(nil)
    }
}

// 创建并运行应用
let app = NSApplication.shared
let delegate = Go2ShellApp()
app.delegate = delegate

// 处理直接打开的情况（用于测试）
if CommandLine.arguments.contains("--test") {
    let finder = FinderPathExtractor()
    let launcher = TerminalLauncher()
    let path = finder.getCurrentPath()
    print("Current path: \(path)")
    launcher.openTerminal(at: path)
}

app.run()
