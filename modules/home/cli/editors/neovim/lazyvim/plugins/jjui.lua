return {
	{
		"HotThoughts/jjui.nvim",
		cmd = {
			"JJUI",
			"JJUICurrentFile",
			"JJUIFilter",
			"JJUIFilterCurrentFile",
			"JJConfig",
		},
		-- Setting the keybinding here helps lazy-loading
		keys = {
			{ "<leader>jj", "<cmd>JJUI<cr>", desc = "JJUI" },
			{ "<leader>jc", "<cmd>JJUICurrentFile<cr>", desc = "JJUI (current file)" },
			{ "<leader>jl", "<cmd>JJUIFilter<cr>", desc = "JJUI Log" },
			{ "<leader>jf", "<cmd>JJUIFilterCurrentFile<cr>", desc = "JJUI Log (current file)" },
		},
		config = function()
			require("jjui").setup({
				-- configuration options (see below)
			})
		end,
	},
}
