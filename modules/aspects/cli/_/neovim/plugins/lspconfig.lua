return {
	{
		"neovim/nvim-lspconfig",
		opts = {
			-- This is the LazyVim specific toggle
			folds = {
				enabled = false,
			},
			servers = {
				-- Use nixpkgs marksman instead of Mason-installed binary
				-- (Mason binary crashes under nix-ld)
				marksman = {
					cmd = { vim.g.marksman_bin, "server" },
				},
			},
		},
	},
}
