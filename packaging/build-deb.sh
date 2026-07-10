#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-0.1.0}"
ARCH="all"
BUILD_ROOT="$ROOT/dist/deb"
PACKAGE_ROOT="$BUILD_ROOT/nerdshell_${VERSION}_${ARCH}"
OUTPUT="$ROOT/dist/nerdshell_${VERSION}_${ARCH}.deb"

case "$VERSION" in
  *[!0-9A-Za-z.+:~-]*|'')
    printf 'Invalid Debian version: %s\n' "$VERSION" >&2
    exit 1
    ;;
esac

rm -rf "$PACKAGE_ROOT"
mkdir -p \
  "$PACKAGE_ROOT/DEBIAN" \
  "$PACKAGE_ROOT/usr/bin" \
  "$PACKAGE_ROOT/usr/lib/nerdshell" \
  "$PACKAGE_ROOT/usr/share/applications" \
  "$PACKAGE_ROOT/usr/share/doc/nerdshell" \
  "$PACKAGE_ROOT/usr/share/icons/hicolor/scalable/apps" \
  "$PACKAGE_ROOT/usr/share/metainfo"

sed "s/@VERSION@/$VERSION/g" \
  "$ROOT/packaging/debian/control" > "$PACKAGE_ROOT/DEBIAN/control"
install -m 0755 "$ROOT/packaging/debian/postinst" "$PACKAGE_ROOT/DEBIAN/postinst"
install -m 0755 "$ROOT/packaging/debian/postrm" "$PACKAGE_ROOT/DEBIAN/postrm"

cp -R "$ROOT/configs" "$PACKAGE_ROOT/usr/lib/nerdshell/configs"
cp -R "$ROOT/scripts" "$PACKAGE_ROOT/usr/lib/nerdshell/scripts"
mkdir -p "$PACKAGE_ROOT/usr/lib/nerdshell/linux"
install -m 0755 "$ROOT/linux/install.sh" "$PACKAGE_ROOT/usr/lib/nerdshell/linux/install.sh"
install -m 0755 "$ROOT/linux/nerdshell-installer" "$PACKAGE_ROOT/usr/bin/nerdshell-installer"

install -m 0644 "$ROOT/packaging/debian/nerdshell.desktop" \
  "$PACKAGE_ROOT/usr/share/applications/nerdshell.desktop"
install -m 0644 "$ROOT/packaging/debian/nerdshell.metainfo.xml" \
  "$PACKAGE_ROOT/usr/share/metainfo/io.github.nerdshell.Nerdshell.metainfo.xml"
install -m 0644 "$ROOT/assets/nerdshell.svg" \
  "$PACKAGE_ROOT/usr/share/icons/hicolor/scalable/apps/nerdshell.svg"
install -m 0644 "$ROOT/README.md" "$PACKAGE_ROOT/usr/share/doc/nerdshell/README.md"
install -m 0644 "$ROOT/LICENSE" "$PACKAGE_ROOT/usr/share/doc/nerdshell/copyright"

find "$PACKAGE_ROOT/usr/lib/nerdshell/configs" -type f -exec chmod 0644 {} +
find "$PACKAGE_ROOT/usr/lib/nerdshell/scripts" -type f -exec chmod 0644 {} +

mkdir -p "$ROOT/dist"

if command -v dpkg-deb >/dev/null 2>&1; then
  dpkg-deb --root-owner-group --build "$PACKAGE_ROOT" "$OUTPUT"
else
  command -v ar >/dev/null 2>&1 || {
    printf 'dpkg-deb or ar is required to build the package.\n' >&2
    exit 1
  }

  ARCHIVE_ROOT="$BUILD_ROOT/archive"
  rm -rf "$ARCHIVE_ROOT"
  mkdir -p "$ARCHIVE_ROOT/control" "$ARCHIVE_ROOT/data"
  cp -R "$PACKAGE_ROOT/DEBIAN/." "$ARCHIVE_ROOT/control/"
  cp -R "$PACKAGE_ROOT/usr" "$ARCHIVE_ROOT/data/usr"

  printf '2.0\n' > "$ARCHIVE_ROOT/debian-binary"
  COPYFILE_DISABLE=1 tar --uid 0 --gid 0 --uname root --gname root --format ustar -czf \
    "$ARCHIVE_ROOT/control.tar.gz" -C "$ARCHIVE_ROOT/control" .
  COPYFILE_DISABLE=1 tar --uid 0 --gid 0 --uname root --gname root --format ustar -czf \
    "$ARCHIVE_ROOT/data.tar.gz" -C "$ARCHIVE_ROOT/data" .

  rm -f "$OUTPUT"
  (
    cd "$ARCHIVE_ROOT"
    ar -qS "$OUTPUT" debian-binary control.tar.gz data.tar.gz
  )
fi

"$ROOT/packaging/verify-deb.sh" "$OUTPUT"
printf 'Built %s\n' "$OUTPUT"
