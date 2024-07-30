local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.git_status, {})
vim.keymap.set('n', '<C-p>', function() builtin.find_files({ hidden=true }) end)
-- vim.keymap.set('n', '<C-p>', builtin.git_files, {})
vim.keymap.set('n', '<leader>fs', function()
	builtin.grep_string({ search = vim.fn.input("Grep > ") })
end)
-- Show diagnostics from all open buffers.
vim.keymap.set('n', '<leader>vg', builtin.diagnostics, {})
-- Show diagnostics from current buffer.
vim.keymap.set('n', '<leader>vh', function()  builtin.diagnostics({ bufnr = 0 }) end, { noremap = true, silent = true })
-- Show diagnostics all diagnostics in workspace.
-- vim.keymap.set('n', '<leader>vb', function()  builtin.diagnostics({ hide_filename = false, get_all = true }) end, { noremap = true, silent = true })

vim.keymap.set('n', '<leader>fb', builtin.buffers, {})

