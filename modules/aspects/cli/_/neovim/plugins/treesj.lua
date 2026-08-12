return {
	"Wansmer/treesj",
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	keys = {
		{ "gS", "<cmd>TSJToggle<cr>", desc = "Toggle split/join" },
	},
	opts = {
		use_default_keymaps = false,
	},
}
