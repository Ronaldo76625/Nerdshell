#!/usr/bin/env bash
set -euo pipefail

PACKAGE="${1:-}"
if [[ -z "$PACKAGE" || ! -f "$PACKAGE" ]]; then
  printf 'Usage: %s path/to/nerdshell.pkg.tar.zst\n' "$0" >&2
  exit 1
fi

PACKAGE="$(cd "$(dirname "$PACKAGE")" && pwd)/$(basename "$PACKAGE")"
command -v bsdtar >/dev/null 2>&1 || {
  printf 'bsdtar is required to verify the Arch package.\n' >&2
  exit 1
}

PKGINFO="$(bsdtar -xOf "$PACKAGE" .PKGINFO)"
grep -q '^pkgname = nerdshell$' <<< "$PKGINFO"
grep -q '^arch = any$' <<< "$PKGINFO"

CONTENTS="$(bsdtar -tf "$PACKAGE")"
for required_file in \
  'usr/bin/nerdshell-installer' \
  'usr/lib/nerdshell/linux/install.sh' \
  'usr/lib/nerdshell/.skip-system-packages' \
  'usr/share/applications/nerdshell.desktop' \
  'usr/share/icons/hicolor/scalable/apps/nerdshell.svg'; do
  grep -q "^${required_file}$" <<< "$CONTENTS" || {
    printf 'Missing packaged file: %s\n' "$required_file" >&2
    exit 1
  }
done

if command -v pacman >/dev/null 2>&1; then
  pacman -Qip "$PACKAGE" >/dev/null
fi

printf 'Verified %s\n' "$PACKAGE"
