local M = {}
local pluginConfs = require "custom.plugins.configs"
M.options, M.ui, M.mappings, M.plugins = {}, {}, {}, {}

M.mappings = require "custom.plugins.mappings"

M.plugins = {
  user = {
    -- dashboard
    ["goolord/alpha-nvim"] = {
      disable = false,
    },
    ["neovim/nvim-lspconfig"] = {
      config = function()
        require "plugins.configs.lspconfig"
        require "custom.plugins.lspconf"
      end,
    },
    ["jose-elias-alvarez/null-ls.nvim"] = {
      after = "nvim-lspconfig",
      config = function()
        require "custom.plugins.null-ls"
      end,
    },
    ["mg979/vim-visual-multi"] = {},
    ["ianding1/leetcode.vim"] = {},
    ["easymotion/vim-easymotion"] = {},
  },
  override = {
    ["kyazdani42/nvim-tree.lua"] = pluginConfs.nvimtree,
    ["williamboman/mason.nvim"] = pluginConfs.mason,
    ["goolord/alpha-nvim"] = pluginConfs.alpha,
    -- ["nvim-treesitter/nvim-treesitter"] = pluginConfs.treesitter,
  },
}

-- theme
M.ui = {
  theme = "chadtain",
}

return M
