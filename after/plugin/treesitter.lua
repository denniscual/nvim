local treesitter = require("nvim-treesitter")

treesitter.setup({
	install_dir = vim.fn.stdpath("data") .. "/site",
})

-- Tree-sitter highlighting is provided by Neovim 0.12; enable it for the
-- languages managed by this configuration.
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "vimdoc", "javascript", "typescript", "c", "lua", "rust", "css", "html", "json", "markdown" },
	callback = function()
		pcall(vim.treesitter.start)
	end,
})
