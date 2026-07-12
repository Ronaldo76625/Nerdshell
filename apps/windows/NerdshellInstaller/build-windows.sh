#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
VERSION="${1:-0.1.0}"
APP_ROOT="$ROOT/apps/windows/NerdshellInstaller"
OUTPUT_DIR="$ROOT/dist/windows"
export GOCACHE="$ROOT/dist/.go-cache"
export GOMODCACHE="$ROOT/dist/.go-mod-cache"

case "$VERSION" in
  *[!0-9A-Za-z.+-]*|'')
    printf 'Invalid version: %s\n' "$VERSION" >&2
    exit 1
    ;;
esac

command -v go >/dev/null 2>&1 || {
  printf 'Go is required to cross-compile the Windows installer.\n' >&2
  exit 1
}

mkdir -p "$OUTPUT_DIR" "$GOCACHE" "$GOMODCACHE"

build_architecture() {
  local go_arch="$1"
  local label="$2"
  local output="$OUTPUT_DIR/Nerdshell-${VERSION}-Windows-${label}-Setup.exe"

  printf 'Building Windows %s installer...\n' "$label"
  (
    cd "$APP_ROOT"
    CGO_ENABLED=0 GOOS=windows GOARCH="$go_arch" \
      go build -trimpath -ldflags "-H=windowsgui -s -w -X main.version=$VERSION" \
      -o "$output" .
  )
  file "$output" | grep -q 'PE32'
  printf 'Built %s\n' "$output"
}

build_architecture amd64 x64
build_architecture arm64 ARM64

"$APP_ROOT/verify-windows.sh" "$VERSION"
shasum -a 256 \
  "$OUTPUT_DIR/Nerdshell-${VERSION}-Windows-x64-Setup.exe" \
  "$OUTPUT_DIR/Nerdshell-${VERSION}-Windows-ARM64-Setup.exe"
