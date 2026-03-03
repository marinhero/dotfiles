-- Detect whether the current project is a Deno project
local function is_deno_project(fname)
  return vim.fs.root(fname, { "deno.json", "deno.jsonc" }) ~= nil
end

return {
  -- Treesitter: ensure TS/web parsers are installed
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "typescript",
        "tsx",
        "javascript",
        "json",
        "jsonc",
        "jsdoc",
        "html",
        "css",
      },
    },
  },

  -- LSP: Deno/vtsls conflict resolution
  -- lazy.nvim doesn't add lspconfig's lsp/ dir to rtp, so vim.lsp.config["denols"]
  -- is nil and LazyVim's TypeScript extra resolver never runs. Pre-register both
  -- servers so the resolver can detect and wrap them.
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      if vim.lsp and type(vim.lsp.config) == "function" then
        vim.lsp.config("denols", { root_markers = { "deno.json", "deno.jsonc" } })
        vim.lsp.config("vtsls", { root_markers = { "package.json", "tsconfig.json" } })
      end

      opts.servers = opts.servers or {}
      opts.servers.denols = vim.tbl_deep_extend("force", opts.servers.denols or {}, {
        single_file_support = false,
      })
      opts.servers.vtsls = vim.tbl_deep_extend("force", opts.servers.vtsls or {}, {
        single_file_support = false,
      })
    end,
  },

  -- Formatting: use deno_fmt in Deno projects, Prettier elsewhere (via extra)
  -- Uses formatter conditions so formatters_by_ft stays as plain tables
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters = opts.formatters or {}
      opts.formatters_by_ft = opts.formatters_by_ft or {}

      -- deno_fmt only activates in Deno projects
      opts.formatters.deno_fmt = {
        condition = function(_, ctx)
          return is_deno_project(ctx.filename)
        end,
      }

      -- Wrap prettier condition to skip Deno projects
      local prettier = opts.formatters.prettier or {}
      local orig_condition = prettier.condition
      opts.formatters.prettier = vim.tbl_deep_extend("force", prettier, {
        condition = function(self, ctx)
          if is_deno_project(ctx.filename) then
            return false
          end
          if orig_condition then
            return orig_condition(self, ctx)
          end
          return true
        end,
      })

      -- Add deno_fmt alongside prettier for all relevant filetypes
      local fts = { "typescript", "typescriptreact", "javascript", "javascriptreact", "json", "jsonc", "markdown" }
      for _, ft in ipairs(fts) do
        opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
        table.insert(opts.formatters_by_ft[ft], "deno_fmt")
      end
    end,
  },

  -- Testing: neotest with vitest and deno adapters
  {
    "nvim-neotest/neotest",
    dependencies = {
      "marilari88/neotest-vitest",
      "MarkEmmons/neotest-deno",
    },
    opts = {
      adapters = {
        ["neotest-vitest"] = {},
        ["neotest-deno"] = {},
      },
    },
  },
}
