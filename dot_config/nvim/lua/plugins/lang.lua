return {
  -- Deno LSP (no LazyVim extra available, configure manually)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        denols = {
          root_dir = require("lspconfig.util").root_pattern("deno.json", "deno.jsonc"),
        },
      },
    },
  },
}
