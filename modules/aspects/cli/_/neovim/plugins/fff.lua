local function picker(method, root)
	return function()
		require("fff-snacks")[method]({
			cwd = root and LazyVim.root({ normalize = true }) or vim.fs.normalize(vim.uv.cwd() or vim.fn.getcwd()),
		})
	end
end

local function native_handoff(source, forced)
	return function(picker)
		local query = picker:filter().search
		local opts = {
			cwd = picker:cwd(),
			ignored = forced == "ignored" or picker.opts.ignored,
			hidden = forced == "hidden" or picker.opts.hidden,
			exclude = { ".jj" },
			on_show = function()
				picker:close()
			end,
		}

		if source == "files" then
			opts.pattern = query
		else
			local mode = picker.opts.grep_mode and picker.opts.grep_mode[1]
			opts.search = query
			opts.regex = mode == "regex"
			if mode == "fuzzy" then
				vim.notify("FFF fuzzy grep falls back to fixed-string Snacks grep", vim.log.levels.WARN)
			end
		end

		for _, active in ipairs(Snacks.picker.get({ source = source })) do
			active:close()
		end

		Snacks.picker.pick(source, opts)
	end
end

local function ignored_handoff(source)
	return {
		actions = {
			fff_ignored = native_handoff(source, "ignored"),
			fff_hidden = native_handoff(source, "hidden"),
		},
		win = {
			input = {
				keys = {
					["<a-h>"] = { "fff_hidden", mode = { "i", "n" } },
					["<a-i>"] = { "fff_ignored", mode = { "i", "n" } },
				},
			},
			list = {
				keys = {
					["<a-h>"] = "fff_hidden",
					["<a-i>"] = "fff_ignored",
				},
			},
		},
	}
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
		opts = {
			find_files = ignored_handoff("files"),
			live_grep = ignored_handoff("grep"),
			grep_word = ignored_handoff("grep"),
		},
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
