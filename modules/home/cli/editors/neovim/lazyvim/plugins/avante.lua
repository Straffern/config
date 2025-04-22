return {
	{
		"yetone/avante.nvim",
		event = "VeryLazy",
		lazy = false,
		version = false, -- Set this to "*" to always pull the latest release version, or set it to false to update to the latest code changes.
		opts = {
			provider = "openrouter_deepseek",

			claude = {
				endpoint = "https://api.anthropic.com",
				model = "claude-3-5-sonnet-20241022",
				timeout = 30000, -- Timeout in milliseconds
				temperature = 0,
				max_tokens = 4096,
			},

			gemini = {
				model = "gemini-2.5-pro-preview-03-25",
				timeout = 60000, -- Timeout in milliseconds
				temperature = 0,
				max_tokens = 32768,
				api_key_name = "GEMINI_API_KEY",
			},

			-- rag_service = {
			-- 	enabled = true, -- Enables the rag service, requires OPENAI_API_KEY to be set
			-- 	-- runner = "nix",
			-- },

			auto_suggestions_provider = "openrouter_claude_3_5",
			cursor_applying_provider = "groq", -- In this example, use Groq for applying, but you can also use any provider you want.
			behaviour = {
				auto_suggestions = false, -- Experimental stage

				minimize_diff = true, -- Whether to remove unchanged lines when applying a code block
				enable_cursor_planning_mode = true, -- Whether to enable Cursor Planning Mode. Default to false.
				-- enable_claude_text_editor_tool_mode = true,
			},

			suggestion = {
				debounce = 600,
				throttle = 600,
			},

			vendors = {
				--- ... existing vendors
				groq = { -- define groq provider
					__inherited_from = "openai",
					api_key_name = "GROQ_API_KEY",
					endpoint = "https://api.groq.com/openai/v1/",
					model = "llama-3.3-70b-versatile",
					max_tokens = 32768, -- remember to increase this value, otherwise it will stop generating halfway
				},

				openrouter_deepseek = {
					__inherited_from = "openai",
					endpoint = "https://openrouter.ai/api/v1",
					api_key_name = "OPENROUTER_API_KEY",
					model = "deepseek/deepseek-chat-v3-0324",
					max_tokens = 32768, -- remember to increase this value, otherwise it will stop generating halfway
				},

				openrouter_meta_scout = {
					__inherited_from = "openai",
					endpoint = "https://openrouter.ai/api/v1",
					api_key_name = "OPENROUTER_API_KEY",
					model = "meta-llama/llama-4-scout",
					max_tokens = 32768, -- remember to increase this value, otherwise it will stop generating halfway
				},

				openrouter_meta_maverick = {
					__inherited_from = "openai",
					endpoint = "https://openrouter.ai/api/v1",
					api_key_name = "OPENROUTER_API_KEY",
					model = "meta-llama/llama-4-maverick",
					max_tokens = 32768, -- remember to increase this value, otherwise it will stop generating halfway
				},

				openrouter_deepseek_distill = {
					__inherited_from = "openai",
					endpoint = "https://openrouter.ai/api/v1",
					api_key_name = "OPENROUTER_API_KEY",
					model = "deepseek/deepseek-r1-distill-llama-8b",
					max_tokens = 32768, -- remember to increase this value, otherwise it will stop generating halfway
				},

				openrouter_claude_3_5 = {
					__inherited_from = "openai",
					endpoint = "https://openrouter.ai/api/v1",
					api_key_name = "OPENROUTER_API_KEY",
					model = "anthropic/claude-3.5-sonnet",
					max_tokens = 32768, -- remember to increase this value, otherwise it will stop generating halfway
				},

				openrouter_claude_3_7 = {
					__inherited_from = "openai",
					endpoint = "https://openrouter.ai/api/v1",
					api_key_name = "OPENROUTER_API_KEY",
					model = "anthropic/claude-3.7-sonnet",
					max_tokens = 32768, -- remember to increase this value, otherwise it will stop generating halfway
				},

				openrouter_gemini_2_5_pro = {
					__inherited_from = "openai",
					endpoint = "https://openrouter.ai/api/v1",
					api_key_name = "OPENROUTER_API_KEY",
					model = "google/gemini-2.5-pro-preview-03-25",
					max_tokens = 32768, -- remember to increase this value, otherwise it will stop generating halfway
					timeout = 60000,
				},
				openrouter_grok_3_mini = {
					__inherited_from = "openai",
					endpoint = "https://openrouter.ai/api/v1",
					api_key_name = "OPENROUTER_API_KEY",
					model = "x-ai/grok-3-mini-beta",
					max_tokens = 32768, -- remember to increase this value, otherwise it will stop generating halfway
				},

				gemini_flash = {
					__inherited_from = "gemini",
					model = "gemini-2.0-flash",
					timeout = 30000, -- Timeout in milliseconds
					temperature = 0,
					max_tokens = 32768,
					api_key_name = "GEMINI_API_KEY",
				},

				gemini_flash_lite = {
					__inherited_from = "gemini",
					model = "gemini-2.0-flash-lite",
					timeout = 30000, -- Timeout in milliseconds
					temperature = 0,
					max_tokens = 32768,
					api_key_name = "GEMINI_API_KEY",
				},
			},

			-- add any opts here
			-- for example
		},
		-- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
		build = "make",
		-- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"stevearc/dressing.nvim",
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			--- The below dependencies are optional,
			"echasnovski/mini.pick", -- for file_selector provider mini.pick
			"nvim-telescope/telescope.nvim", -- for file_selector provider telescope
			"hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
			"ibhagwan/fzf-lua", -- for file_selector provider fzf
			"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
			"zbirenbaum/copilot.lua", -- for providers='copilot'
			{
				-- support for image pasting
				"HakonHarnes/img-clip.nvim",
				event = "VeryLazy",
				opts = {
					-- recommended settings
					default = {
						embed_image_as_base64 = false,
						prompt_for_file_name = false,
						drag_and_drop = {
							insert_mode = true,
						},
						-- required for Windows users
						use_absolute_path = true,
					},
				},
			},
			{
				-- Make sure to set this up properly if you have lazy=true
				"MeanderingProgrammer/render-markdown.nvim",
				opts = {
					file_types = { "markdown", "Avante" },
				},
				ft = { "markdown", "Avante" },
			},
		},
	},
}
