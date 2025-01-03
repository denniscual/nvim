require("trouble").setup()

vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle filter.buf=0<cr><cr>",
  { silent = true, noremap = true, desc = "Buffer Diagnostics (Trouble)" }
)
vim.keymap.set("n", "<leader>xX", "<cmd>Trouble diagnostics toggle<cr>",
  { silent = true, noremap = true, desc = "Diagnostics (Trouble)" }
)
