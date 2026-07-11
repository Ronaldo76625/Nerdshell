#!/usr/bin/env bash
set -euo pipefail

VERSION="$1"
DEB_ARCH="$2"
APP_ROOT="/workspace/apps/linux/NerdshellDesktop"
PACKAGE_ROOT="/workspace/dist/linux-desktop/nerdshell-desktop_${VERSION}_${DEB_ARCH}"
OUTPUT="/workspace/dist/nerdshell-desktop_${VERSION}_${DEB_ARCH}.deb"

make -C "$APP_ROOT" clean all
rm -rf "$PACKAGE_ROOT"
install -d \
  "$PACKAGE_ROOT/DEBIAN" \
  "$PACKAGE_ROOT/usr/bin" \
  "$PACKAGE_ROOT/usr/share/nerdshell-desktop" \
  "$PACKAGE_ROOT/usr/share/applications" \
  "$PACKAGE_ROOT/usr/share/metainfo" \
  "$PACKAGE_ROOT/usr/share/icons/hicolor/scalable/apps" \
  "$PACKAGE_ROOT/usr/share/doc/nerdshell-desktop"

sed -e "s/@VERSION@/$VERSION/g" -e "s/@ARCH@/$DEB_ARCH/g" \
  "$APP_ROOT/packaging/control.in" >"$PACKAGE_ROOT/DEBIAN/control"
install -m 0755 "$APP_ROOT/packaging/postinst" "$PACKAGE_ROOT/DEBIAN/postinst"
install -m 0755 "$APP_ROOT/packaging/postrm" "$PACKAGE_ROOT/DEBIAN/postrm"
install -m 0755 "$APP_ROOT/build/nerdshell" "$PACKAGE_ROOT/usr/bin/nerdshell"
cp -R /workspace/configs "$PACKAGE_ROOT/usr/share/nerdshell-desktop/configs"
install -m 0644 "$APP_ROOT/resources/io.github.nerdshell.desktop" "$PACKAGE_ROOT/usr/share/applications/io.github.nerdshell.desktop"
install -m 0644 "$APP_ROOT/resources/io.github.nerdshell.metainfo.xml" "$PACKAGE_ROOT/usr/share/metainfo/io.github.nerdshell.metainfo.xml"
install -m 0644 /workspace/assets/nerdshell.svg "$PACKAGE_ROOT/usr/share/icons/hicolor/scalable/apps/nerdshell.svg"
install -m 0644 /workspace/LICENSE "$PACKAGE_ROOT/usr/share/doc/nerdshell-desktop/copyright"
install -m 0644 "$APP_ROOT/README.md" "$PACKAGE_ROOT/usr/share/doc/nerdshell-desktop/README.md"

find "$PACKAGE_ROOT/usr/share/nerdshell-desktop/configs" -type f -exec chmod 0644 {} +
dpkg-deb --root-owner-group --build "$PACKAGE_ROOT" "$OUTPUT"
dpkg-deb --info "$OUTPUT"
dpkg-deb --contents "$OUTPUT" >/dev/null
file "$PACKAGE_ROOT/usr/bin/nerdshell"
