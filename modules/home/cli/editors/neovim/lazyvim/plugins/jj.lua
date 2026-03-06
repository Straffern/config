return {
	{
		"nicolasgb/jj.nvim",
		dependencies = {
			"folke/snacks.nvim",
		},
		cmd = {
			"J",
			"Jbrowse",
			"Jdiff",
			"Jhdiff",
			"Jvdiff",
		},
		opts = {
			picker = {
				snacks = {},
			},
		},
		keys = {
			{
				"<leader>gs",
				function()
					require("jj.picker").status()
				end,
				desc = "JJ Status",
			},
			{
				"<leader>gS",
				function()
					require("jj.cmd").split()
				end,
				desc = "JJ Split",
			},
			{
				"<leader>gl",
				function()
					require("jj.cmd").log()
				end,
				desc = "JJ Log",
			},
			{
				"<leader>gL",
				function()
					require("jj.cmd").log({ revisions = "'all()'" })
				end,
				desc = "JJ Log (All)",
			},
			{
				"<leader>gb",
				function()
					require("jj.annotate").line()
				end,
				desc = "JJ Annotate Line",
			},
			{
				"<leader>gf",
				function()
					require("jj.picker").file_history()
				end,
				desc = "JJ File History",
			},
			{
				"<leader>gd",
				function()
					require("jj.diff").diff_current()
				end,
				desc = "JJ Diff",
			},
			{
				"<leader>gD",
				function()
					require("jj.diff").diff_current({ rev = "trunk()" })
				end,
				desc = "JJ Diff Trunk",
			},
			{
				"<leader>gB",
				"<cmd>Jbrowse<cr>",
				mode = "n",
				desc = "JJ Browse",
			},
			{
				"<leader>gB",
				":Jbrowse<cr>",
				mode = "x",
				desc = "JJ Browse",
			},
			{
				"<leader>gp",
				function()
					require("jj.cmd").open_pr()
				end,
				desc = "JJ Open PR",
			},
			{
				"<leader>gP",
				function()
					require("jj.cmd").open_pr({ list_bookmarks = true })
				end,
				desc = "JJ Open PR (Bookmarks)",
			},
		},
	},
	{
		"folke/snacks.nvim",
		keys = {
			{ "<leader>gs", false },
			{ "<leader>gS", false },
			{ "<leader>gd", false },
			{ "<leader>gD", false },
			{ "<leader>gi", false },
			{ "<leader>gI", false },
			{ "<leader>gp", false },
			{ "<leader>gP", false },
		},
	},
}
