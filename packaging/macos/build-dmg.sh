#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VERSION="${1:-0.1.0}"
BUILD_VERSION="${BUILD_VERSION:-1}"
APP_NAME="Nerdshell Installer"
VOLUME_NAME="Nerdshell Installer"
BUILD_ROOT="$ROOT/dist/macos"
APP="$BUILD_ROOT/$APP_NAME.app"
DMG_ROOT="$BUILD_ROOT/dmg-root"
DMG="$ROOT/dist/Nerdshell-${VERSION}-macOS.dmg"
RW_DMG="$BUILD_ROOT/Nerdshell-rw.dmg"

for tool in clang lipo iconutil hdiutil codesign magick; do
  command -v "$tool" >/dev/null 2>&1 || {
    printf '%s is required to build the macOS installer.\n' "$tool" >&2
    exit 1
  }
done

case "$VERSION" in
  *[!0-9A-Za-z.-]*|'')
    printf 'Invalid version: %s\n' "$VERSION" >&2
    exit 1
    ;;
esac

rm -rf "$BUILD_ROOT"
mkdir -p \
  "$APP/Contents/MacOS" \
  "$APP/Contents/Resources/nerdshell" \
  "$DMG_ROOT/.background"

sed \
  -e "s/@VERSION@/$VERSION/g" \
  -e "s/@BUILD_VERSION@/$BUILD_VERSION/g" \
  "$ROOT/packaging/macos/Info.plist" > "$APP/Contents/Info.plist"

clang -O2 -fobjc-arc -target arm64-apple-macos13.0 -framework Cocoa \
  "$ROOT/packaging/macos/NerdshellInstaller.m" \
  -o "$BUILD_ROOT/nerdshell-arm64"
clang -O2 -fobjc-arc -target x86_64-apple-macos13.0 -framework Cocoa \
  "$ROOT/packaging/macos/NerdshellInstaller.m" \
  -o "$BUILD_ROOT/nerdshell-x86_64"
lipo -create \
  "$BUILD_ROOT/nerdshell-arm64" \
  "$BUILD_ROOT/nerdshell-x86_64" \
  -output "$APP/Contents/MacOS/$APP_NAME"

ICONSET="$BUILD_ROOT/AppIcon.iconset"
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
  magick -background none "$ROOT/assets/nerdshell.svg" -resize "${size}x${size}" \
    "$ICONSET/icon_${size}x${size}.png"
  retina=$((size * 2))
  magick -background none "$ROOT/assets/nerdshell.svg" -resize "${retina}x${retina}" \
    "$ICONSET/icon_${size}x${size}@2x.png"
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

cp -R "$ROOT/configs" "$APP/Contents/Resources/nerdshell/configs"
cp -R "$ROOT/scripts" "$APP/Contents/Resources/nerdshell/scripts"
cp -R "$ROOT/macos" "$APP/Contents/Resources/nerdshell/macos"
chmod 0755 \
  "$APP/Contents/Resources/nerdshell/macos/install.sh" \
  "$APP/Contents/Resources/nerdshell/macos/install.command"

CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"
if [[ "$CODESIGN_IDENTITY" == "-" ]]; then
  codesign --force --sign - "$APP"
  printf 'App signed ad hoc. Gatekeeper may warn on other Macs.\n'
else
  codesign --force --options runtime --timestamp --sign "$CODESIGN_IDENTITY" "$APP"
fi

cp -R "$APP" "$DMG_ROOT/$APP_NAME.app"
ln -s /Applications "$DMG_ROOT/Applications"
magick "$ROOT/packaging/macos/dmg-background.svg" "$DMG_ROOT/.background/background.png"

rm -f "$RW_DMG" "$DMG"
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$DMG_ROOT" \
  -ov -format UDRW \
  "$RW_DMG" >/dev/null

MOUNT_POINT="/Volumes/$VOLUME_NAME"
MOUNTED=0
cleanup_mount() {
  if [[ "$MOUNTED" -eq 1 && -d "$MOUNT_POINT" ]]; then
    hdiutil detach "$MOUNT_POINT" -force >/dev/null 2>&1 || true
  fi
}
trap cleanup_mount EXIT

hdiutil attach "$RW_DMG" -readwrite -noverify -noautoopen >/dev/null
MOUNTED=1

set +e
osascript <<APPLESCRIPT &
tell application "Finder"
  tell disk "$VOLUME_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set pathbar visible of container window to false
    set bounds of container window to {120, 120, 780, 540}
    set theViewOptions to the icon view options of container window
    set arrangement of theViewOptions to not arranged
    set icon size of theViewOptions to 112
    set text size of theViewOptions to 13
    set background picture of theViewOptions to file ".background:background.png"
    set position of item "$APP_NAME.app" of container window to {175, 215}
    set position of item "Applications" of container window to {485, 215}
    close
    open
    update without registering applications
    delay 2
    close
  end tell
end tell
APPLESCRIPT
FINDER_STYLE_PID=$!
set -e

FINDER_STYLE_FINISHED=0
for _ in {1..15}; do
  if ! kill -0 "$FINDER_STYLE_PID" 2>/dev/null; then
    FINDER_STYLE_FINISHED=1
    break
  fi
  sleep 1
done

if [[ "$FINDER_STYLE_FINISHED" -eq 1 ]]; then
  if ! wait "$FINDER_STYLE_PID"; then
    printf 'Finder styling was skipped; continuing with the standard DMG layout.\n' >&2
  fi
else
  kill "$FINDER_STYLE_PID" 2>/dev/null || true
  wait "$FINDER_STYLE_PID" 2>/dev/null || true
  printf 'Finder styling timed out; continuing with the standard DMG layout.\n' >&2
fi

sync
hdiutil detach "$MOUNT_POINT" >/dev/null
MOUNTED=0
hdiutil convert "$RW_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG" >/dev/null

if [[ "$CODESIGN_IDENTITY" != "-" ]]; then
  codesign --force --timestamp --sign "$CODESIGN_IDENTITY" "$DMG"
fi

codesign --verify --deep --strict --verbose=2 "$APP"
hdiutil verify "$DMG" >/dev/null

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  if [[ "$CODESIGN_IDENTITY" == "-" ]]; then
    printf 'NOTARY_PROFILE requires a Developer ID Application signing identity.\n' >&2
    exit 1
  fi
  xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG"
  xcrun stapler validate "$DMG"
fi

trap - EXIT

printf 'Built %s\n' "$DMG"
