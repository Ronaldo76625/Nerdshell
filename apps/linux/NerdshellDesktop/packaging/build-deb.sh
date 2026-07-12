#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-0.1.0}"
ARCH="${2:-amd64}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
export DOCKER_CONFIG="$ROOT/apps/linux/NerdshellDesktop/.docker"
if [[ -S "$HOME/.colima/default/docker.sock" ]]; then
  export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"
fi

case "$VERSION" in *[!0-9A-Za-z.+:~-]*|'') echo "Invalid version: $VERSION" >&2; exit 2;; esac
case "$ARCH" in amd64) PLATFORM="linux/amd64";; arm64) PLATFORM="linux/arm64";; *) echo "Architecture must be amd64 or arm64" >&2; exit 2;; esac

BASE_IMAGE="nerdshell-ubuntu:22.04-${ARCH}"
MANIFEST_ARCH="$ARCH"
DIGEST="$(docker manifest inspect ubuntu:22.04 | jq -r ".manifests[] | select(.platform.os == \"linux\" and .platform.architecture == \"$MANIFEST_ARCH\") | .digest" | head -n1)"
test -n "$DIGEST" && test "$DIGEST" != "null"
docker pull "ubuntu@$DIGEST"
docker tag "ubuntu@$DIGEST" "$BASE_IMAGE"

IMAGE="nerdshell-desktop-build:${VERSION}-${ARCH}"
CONTAINER="nerdshell-desktop-export-${ARCH}"
OUTPUT="$ROOT/dist/nerdshell-desktop_${VERSION}_${ARCH}.deb"
CONTEXT="$ROOT/dist/linux-desktop/docker-context-$ARCH"

rm -rf "$CONTEXT"
mkdir -p "$CONTEXT/apps/linux" "$CONTEXT/assets"
cp -R "$ROOT/apps/linux/NerdshellDesktop" "$CONTEXT/apps/linux/NerdshellDesktop"
cp -R "$ROOT/configs" "$CONTEXT/configs"
cp "$ROOT/assets/nerdshell.svg" "$CONTEXT/assets/nerdshell.svg"
cp "$ROOT/LICENSE" "$CONTEXT/LICENSE"

docker build --platform "$PLATFORM" \
  --build-arg "BASE_IMAGE=$BASE_IMAGE" \
  --build-arg "VERSION=$VERSION" \
  --build-arg "DEB_ARCH=$ARCH" \
  -f "$ROOT/apps/linux/NerdshellDesktop/packaging/Dockerfile" \
  -t "$IMAGE" \
  "$CONTEXT"

docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
docker create --name "$CONTAINER" "$IMAGE" >/dev/null
mkdir -p "$ROOT/dist"
docker cp "$CONTAINER:/workspace/dist/nerdshell-desktop_${VERSION}_${ARCH}.deb" "$OUTPUT"
docker rm "$CONTAINER" >/dev/null

echo "Built $OUTPUT"
