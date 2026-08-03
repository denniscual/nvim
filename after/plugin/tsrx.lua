-- Octane `.tsrx`: filetype, tree-sitter, and language server.
-- Requires: npm install -g @ripple-ts/language-server

vim.filetype.add({ extension = { tsrx = "tsrx" } })

-- Borrow the tsx grammar; syntax/tsrx.vim colors the directives it misses.
vim.treesitter.language.register("tsx", "tsrx")

if vim.fn.executable("ripple-language-server") == 0 then
	return -- degrade to highlighting-only rather than erroring on every open
end

-- cmp capabilities and the shared on_attach keymaps, without editing lsp.lua.
-- build_options() also calls skip_server() so lsp-zero and mason leave it alone.
local ok, lsp_zero_server = pcall(require, "lsp-zero.server")
local base = ok and lsp_zero_server.build_options("tsrx", {}) or {}

vim.lsp.config("tsrx", {
	cmd = { "ripple-language-server", "--stdio" },
	filetypes = { "tsrx" },
	root_markers = { "package.json", "tsconfig.json", ".git" },
	capabilities = base.capabilities,
	on_attach = base.on_attach,

	-- Load-bearing: the server keys its virtual-code lookup off the `ripple`
	-- languageId. Send `tsrx` and every request returns empty while the client
	-- still looks attached and healthy.
	get_language_id = function()
		return "ripple"
	end,
})

vim.lsp.enable("tsrx")
