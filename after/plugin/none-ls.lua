local null_ls = require("null-ls")

null_ls.setup({
	sources = {
		null_ls.builtins.completion.spell,
		null_ls.builtins.formatting.prettierd,
		null_ls.builtins.formatting.stylua,
	},
})

-- Format on save
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = {
		"*.js",
		"*.jsx",
		"*.ts",
		"*.tsx",
		"*.css",
		"*.scss",
		"*.html",
		"*.json",
		"*.md",
		"*.lua",
	},
	callback = function()
		vim.lsp.buf.format()
	end,
})
