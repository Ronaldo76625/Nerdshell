#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../scripts/common.sh
source "$ROOT/scripts/common.sh"

[[ "$(uname -s)" == "Darwin" ]] || fail "This installer is for macOS."

ensure_xcode_tools() {
  if ! xcode-select -p >/dev/null 2>&1; then
    warn "Command Line Tools are required. macOS will open the installer."
    xcode-select --install || true
    fail "Run Nerdshell again after Command Line Tools finish installing."
  fi
}

ensure_homebrew() {
  if command_exists brew; then
    log "Homebrew found"
    return
  fi

  warn "Homebrew is not installed. Installing Homebrew now."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_brew_packages() {
  log "Installing terminal and developer packages"
  brew update
  brew install \
    eza bat btop fastfetch lazygit fzf fd ripgrep git-delta zoxide thefuck \
    zsh-autosuggestions zsh-syntax-highlighting starship nvm node \
    yazi ffmpeg imagemagick poppler jq p7zip sevenzip fontconfig

  brew install --cask \
    ghostty \
    font-jetbrains-mono-nerd-font \
    font-symbols-only-nerd-font
}

ensure_nvm_dir() {
  mkdir -p "$HOME/.nvm"
}

ensure_sdkman() {
  if [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
    log "SDKMAN found"
    return
  fi

  warn "Installing SDKMAN for Java/Grails/Groovy management"
  curl -s "https://get.sdkman.io" | bash
}

configure_terminal_app() {
  if command_exists osascript; then
    log "Configuring Terminal.app font"
    osascript <<'OSA' || true
tell application "Terminal"
  set font of settings set "Basic" to "JetBrainsMono Nerd Font Mono"
  set font antialiasing of settings set "Basic" to true
end tell
OSA
  fi
}

link_ghostty_cli() {
  if [[ ! -e /opt/homebrew/bin/ghostty && -x /Applications/Ghostty.app/Contents/MacOS/ghostty ]]; then
    ln -s /Applications/Ghostty.app/Contents/MacOS/ghostty /opt/homebrew/bin/ghostty || true
  elif [[ ! -e /usr/local/bin/ghostty && -x /Applications/Ghostty.app/Contents/MacOS/ghostty ]]; then
    ln -s /Applications/Ghostty.app/Contents/MacOS/ghostty /usr/local/bin/ghostty || true
  fi
}

main() {
  log "Starting macOS setup"
  ensure_xcode_tools
  ensure_homebrew
  install_brew_packages
  ensure_nvm_dir
  ensure_sdkman

  local backup_root
  backup_root="$(make_backup_root)"
  install_configs "$ROOT" "$backup_root"
  configure_git_delta
  configure_terminal_app
  link_ghostty_cli

  log "Backup saved at $backup_root"
  log "Nerdshell is installed. Open Ghostty or a new terminal window."
}

main "$@"
