return {
	{
		"julienvincent/hunk.nvim",
		cmd = { "DiffEditor" },
		dependencies = { "MunifTanjim/nui.nvim" },
		config = function()
			require("hunk").setup()
		end,
	},
}
