#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VERSION="${1:-0.1.0}"
BUILD_ROOT="$ROOT/dist/rpm"
CONTEXT="$BUILD_ROOT/context"
SOURCE_ROOT="$CONTEXT/nerdshell-$VERSION"
OUTPUT="$ROOT/dist/nerdshell-${VERSION}-1.noarch.rpm"
CONTAINER="nerdshell-rpm-builder-$$"

cleanup_container() {
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
}
trap cleanup_container EXIT

case "$VERSION" in
  *[!0-9A-Za-z.+]*|'')
    printf 'Invalid RPM version: %s\n' "$VERSION" >&2
    exit 1
    ;;
esac

command -v docker >/dev/null 2>&1 || {
  printf 'Docker is required to build the RPM outside Fedora/RHEL.\n' >&2
  exit 1
}

rm -rf "$BUILD_ROOT"
mkdir -p "$SOURCE_ROOT/linux" "$CONTEXT/SOURCES" "$CONTEXT/SPECS"

cp -R "$ROOT/configs" "$SOURCE_ROOT/configs"
cp -R "$ROOT/scripts" "$SOURCE_ROOT/scripts"
install -m 0755 "$ROOT/linux/install.sh" "$SOURCE_ROOT/linux/install.sh"
install -m 0755 "$ROOT/linux/nerdshell-installer" "$SOURCE_ROOT/linux/nerdshell-installer"
install -m 0644 "$ROOT/assets/nerdshell.svg" "$SOURCE_ROOT/nerdshell.svg"
install -m 0644 "$ROOT/packaging/debian/nerdshell.desktop" "$SOURCE_ROOT/nerdshell.desktop"
install -m 0644 "$ROOT/packaging/debian/nerdshell.metainfo.xml" "$SOURCE_ROOT/nerdshell.metainfo.xml"
install -m 0644 "$ROOT/README.md" "$SOURCE_ROOT/README.md"
install -m 0644 "$ROOT/LICENSE" "$SOURCE_ROOT/LICENSE"

COPYFILE_DISABLE=1 tar --no-xattrs -czf "$CONTEXT/SOURCES/nerdshell-$VERSION.tar.gz" \
  -C "$CONTEXT" "nerdshell-$VERSION"
sed "s/@VERSION@/$VERSION/g" \
  "$ROOT/packaging/rpm/nerdshell.spec.in" > "$CONTEXT/SPECS/nerdshell.spec"

docker create --name "$CONTAINER" \
  fedora:44 \
  bash -lc 'dnf install -y rpm-build shadow-utils >/dev/null && useradd --create-home builder && chown -R builder:builder /build && su builder -c "rpmbuild --define \"_topdir /build\" -ba /build/SPECS/nerdshell.spec"' \
  >/dev/null
docker cp "$CONTEXT/." "$CONTAINER:/build"
docker start -a "$CONTAINER"
docker cp "$CONTAINER:/build/RPMS/noarch/nerdshell-${VERSION}-1.noarch.rpm" "$OUTPUT"

"$ROOT/packaging/rpm/verify-rpm.sh" "$OUTPUT"
trap - EXIT
cleanup_container
printf 'Built %s\n' "$OUTPUT"
