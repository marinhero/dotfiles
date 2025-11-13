# Scripts

Utility scripts for dotfiles management and configuration.

## fix-lazyvim.sh

Automated fixer for LazyVim health check issues on macOS.

### Purpose

This script resolves common warnings and errors found when running `:checkhealth` in Neovim with LazyVim. It automatically installs missing dependencies and configures providers.

### What It Fixes

#### Critical Issues (Auto-fixed)
- ✅ **fd/fdfind** - Fast file finder required by LazyVim and Snacks
- ✅ **lazygit** - Git TUI integration for LazyVim
- ✅ **ast-grep** - Advanced code search for grug-far plugin
- ✅ **Python neovim module** - Required for Python provider
- ✅ **Node.js neovim package** - Required for Node.js provider
- ✅ **Ruby neovim gem** - Required for Ruby provider

#### Python/asdf Issues
- Configures Python 3.12.0 via asdf (if asdf is installed)
- Sets global Python version
- Installs `pynvim` package

#### Optional Items (Interactive)
- ImageMagick - For image rendering in snacks.nvim
- Perl provider - Can be disabled (rarely needed)

### Usage

```bash
# Run the script
./scripts/fix-lazyvim.sh

# Or from anywhere in your dotfiles
bash scripts/fix-lazyvim.sh
```

### Prerequisites

- macOS (Darwin-based system)
- Homebrew installed
- Neovim with LazyVim configuration

### What It Doesn't Fix

These are optional and should only be installed if you need them:

- **Language-specific tools** (cargo, java, php, julia, composer)
  - Only install if you're developing in those languages
- **Terminal graphics protocol**
  - iTerm doesn't support kitty graphics (this is normal)
- **Luarocks**
  - Can be safely disabled in lazy.nvim config if not needed

### After Running

1. Restart your terminal or source your shell config:
   ```bash
   source ~/.zshrc  # or ~/.bashrc
   ```

2. Open Neovim and verify fixes:
   ```vim
   :checkhealth
   ```

3. Most warnings should be resolved. Any remaining warnings are typically optional.

### Disabling Luarocks Warnings

If you don't need luarocks (most users don't), add this to your LazyVim config:

```lua
-- In ~/.config/nvim/lua/config/lazy.lua or init.lua
require("lazy").setup({
  rocks = {
    enabled = false,  -- Disable luarocks if not needed
  },
  -- ... rest of your plugins
})
```

### Health Check Issues Reference

From your original `:checkhealth` output:

| Component | Issue | Status | Fix |
|-----------|-------|--------|-----|
| conform | fish_indent missing | Optional | Install fish shell if needed |
| grug-far | ast-grep missing | Fixed | Script installs via brew |
| lazy | luarocks errors | Optional | Can disable in config |
| lazyvim | fd missing | Fixed | Script installs via brew |
| lazyvim | lazygit missing | Fixed | Script installs via brew |
| mason | Python unavailable | Fixed | Script configures asdf + pynvim |
| mason | cargo/rust missing | Optional | Install if doing Rust dev |
| mason | java missing | Optional | Install if doing Java dev |
| snacks | lazygit missing | Fixed | Script installs via brew |
| snacks | fd missing | Fixed | Script installs via brew |
| snacks | ImageMagick missing | Optional | Script offers to install |
| vim.provider | Node neovim missing | Fixed | Script installs globally |
| vim.provider | Python neovim missing | Fixed | Script installs pynvim |
| vim.provider | Ruby neovim missing | Fixed | Script installs gem |
| vim.provider | Perl provider warning | Fixed | Script offers to disable |

### Troubleshooting

#### asdf Python Issues
If Python still shows errors after running the script:

```bash
# Verify Python is installed
asdf list python

# Set global version
asdf global python 3.12.0

# Reshim
asdf reshim python

# Verify it works
python3 --version

# Reinstall pynvim
pip3 install --upgrade pynvim
```

#### Node.js neovim Package Issues
```bash
# Verify installation
npm list -g neovim

# Reinstall if needed
npm install -g neovim

# Check npm prefix
npm config get prefix
```

#### Ruby neovim Gem Issues
```bash
# If using rbenv/rvm, install in user space
gem install neovim --user-install

# Or with sudo (system Ruby)
sudo gem install neovim

# Verify
gem list neovim
```

### Related Files

- `~/.config/nvim/init.lua` - Main Neovim config
- `~/.config/nvim/lua/config/lazy.lua` - Lazy.nvim setup
- `~/.config/nvim/lua/config/providers.lua` - Provider config (created by script)
- `~/.tool-versions` - asdf version file

### Further Reading

- [LazyVim Documentation](https://lazyvim.org)
- [Neovim Health Check](https://neovim.io/doc/user/health.html)
- [asdf Version Manager](https://asdf-vm.com)
