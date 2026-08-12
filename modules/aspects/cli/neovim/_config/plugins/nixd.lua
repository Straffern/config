return {
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				nixd = {
					settings = {
						nixd = {
							formatting = {
								command = { "alejandra", "-qq" },
							},
						},
					},
				},
			},
		},
	},
}
