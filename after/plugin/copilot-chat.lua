local copilotChat = require("CopilotChat")

copilotChat.setup()

-- Open Chat Window
vim.api.nvim_set_keymap("n", "<leader>ccw", "<cmd>CopilotChatToggle<CR>", { noremap = true, silent = true })

-- Open Quick Chat
vim.keymap.set("x", "<leader>ccq", function()
	local input = vim.fn.input("Quick Chat: ")
	if input ~= "" then
		require("CopilotChat").ask(input, { selection = require("CopilotChat.select").visual })
	end
end, { desc = "CopilotChat - Quick chat", noremap = true })

-- Open Prompt Actions
vim.keymap.set("x", "<leader>ccp", function()
	local actions = require("CopilotChat.actions")
	require("CopilotChat.integrations.telescope").pick(actions.prompt_actions())
end, { desc = "CopilotChat - Prompt actions", noremap = true })
