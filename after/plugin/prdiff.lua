require("prdiff").setup({ layout = "unified" })

vim.keymap.set("n", "<leader>gp", "<cmd>PrDiff<CR>", { desc = "PR-style diff of the current branch" })
