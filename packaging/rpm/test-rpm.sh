#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PACKAGE="${1:-$ROOT/dist/nerdshell-0.1.0-1.noarch.rpm}"
CURRENT_CONTAINER=""

cleanup_container() {
  if [[ -n "$CURRENT_CONTAINER" ]]; then
    docker rm -f "$CURRENT_CONTAINER" >/dev/null 2>&1 || true
  fi
}
trap cleanup_container EXIT

[[ -f "$PACKAGE" ]] || {
  printf 'RPM package not found: %s\n' "$PACKAGE" >&2
  exit 1
}

test_image() {
  local image="$1"
  local label="$2"
  local container="nerdshell-rpm-test-${label}-$$"
  CURRENT_CONTAINER="$container"

  docker create --name "$container" "$image" bash -lc '
    set -e
    rpm -i --nodeps /tmp/nerdshell.rpm
    rpm -q nerdshell
    test -x /usr/bin/nerdshell-installer
    test -x /usr/lib/nerdshell/linux/install.sh
    test -f /usr/share/applications/nerdshell.desktop
    rpm -e nerdshell
    test ! -e /usr/bin/nerdshell-installer
    printf "RPM_PACKAGE_TEST_OK\n"
  ' >/dev/null

  docker cp "$PACKAGE" "$container:/tmp/nerdshell.rpm"
  docker start -a "$container"
  docker rm "$container" >/dev/null
  CURRENT_CONTAINER=""
}

test_image fedora:44 fedora
test_image rockylinux:9 rocky9
test_image quay.io/centos/centos:stream10 centos10

trap - EXIT
