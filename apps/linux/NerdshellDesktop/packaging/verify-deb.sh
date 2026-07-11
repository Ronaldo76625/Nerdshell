#!/usr/bin/env bash
set -euo pipefail

PACKAGE="$1"
EXPECTED_ARCH="${2:-}"
test -s "$PACKAGE"
ARCH="$(dpkg-deb -f "$PACKAGE" Architecture)"
test -z "$EXPECTED_ARCH" || test "$ARCH" = "$EXPECTED_ARCH"
test "$(dpkg-deb -f "$PACKAGE" Package)" = "nerdshell-desktop"
dpkg-deb --contents "$PACKAGE" | grep -q './usr/bin/nerdshell$'
dpkg-deb --contents "$PACKAGE" | grep -q './usr/share/applications/io.github.nerdshell.desktop$'
echo "Verified $PACKAGE ($ARCH)"
