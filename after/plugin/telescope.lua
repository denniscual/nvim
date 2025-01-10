local builtin = require("telescope.builtin")

-- Keybinds:
local leader_telescope = "<leader>f"

vim.keymap.set("n", leader_telescope .. "f", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", leader_telescope .. "g", builtin.git_status, { desc = "Git status" })
vim.keymap.set("n", "<C-p>", function()
	builtin.find_files({ hidden = true })
end, { desc = "Find files (hidden included)" })
vim.keymap.set("n", leader_telescope .. "s", function()
	builtin.grep_string({ search = vim.fn.input("Grep > ") })
end, { desc = "Grep string" })
vim.keymap.set("n", leader_telescope .. "m", builtin.marks, { desc = "Marks" })
vim.keymap.set("n", leader_telescope .. "b", builtin.buffers, { desc = "Buffers" })
