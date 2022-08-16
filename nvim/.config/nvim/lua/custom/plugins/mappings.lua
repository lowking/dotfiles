-- n, v, i, t = mode names
local M = {}

M.disabled = {
	["<C-n>"] = "",
}

M.easymotion = {
	n = {
		["<C-;>"] = { "<Plug>(easymotion-overwin-f)", "Jump anywhere" },
	},
}

M.multipleCursors = {
	n = {
		["S<D-l>"] = { "<Plug>(VM-Select-All)", "Multi cursor start" },
		["<D-/>"] = {
			function()
				require("Comment.api").toggle_current_linewise()
			end,
			"蘒  toggle comment",
		},
	},
	v = {
		["<D-/>"] = {
			"<ESC><cmd>lua require('Comment.api').toggle_linewise_op(vim.fn.visualmode())<CR>",
			"蘒  toggle comment",
		},
	},
}

M.nvimtree = {
	n = {
		["<D-t>"] = { "<cmd> NvimTreeToggle <CR>", "   toggle nvimtree" },
	},
}

return M
