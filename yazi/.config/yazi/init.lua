require("smart-enter"):setup {
	open_multi = true,
}

require("git"):setup()
require("githead"):setup()

require("eza-preview"):setup({
    -- Determines the directory depth level to tree preview (default: 3)
    level = 3,
    -- Whether to follow symlinks when previewing directories (default: false)
    follow_symlinks = false,
    -- Whether to show target file info instead of symlink info (default: false)
    dereference = false
})
