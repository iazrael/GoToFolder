#!/bin/bash

# Go2Shell Build Script

set -e

APP_NAME="Go2Shell"
APP_PATH="$APP_NAME.app"
CONTENTS="$APP_PATH/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "Building $APP_NAME..."

# 清理旧版本
rm -rf "$APP_PATH"

# 创建 .app 结构
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

# 编译
echo "Compiling..."
swiftc -o "$MACOS/$APP_NAME" Sources/Go2Shell/main.swift -framework Cocoa

# 复制资源
echo "Copying resources..."
cp Resources/ToolbarScript.applescript "$RESOURCES/"
cp Resources/ToolbarScript-iTerm2.applescript "$RESOURCES/"

# 创建 Info.plist
cat > "$CONTENTS/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Go2Shell</string>
    <key>CFBundleIdentifier</key>
    <string>com.go2shell.app</string>
    <key>CFBundleName</key>
    <string>Go2Shell</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "Build complete: $APP_PATH"
echo ""
echo "To install:"
echo "  cp -R $APP_PATH /Applications/"
