# Neovim LazyVim Configuration

Migrated LazyVim configuration with modern `snacks.lsp` patterns.

## Migration Status

✅ **Fully migrated from deprecated `on_attach` to modern patterns**

### Files Migrated

#### `lua/plugins/lsp-vtsls.lua`
- **What changed**: Replaced `LazyVim.lsp.on_attach()` with `on_init()`
- **Why**: The custom command registration only needs the client object, not the buffer
- **Pattern used**: `on_init` for client-only setup
- **Functionality preserved**: All move-to-file refactoring commands work identically

**Before:**
```lua
setup = {
  vtsls = function(_, opts)
    LazyVim.lsp.on_attach(function(client, buffer)
      client.commands["_typescript.moveToFileRefactoring"] = function(command, ctx)
        -- ... command implementation
      end
    end, "vtsls")
  end,
}
```

**After:**
```lua
servers = {
  vtsls = {
    on_init = function(client)
      client.commands["_typescript.moveToFileRefactoring"] = function(command, ctx)
        -- ... command implementation
      end
    end,
  },
}
```

#### `lua/plugins/example.lua`
- **What changed**: Replaced `require("lazyvim.util").lsp.on_attach()` with `keys` table
- **Why**: The keymaps should be declared in the server config, not in an init function
- **Pattern used**: `keys` table for LSP keymaps
- **Note**: This file is disabled (returns `{}` at top), but updated for reference

**Before:**
```lua
dependencies = {
  "jose-elias-alvarez/typescript.nvim",
  init = function()
    require("lazyvim.util").lsp.on_attach(function(_, buffer)
      vim.keymap.set("n", "<leader>co", "TypescriptOrganizeImports", { buffer = buffer })
      vim.keymap.set("n", "<leader>cR", "TypescriptRenameFile", { buffer = buffer })
    end)
  end,
},
```

**After:**
```lua
servers = {
  tsserver = {
    keys = {
      { "<leader>co", "<cmd>TypescriptOrganizeImports<cr>", desc = "Organize Imports" },
      { "<leader>cR", "<cmd>TypescriptRenameFile<cr>", desc = "Rename File" },
    },
  },
},
```

## Key Features

### VTSLS Language Server
Custom TypeScript/JavaScript LSP configuration with:
- Source definition navigation (`gD`)
- File references (`gR`)
- Import management (`<leader>co`, `<leader>cM`, `<leader>cu`)
- Fix all diagnostics (`<leader>cD`)
- TypeScript version selector (`<leader>cV`)
- Move to file refactoring (custom command)

### Configuration Highlights

- **Disabled servers**: `tsserver` and `ts_ls` (using `vtsls` instead)
- **Complete function calls**: Enabled for better autocomplete
- **Inlay hints**: Configured for function returns, parameters, and types
- **Auto imports**: Enabled with "always" update on file move

## Benefits of Migration

1. **No deprecation warnings** - Uses modern LazyVim patterns
2. **Better maintainability** - Clearer separation of concerns
3. **Automatic keymaps** - Default LSP keymaps via `snacks.lsp`
4. **Future-proof** - Compatible with latest LazyVim versions

## Verification

After updating your config, verify everything works:

```vim
" Check for deprecation warnings
:messages

" Test LSP keymaps
gd      " Go to definition
gr      " Show references
K       " Hover documentation
<leader>ca  " Code actions

" Test VTSLS-specific features
gD      " Go to source definition
gR      " File references
<leader>co  " Organize imports
```

## Related Documentation

- [LazyVim LSP Configuration](https://www.lazyvim.org/configuration/lsp)
- [Snacks.nvim LSP](https://github.com/folke/snacks.nvim#-lsp)
- [Migration Guide](../../scripts/README.md#migrating-from-on_attach-to-snackslsp)

## Adding to Dotfiles

This configuration is managed via chezmoi. To apply changes:

```bash
# If you're syncing from ~/.config/nvim to dotfiles
chezmoi add ~/.config/nvim/lua/plugins/lsp-vtsls.lua
chezmoi add ~/.config/nvim/lua/plugins/example.lua

# To apply dotfiles to system
chezmoi apply
```
