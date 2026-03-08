# Go2Shell

一个极简的 macOS 工具，通过 Finder 工具栏按钮一键在当前文件夹打开终端。

## 功能

- 点击 Finder 工具栏按钮，在当前文件夹打开终端
- 自动 cd 到当前 Finder 窗口路径
- 极简设计，无多余配置

## 快速开始

### 1. 构建应用

```bash
./build.sh
```

### 2. 安装到应用程序文件夹

```bash
cp -R Go2Shell.app /Applications/
```

### 3. 添加到 Finder 工具栏

1. 打开一个新的 Finder 窗口
2. 在窗口右上角工具栏区域，**按住 ⌘ 键点击**
3. 从菜单中选择「自定义工具栏...」
4. 将 Go2Shell 图标拖到工具栏
5. 点击「完成」

### 4. 使用

在任意 Finder 窗口中，点击工具栏上的 Go2Shell 图标即可在当前文件夹打开终端。

## 切换终端应用

默认使用系统自带的 Terminal.app。要使用 iTerm2 等其他终端，可以修改 `Sources/Go2Shell/main.swift` 中的 `terminalBundleId`：

```swift
// Terminal.app (默认)
"com.apple.Terminal"

// iTerm2
"com.googlecode.iterm2"

// Warp
"dev.warp.Warp-Stable"
```

修改后重新运行 `./build.sh` 即可。

## 构建

```bash
./build.sh
```

## 原版 Go2Shell

本项目受原版 [Go2Shell](http://go2shell.cz.it/) 启发，重新实现以兼容新版本 macOS。

## 许可

MIT License
