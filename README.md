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

**Shell & terminal:** zsh, oh-my-zsh, zellij, fzf
**Editors:** neovim (LazyVim), vim (vim-plug)
**Dev tools (via asdf):** neovim, fzf, chezmoi, jq, zellij, golang, python, nodejs
**Other:** git, btop, Claude Code, OpenCode, bibletui, Iosevka Nerd Font

## Setup

```bash
# macOS (run as normal user)
./setup.sh

# Linux (run with sudo)
sudo ./setup.sh
```

The script is idempotent — rerun it safely to pick up changes. It will prompt interactively for hostname if not provided as an argument.

## How it works

Chezmoi templates (`.tmpl` files) use hostname detection to apply machine-specific config. See `.chezmoi.toml.tmpl` for the mapping and `AGENTS.md` for the full architecture guide.
