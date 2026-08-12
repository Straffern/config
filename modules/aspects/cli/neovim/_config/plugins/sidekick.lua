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
  },
	},
}
