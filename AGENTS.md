# AGENTS.md - Dotfiles Repository Guide

## Repository Overview

This repository contains personal dotfiles managed by [chezmoi](https://www.chezmoi.io), a dotfile management tool that maintains system configurations across different machines.

**Repository Purpose**: Centralized version-controlled configuration files for development tools and shell environments.

**Git Remote**: `git@github.com:marinhero/dotfiles.git`

## Architecture

### Dual Directory System

This repository operates with a dual-directory structure managed by chezmoi:

1. **Source Directory** (Version Controlled)
   - Path: `/home/marin/.local/share/chezmoi/`
   - Git repository with remotes
   - Contains files with `dot_` prefix naming convention
   - This is where you edit files

2. **Working Directory** (Development Mirror)
   - Path: `/home/marin/Code/dotfiles/`
   - Local git repository pointing to source directory
   - Remote: `/home/marin/.local/share/chezmoi` (local)
   - Used for development and testing

3. **Target Directory** (Applied Configs)
   - Path: `~/` (home directory)
   - Actual dotfiles used by the system
   - Files without `dot_` prefix (e.g., `~/.gitconfig`, `~/.vimrc`)

### File Naming Convention

Chezmoi uses special prefixes:
- `dot_` → translates to `.` (hidden files)
  - Example: `dot_gitconfig` → `~/.gitconfig`
  - Example: `dot_config/` → `~/.config/`
- Files are stored in source directory with prefixes
- Applied to home directory without prefixes

## Current Configurations

### Shell & Terminal
- **oh-my-zsh** (`dot_oh-my-zsh/`) - Zsh framework and configuration
- **zellij** (`dot_config/zellij/config.kdl`) - Terminal multiplexer
  - Modal keybindings (Ctrl+p, Ctrl+t, Ctrl+n, etc.)
  - Multiple themes (Catppuccin Mocha, Dracula, Gruvbox, Nord, Tokyo Night)
  - macOS clipboard integration via `pbcopy`

### Editors
- **vim** (`dot_vimrc`) - Classic Vim configuration
- **neovim** (`dot_config/nvim/init.vim`) - Modern Neovim setup

### Git
- **gitconfig** (`dot_gitconfig`) - Git global configuration
- **gitignore_global** (`dot_gitignore_global`) - Global ignore patterns

## How to Work with This Repository

### For AI Agents (Claude Code, etc.)

When making changes to configurations:

#### Step 1: Edit in Working Directory
```bash
# You're likely already here
cd /home/marin/Code/dotfiles

# Edit files with dot_ prefix
vim dot_config/zellij/config.kdl
vim dot_gitconfig
```

#### Step 2: Sync to Chezmoi Source
```bash
# Copy changes to chezmoi source directory
cp -r dot_config/zellij /home/marin/.local/share/chezmoi/dot_config/
# or for individual files:
cp dot_gitconfig /home/marin/.local/share/chezmoi/
```

#### Step 3: Apply to System
```bash
# Apply specific config
chezmoi apply ~/.config/zellij

# Or apply specific file
chezmoi apply ~/.gitconfig

# Or apply everything
chezmoi apply
```

#### Step 4: Commit Changes (if requested)
```bash
# In the working directory
git add .
git commit -m "Description of changes"

# Or in the source directory
cd /home/marin/.local/share/chezmoi
git add .
git commit -m "Description of changes"
git push
```

### Quick Reference Commands

#### Check What Would Change
```bash
chezmoi diff
```

#### See Where Chezmoi Stores Files
```bash
chezmoi source-path
# Returns: /home/marin/.local/share/chezmoi
```

#### Verify Applied Config
```bash
# Check if file exists in home directory
ls -la ~/.config/zellij/config.kdl
ls -la ~/.gitconfig
```

#### Update from Repository
```bash
# Pull latest from git and apply
cd /home/marin/.local/share/chezmoi
git pull
chezmoi apply
```

## Best Practices for Agents

### DO:
1. **Always sync to chezmoi source** after editing in working directory
2. **Use `chezmoi apply`** to activate changes (don't manually copy to ~/)
3. **Test changes** by checking the applied files in home directory
4. **Respect existing structure** - maintain the `dot_` prefix convention
5. **Document changes** in commit messages
6. **Verify paths** before and after operations with `ls` or `chezmoi diff`

### DON'T:
1. **Don't edit files directly in home directory** (e.g., `~/.gitconfig`)
   - Changes will be overwritten by `chezmoi apply`
2. **Don't forget the sync step** - working dir changes aren't auto-synced
3. **Don't remove the `dot_` prefix** from files in source/working directories
4. **Don't assume changes are live** until after `chezmoi apply`

## Common Workflows

### Adding a New Configuration File

```bash
# 1. Create in working directory with dot_ prefix
echo "config content" > dot_config/newapp/config.conf

# 2. Sync to chezmoi source
cp -r dot_config/newapp /home/marin/.local/share/chezmoi/dot_config/

# 3. Apply to system
chezmoi apply ~/.config/newapp

# 4. Verify
ls -la ~/.config/newapp/config.conf
```

### Modifying Existing Configuration

```bash
# 1. Edit in working directory
vim dot_config/zellij/config.kdl

# 2. Sync to chezmoi
cp dot_config/zellij/config.kdl /home/marin/.local/share/chezmoi/dot_config/zellij/

# 3. Apply changes
chezmoi apply ~/.config/zellij

# 4. Verify changes took effect
cat ~/.config/zellij/config.kdl | grep "your_change"
```

### Reviewing Changes Before Applying

```bash
# See what would change
chezmoi diff

# See status of managed files
chezmoi status

# Dry-run apply
chezmoi apply --dry-run
```

## Platform-Specific Notes

### macOS
- Clipboard integration: `pbcopy` / `pbpaste`
- Zellij configured with `copy_command "pbcopy"`

### Linux
- Clipboard tools: `wl-copy` (Wayland) or `xclip` (X11)
- May need to adjust clipboard commands in configs

## Troubleshooting

### Changes Not Appearing
```bash
# Ensure you synced to chezmoi source
ls -la /home/marin/.local/share/chezmoi/dot_config/

# Then apply
chezmoi apply
```

### Conflicts Between Directories
```bash
# Chezmoi source is the source of truth
# To sync working dir from source:
cd /home/marin/Code/dotfiles
git pull  # Pulls from chezmoi source (local remote)
```

### Checking What Chezmoi Manages
```bash
chezmoi managed
```

## Additional Resources

- [Chezmoi Documentation](https://www.chezmoi.io/user-guide/command-overview/)
- [Zellij Documentation](https://zellij.dev/documentation/)
- Repository README: See `README.md` for high-level overview

## Summary for AI Agents

**TL;DR**: When modifying dotfiles:
1. Edit in `/home/marin/Code/dotfiles/` (files with `dot_` prefix)
2. Copy to `/home/marin/.local/share/chezmoi/` (same structure)
3. Run `chezmoi apply` to activate
4. Verify in home directory (`~/`)
5. Commit if requested

This workflow ensures changes are version-controlled, applied consistently, and reproducible across machines.
