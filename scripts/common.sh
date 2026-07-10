#!/usr/bin/env bash
set -euo pipefail

NERDSHELL_NAME="Nerdshell"

log() {
  printf '\033[1;36m[%s]\033[0m %s\n' "$NERDSHELL_NAME" "$*"
}

warn() {
  printf '\033[1;33m[%s]\033[0m %s\n' "$NERDSHELL_NAME" "$*"
}

fail() {
  printf '\033[1;31m[%s]\033[0m %s\n' "$NERDSHELL_NAME" "$*" >&2
  exit 1
}

detect_root() {
  local source_path="${BASH_SOURCE[0]}"
  local script_dir
  script_dir="$(cd "$(dirname "$source_path")" && pwd)"
  cd "$script_dir/.." && pwd
}

backup_item() {
  local source="$1"
  local backup_root="$2"

  if [[ -e "$source" || -L "$source" ]]; then
    local rel="${source#$HOME/}"
    mkdir -p "$backup_root/$(dirname "$rel")"
    cp -R "$source" "$backup_root/$rel"
  fi
}

install_file() {
  local source="$1"
  local target="$2"
  mkdir -p "$(dirname "$target")"
  cp "$source" "$target"
}

append_if_missing() {
  local needle="$1"
  local target="$2"
  touch "$target"
  grep -Fqs "$needle" "$target" || printf '%s\n' "$needle" >> "$target"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

make_backup_root() {
  local stamp
  stamp="$(date +%Y%m%d-%H%M%S)"
  local backup_root="$HOME/.config-backups/nerdshell-$stamp"
  mkdir -p "$backup_root"
  printf '%s\n' "$backup_root"
}

install_configs() {
  local root="$1"
  local backup_root="$2"

  log "Creating backups in $backup_root"
  backup_item "$HOME/.zshrc" "$backup_root"
  backup_item "$HOME/.zprofile" "$backup_root"
  backup_item "$HOME/.zshenv" "$backup_root"
  backup_item "$HOME/.config/starship.toml" "$backup_root"
  backup_item "$HOME/.config/eza/theme.yml" "$backup_root"
  backup_item "$HOME/.config/ghostty/config" "$backup_root"
  backup_item "$HOME/.config/ghostty/config.ghostty" "$backup_root"
  backup_item "$HOME/.config/lsd" "$backup_root"
  backup_item "$HOME/.gitconfig" "$backup_root"

  log "Installing Zsh, Starship, eza and Ghostty configs"
  install_file "$root/configs/zsh/zshrc" "$HOME/.zshrc"
  install_file "$root/configs/zsh/zprofile" "$HOME/.zprofile"
  install_file "$root/configs/zsh/zshenv" "$HOME/.zshenv"
  install_file "$root/configs/starship/starship.toml" "$HOME/.config/starship.toml"
  install_file "$root/configs/eza/theme.yml" "$HOME/.config/eza/theme.yml"
  install_file "$root/configs/ghostty/config" "$HOME/.config/ghostty/config"

  if [[ -d "$HOME/.config/lsd" ]]; then
    mv "$HOME/.config/lsd" "$backup_root/lsd.removed"
  fi
}

configure_git_delta() {
  if command_exists git; then
    log "Configuring Git delta"
    git config --global core.pager "delta"
    git config --global interactive.diffFilter "delta --color-only"
    git config --global delta.navigate true
    git config --global delta.side-by-side true
    git config --global delta.line-numbers true
    git config --global merge.conflictstyle zdiff3
    git config --global diff.colorMoved default
  fi
}
