require("code-bridge").setup({
	chat = {
		model = "claude-opus-4-5",
		permission = "acceptEdits", -- Auto-accept edits from Claude Code
	},
})

-- For Claude Code

vim.keymap.set("n", "<leader>ct", ":CodeBridgeTmux<CR>", { desc = "Send file to claude" })
vim.keymap.set("v", "<leader>ct", ":CodeBridgeTmux<CR>", { desc = "Send selection to claude" })
vim.keymap.set("n", "<leader>cd", ":CodeBridgeTmuxDiffStaged<CR>", { desc = "Send git git staged to claude" })

-- Chat interface
vim.keymap.set("n", "<leader>cq", ":CodeBridgeQuery<CR>", { desc = "Query claude with context" })
vim.keymap.set("v", "<leader>cq", ":CodeBridgeQuery<CR>", { desc = "Query claude with selection" })
vim.keymap.set("n", "<leader>cc", ":CodeBridgeChat<CR>", { desc = "Chat with claude" })
vim.keymap.set("n", "<leader>ch", ":CodeBridgeHide<CR>", { desc = "Hide chat window" })
vim.keymap.set("n", "<leader>cs", ":CodeBridgeShow<CR>", { desc = "Show chat window" })
vim.keymap.set("n", "<leader>cx", ":CodeBridgeWipe<CR>", { desc = "Wipe chat and clear history" })

-- For Codex

-- Create a helper to send to a different tmux window
local function send_to_codex(message)
	-- Write message to temp file and paste into the "codex" tmux window
	local temp = vim.fn.tempname()
	local f = io.open(temp, "w")
	if f then
		f:write(message)
		f:close()
		local result =
			vim.fn.system(string.format('tmux load-buffer "%s" \\; paste-buffer -p -t codex \\; delete-buffer', temp))
		local err = vim.v.shell_error
		vim.fn.delete(temp)
		if err ~= 0 then
			print("Failed to send to codex window: " .. result)
			vim.fn.setreg("+", message)
		else
			-- Optionally switch to the codex window
			vim.fn.system("tmux select-window -t codex")
		end
	end
end

-- Now create Codex-specific commands
vim.api.nvim_create_user_command("CodexTmux", function(opts)
	-- Build context the same way the plugin does
	local file = vim.fn.expand("%")
	if file == "" then
		print("no file context")
		return
	end
	local context
	if opts.range == 2 then
		context = "@" .. file .. "#L" .. opts.line1 .. "-" .. opts.line2
	else
		context = "@" .. file
	end
	send_to_codex(context)
end, { range = true })

-- Keybindings for Codex
vim.keymap.set("n", "<leader>vt", ":CodexTmux<CR>", { desc = "Send file to codex" })
vim.keymap.set("v", "<leader>vt", ":CodexTmux<CR>", { desc = "Send selection to codex" })
