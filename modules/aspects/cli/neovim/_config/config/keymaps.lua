-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

local function del(mode, lhs)
	pcall(vim.keymap.del, mode, lhs)
end

del("n", "<leader>gl")
del("n", "<leader>gL")
del("n", "<leader>gb")
del("n", "<leader>gf")
del({ "n", "x" }, "<leader>gB")
del({ "n", "x" }, "<leader>gY")

-- greatest remap ever
vim.keymap.set("x", "<leader>p", [["_dP]])
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])
vim.keymap.set("n", "<leader>y", "0y$")
vim.keymap.set("n", "<leader>.", '".P')

vim.keymap.set("n", "<leader>;", function()
	Snacks.scratch()
end)
