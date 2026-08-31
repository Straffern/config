return {
	{
		"folke/sidekick.nvim",
		opts = {
			-- add any options here
			nes = { enabled = false },

			cli = {
				tools = {
					opencode = {
						keys = { prompt = { "<a-p>", "prompt" } },
					},
					omp = {
						cmd = { "omp" },
						is_proc = "\\<omp\\>",
						url = "https://github.com/can1357/oh-my-pi",
						keys = { prompt = { "<a-p>", "prompt" } },
					},
				},
			},
		},
  -- stylua: ignore
  keys = {
    {
      "<leader>ac",
      function() require("sidekick.cli").toggle({ name = "opencode", focus = true }) end,
      desc = "Sidekick Toggle Claude",
    },
    {
      "<leader>ao",
      function() require("sidekick.cli").toggle({ name = "omp", focus = true }) end,
      desc = "Sidekick Toggle OMP",
    },
  },
	},
}
