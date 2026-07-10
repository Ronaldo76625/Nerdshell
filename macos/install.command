#!/usr/bin/env bash
cd "$(dirname "$0")/.."
clear
printf 'Nerdshell macOS installer\n'
printf '=========================\n\n'
"./macos/install.sh"
status=$?
printf '\n'
if [[ $status -eq 0 ]]; then
  printf 'Done. Open a new terminal window to use Nerdshell.\n'
else
  printf 'Installer failed with exit code %s.\n' "$status"
fi
printf 'Press Enter to close this window...'
read -r _
exit "$status"
