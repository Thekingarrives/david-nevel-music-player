#!/bin/bash

# Easylove Music Player Build Script
# Usage: ./Scripts/build.sh

set -e

# 获取项目根目录
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

# 配置
APP_NAME="Easylove"
SOURCES_DIR="Sources"
RESOURCES_DIR="Resources"
BUILD_DIR="Build"
ICON_SOURCE="$RESOURCES_DIR/001.png"

echo "🎵 Easylove Music Player Builder"
echo "================================"
echo ""

# 检查源文件
if [ ! -f "$SOURCES_DIR/main.swift" ]; then
    echo "❌ Error: main.swift not found in $SOURCES_DIR"
    exit 1
fi

# 检查图标
if [ ! -f "$ICON_SOURCE" ]; then
    echo "❌ Error: App icon not found at $ICON_SOURCE"
    exit 1
fi

echo "📦 Building $APP_NAME..."

# 1. 编译
echo "   🔨 Compiling..."
swiftc -o "$BUILD_DIR/SimpleMusicPlayer" "$SOURCES_DIR/main.swift" -framework Cocoa -framework AVFoundation

# 2. 清理旧的构建
echo "   🧹 Cleaning old builds..."
rm -rf "$BUILD_DIR/$APP_NAME.app"
rm -rf "$BUILD_DIR/dmg"

# 3. 创建 app 结构
echo "   📁 Creating app bundle..."
mkdir -p "$BUILD_DIR/$APP_NAME.app/Contents/MacOS"
mkdir -p "$BUILD_DIR/$APP_NAME.app/Contents/Resources"
mkdir -p "$BUILD_DIR/dmg/$APP_NAME.app/Contents/MacOS"
mkdir -p "$BUILD_DIR/dmg/$APP_NAME.app/Contents/Resources"

# 4. 复制可执行文件
cp "$BUILD_DIR/SimpleMusicPlayer" "$BUILD_DIR/$APP_NAME.app/Contents/MacOS/"
cp "$BUILD_DIR/SimpleMusicPlayer" "$BUILD_DIR/dmg/$APP_NAME.app/Contents/MacOS/"

# 5. 创建 Info.plist
echo "   📝 Creating Info.plist..."
cat > "$BUILD_DIR/$APP_NAME.app/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>SimpleMusicPlayer</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.easylove</string>
    <key>CFBundleName</key>
    <string>Easylove</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
</dict>
</plist>
PLIST

cp "$BUILD_DIR/$APP_NAME.app/Contents/Info.plist" "$BUILD_DIR/dmg/$APP_NAME.app/Contents/Info.plist"

# 6. 创建图标集
echo "   🎨 Creating app icon..."
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

# 生成所有需要的图标尺寸
sips -z 16 16     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16.png" &>/dev/null
sips -z 32 32     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16@2x.png" &>/dev/null
sips -z 32 32     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32.png" &>/dev/null
sips -z 64 64     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32@2x.png" &>/dev/null
sips -z 128 128   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128.png" &>/dev/null
sips -z 256 256   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128@2x.png" &>/dev/null
sips -z 256 256   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256.png" &>/dev/null
sips -z 512 512   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256@2x.png" &>/dev/null
sips -z 512 512   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_512x512.png" &>/dev/null
sips -z 1024 1024 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_512x512@2x.png" &>/dev/null

# 转换为 icns
iconutil -c icns "$ICONSET_DIR" -o "$BUILD_DIR/$APP_NAME.app/Contents/Resources/AppIcon.icns"
iconutil -c icns "$ICONSET_DIR" -o "$BUILD_DIR/dmg/$APP_NAME.app/Contents/Resources/AppIcon.icns"

# 清理临时文件
rm -rf "$ICONSET_DIR"

echo "   ✓ Icon created successfully"

# 7. 创建 DMG
echo "   💿 Creating DMG..."
rm -f "$BUILD_DIR/$APP_NAME.dmg"
hdiutil create -srcfolder "$BUILD_DIR/dmg/$APP_NAME.app" -volname "$APP_NAME" -o "$BUILD_DIR/$APP_NAME.dmg" -quiet

# 8. 复制到 Release
echo "   📤 Copying to Release..."
mkdir -p "$PROJECT_ROOT/Release"
rm -rf "$PROJECT_ROOT/Release/$APP_NAME.app"
cp -R "$BUILD_DIR/$APP_NAME.app" "$PROJECT_ROOT/Release/"
cp "$BUILD_DIR/$APP_NAME.dmg" "$PROJECT_ROOT/Release/"

echo ""
echo "✅ Build successful!"
echo ""
echo "📍 Output locations:"
echo "   • App:  $BUILD_DIR/$APP_NAME.app"
echo "   • DMG:  $BUILD_DIR/$APP_NAME.dmg"
echo "   • Release: $PROJECT_ROOT/Release/"
echo ""
