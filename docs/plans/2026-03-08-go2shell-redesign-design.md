# Go2Shell 重新设计方案

**日期：** 2026-03-08
**版本：** 1.0

---

## 概述

重新设计一个类似 Go2Shell 的 macOS 工具，通过 Finder 工具栏按钮一键在当前文件夹打开终端，并自动 cd 到该目录。原版 Go2Shell 多年未更新，新版本系统不兼容。

---

## 产品定位

**核心功能：**
1. 在 Finder 工具栏显示一个可点击的按钮/图标
2. 点击时获取当前 Finder 窗口的路径
3. 打开用户配置的终端应用（Terminal/iTerm2/Warp 等）
4. 新终端窗口自动 cd 到该路径

**设计原则：**
- 极简：只保留核心功能，避免不必要的复杂性
- 可配置：用户可选择喜欢的终端应用
- 易安装：独立的 .app 安装包

---

## 技术栈

- **语言：** Swift 原生开发
- **框架：** AppKit, Foundation, NSWorkspace
- **脚本：** AppleScript (与 Finder 交互)
- **存储：** UserDefaults

**为什么不用纯 AppleScript：**
虽然 AppleScript 很轻量，但要做成独立的 .app 安装包并实现可配置的终端选择，Swift 原生 App 是更好的选择。

---

## 架构设计

### 应用结构

```
Go2Shell.app
├── Contents/
│   ├── MacOS/
│   │   └── go2shell                    # Swift 编译的二进制
│   ├── Resources/
│   │   ├── Assets.xcassets/            # 图标资源
│   │   └── ToolbarScript.applescript   # 工具栏脚本
│   └── Info.plist
```

### 核心组件

1. **Main App (Go2ShellApp)**
   - 启动时检查是否已安装工具栏脚本
   - 提供"安装到工具栏"引导界面
   - 提供终端选择配置界面

2. **Toolbar Script (AppleScript)**
   - 被拖到 Finder 工具栏后执行
   - 获取当前 Finder 窗口路径
   - 调用主 App 的 open URL scheme 传递路径

3. **URL Scheme Handler**
   - 接收 `go2shell://open?path=/xxx` 请求
   - 读取用户配置的终端应用
   - 使用 NSWorkspace.openTerminal 打开终端并 cd

### 数据流

```
用户点击 Finder 工具栏按钮
  → AppleScript 获取当前路径
  → 调用 go2shell://open?path=xxx
  → 主 App 读取配置的终端
  → NSWorkspace 打开终端 + cd
```

---

## 核心实现

### 获取 Finder 当前路径

```swift
func getCurrentFinderPath() -> String? {
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
    let output = NSAppleScript(source: script)?.executeAndReturnError(&error)
    return output?.stringValue
}
```

### 打开终端并 cd

```swift
func openTerminal(at path: String) {
    guard let terminalURL = getConfiguredTerminalURL() else { return }

    // 构建带 cd 的参数
    let arguments = [
        "--new",  // iTerm2
        // 或 "--args" for Terminal
    ]

    // 使用 NSWorkspace 打开
    NSWorkspace.shared.open(
        URL(fileURLWithPath: path),
        withApplicationAt: terminalURL,
        configuration: NSWorkspace.OpenConfiguration()
    )
}
```

### 配置存储

```swift
struct AppConfig: Codable {
    var terminalBundleId: String  // "com.apple.Terminal", "com.googlecode.iterm2"
    var terminalPath: String?      // 自定义路径
}

let configKey = "terminalConfig"
```

---

## Finder 工具栏集成

### 工具栏按钮图标

参考原版 Go2Shell 的经典设计 —— **">_<"** 符号组合：

- `>` - 终端提示符，代表命令行
- `_` - 光标位置，代表输入等待
- 组合形成类似 "(>_<)" 表情的视觉效果，友好且易识别

**实现方式：**
- Assets.xcassets 中提供图标资源
- `terminal_icon.pdf` - Template Image（自适应深色/浅色模式）
- 图标尺寸：16x16 pt（标准 Finder 工具栏大小）

### 工具栏脚本

```applescript
on run
    tell application "Go2Shell" to open location "go2shell://open"
end run
```

用户将此脚本拖到 Finder 工具栏即可使用。

---

## 用户界面

首次启动时显示一个简洁的配置窗口：

```
┌─────────────────────────────────────┐
│           Go2Shell                  │
├─────────────────────────────────────┤
│                                     │
│    选择终端应用:                    │
│    ┌───────────────────────────┐    │
│    │ □ Terminal.app            │    │
│    │ ☑ iTerm2                  │    │
│    │ □ Warp                    │    │
│    │ □ 其他...                 │    │
│    └───────────────────────────┘    │
│                                     │
│    [安装到工具栏]                   │
│                                     │
│  → 将下面的脚本拖到 Finder 工具栏   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │      📜 Terminal Script     │   │
│  └─────────────────────────────┘   │
│                                     │
│              [完成]                 │
└─────────────────────────────────────┘
```

**界面特点：**
- 仅显示一次（设置后可从菜单重新打开）
- 终端选择使用 NSPopUpButton
- 拖拽区域使用拖放友好的视觉提示
- 使用系统原生控件，融合 macOS 风格

---

## 错误处理与边界情况

### 需要处理的边界情况

1. **没有 Finder 窗口打开时**
   - 回退到用户主目录或桌面路径

2. **配置的终端应用未安装时**
   - 检测 Bundle ID 是否存在
   - 回退到系统默认 Terminal.app
   - 通知用户并提示重新配置

3. **路径包含特殊字符或空格**
   - 使用 shell 转义处理
   - 正确处理中文路径

4. **网络驱动器或不可访问路径**
   - 优雅降级，显示错误提示而不是崩溃

### 错误提示方式

- 关键错误：使用 `NSAlert` 通知
- 非关键错误：静默处理（如回退到默认路径）
- 日志记录：`~/Library/Logs/Go2Shell/`

---

## 部署与分发

### 分发方式

1. **直接下载 .dmg 镜像**
   - 用户拖拽到 /Applications 安装
   - 简单直接，无需 App Store 审核

2. **开源发布**
   - GitHub Releases 提供编译好的 .app
   - 源码公开，社区可贡献

### Info.plist 配置

```xml
<key>CFBundleIdentifier</key>
<string>com.go2shell.app</string>

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>go2shell</string>
        </array>
    </dict>
</array>

<key>LSUIElement</key>
<false/>
```

### 版本管理

- 语义化版本：v1.0.0
- 支持 Sparkle 或原生自动更新（可选）

---

## 后续实现计划

1. 创建 Swift Xcode 项目
2. 实现核心功能（路径获取、终端打开）
3. 实现配置界面
4. 实现工具栏脚本
5. 测试与打包
