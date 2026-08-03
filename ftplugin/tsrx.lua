local bufnr = vim.api.nvim_get_current_buf()

vim.bo[bufnr].commentstring = "// %s"

local ts_ok = pcall(vim.treesitter.start, bufnr, "tsx")

-- Deferred: treesitter.start() clears &syntax, and nvim-treesitter clears it
-- again on the same FileType event. An inline assignment never survives.
local syn = ts_ok and "tsrx" or "typescriptreact"
vim.schedule(function()
	if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype == "tsrx" then
		vim.bo[bufnr].syntax = syn
	end
end)
