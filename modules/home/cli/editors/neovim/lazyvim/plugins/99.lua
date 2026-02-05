return {
	{
		"ThePrimeagen/99",
		dependencies = { "hrsh7th/nvim-cmp" },
		config = function()
			local _99 = require("99")
			local cwd = vim.uv.cwd()
			local basename = vim.fs.basename(cwd)

			_99.setup({
				completion = {
					custom_rules = {
						"scratch/custom_rules/",
					},
					source = "cmp",
				},
				md_files = {
					"AGENT.md",
					"CLAUDE.md",
				},
			})
		end,
    -- stylua: ignore
    keys = {
      { "<leader>9f", function() require("99").fill_in_function() end, desc = "99: Fill in function" },
      { "<leader>9p", function() require("99").fill_in_function_prompt() end, desc = "99: Fill in function, with prompt" },
      { "<leader>9v", function() require("99").visual() end, mode = "v", desc = "99: Visual edit" },
      { "<leader>9s", function() require("99").stop_all_requests() end, desc = "99: Stop all requests" },
      { "<leader>9l", function() require("99").view_logs() end, desc = "99: View logs" },
      { "<leader>9[", function() require("99").prev_request_logs() end, desc = "99: Prev logs" },
      { "<leader>9]", function() require("99").next_request_logs() end, desc = "99: Next logs" },
    },
	},
}
