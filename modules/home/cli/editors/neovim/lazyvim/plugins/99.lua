return {
	{
		"ThePrimeagen/99",
		dependencies = { "saghen/blink.cmp" },
		config = function()
			local _99 = require("99")
			local cwd = vim.uv.cwd()
			local basename = vim.fs.basename(cwd)

			_99.setup({
				provider = _99.OpenCodeProvider,
				model = "opencode/kimi-k2.5",
				completion = {
					custom_rules = {
						"scratch/custom_rules/",
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
      { "<leader>9s", function() require("99").stop_all_requests() end, desc = "99: Stop all requests" },
      -- { "<leader>9l", function() require("99").view_logs() end, desc = "99: View logs" },
      -- { "<leader>9[", function() require("99").prev_request_logs() end, desc = "99: Prev logs" },
      -- { "<leader>9]", function() require("99").next_request_logs() end, desc = "99: Next logs" },
    },
	},
}
