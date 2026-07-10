#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../scripts/common.sh
source "$ROOT/scripts/common.sh"

[[ "$(uname -s)" == "Linux" ]] || fail "This installer is for Linux."

INSTALL_SYSTEM_PACKAGES=1
for argument in "$@"; do
  case "$argument" in
    --skip-packages)
      INSTALL_SYSTEM_PACKAGES=0
      ;;
    *)
      fail "Unknown installer option: $argument"
      ;;
  esac
done

SUDO=""
if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  command_exists sudo || fail "sudo is required to install Linux packages."
  SUDO="sudo"
fi

install_linux_packages() {
  log "Installing packages for your Linux distribution"

  if command_exists apt-get; then
    $SUDO apt-get update
    install_apt_packages
  elif command_exists dnf; then
    $SUDO dnf install -y \
      zsh git curl unzip fontconfig eza bat btop fastfetch lazygit fzf fd-find \
      ripgrep git-delta zoxide zsh-autosuggestions zsh-syntax-highlighting \
      starship jq p7zip p7zip-plugins
  elif command_exists pacman; then
    $SUDO pacman -Syu --needed --noconfirm \
      zsh git curl unzip fontconfig eza bat btop fastfetch lazygit fzf fd \
      ripgrep git-delta zoxide zsh-autosuggestions zsh-syntax-highlighting \
      starship jq p7zip
  elif command_exists zypper; then
    $SUDO zypper install -y \
      zsh git curl unzip fontconfig eza bat btop fastfetch lazygit fzf fd \
      ripgrep git-delta zoxide zsh-autosuggestions zsh-syntax-highlighting \
      starship jq p7zip
  else
    fail "Unsupported Linux package manager. Install packages manually, then rerun Nerdshell."
  fi
}

apt_package_exists() {
  apt-cache show "$1" >/dev/null 2>&1
}

install_apt_packages() {
  local required=(zsh git curl ca-certificates unzip xz-utils fontconfig)
  local optional=(
    eza bat btop fastfetch lazygit fzf fd-find ripgrep git-delta zoxide
    zsh-autosuggestions zsh-syntax-highlighting starship jq p7zip-full
  )
  local available=()
  local missing=()
  local package

  $SUDO apt-get install -y "${required[@]}"

  for package in "${optional[@]}"; do
    if apt_package_exists "$package"; then
      available+=("$package")
    else
      missing+=("$package")
    fi
  done

  if ((${#available[@]})); then
    $SUDO apt-get install -y "${available[@]}"
  fi

  if ((${#missing[@]})); then
    warn "Not available in this distribution's repositories: ${missing[*]}"
    warn "Nerdshell will continue; unavailable optional features will stay disabled."
  fi
}

install_nerd_fonts() {
  local font_dir="$HOME/.local/share/fonts/NerdFonts"
  mkdir -p "$font_dir"

  if fc-match "JetBrainsMono Nerd Font Mono" | grep -qi "JetBrains"; then
    log "JetBrainsMono Nerd Font already available"
    return
  fi

  warn "Installing Nerd Fonts from GitHub releases"
  local tmp_dir
  tmp_dir="$(mktemp -d)"

  curl -fL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz" -o "$tmp_dir/JetBrainsMono.tar.xz"
  curl -fL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.tar.xz" -o "$tmp_dir/NerdFontsSymbolsOnly.tar.xz" || true

  tar -xf "$tmp_dir/JetBrainsMono.tar.xz" -C "$font_dir"
  if [[ -s "$tmp_dir/NerdFontsSymbolsOnly.tar.xz" ]]; then
    tar -xf "$tmp_dir/NerdFontsSymbolsOnly.tar.xz" -C "$font_dir"
  fi

  fc-cache -f "$font_dir"
}

ensure_nvm() {
  if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    log "NVM found"
    return
  fi

  warn "Installing NVM"
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
}

ensure_sdkman() {
  if [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
    log "SDKMAN found"
    return
  fi

  warn "Installing SDKMAN"
  curl -s "https://get.sdkman.io" | bash
}

set_default_shell() {
  if [[ "${SHELL:-}" != *"/zsh" ]] && command_exists chsh; then
    warn "Changing default shell to zsh may require your password."
    chsh -s "$(command -v zsh)" || warn "Could not change the default shell automatically."
  fi
}

main() {
  log "Starting Linux setup"
  if [[ "$INSTALL_SYSTEM_PACKAGES" -eq 1 ]]; then
    install_linux_packages
  else
    log "System packages are managed by the installed distribution package"
  fi
  install_nerd_fonts
  ensure_nvm
  ensure_sdkman

  local backup_root
  backup_root="$(make_backup_root)"
  install_configs "$ROOT" "$backup_root"
  configure_git_delta
  set_default_shell

  log "Backup saved at $backup_root"
  log "Nerdshell is installed. Open a new terminal window."
}

main "$@"
