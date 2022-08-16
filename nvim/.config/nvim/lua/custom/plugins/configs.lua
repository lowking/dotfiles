local M = {}

local function button(sc, txt, keybind)
	local sc_ = sc:gsub("%s", ""):gsub("SPC", "<leader>")

	local opts = {
		position = "center",
		text = txt,
		shortcut = sc,
		cursor = 5,
		width = 36,
		align_shortcut = "right",
		hl = "AlphaButtons",
	}

	if keybind then
		opts.keymap = { "n", sc_, keybind, { noremap = true, silent = true } }
	end

	return {
		type = "button",
		val = txt,
		on_press = function()
			local key = vim.api.nvim_replace_termcodes(sc_, true, false, true)
			vim.api.nvim_feedkeys(key, "normal", false)
		end,
		opts = opts,
	}
end

M.alpha = {
	header = {
		val = {
			"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
			"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
			"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⠀⠀⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
			"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡆⠀⠀⢰⡿⠀⠀⣿⡄⠀⠀⢱⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
			"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡼⠀⠀⢀⣿⡇⠀⠀⢹⣷⡀⠀⠈⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
			"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡾⠁⠀⢀⣾⣿⠃⠀⠀⠸⣿⣷⠀⠀⠘⣷⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
			"⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⡿⠁⠀⠀⣼⣿⡟⠀⠀⠀⠀⢿⣿⣧⠀⠀⠘⢿⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
			"⠀⠀⠀⠀⠀⠀⠀⠀⣠⣾⡟⠁⠀⠀⣸⣿⣿⠇⠀⠀⠀⠀⢸⣿⣿⡆⠀⠀⠈⢻⣷⡄⠀⠀⠀⠀⠀⠀⠀⠀",
			"⠀⠀⠀⠀⠀⠀⢀⣴⣿⡏⠀⠀⠀⢀⣿⣿⣿⠀⠀⠀⠀⠀⠈⣿⣿⣿⠀⠀⠀⠀⢻⣿⣦⠀⠀⠀⠀⠀⠀⠀",
			"⠀⠀⠀⠀⠀⢠⣾⣿⣿⠀⠀⠀⠀⣸⣿⣿⣿⠀⠀⠀⠀⠀⠀⣿⣿⣿⡇⠀⠀⠀⠀⣿⣿⣷⡀⠀⠀⠀⠀⠀",
			"⠀⠀⠀⠀⢠⣿⣿⣿⣿⡀⠀⠀⣠⣿⣿⣿⣿⡀⠀⠀⠀⠀⢀⣿⣿⣿⣿⡄⠀⠀⢠⣿⣿⣿⣿⡀⠀⠀⠀⠀",
			"⠀⠀⠀⠀⠈⠉⠛⢿⣿⣷⣦⠀⠀⠙⣿⣿⣿⣧⠀⠀⠀⠀⣼⣿⣿⣿⠋⠀⠀⣴⣿⣿⡿⠛⠉⠀⠀⠀⠀⠀",
			"⠀⠀⠀⠀⠀⠀⢀⣸⣿⣿⡇⠀⠀⠀⢸⣿⣿⡏⠀⠀⠀⠀⢹⣿⣿⡇⠀⠀⠀⢸⣿⣿⣇⠀⠀⠀⠀⠀⠀⠀",
			"⠀⠀⠀⠀⠀⠀⠀⠉⠻⣿⣧⣀⠀⠀⢿⣿⣿⣇⠀⠀⠀⠀⣼⣿⣿⡷⠀⠀⣀⣾⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀",
			"⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣿⣿⣷⣶⣼⣿⣿⣿⣷⣄⣠⣾⣿⣿⣿⣧⣶⣾⣿⣿⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀",
			"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
			"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
			"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢼⣿⣿⣿⣿⣿⣿⣿⣿⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
			"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⣿⣿⣿⣿⣿⡿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
			"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
			"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
			"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⣿⣿⣿⣿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
			"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠻⣿⣿⠟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
			"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
			"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
		},
	},
	buttons = {
		type = "group",
		val = {
			button("SPC f f", "  Find File  ", ":Telescope find_files<CR>"),
			button("SPC f o", "  Recent File  ", ":Telescope oldfiles<CR>"),
			button("SPC f w", "  Find Word  ", ":Telescope live_grep<CR>"),
			button("SPC b m", "  Bookmarks  ", ":Telescope marks<CR>"),
		},
		opts = {
			spacing = 1,
		},
	},
}

M.nvimtree = {
	git = {
		enable = true,
	},

	renderer = {
		-- icons = {
		--   webdev_colors = true,
		--   git_placement = "before",
		--   padding = " ",
		--   symlink_arrow = " ➛ ",
		--   show = {
		--     file = true,
		--     folder = true,
		--     folder_arrow = true,
		--     git = true,
		--   },
		--   glyphs = {
		--     default = "",
		--     symlink = "",
		--     bookmark = "",
		--     folder = {
		--       arrow_closed = "",
		--       arrow_open = "",
		--       default = "",
		--       open = "",
		--       empty = "",
		--       empty_open = "",
		--       symlink = "",
		--       symlink_open = "",
		--     },
		--     git = {
		--       unstaged = "✗",
		--       staged = "✓",
		--       unmerged = "",
		--       renamed = "➜",
		--       untracked = "★",
		--       deleted = "",
		--       ignored = "◌",
		--     },
		--   },
		-- },
		indent_markers = {
			enable = true,
			inline_arrows = true,
			icons = {
				corner = "",
				edge = "",
				item = "",
				none = "",
			},
		},
		icons = {
			show = {
				git = true,
			},
		},
	},
	-- update_cwd = false,
	respect_buf_cwd = false, -- 进入目录之后，开关目录树是否还原到之前到目录
	-- update_focused_file = {
	--   enable = true,
	--   update_cwd = true,
	--   ignore_list = {},
	-- },
	view = {
		adaptive_size = false,
		side = "left",
		width = 30,
	},
	-- actions = {
	--   open_file = {
	--     resize_window = true,
	--   },
	-- },
}

M.mason = {
	ensure_installed = {
		-- lua
		"stylua",
		"lua-language-server",

		-- web
		"css-lsp",
		"html-lsp",
		"typescript-language-server",
		"deno",
		"emmet-ls",
		"json-lsp",

		-- shell
		-- "shfmt",
		-- "shellcheck",

		-- yaml
		"yamllint",
		"yaml-language-server",

		-- python
		"pyright",
	},
}

return M
