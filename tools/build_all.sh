#!/bin/bash
set -euo pipefail

GODOT="${GODOT_BIN:-godot}"
PROJECT_PATH="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_PATH/build"

echo "=== MeaCore Quest Build All ==="
echo "Using Godot: $GODOT"
echo "Project: $PROJECT_PATH"
echo ""

# Windows
echo "[1/4] Building Windows..."
mkdir -p "$BUILD_DIR/windows"
$GODOT --headless --path "$PROJECT_PATH" --export-release "Windows Desktop" "$BUILD_DIR/windows/MeaCoreQuest.exe"
echo "Windows -> $BUILD_DIR/windows/MeaCoreQuest.exe"
echo ""

# Linux
echo "[2/4] Building Linux..."
mkdir -p "$BUILD_DIR/linux"
$GODOT --headless --path "$PROJECT_PATH" --export-release "Linux Desktop" "$BUILD_DIR/linux/MeaCoreQuest.x86_64"
echo "Linux -> $BUILD_DIR/linux/MeaCoreQuest.x86_64"
echo ""

# Linux Server Headless
echo "[3/4] Building Linux Server Headless..."
mkdir -p "$BUILD_DIR/server"
$GODOT --headless --path "$PROJECT_PATH" --export-release "Linux Server Headless" "$BUILD_DIR/server/MeaCoreQuest_Server.x86_64"
echo "Server -> $BUILD_DIR/server/MeaCoreQuest_Server.x86_64"
echo ""

# Android
echo "[4/4] Building Android..."
if [ -f "$GODOT" ] && $GODOT --headless --path "$PROJECT_PATH" --export-release "Android" "$BUILD_DIR/android/MeaCoreQuest.apk" 2>/dev/null; then
    echo "Android -> $BUILD_DIR/android/MeaCoreQuest.apk"
else
    echo "Android build skipped (requires Android SDK + export templates)"
fi
echo ""

echo "=== Build complete ==="
ls -lh "$BUILD_DIR"/*/
