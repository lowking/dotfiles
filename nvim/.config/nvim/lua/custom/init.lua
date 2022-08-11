-- example file i.e lua/custom/init.lua
-- load your options globals, autocmds here or anything .__.
-- you can even override default options here (core/options.lua)

vim.cmd[[hi NvimTreeNormal guibg=NONE ctermbg=NONE]]
-- neovide
vim.g.neovide_refresh_rate = 90
vim.g.neovide_refresh_rate_idle = 5
-- 透明度
vim.g.neovide_transparency = 1
-- 左上角监视器
vim.g.neovide_profiler = false
-- 动画长度
vim.g.neovide_cursor_animation_length = 0.1
-- 尾巴长度
vim.g.neovide_cursor_trail_length = 0.3
-- 抗锯齿
vim.g.neovide_cursor_antialiasing = true
-- 未聚焦时候的光标边框
vim.g.neovide_cursor_unfocused_outline_width = 0
-- 粒子效果: railgun torpedo pixiedust sonicboom ripple wireframe
vim.g.neovide_cursor_vfx_mode = "wireframe"
-- vim.g.neovide_fullscreen = true
-- vim.g.neovide_floating_blur_amount_x = 20
-- vim.g.neovide_floating_blur_amount_y = 20
vim.o.guifont = "FiraCode Nerd Font:h18"
vim.o.rnu = true
vim.o.scrolloff = 7

-- Allow clipboard copy paste in neovim
vim.g.neovide_input_use_logo = true
vim.api.nvim_set_keymap("", "<D-v>", "+p<CR>", { noremap = true, silent = false })
vim.api.nvim_set_keymap("!", "<D-v>", "<C-R>+", { noremap = true, silent = false })
vim.api.nvim_set_keymap("t", "<D-v>", "<C-R>+", { noremap = true, silent = false })
vim.api.nvim_set_keymap("v", "<D-v>", "<C-R>+", { noremap = true, silent = false })
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4

-- vim-visual-multi
vim.g.VM_leader = "<space>"

-- leetcode.vim
vim.g.leetcode_cookie =
	'csrftoken=sY1kw7SpcrQg4oHNleTqGdKGF0uW25Yo5Bq2npGe5NR4uWZHzhmugcRMTwjPSCRQ; messages="77d77d2ac34d1e36e4e01a2715fa6e75ba887d01$[["__json_message"\0540\05425\054"Successfully signed in as lowking."]]"; LEETCODE_SESSION=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJfYXV0aF91c2VyX2lkIjoiNjkzMzM3MSIsIl9hdXRoX3VzZXJfYmFja2VuZCI6ImRqYW5nby5jb250cmliLmF1dGguYmFja2VuZHMuTW9kZWxCYWNrZW5kIiwiX2F1dGhfdXNlcl9oYXNoIjoiNGFkMTM4OGU2MjdkZTliNGNlMDRhNGEyMWYzZDgxYWFkYWJiODg3MyIsImlkIjo2OTMzMzcxLCJlbWFpbCI6ImFwcGx5QGxvd2tpbmcucHJvIiwidXNlcm5hbWUiOiJsb3draW5nIiwidXNlcl9zbHVnIjoibG93a2luZyIsImF2YXRhciI6Imh0dHBzOi8vczMtdXMtd2VzdC0xLmFtYXpvbmF3cy5jb20vczMtbGMtdXBsb2FkL2Fzc2V0cy9kZWZhdWx0X2F2YXRhci5qcGciLCJyZWZyZXNoZWRfYXQiOjE2NjAwNzczMDksImlwIjoiMTAzLjE3MS4xNzcuMjI4IiwiaWRlbnRpdHkiOiJkNDUzY2EyNjI2Y2ViMDE3ZGYyNzVjOGU3ZTY1YTAyZCIsInNlc3Npb25faWQiOjI1ODI1Mjc5LCJfc2Vzc2lvbl9leHBpcnkiOjEyMDk2MDB9.4pW1iUzyfcR-YEUF-ywBBBcmELrd-rC3yZpU18uN_Ic; NEW_PROBLEMLIST_PAGE=1'
vim.g.leetcode_china = 1
vim.g.leetcode_browser = "chrome"
vim.g.leetcode_solution_filetype = "java"
vim.g.loaded_python3_provider = 1
vim.g.python_host_prog = "/usr/bin/python"
vim.g.python3_host_prog = "/usr/local/bin/python3"
-- vim.g.loaded_ruby_provider = 1
-- vim.g.loaded_node_provider = 1
-- vim.g.loaded_perl_provider = 1
