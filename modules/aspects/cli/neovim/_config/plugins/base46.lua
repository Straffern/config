return {
	{
		"AvengeMedia/base46",
		lazy = true,
		opts = {},
	},

	{
		"LazyVim/LazyVim",
		opts = {
			-- DMS renders the dms colorscheme; other shells fall back to a bundled one.
			colorscheme = function()
				if not pcall(vim.cmd.colorscheme, "dms") then
					vim.cmd.colorscheme("tokyonight")
				end
			end,
		},
	},
}
