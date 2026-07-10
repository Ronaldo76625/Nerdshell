# Nerdshell

Nerdshell is a premium terminal environment for macOS and Linux: Zsh, Starship, eza icons, Ghostty, Git delta, fast search, better navigation, Java/Grails and Node/Angular-friendly defaults.

It is designed for people who want a beautiful, visual, useful terminal without manually wiring every tool.

## macOS: double click install

1. Download or clone this repository.
2. Open the `macos` folder.
3. Double click `install.command`.
4. Follow the prompts.
5. Open Ghostty or a new terminal window.

The installer creates backups before replacing any shell or terminal config.

## Linux install

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
