return {
	-- {
	-- 	"3rd/image.nvim",
	-- 	build = false, -- so that it doesn't build the rock https://github.com/3rd/image.nvim/issues/91#issuecomment-2453430239
	-- 	opts = {
	-- 		processor = "magick_cli",
	-- 	},
	-- },
	{
		"folke/snacks.nvim",
		---@type snacks.Config
		opts = {
			image = {
				-- your image configuration comes here
				-- or leave it empty to use the default settings
				-- refer to the configuration section below
			},
		},
	},
}
