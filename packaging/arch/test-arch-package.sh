#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PACKAGE="${1:-$ROOT/dist/nerdshell-0.1.0-1-any.pkg.tar.zst}"
CONTAINER="nerdshell-arch-test-$$"

[[ -f "$PACKAGE" ]] || {
  printf 'Arch package not found: %s\n' "$PACKAGE" >&2
  exit 1
}

cleanup_container() {
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
}
trap cleanup_container EXIT

docker create --name "$CONTAINER" --platform linux/amd64 \
  archlinux:base \
  bash -lc '
    set -e
    pacman --disable-sandbox -Sy --noconfirm >/dev/null
    for package in \
      bash zsh git curl unzip zip fontconfig eza bat btop fastfetch lazygit \
      fzf fd ripgrep git-delta zoxide zsh-autosuggestions \
      zsh-syntax-highlighting starship jq ttf-jetbrains-mono-nerd \
      ttf-nerd-fonts-symbols-mono; do
      pacman -Si "$package" >/dev/null
    done
    pacman --disable-sandbox -U --noconfirm -dd /tmp/nerdshell.pkg.tar.zst >/dev/null
    pacman -Q nerdshell
    test -x /usr/bin/nerdshell-installer
    test -x /usr/lib/nerdshell/linux/install.sh
    test -f /usr/lib/nerdshell/.skip-system-packages
    test -f /usr/share/applications/nerdshell.desktop
    pacman -R --noconfirm nerdshell >/dev/null
    test ! -e /usr/bin/nerdshell-installer
    printf "ARCH_PACKAGE_TEST_OK\n"
  ' >/dev/null

docker cp "$PACKAGE" "$CONTAINER:/tmp/nerdshell.pkg.tar.zst"
docker start -a "$CONTAINER"

trap - EXIT
cleanup_container
