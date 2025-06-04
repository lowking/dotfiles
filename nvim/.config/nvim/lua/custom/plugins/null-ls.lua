local present, null_ls = pcall(require, "null-ls")

if not present then
   return
end

local b = null_ls.builtins

local sources = {
  b.formatting.code_actions.gitsigns,

   -- webdev stuff
   b.formatting.deno_fmt,
   b.formatting.prettier,

   -- Lua
   b.formatting.stylua,

   -- python
   b.formatting.black,
   b.formatting.isort,

   -- Shell
   -- b.formatting.shfmt,
   -- b.diagnostics.shellcheck.with { diagnostics_format = "#{m} [#{c}]" },
}

null_ls.setup {
   debug = true,
   sources = sources,
}
