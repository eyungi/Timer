#!/bin/bash
# Timer.app 번들을 만들어 ~/Applications 에 설치합니다.
set -e
cd "$(dirname "$0")"

APP_NAME="Timer"
APP_DIR="$APP_NAME.app"

echo "▶ 릴리스 빌드 중..."
swift build -c release

BIN_PATH="$(swift build -c release --show-bin-path)/$APP_NAME"

echo "▶ 앱 아이콘 생성 중..."
swift make-icon.swift
rm -rf AppIcon.iconset
mkdir -p AppIcon.iconset
for s in 16 32 128 256 512; do
    sips -z "$s" "$s"           icon_1024.png --out "AppIcon.iconset/icon_${s}x${s}.png"    >/dev/null
    sips -z "$((s*2))" "$((s*2))" icon_1024.png --out "AppIcon.iconset/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns AppIcon.iconset -o AppIcon.icns

echo "▶ .app 번들 생성 중..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp AppIcon.icns "$APP_DIR/Contents/Resources/AppIcon.icns"

cat > "$APP_DIR/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>     <string>Timer</string>
    <key>CFBundleExecutable</key>      <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>      <string>com.timer.app</string>
    <key>CFBundleVersion</key>         <string>1.0</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleIconFile</key>        <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>  <string>14.0</string>
    <key>NSHighResolutionCapable</key> <true/>
</dict>
</plist>
EOF

echo "▶ ~/Applications 에 설치 중..."
mkdir -p "$HOME/Applications"
rm -rf "$HOME/Applications/$APP_DIR"
cp -R "$APP_DIR" "$HOME/Applications/"

echo "✅ 완료: ~/Applications/$APP_DIR"
echo "   실행: open \"$HOME/Applications/$APP_DIR\""
