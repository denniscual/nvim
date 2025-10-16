local nvim_tree = require("nvim-tree")

nvim_tree.setup({
	view = {
		adaptive_size = true,
	},
})

vim.keymap.set("n", "<leader>e", ":NvimTreeFindFileToggle<CR>")
vim.keymap.set("n", "<leader>w", ":NvimTreeFindFile<CR>")
