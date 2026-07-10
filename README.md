# Nerdshell

Nerdshell is a premium terminal environment for macOS and Linux: Zsh, Starship, eza icons, Ghostty, Git delta, fast search, better navigation, Java/Grails and Node/Angular-friendly defaults.

It is designed for people who want a beautiful, visual, useful terminal without manually wiring every tool.

## Preview

### Project listing

![Nerdshell project listing](assets/screenshots/listing-project.png)

### Tree view

![Nerdshell tree view](assets/screenshots/tree-view.png)

### Autosuggestions and Git branch

![Nerdshell autosuggestions and Git branch](assets/screenshots/autosuggestions-git.png)

### Root directory listing

![Nerdshell root listing](assets/screenshots/listing-root.png)

## macOS: double click install

1. Download or clone this repository.
2. Open the `macos` folder.
3. Double click `install.command`.
4. Follow the prompts.
5. Open Ghostty or a new terminal window.

The installer creates backups before replacing any shell or terminal config.

## Debian, Ubuntu and derivatives (.deb)

Build the package on macOS or Linux:

```bash
./packaging/build-deb.sh 0.1.0
```

The package is created at `dist/nerdshell_0.1.0_all.deb`. Install it with your
graphical package manager (Discover, App Center, Software) or with:

```bash
sudo apt install ./dist/nerdshell_0.1.0_all.deb
```

After installing the package, open **Nerdshell Installer** from the application
menu. It runs as your normal user, creates backups, installs available tools and
applies the terminal configuration.

Official targets are Debian, Ubuntu and Kubuntu. Linux Mint, KDE Neon, Pop!_OS,
Zorin OS and other compatible derivatives are expected to work as well.

## Other Linux distributions

From the project folder:

```bash
./linux/install.sh
```

Some Linux file managers allow double click execution through `linux/Nerdshell.desktop`, but behavior varies by desktop environment. The terminal command above is the reliable path.

## What Nerdshell installs/configures

- Zsh with fast startup, history, completion, autosuggestions and syntax highlighting.
- Starship prompt with visual Java, Node, Git, Gradle and Docker context.
- eza with Nerd Font icons and a rich file theme.
- Bat, ripgrep, fd, fzf, zoxide, btop, fastfetch and lazygit.
- Git delta for side-by-side diffs and line numbers.
- Ghostty config with JetBrainsMono Nerd Font and Symbols Nerd Font.
- SDKMAN and NVM bootstrap for Java/Grails/Groovy and Node workflows.

## Safety

Nerdshell does not delete your existing config. It backs up these files first:

- `~/.zshrc`
- `~/.zprofile`
- `~/.zshenv`
- `~/.config/starship.toml`
- `~/.config/eza/theme.yml`
- `~/.config/ghostty/config`
- `~/.gitconfig`
- `~/.config/lsd`

Backups are saved under:

```text
~/.config-backups/nerdshell-YYYYMMDD-HHMMSS
```

## Notes

- macOS is the most complete install path.
- Linux support covers common package managers: `apt`, `dnf`, `pacman`, and `zypper`.
- Terminal icon rendering depends on the terminal app using a Nerd Font. Ghostty is recommended.
