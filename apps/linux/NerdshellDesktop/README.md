# Nerdshell Desktop for Linux

Native GTK/VTE terminal for Debian, Ubuntu, Kubuntu and derivatives. It uses an
isolated Nerdshell Zsh profile and does not replace the user's global dotfiles.

## Build locally

```bash
sudo apt install build-essential pkg-config libgtk-3-dev libvte-2.91-dev
make
./build/nerdshell
```

## Build Debian packages

From the repository root, with Docker running:

```bash
./apps/linux/NerdshellDesktop/packaging/build-deb.sh 0.1.0 amd64
./apps/linux/NerdshellDesktop/packaging/build-deb.sh 0.1.0 arm64
```
