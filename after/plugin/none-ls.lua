local null_ls = require("null-ls")

null_ls.setup({
	sources = {
		null_ls.builtins.completion.spell,
		-- prettierd has no `tsrx` filetype of its own. Formatting a .tsrx also
		-- needs @tsrx/prettier-plugin, which prettierd picks up from the
		-- project's own .prettierrc — so this only works where the project
		-- declares it.
		null_ls.builtins.formatting.prettierd.with({ extra_filetypes = { "tsrx" } }),
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
		"*.tsrx",
		"*.css",
		"*.scss",
		"*.html",
		"*.json",
		"*.md",
		"*.lua",
	},
	callback = function()
		vim.lsp.buf.format({
			-- Route through null-ls (prettier / stylua). ts_ls also advertises
			-- formatting, and without this filter it can win and format with
			-- tsserver's rules instead of the project's prettier config.
			filter = function(client)
				return client.name == "null-ls"
			end,
		})
	end,
})
