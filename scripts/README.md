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
- ✅ **ImageMagick** - Image rendering support for snacks.nvim
- ✅ **Python neovim module** - Required for Python provider
- ✅ **Node.js neovim package** - Required for Node.js provider
- ✅ **Ruby neovim gem** - Required for Ruby provider

#### Python/asdf Issues
- Configures Python 3.12.0 via asdf (if asdf is installed)
- Sets global Python version
- Installs `pynvim` package

#### Optional Items (Interactive)
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
| snacks | ImageMagick missing | Fixed | Script installs via brew |
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

### Migrating from on_attach to snacks.lsp

#### Deprecation Notice

The traditional LSP `on_attach` callback pattern is deprecated in newer versions of LazyVim. The modern approach uses `snacks.lsp` for LSP keymaps and functionality.

#### Why the Change?

- **Better integration**: `snacks.lsp` is part of the Snacks plugin ecosystem and provides better defaults
- **Cleaner config**: Less boilerplate code in your LSP configuration
- **More features**: Built-in enhancements like better hover, signature help, and references
- **Maintained**: Active development and improvements from the LazyVim team

#### Migration Steps

**1. Remove old on_attach callbacks**

If you have custom LSP configurations in `~/.config/nvim/lua/plugins/lsp.lua` or similar, look for patterns like:

```lua
-- ❌ OLD WAY (Deprecated)
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      eslint = {
        on_attach = function(client, bufnr)
          -- Custom keymaps and settings
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = bufnr })
          vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr })
        end,
      },
    },
  },
}
```

**2. Use snacks.lsp instead**

LazyVim now handles LSP keymaps automatically through `snacks.lsp`. For most users, you can simply remove the `on_attach` callback:

```lua
-- ✅ NEW WAY (Recommended)
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      eslint = {
        -- No on_attach needed! Keymaps are handled by snacks.lsp
        settings = {
          -- Your LSP-specific settings here
        },
      },
    },
  },
}
```

**3. Custom keymaps (if needed)**

If you need custom LSP keymaps, add them to your LazyVim keys configuration:

```lua
-- ~/.config/nvim/lua/config/keymaps.lua or in your plugin spec
return {
  "neovim/nvim-lspconfig",
  keys = {
    { "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", desc = "Go to Definition" },
    { "K", "<cmd>lua vim.lsp.buf.hover()<cr>", desc = "Hover Documentation" },
    -- Add your custom LSP keymaps here
  },
}
```

**4. Verify snacks.lsp is enabled**

Check that `snacks.nvim` is properly configured in your LazyVim setup:

```lua
-- This should be in your LazyVim config (usually automatic)
{
  "folke/snacks.nvim",
  opts = {
    lsp = {
      enabled = true, -- Ensure LSP integration is enabled
    },
  },
}
```

#### Default Keymaps Provided by snacks.lsp

When using `snacks.lsp`, you automatically get these keymaps:

| Keymap | Action | Description |
|--------|--------|-------------|
| `gd` | Definition | Go to definition |
| `gr` | References | Show references |
| `gD` | Declaration | Go to declaration |
| `gI` | Implementation | Go to implementation |
| `gy` | Type Definition | Go to type definition |
| `K` | Hover | Show hover documentation |
| `gK` | Signature Help | Show signature help |
| `<leader>ca` | Code Action | Show code actions |
| `<leader>cr` | Rename | Rename symbol |
| `<leader>cl` | LSP Info | Show LSP info |

#### Example: Full Migration

**Before (deprecated):**

```lua
-- ~/.config/nvim/lua/plugins/lsp.lua
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      tsserver = {
        on_attach = function(client, bufnr)
          local opts = { buffer = bufnr }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

          -- Disable formatting (use prettier instead)
          client.server_capabilities.documentFormattingProvider = false
        end,
      },
      eslint = {
        on_attach = function(client, bufnr)
          vim.keymap.set("n", "<leader>cf", "<cmd>EslintFixAll<cr>", { buffer = bufnr })
        end,
      },
    },
  },
}
```

**After (modern):**

```lua
-- ~/.config/nvim/lua/plugins/lsp.lua
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      tsserver = {
        -- Keymaps are automatic via snacks.lsp
        -- Just configure server-specific settings
        on_init = function(client)
          -- Disable formatting (use prettier instead)
          client.server_capabilities.documentFormattingProvider = false
        end,
      },
      eslint = {
        -- Custom keymap for ESLint fix all
        keys = {
          { "<leader>cf", "<cmd>EslintFixAll<cr>", desc = "ESLint Fix All" },
        },
      },
    },
  },
}
```

#### Common Patterns

**Pattern 1: Disable formatting for specific LSPs**

```lua
-- Use on_init instead of on_attach
{
  tsserver = {
    on_init = function(client)
      client.server_capabilities.documentFormattingProvider = false
    end,
  },
}
```

**Pattern 2: Server-specific keymaps**

```lua
{
  gopls = {
    keys = {
      { "<leader>td", "<cmd>GoTestFunc<cr>", desc = "Test Function" },
      { "<leader>tf", "<cmd>GoTestFile<cr>", desc = "Test File" },
    },
  },
}
```

**Pattern 3: Custom capabilities**

```lua
{
  lua_ls = {
    -- Capabilities are handled automatically
    settings = {
      Lua = {
        workspace = { checkThirdParty = false },
        telemetry = { enable = false },
      },
    },
  },
}
```

#### Troubleshooting

**Q: My custom keymaps aren't working**

A: Make sure you're using the `keys` table in your server config, not `on_attach`.

**Q: I need access to the client or buffer in my setup**

A: Use `on_init` for client setup. For buffer-specific actions, use autocommands with `LspAttach` event:

```lua
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local bufnr = args.buf
    -- Your custom logic here
  end,
})
```

**Q: How do I know if I'm using the old pattern?**

A: Search your config for `on_attach` in LSP files:

```bash
cd ~/.config/nvim
grep -r "on_attach" lua/plugins/
```

**Q: Will my config break if I don't migrate?**

A: Not immediately, but `on_attach` is deprecated and may be removed in future versions. Migrating ensures compatibility and access to new features.

#### Verification

After migration, verify everything works:

1. Open Neovim and run `:checkhealth lazy`
2. Open a code file and test LSP keymaps:
   - `gd` for definition
   - `K` for hover
   - `<leader>ca` for code actions
3. Check for deprecation warnings in `:messages`

### Related Files

- `~/.config/nvim/init.lua` - Main Neovim config
- `~/.config/nvim/lua/config/lazy.lua` - Lazy.nvim setup
- `~/.config/nvim/lua/config/providers.lua` - Provider config (created by script)
- `~/.tool-versions` - asdf version file

### Further Reading

- [LazyVim Documentation](https://lazyvim.org)
- [Snacks.nvim LSP Documentation](https://github.com/folke/snacks.nvim#-lsp)
- [Neovim Health Check](https://neovim.io/doc/user/health.html)
- [asdf Version Manager](https://asdf-vm.com)
- [LazyVim on_attach Migration](https://www.lazyvim.org/configuration/lsp#lsp-keymaps)
