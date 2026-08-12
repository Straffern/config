return {
	{
		"folke/snacks.nvim",
		opts = {
			picker = {
				sources = {
					files = {
						args = { "--no-require-git" },
					},
					grep = {
						args = { "--no-require-git" },
					},
				},
			},
		},
	},
}
