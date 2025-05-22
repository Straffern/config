-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- prefil edit window with common scenarios to avoid repeating query and submit immediately
vim.g.snacks_animate = false
vim.g.ai_cmp = false

vim.api.nvim_create_user_command("HighlightHomoglyphs", function()
	vim.fn.clearmatches()
	vim.fn.matchadd("Search", "[^\\x00-\\x7F]", 10)
end, {})
