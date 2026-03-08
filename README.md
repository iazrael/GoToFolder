# Go2Shell

一个极简的 macOS 工具，通过 Finder 工具栏按钮一键在当前文件夹打开终端。

![Go2Shell Icon](Resources/icon.png)

## 功能

- 点击 Finder 工具栏按钮，在当前文件夹打开终端
- 支持多种终端应用（Terminal.app, iTerm2）
- 自动 cd 到当前 Finder 窗口路径

## 快速开始

### 1. 安装工具栏脚本

将 `Resources/ToolbarScript.applescript` 拖到 Finder 工具栏：

1. 在 Finder 中，按住 `⌘` 键
2. 将工具栏脚本文件拖到 Finder 窗口顶部的工具栏区域
3. 释放鼠标，脚本按钮就会出现

### 2. 使用

- 在任意 Finder 窗口中，点击工具栏上的脚本按钮
- 新终端窗口会在当前文件夹打开

## 不同终端

项目提供了针对不同终端的脚本版本：

- `ToolbarScript.applescript` - 系统自带 Terminal.app
- `ToolbarScript-iTerm2.applescript` - iTerm2

## 构建

```bash
./build.sh
```

这将生成 `Go2Shell.app`。

## 安装应用

```bash
cp -R Go2Shell.app /Applications/
```

## 配置

默认使用 Terminal.app。要使用其他终端，请：

1. 打开 Go2Shell.app
2. 按照提示选择终端应用

或直接拖入对应的工具栏脚本版本。

## 原版 Go2Shell

本项目受原版 [Go2Shell](http://go2shell.cz.it/) 启发，重新实现以兼容新版本 macOS。

## 许可

MIT License
