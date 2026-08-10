-- Set colorscheme
require("rose-pine").setup({
	disable_background = false,
	variant = "auto", -- auto (default), main, moon, or dawn
	dark_variant = "main", -- main (default), moon, or dawn
	-- Softened text and bright accents to reduce eye strain.
	-- Swap which pair is commented to A/B the two options.
	palette = {
		-- Option A: subtle reduction (12.2:1 contrast on base)
		-- main = { text = "#d1d7e0", gold = "#e0b06e", rose = "#d9adab", foam = "#8fbfc7" },
		-- moon = { text = "#d1d7e0", gold = "#e0b06e", rose = "#d88e8b", foam = "#8fbfc7" },

		-- Option B: further reduced (9.7:1 contrast on base)
		main = { text = "#b9c0cc", gold = "#e0b06e", rose = "#d9adab", foam = "#8fbfc7" },
		moon = { text = "#b9c0cc", gold = "#e0b06e", rose = "#d88e8b", foam = "#8fbfc7" },
	},
})

-- https://github.com/ellisonleao/gruvbox.nvim
require("gruvbox").setup({})

-- https://github.com/Mofiqul/dracula.nvim
require("dracula").setup({})

function ColorMyPencils(color)
	color = color or "rose-pine"
	-- color = color or "dracula"
	vim.cmd.colorscheme(color)

	-- `nvim_set_hl` replaces the whole group, so set fg too or it gets dropped
	vim.api.nvim_set_hl(0, "Normal", { fg = require("rose-pine.palette").text, bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
	vim.api.nvim_set_hl(0, "TreesitterContext", { bg = "#18151f" })
	vim.api.nvim_set_hl(0, "TreesitterContextLineNumber", { bg = "#18151f", fg = "#6e6a86" })
	-- vim.api.nvim_set_hl(0, "TreesitterContextLineNumberBottom", { underline = true, sp = "#383344"})
	-- vim.api.nvim_set_hl(0, "TreesitterContextBottom", { underline = true, sp = "#383344"})
end

ColorMyPencils()
