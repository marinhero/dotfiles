# Dotfiles

Personal dotfiles managed by [chezmoi](https://www.chezmoi.io) for macOS and openSUSE Linux.

## Machines

| Hostname | Type | OS |
|----------|------|----|
| `GJHLXK2QHD` | Work | macOS |
| `nostromo` | Desktop | openSUSE |
| `march` | Personal laptop | openSUSE |
| `discovery` | Personal laptop | openSUSE |

## What's included

### Desktop environment (Linux)
- **bspwm** — tiling window manager
- **sxhkd** — hotkey daemon (vim-style + macOS-inspired keybinds)
- **polybar** — status bar
- **rofi** — app launcher, window switcher, clipboard picker, web search
- **picom** — compositor
- **i3lock** — lock screen with blurred screenshot
- **feh** — wallpaper manager with random rotation

### Shell & terminal
- **st** (suckless terminal) — with black+Nord color theme via escape sequences
- **zsh + oh-my-zsh** — shell with vi mode
- **zellij** — terminal multiplexer (Nord theme, modal keybinds)
- **fzf** — fuzzy finder (Ctrl-R history, Ctrl-T files, Alt-C cd)

### Editors
- **Neovim** — LazyVim distribution
- **Vim** — vim-plug config (legacy)

### Dev tools (via asdf)
neovim, fzf, chezmoi, jq, zellij, golang, python, nodejs, deno

### Custom scripts (`~/.local/bin/`)
| Script | Description |
|--------|-------------|
| `st-wrapper` | Launches st with Iosevka Nerd Font |
| `web-search` | Rofi → DuckDuckGo search |
| `lock-screen` | Screenshot → blur → i3lock |
| `random-wallpaper` | Random wallpaper from collection |
| `wallpaper-exclude` | Exclude current wallpaper from rotation |
| `wallpaper-favorite` | Favorite current wallpaper |
| `sxhkd-help` | Keybinding cheatsheet via rofi |
| `zellij-copy` | Clipboard helper for zellij |

### Theme
Black background with [Nord](https://www.nordtheme.com/) accent colors across st, rofi, polybar, bspwm borders, zellij, and i3lock.

## Key bindings (super = Mod4)

| Binding | Action |
|---------|--------|
| `super + space` | App launcher |
| `super + Return` | Terminal |
| `super + s` | Web search |
| `super + v` | Clipboard history |
| `super + Tab` | Window switcher |
| `super + h/j/k/l` | Focus window |
| `super + shift + h/j/k/l` | Swap window |
| `super + 1-9` | Switch desktop |
| `super + w` | Close window |
| `super + f` | Fullscreen |
| `super + m` | Monocle layout |
| `super + =` | Toggle gaps + polybar |
| `super + x` | Lock screen |
| `super + b` | Random wallpaper |
| `super + /` | Keybinding cheatsheet |

## Setup

```bash
# Full system setup (Linux, run with sudo)
sudo ./setup.sh

# bspwm desktop environment only
sudo ./bspwm-setup.sh
```

Both scripts are idempotent.

## How it works

Chezmoi templates (`.tmpl` files) use hostname detection to apply machine-specific config. See `.chezmoi.toml.tmpl` for the mapping and `AGENTS.md` for the full architecture guide.
