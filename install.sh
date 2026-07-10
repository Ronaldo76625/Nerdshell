#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

case "$(uname -s)" in
  Darwin)
    exec "$ROOT/macos/install.sh"
    ;;
  Linux)
    exec "$ROOT/linux/install.sh"
    ;;
  *)
    printf 'Nerdshell only supports macOS and Linux right now.\n' >&2
    exit 1
    ;;
esac
