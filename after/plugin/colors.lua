-- Set colorscheme
require("rose-pine").setup({
	disable_background = false,
	dark_variant = "main",
})

function ColorMyPencils(color)
	color = color or "rose-pine"
	vim.cmd.colorscheme(color)

	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
	vim.api.nvim_set_hl(0, "TreesitterContext", { bg = "#18151f" })
	vim.api.nvim_set_hl(0, "TreesitterContextLineNumber", { bg = "#18151f", fg = "#6e6a86" })
	-- vim.api.nvim_set_hl(0, "TreesitterContextLineNumberBottom", { underline = true, sp = "#383344"})
	-- vim.api.nvim_set_hl(0, "TreesitterContextBottom", { underline = true, sp = "#383344"})
end

ColorMyPencils()
