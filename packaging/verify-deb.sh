#!/usr/bin/env bash
set -euo pipefail

PACKAGE="${1:-}"

if [[ -z "$PACKAGE" || ! -f "$PACKAGE" ]]; then
  printf 'Usage: %s path/to/nerdshell.deb\n' "$0" >&2
  exit 1
fi

PACKAGE="$(cd "$(dirname "$PACKAGE")" && pwd)/$(basename "$PACKAGE")"

for command_name in ar tar grep; do
  command -v "$command_name" >/dev/null 2>&1 || {
    printf '%s is required to verify the package.\n' "$command_name" >&2
    exit 1
  }
done

MEMBERS="$(ar -t "$PACKAGE")"
EXPECTED=$'debian-binary\ncontrol.tar.gz\ndata.tar.gz'
[[ "$MEMBERS" == "$EXPECTED" ]] || {
  printf 'Invalid Debian archive members:\n%s\n' "$MEMBERS" >&2
  exit 1
}

[[ "$(ar -p "$PACKAGE" debian-binary)" == "2.0" ]] || {
  printf 'Unsupported or missing Debian binary format marker.\n' >&2
  exit 1
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
(
  cd "$TMP_DIR"
  ar -x "$PACKAGE"
)

CONTROL="$(tar -xOzf "$TMP_DIR/control.tar.gz" ./control)"
grep -q '^Package: nerdshell$' <<< "$CONTROL"
grep -q '^Architecture: all$' <<< "$CONTROL"

CONTENTS="$(tar -tzf "$TMP_DIR/data.tar.gz")"
for required_file in \
  './usr/bin/nerdshell-installer' \
  './usr/lib/nerdshell/linux/install.sh' \
  './usr/share/applications/nerdshell.desktop' \
  './usr/share/metainfo/io.github.nerdshell.Nerdshell.metainfo.xml' \
  './usr/share/icons/hicolor/scalable/apps/nerdshell.svg'; do
  grep -q "^${required_file}$" <<< "$CONTENTS" || {
    printf 'Missing packaged file: %s\n' "$required_file" >&2
    exit 1
  }
done

if command -v dpkg-deb >/dev/null 2>&1; then
  dpkg-deb --info "$PACKAGE" >/dev/null
  dpkg-deb --contents "$PACKAGE" >/dev/null
fi

printf 'Verified %s\n' "$PACKAGE"
