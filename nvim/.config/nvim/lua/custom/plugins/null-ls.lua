local present, null_ls = pcall(require, "null-ls")

if not present then
	return
end

local b = null_ls.builtins

local sources = {
	-- webdev stuff
	b.formatting.deno_fmt,
	b.formatting.prettier.with({
		extra_args = { "--tab-width", "4" },
	}),

	-- Lua
	b.formatting.stylua,

	-- python
	b.formatting.black,
	b.formatting.isort,

	-- Shell
	-- b.formatting.shfmt,
	-- b.diagnostics.shellcheck.with { diagnostics_format = "#{m} [#{c}]" },

	b.code_actions.gitsigns,
}

null_ls.setup({
	debug = true,
	sources = sources,
})
