return {
	{
		"yetone/avante.nvim",
		event = "VeryLazy",
		lazy = false,
		version = false, -- Set this to "*" to always pull the latest release version, or set it to false to update to the latest code changes.
		opts = {

			use_cwd_as_project_root = false,
			provider = "openrouter_deepseek",
			mode = "legacy",

			auto_suggestions_provider = "openrouter_openai_4_1", -- In this example, use Openrouter for auto-suggestions, but you can also use any provider you want.
			cursor_applying_provider = "groq", -- In this example, use Groq for applying, but you can also use any provider you want.
			behaviour = {
				use_absolute_path = true,
				auto_suggestions = false, -- Experimental stage

				minimize_diff = true, -- Whether to remove unchanged lines when applying a code block
				enable_cursor_planning_mode = true, -- Whether to enable Cursor Planning Mode. Default to false.
				-- enable_claude_text_editor_tool_mode = true,
			},

			suggestion = {
				debounce = 600,
				throttle = 600,
			},

			providers = {
				--- ... existing providers
				groq = { -- define groq provider
					__inherited_from = "openai",
					api_key_name = "GROQ_API_KEY",
					endpoint = "https://api.groq.com/openai/v1/",
					model = "llama-3.3-70b-versatile",
					extra_request_body = {
						max_tokens = 32768, -- remember to increase this value, otherwise it will stop generating halfway
					},
				},

				openrouter_openai_4_1 = {
					__inherited_from = "openai",
					endpoint = "https://openrouter.ai/api/v1",
					api_key_name = "OPENROUTER_API_KEY",
					model = "openai/gpt-4.1",
					extra_request_body = {
						max_tokens = 32768, -- remember to increase this value, otherwise it will stop generating halfway
					},
				},

				openrouter_deepseek = {
					__inherited_from = "openai",
					endpoint = "https://openrouter.ai/api/v1",
					api_key_name = "OPENROUTER_API_KEY",
					model = "deepseek/deepseek-r1-0528",
					extra_request_body = {
						max_tokens = 32768, -- remember to increase this value, otherwise it will stop generating halfway
					},
				},

				openrouter_deepseek_r1 = {
					__inherited_from = "openai",
					endpoint = "https://openrouter.ai/api/v1",
					api_key_name = "OPENROUTER_API_KEY",
					model = "deepseek/deepseek-r1-0528",
					extra_request_body = {
						max_tokens = 32768, -- remember to increase this value, otherwise it will stop generating halfway
					},
				},

				openrouter_deepseek_distill = {
					__inherited_from = "openai",
					endpoint = "https://openrouter.ai/api/v1",
					api_key_name = "OPENROUTER_API_KEY",
					model = "deepseek/deepseek-r1-distill-llama-8b",
					extra_request_body = {
						max_tokens = 32768, -- remember to increase this value, otherwise it will stop generating halfway
					},
				},

				openrouter_gemini_2_5_pro = {
					__inherited_from = "openai",
					endpoint = "https://openrouter.ai/api/v1",
					api_key_name = "OPENROUTER_API_KEY",
					model = "google/gemini-2.5-pro",
					extra_request_body = {
						max_tokens = 32768, -- remember to increase this value, otherwise it will stop generating halfway
						timeout = 60000,
					},
				},

				openrouter_gemini_flash = {
					__inherited_from = "openai",
					endpoint = "https://openrouter.ai/api/v1",
					api_key_name = "OPENROUTER_API_KEY",
					model = "google/gemini-2.0-flash-001",
					extra_request_body = {
						timeout = 30000, -- Timeout in milliseconds
						max_tokens = 60000,
					},
				},

				openrouter_gemini_flash_2_5 = {
					__inherited_from = "openai",
					endpoint = "https://openrouter.ai/api/v1",
					api_key_name = "OPENROUTER_API_KEY",
					model = "google/gemini-2.5-flash",
					extra_request_body = {
						timeout = 30000, -- Timeout in milliseconds
						max_tokens = 60000,
					},
				},

				openrouter_gemini_flash_2_5_lite = {
					__inherited_from = "openai",
					endpoint = "https://openrouter.ai/api/v1",
					api_key_name = "OPENROUTER_API_KEY",
					model = "google/gemini-2.5-flash-lite-preview-06-17",
					extra_request_body = {
						timeout = 30000, -- Timeout in milliseconds
						max_tokens = 60000,
					},
				},

				openrouter_gemini_flash_lite = {
					__inherited_from = "openai",
					endpoint = "https://openrouter.ai/api/v1",
					api_key_name = "OPENROUTER_API_KEY",
					model = "google/gemini-2.0-flash-lite-001",
					extra_request_body = {
						timeout = 30000, -- Timeout in milliseconds
						max_tokens = 60000,
					},
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
