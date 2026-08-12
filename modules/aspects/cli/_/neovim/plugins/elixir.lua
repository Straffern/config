local function elixirls_completion_only(client)
	client.server_capabilities.hoverProvider = false
	client.server_capabilities.definitionProvider = false
	client.server_capabilities.implementationProvider = false
	client.server_capabilities.typeDefinitionProvider = false
	client.server_capabilities.declarationProvider = false
	client.server_capabilities.referencesProvider = false
	client.server_capabilities.renameProvider = false
	client.server_capabilities.codeActionProvider = false
	client.server_capabilities.documentSymbolProvider = false
	client.server_capabilities.workspaceSymbolProvider = false
	client.server_capabilities.documentFormattingProvider = false
	client.server_capabilities.documentRangeFormattingProvider = false
	client.server_capabilities.signatureHelpProvider = false
	client.server_capabilities.callHierarchyProvider = false
	client.server_capabilities.inlayHintProvider = false
	client.server_capabilities.documentHighlightProvider = false
	client.server_capabilities.semanticTokensProvider = false
	client.server_capabilities.foldingRangeProvider = false
	client.server_capabilities.colorProvider = false
	client.server_capabilities.codeLensProvider = false

	client.handlers["textDocument/publishDiagnostics"] = function() end
end

return {
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			opts.servers = opts.servers or {}
			opts.setup = opts.setup or {}

			local has_expert = vim.fn.executable("expert") == 1
			local has_elixirls = vim.fn.executable("elixir-ls") == 1
			local dual = has_expert and has_elixirls

			if has_expert then
				local expert = opts.servers.expert
				if type(expert) ~= "table" then
					expert = {}
				end
				expert.mason = false
				opts.servers.expert = expert
			else
				opts.servers.expert = false
			end

			if has_elixirls then
				local elixirls = opts.servers.elixirls
				if type(elixirls) ~= "table" then
					elixirls = {}
				end
				elixirls.mason = false

				if dual then
					elixirls.settings = vim.tbl_deep_extend("force", elixirls.settings or {}, {
						elixirLS = {
							dialyzerEnabled = false,
							fetchDeps = false,
						},
					})
				end

				opts.servers.elixirls = elixirls
			else
				opts.servers.elixirls = false
			end

			if dual then
				opts.setup.expert = function()
					Snacks.util.lsp.on({ name = "expert" }, function(_, client)
						client.server_capabilities.completionProvider = false
					end)
				end

				opts.setup.elixirls = function()
					Snacks.util.lsp.on({ name = "elixirls" }, function(_, client)
						elixirls_completion_only(client)
					end)
				end
			end
		end,
	},
}
