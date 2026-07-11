# Nerdshell Desktop for macOS

Native macOS terminal application under active development. This directory is
isolated from Nerdshell's existing installers and configuration packages.

## Requirements

- macOS 14 or later
- Xcode command-line tools with Swift 6

## Build

```bash
swift build
./script/test.sh
```

## Run as a macOS application

```bash
./script/build_and_run.sh
```

## Package a local DMG

```bash
./script/package_dmg.sh 0.1.0
```

Without a Developer ID identity, the script applies an ad-hoc Hardened Runtime
signature suitable for local testing. Public distribution requires Developer ID
signing and Apple notarization.

The terminal area is backed by SwiftTerm and launches the user's shell through a
real PTY with an isolated Nerdshell profile. Existing repository installers and
global shell configuration remain separate from this application.
