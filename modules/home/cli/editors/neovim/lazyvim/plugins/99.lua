return {
	{
		"ThePrimeagen/99",
		dependencies = {
			{ "saghen/blink.compat", version = "2.*", opts = {} },
			{ "nvim-telescope/telescope.nvim" },
		},
		config = function()
			local _99 = require("99")

			_99.setup({
				provider = _99.Providers.OpenCodeProvider,
				model = "openai/gpt-5.3-codex",
				display_errors = true,
				auto_add_skills = true,
				tmp_dir = "./.tmp",
				completion = {
					custom_rules = {
						"scratch/custom_rules/",
					},
					files = {
						exclude = {
							".git",
							"node_modules",
							".jj",
						},
					},
					source = "blink",
				},
				md_files = {
					"AGENT.md",
					"AGENTS.md",
				},
			})
		end,
		-- stylua: ignore
		keys = {
			{ "<leader>9v", function() require("99").visual() end, mode = "v", desc = "99: Visual edit" },
			{ "<leader>9s", function() require("99").search() end, desc = "99: Search" },
			{
				"<leader>9d",
				function()
					require("99").search({
						additional_prompt = [[
run and debug the test failures and provide me a comprehensive set of steps where
the tests are breaking ]],
					})
				end,
				desc = "99: Debug tests",
			},
			{ "<leader>9b", function() require("99").vibe() end, desc = "99: Vibe" },
			{ "<leader>9o", function() require("99").open() end, desc = "99: Open result" },
			{ "<leader>9w", function() require("99").Extensions.Worker.set_work() end, desc = "99: Set work" },
			{ "<leader>9W", function() require("99").Extensions.Worker.search() end, desc = "99: Work search" },
			{ "<leader>9c", function() require("99").clear_previous_requests() end, desc = "99: Clear history" },
			{ "<leader>9x", function() require("99").stop_all_requests() end, desc = "99: Stop all requests" },
			{ "<leader>9l", function() require("99").view_logs() end, desc = "99: View logs" },
			{ "<leader>9m", function() require("99.extensions.telescope").select_model() end, desc = "99: Select model" },
			{ "<leader>9p", function() require("99.extensions.telescope").select_provider() end, desc = "99: Select provider" },
		},
	},
}
