-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Termux: keep the provider for explicit "+y / "+p, but don't auto-sync
-- the unnamed register to the system clipboard. termux-clipboard-* spawns
-- a JVM-backed Android bridge per call (~hundreds of ms), so syncing on
-- every yank/delete froze select mode (each keystroke = one bridge call).
-- Use <leader>y / <leader>p (see keymaps.lua) for explicit Android clipboard.
if vim.fn.executable("termux-clipboard-set") == 1 then
  vim.g.clipboard = {
    name = "termux-clipboard",
    copy = {
      ["+"] = "termux-clipboard-set",
      ["*"] = "termux-clipboard-set",
    },
    paste = {
      ["+"] = "termux-clipboard-get",
      ["*"] = "termux-clipboard-get",
    },
    cache_enabled = 1,
  }
end
vim.opt.clipboard = ""
