#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-0.1.0}"
APP_NAME="Nerdshell"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPOSITORY_ROOT="$(cd "$ROOT_DIR/../../.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
DMG_ROOT="$DIST_DIR/dmg-root"
DMG_PATH="$DIST_DIR/$APP_NAME-$VERSION-macOS-arm64.dmg"
ICONSET="$DIST_DIR/AppIcon.iconset"
SOURCE_ICON="$REPOSITORY_ROOT/assets/nerdshell.svg"
SIGNING_IDENTITY="${CODESIGN_IDENTITY:--}"

cd "$ROOT_DIR"
./script/build_and_run.sh --build

rm -rf "$ICONSET" "$DMG_ROOT"
mkdir -p "$ICONSET" "$DMG_ROOT"

render_icon() {
  local size="$1"
  local output="$2"
  /opt/homebrew/bin/magick -background none "$SOURCE_ICON" -resize "${size}x${size}" "$output"
}

render_icon 16 "$ICONSET/icon_16x16.png"
render_icon 32 "$ICONSET/icon_16x16@2x.png"
render_icon 32 "$ICONSET/icon_32x32.png"
render_icon 64 "$ICONSET/icon_32x32@2x.png"
render_icon 128 "$ICONSET/icon_128x128.png"
render_icon 256 "$ICONSET/icon_128x128@2x.png"
render_icon 256 "$ICONSET/icon_256x256.png"
render_icon 512 "$ICONSET/icon_256x256@2x.png"
render_icon 512 "$ICONSET/icon_512x512.png"
render_icon 1024 "$ICONSET/icon_512x512@2x.png"

iconutil -c icns "$ICONSET" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
printf 'APPL????' >"$APP_BUNDLE/Contents/PkgInfo"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_BUNDLE/Contents/Info.plist"

codesign --force --deep --options runtime --timestamp=none --sign "$SIGNING_IDENTITY" "$APP_BUNDLE"
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

ditto "$APP_BUNDLE" "$DMG_ROOT/$APP_NAME.app"
ln -s /Applications "$DMG_ROOT/Applications"

rm -f "$DMG_PATH"
hdiutil create \
  -volname "$APP_NAME $VERSION" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

hdiutil verify "$DMG_PATH"
printf '%s\n' "$DMG_PATH"
