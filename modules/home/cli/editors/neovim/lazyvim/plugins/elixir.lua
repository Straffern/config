return {
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			opts.servers = opts.servers or {}

			if vim.fn.executable("expert") == 1 then
				local expert = opts.servers.expert
				if type(expert) ~= "table" then
					expert = {}
					opts.servers.expert = expert
				end
				expert.mason = false
				opts.servers.elixirls = false
			elseif vim.fn.executable("elixir-ls") == 1 then
				opts.servers.expert = false
				local elixirls = opts.servers.elixirls
				if type(elixirls) ~= "table" then
					elixirls = {}
					opts.servers.elixirls = elixirls
				end
				elixirls.mason = false
			end
		end,
	},
}
