local copilotChat = require("CopilotChat")

copilotChat.setup()

vim.api.nvim_set_keymap("n", "<leader>cc", "<cmd>CopilotChatToggle<CR>", { noremap = true, silent = true })
