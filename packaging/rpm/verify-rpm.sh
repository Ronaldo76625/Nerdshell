#!/usr/bin/env bash
set -euo pipefail

PACKAGE="${1:-}"
if [[ -z "$PACKAGE" || ! -f "$PACKAGE" ]]; then
  printf 'Usage: %s path/to/nerdshell.noarch.rpm\n' "$0" >&2
  exit 1
fi

PACKAGE="$(cd "$(dirname "$PACKAGE")" && pwd)/$(basename "$PACKAGE")"

if command -v rpm >/dev/null 2>&1; then
  [[ "$(rpm -qp --queryformat '%{NAME}' "$PACKAGE")" == "nerdshell" ]]
  [[ "$(rpm -qp --queryformat '%{ARCH}' "$PACKAGE")" == "noarch" ]]
  CONTENTS="$(rpm -qlp "$PACKAGE")"
else
  command -v bsdtar >/dev/null 2>&1 || {
    printf 'rpm or bsdtar is required to verify the package.\n' >&2
    exit 1
  }
  CONTENTS="$(bsdtar -tf "$PACKAGE")"
fi

for required_file in \
  'usr/bin/nerdshell-installer' \
  'usr/lib/nerdshell/linux/install.sh' \
  'usr/share/applications/nerdshell.desktop' \
  'usr/share/metainfo/io.github.nerdshell.Nerdshell.metainfo.xml' \
  'usr/share/icons/hicolor/scalable/apps/nerdshell.svg'; do
  grep -Eq "^(\./|/)?${required_file}$" <<< "$CONTENTS" || {
    printf 'Missing packaged file: %s\n' "$required_file" >&2
    exit 1
  }
done

printf 'Verified %s\n' "$PACKAGE"
