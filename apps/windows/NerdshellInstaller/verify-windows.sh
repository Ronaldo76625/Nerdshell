#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
VERSION="${1:-0.1.0}"
X64="$ROOT/dist/windows/Nerdshell-${VERSION}-Windows-x64-Setup.exe"
ARM64="$ROOT/dist/windows/Nerdshell-${VERSION}-Windows-ARM64-Setup.exe"

for executable in "$X64" "$ARM64"; do
  [[ -f "$executable" ]] || {
    printf 'Missing Windows installer: %s\n' "$executable" >&2
    exit 1
  }
  file "$executable" | grep -q 'PE32+ executable (GUI)'
  go version -m "$executable" | grep -q 'GOOS=windows'

  embedded="$(strings "$executable")"
  for marker in \
    'resources/install.ps1' \
    'Microsoft.WindowsTerminal' \
    'Microsoft.PowerShell' \
    'Starship.Starship' \
    'JetBrainsMonoNerdFontMono' \
    'Nerdshell Terminal'; do
    grep -Fq "$marker" <<< "$embedded" || {
      printf 'Missing embedded resource marker %s in %s\n' "$marker" "$executable" >&2
      exit 1
    }
  done
done

file "$X64" | grep -q 'x86-64'
file "$ARM64" | grep -q 'Aarch64'
printf 'Verified Windows x64 and ARM64 installers.\n'
