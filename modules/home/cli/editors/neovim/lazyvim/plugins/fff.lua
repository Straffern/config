local function picker(method, root)
	return function()
		require("fff-snacks")[method]({
			cwd = root and LazyVim.root({ normalize = true }) or vim.fs.normalize(vim.uv.cwd() or vim.fn.getcwd()),
		})
	end
end

return {
	{
		"dmtrKovalenko/fff.nvim",
		build = "nix run .#release",
		lazy = false,
	},
	{
		"madmaxieee/fff-snacks.nvim",
		dependencies = {
			"dmtrKovalenko/fff.nvim",
			"folke/snacks.nvim",
		},
		lazy = false,
		keys = {
			{ "<leader><space>", picker("find_files", true), desc = "Find Files (Root Dir)" },
			{ "<leader>ff", picker("find_files", true), desc = "Find Files (Root Dir)" },
			{ "<leader>fF", picker("find_files", false), desc = "Find Files (cwd)" },
			{ "<leader>/", picker("live_grep", true), desc = "Grep (Root Dir)" },
			{ "<leader>sg", picker("live_grep", true), desc = "Grep (Root Dir)" },
			{ "<leader>sG", picker("live_grep", false), desc = "Grep (cwd)" },
			{
				"<leader>sw",
				picker("grep_word", true),
				desc = "Visual selection or word (Root Dir)",
				mode = { "n", "x" },
			},
			{ "<leader>sW", picker("grep_word", false), desc = "Visual selection or word (cwd)", mode = { "n", "x" } },
		},
	},
	{
		"folke/snacks.nvim",
		keys = {
			{ "<leader><space>", false },
			{ "<leader>ff", false },
			{ "<leader>fF", false },
			{ "<leader>/", false },
			{ "<leader>sg", false },
			{ "<leader>sG", false },
			{ "<leader>sw", false, mode = { "n", "x" } },
			{ "<leader>sW", false, mode = { "n", "x" } },
		},
	},
}
