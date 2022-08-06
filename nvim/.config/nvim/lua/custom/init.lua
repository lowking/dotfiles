-- example file i.e lua/custom/init.lua
-- load your options globals, autocmds here or anything .__.
-- you can even override default options here (core/options.lua)
vim.o.guifont = "FiraCode Nerd Font:h18"
vim.o.rnu = true
vim.o.scrolloff = 7
-- Allow clipboard copy paste in neovim
vim.g.neovide_input_use_logo = 1
vim.api.nvim_set_keymap("", "<D-v>", "+p<CR>", { noremap = true, silent = false })
vim.api.nvim_set_keymap("!", "<D-v>", "<C-R>+", { noremap = true, silent = false })
vim.api.nvim_set_keymap("t", "<D-v>", "<C-R>+", { noremap = true, silent = false })
vim.api.nvim_set_keymap("v", "<D-v>", "<C-R>+", { noremap = true, silent = false })
