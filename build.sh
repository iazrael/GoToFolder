#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# build.sh — Builds GoToFolder.app without Xcode (uses swiftc directly)
#
# Usage:
#   chmod +x build.sh
#   ./build.sh               # Release build (arm64 + x86_64 universal binary)
#   ./build.sh --debug       # Debug build
#   ./build.sh --install     # Build + copy to /Applications
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
APP_NAME="GoToFolder"
BUNDLE_ID="com.yourname.GoToFolder"
VERSION="1.0.0"
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$ROOT_DIR/Sources/$APP_NAME"
RES_DIR="$ROOT_DIR/Resources"
BUILD_DIR="$ROOT_DIR/.build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

DEBUG=false
INSTALL=false
for arg in "$@"; do
    [[ "$arg" == "--debug"   ]] && DEBUG=true
    [[ "$arg" == "--install" ]] && INSTALL=true
done

OPT_FLAGS="-O -whole-module-optimization"
$DEBUG && OPT_FLAGS="-Onone -g"

echo "═══════════════════════════════════════════════════════"
echo "  Building $APP_NAME v$VERSION"
$DEBUG && echo "  Mode: DEBUG" || echo "  Mode: RELEASE"
echo "═══════════════════════════════════════════════════════"

# ── Clean ─────────────────────────────────────────────────────────────────────
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# ── Compile Swift sources ─────────────────────────────────────────────────────
echo "→ Compiling Swift sources…"
SWIFT_SOURCES=("$SRC_DIR"/*.swift)

# Build universal binary (Apple Silicon + Intel)
TMP_ARM="$BUILD_DIR/${APP_NAME}_arm64"
TMP_X86="$BUILD_DIR/${APP_NAME}_x86_64"
BIN_OUT="$BUILD_DIR/$APP_NAME"

COMMON_FLAGS=(
    -sdk /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk
    -target arm64-apple-macos12
    $OPT_FLAGS
    -framework Cocoa
    -o "$TMP_ARM"
)

echo "   compiling arm64…"
swiftc "${SWIFT_SOURCES[@]}" "${COMMON_FLAGS[@]}"

echo "   compiling x86_64…"
swiftc "${SWIFT_SOURCES[@]}" "${COMMON_FLAGS[@]/#-target arm64-apple-macos12/-target x86_64-apple-macos12}" \
    -sdk /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk \
    -target x86_64-apple-macos12 \
    $OPT_FLAGS \
    -framework Cocoa \
    -o "$TMP_X86"

echo "   creating universal binary…"
lipo -create -output "$BIN_OUT" "$TMP_ARM" "$TMP_X86"
rm -f "$TMP_ARM" "$TMP_X86"

# ── Assemble .app bundle ──────────────────────────────────────────────────────
echo "→ Assembling $APP_NAME.app…"

MACOS_DIR="$APP_BUNDLE/Contents/MacOS"
RESOURCES_DIR="$APP_BUNDLE/Contents/Resources"

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# Binary
cp "$BIN_OUT" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

# Info.plist
cp "$RES_DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# Icon (if generated)
[[ -f "$RES_DIR/AppIcon.icns" ]] && cp "$RES_DIR/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"

# ── Code-sign (ad-hoc, no Developer ID required) ─────────────────────────────
echo "→ Code-signing (ad-hoc)…"
codesign \
    --force \
    --deep \
    --sign - \
    --entitlements "$RES_DIR/GoToFolder.entitlements" \
    --options runtime \
    "$APP_BUNDLE"

# ── Summary ───────────────────────────────────────────────────────────────────
SIZE=$(du -sh "$APP_BUNDLE" | cut -f1)
echo ""
echo "✅  Build complete: $APP_BUNDLE ($SIZE)"
echo ""

# ── Optional install ──────────────────────────────────────────────────────────
if $INSTALL; then
    DEST="/Applications/$APP_NAME.app"
    echo "→ Installing to $DEST…"
    rm -rf "$DEST"
    cp -R "$APP_BUNDLE" "$DEST"
    echo "✅  Installed to $DEST"
    echo ""
    echo "Next steps:"
    echo "  1. Open a Finder window"
    echo "  2. Hold ⌘ Command and drag $DEST into the Finder toolbar"
    echo "  3. Click the >_< icon to open your terminal here"
fi
