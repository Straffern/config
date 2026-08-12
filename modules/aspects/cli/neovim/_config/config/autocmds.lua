-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here
--
-- Create an augroup for non-ASCII dash highlighting
local dash_group = vim.api.nvim_create_augroup("NonAsciiDashHighlight", { clear = true })

-- Define the highlight group for non-ASCII dashes
vim.api.nvim_set_hl(0, "NonAsciiDash", { bg = "#ff0000" }) -- Modern API, red background

-- Create an autocmd that applies the match when you open or enter a window
vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
	group = dash_group,
	callback = function()
		-- Pattern for specific dashes only:
		-- U+2010 (‐), U+2011 (‑), U+2012 (‒), U+2013 (–),
		-- U+2014 (—), U+2015 (―), U+2212 (−)
		local pattern = "[‐‑‒–—―−]"
		vim.fn.matchadd("NonAsciiDash", pattern)
	end,
})
