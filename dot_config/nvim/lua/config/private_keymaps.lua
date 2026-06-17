-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Explicit Android-clipboard yank/paste (clipboard auto-sync is off; see options.lua)
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to Android clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "Yank line to Android clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>p", [["+p]], { desc = "Paste from Android clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>P", [["+P]], { desc = "Paste before from Android clipboard" })
