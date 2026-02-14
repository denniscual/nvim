require("toggleterm").setup({
	open_mapping = [[<c-\>]],
	direction = "float",
	float_opts = {
		border = "curved",
		width = function()
			return math.floor(vim.o.columns * 0.9)
		end,
		height = function()
			return math.floor(vim.o.lines * 0.9)
		end,
	},
	highlights = {
		FloatBorder = {
			guifg = "#6e6e6e",
		},
	},
})

local trim_spaces = true
local terms = require("toggleterm.terminal")

local function ensure_open(id)
	local term = terms.get(id)
	if term and not term:is_open() then
		term:open()
	end
end

-- Send visual selection to terminal and open it
vim.keymap.set("v", "<leader>ct", function()
	local id = vim.v.count1
	require("toggleterm").send_lines_to_terminal("visual_selection", trim_spaces, { args = vim.v.count })
	vim.defer_fn(function()
		ensure_open(id)
	end, 100)
end, { desc = "Send selection to terminal" })

-- Send whole file to terminal and open it
local set_opfunc = vim.fn[vim.api.nvim_exec2(
	[[
	func s:set_opfunc(val)
		let &opfunc = a:val
	endfunc
	echon get(function('s:set_opfunc'), 'name')
]],
	{ output = true }
).output]

vim.keymap.set("n", "<leader>ct", function()
	local id = vim.v.count1
	set_opfunc(function(motion_type)
		require("toggleterm").send_lines_to_terminal(motion_type, false, { args = vim.v.count })
		vim.defer_fn(function()
			ensure_open(id)
		end, 100)
	end)
	vim.api.nvim_feedkeys("ggg@G''", "n", false)
end, { desc = "Send file to terminal" })
