local git = require("prdiff.git")
local sidebar = require("prdiff.sidebar")

local M = {}

M.config = {
	layout = "unified",
	sidebar_width = 40,
	context = 3,
}

local layouts = { unified = "prdiff.unified" }

local state
local sidebar_width
local saved_tabline

-- Like the default tabline, minus the close button, with the PR diff tab named.
function M.tabline()
	local parts = {}
	local current = vim.api.nvim_get_current_tabpage()
	for i, tab in ipairs(vim.api.nvim_list_tabpages()) do
		local label
		if state and tab == state.tab then
			label = "PR diff"
		else
			local wins = vim.tbl_filter(function(w)
				return vim.api.nvim_win_get_config(w).relative == ""
			end, vim.api.nvim_tabpage_list_wins(tab))
			local buf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_get_win(tab))
			local name = vim.api.nvim_buf_get_name(buf)
			name = name == "" and "[No Name]" or vim.fn.pathshorten(vim.fn.fnamemodify(name, ":~:."))
			local modified = vim.iter(wins):any(function(w)
				return vim.bo[vim.api.nvim_win_get_buf(w)].modified
			end)
			label = (#wins > 1 and #wins .. (modified and "+" or "") .. " " or (modified and "+ " or "")) .. name
		end
		local hl = tab == current and "%#TabLineSel#" or "%#TabLine#"
		table.insert(parts, hl .. "%" .. i .. "T " .. label:gsub("%%", "%%%%") .. " ")
	end
	return table.concat(parts) .. "%#TabLineFill#%T"
end

local function use_tabline()
	saved_tabline = vim.o.tabline
	vim.o.tabline = "%!v:lua.require'prdiff'.tabline()"
end

local function restore_tabline()
	if saved_tabline then
		vim.o.tabline = saved_tabline
		saved_tabline = nil
	end
end

local function set_highlights()
	local links = {
		PrDiffAdd = "DiffAdd",
		PrDiffDelete = "DiffDelete",
		PrDiffAddNr = "DiffAdd",
		PrDiffDeleteNr = "DiffDelete",
		PrDiffLineNr = "LineNr",
		PrDiffHunk = "DiffChange",
		PrDiffHunkNr = "DiffChange",
		PrDiffTitle = "Title",
		PrDiffDir = "Directory",
		PrDiffSelected = "Visual",
		PrDiffStatusAdded = "Added",
		PrDiffStatusModified = "Changed",
		PrDiffStatusDeleted = "Removed",
		PrDiffStatusRenamed = "Special",
		PrDiffDeletedName = "Comment",
		PrDiffStatsAdd = "Added",
		PrDiffStatsDel = "Removed",
	}
	for group, target in pairs(links) do
		vim.api.nvim_set_hl(0, group, { link = target, default = true })
	end
end

local function layout()
	return require(layouts[M.config.layout])
end

local function scratch(name, ft)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].filetype = ft
	vim.bo[buf].modifiable = false
	pcall(vim.api.nvim_buf_set_name, buf, name)
	return buf
end

local function set_win_opts(win, opts)
	for k, v in pairs(opts) do
		vim.wo[win][0][k] = v
	end
end

local function is_open()
	return state and vim.api.nvim_tabpage_is_valid(state.tab) and vim.api.nvim_win_is_valid(state.diff_win)
end

local function winbar(file)
	local path = file.old_path and (file.old_path .. " → " .. file.path) or file.path
	local stats = file.binary and "%#Comment#binary"
		or ("%#PrDiffStatsAdd#+" .. file.added .. " %#PrDiffStatsDel#-" .. file.deleted)
	return " %#PrDiffTitle#" .. path:gsub("%%", "%%%%") .. "%*  " .. stats .. "%*"
end

function M.show(idx, focus)
	local file = state.files[idx]
	if not file then
		return
	end
	state.current = idx
	local text = git.diff(state.root, state.base.sha, file, M.config.context)
	layout().render(state.diff_buf, file, text)
	vim.wo[state.diff_win][0].winbar = winbar(file)
	vim.api.nvim_win_set_cursor(state.diff_win, { 1, 0 })
	sidebar.reveal(state, file.path)
	sidebar.mark_current(state, true)
	if focus then
		vim.api.nvim_set_current_win(state.diff_win)
	end
end

local function step_file(delta)
	local n = #state.files
	if n == 0 then
		return
	end
	M.show(((state.current or 1) - 1 + delta) % n + 1, false)
end

local function step_hunk(delta)
	local meta = layout().meta(state.diff_buf)
	if not meta or #meta.hunks == 0 then
		return
	end
	local cur = vim.api.nvim_win_get_cursor(state.diff_win)[1]
	local target
	if delta > 0 then
		for _, r in ipairs(meta.hunks) do
			if r > cur then
				target = r
				break
			end
		end
	else
		for i = #meta.hunks, 1, -1 do
			if meta.hunks[i] < cur then
				target = meta.hunks[i]
				break
			end
		end
	end
	if target then
		vim.api.nvim_win_set_cursor(state.diff_win, { target, 0 })
		vim.cmd("normal! zt")
	end
end

-- Window options the file split inherits from the diff window and must not keep.
local inherited = { "number", "relativenumber", "signcolumn", "foldcolumn", "wrap", "list", "spell", "cursorline", "statuscolumn", "winbar", "winfixwidth" }

local function file_window()
	if state.file_win and vim.api.nvim_win_is_valid(state.file_win) then
		return state.file_win
	end
	local win = vim.api.nvim_open_win(0, false, { split = "right", win = state.diff_win })
	vim.api.nvim_win_call(win, function()
		for _, opt in ipairs(inherited) do
			vim.cmd("setlocal " .. opt .. "<")
		end
	end)
	state.file_win = win
	return win
end

function M.open_file()
	if not is_open() then
		return
	end
	local win = vim.api.nvim_get_current_win()
	if win == state.sidebar_win then
		local item = sidebar.item_at_cursor(state)
		if not (item and item.file) then
			return
		end
		if item.file ~= state.current then
			M.show(item.file, false)
		end
	end
	local file = state.files[state.current]
	if file.status == "D" then
		vim.notify("prdiff: file was deleted", vim.log.levels.WARN)
		return
	end
	local row = win == state.diff_win and vim.api.nvim_win_get_cursor(win)[1] or 1
	local lnum = layout().target_line(state.diff_buf, row)

	local target = file_window()
	vim.api.nvim_set_current_win(target)
	vim.cmd.edit(vim.fn.fnameescape(state.root .. "/" .. file.path))
	pcall(vim.api.nvim_win_set_cursor, target, { lnum, 0 })
	vim.cmd("normal! zz")
end

local function map(buf, lhs, fn, desc)
	vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true, silent = true, desc = "prdiff: " .. desc })
end

local function keymaps()
	local sb, db = state.sidebar_buf, state.diff_buf
	for _, buf in ipairs({ sb, db }) do
		map(buf, "q", M.close, "close")
		map(buf, "R", function()
			M.refresh()
		end, "refresh")
		map(buf, "]f", function()
			step_file(1)
		end, "next file")
		map(buf, "[f", function()
			step_file(-1)
		end, "previous file")
		map(buf, "g?", function()
			vim.notify(table.concat({
				"Sidebar: <CR> open diff / toggle folder · o preview · </> resize · <Tab> focus diff",
				"Diff:    ]c/[c hunk · <CR> open file at line · <Tab> focus sidebar",
				"Both:    gf open file in right split · ]f/[f file · R refresh · q close",
			}, "\n"))
		end, "help")
		map(buf, "gf", M.open_file, "open file in split")
	end

	local function from_cursor(focus)
		return function()
			local item = sidebar.item_at_cursor(state)
			if item and item.dir then
				sidebar.toggle(state, item.dir)
			elseif item then
				M.show(item.file, focus)
			end
		end
	end
	map(sb, "<CR>", from_cursor(true), "open diff")
	map(sb, "o", from_cursor(false), "preview diff")
	map(sb, "<2-LeftMouse>", from_cursor(true), "open diff")
	map(sb, "<Tab>", function()
		vim.api.nvim_set_current_win(state.diff_win)
	end, "focus diff")
	map(sb, ">", function()
		vim.cmd("vertical resize +5")
	end, "widen sidebar")
	map(sb, "<", function()
		vim.cmd("vertical resize -5")
	end, "narrow sidebar")

	map(db, "]c", function()
		step_hunk(1)
	end, "next hunk")
	map(db, "[c", function()
		step_hunk(-1)
	end, "previous hunk")
	map(db, "<CR>", M.open_file, "open file in split")
	map(db, "<Tab>", function()
		vim.api.nvim_set_current_win(state.sidebar_win)
	end, "focus sidebar")
end

local function load(root, ref)
	local base, err = git.resolve_base(root, ref)
	if not base then
		vim.notify("prdiff: " .. err, vim.log.levels.ERROR)
		return nil
	end
	return base, sidebar.sort(git.files(root, base.sha))
end

function M.refresh(ref)
	if not is_open() then
		return
	end
	ref = ref or state.ref
	local current = state.files[state.current]
	local base, files = load(state.root, ref)
	if not base then
		return
	end
	state.ref, state.base, state.files = ref, base, files
	state.current = 1
	for i, f in ipairs(files) do
		if current and f.path == current.path then
			state.current = i
		end
	end
	sidebar.render(state)
	if #files > 0 then
		M.show(state.current, false)
	end
end

function M.open(ref)
	if not layouts[M.config.layout] then
		vim.notify("prdiff: layout '" .. M.config.layout .. "' is not supported yet", vim.log.levels.ERROR)
		return
	end
	local root = is_open() and state.root or git.root(vim.fn.expand("%:p:h")) or git.root(vim.fn.getcwd())
	if not root then
		vim.notify("prdiff: not inside a git repository", vim.log.levels.ERROR)
		return
	end

	if is_open() then
		vim.api.nvim_set_current_tabpage(state.tab)
		M.refresh(ref ~= "" and ref or nil)
		return
	end

	local base, files = load(root, ref)
	if not base then
		return
	end
	if #files == 0 then
		vim.notify("prdiff: no changes against " .. base.label)
		return
	end

	vim.cmd("tabnew")
	local tab = vim.api.nvim_get_current_tabpage()
	local diff_win = vim.api.nvim_get_current_win()
	local diff_buf = scratch("prdiff://diff", "prdiff")
	vim.api.nvim_win_set_buf(diff_win, diff_buf)

	vim.cmd("topleft vsplit")
	local sidebar_win = vim.api.nvim_get_current_win()
	local sidebar_buf = scratch("prdiff://files", "prdiff-files")
	vim.api.nvim_win_set_buf(sidebar_win, sidebar_buf)
	vim.api.nvim_win_set_width(sidebar_win, sidebar_width or M.config.sidebar_width)

	local common = { number = false, relativenumber = false, signcolumn = "no", foldcolumn = "0",
		wrap = false, list = false, spell = false, cursorline = true }
	set_win_opts(sidebar_win, vim.tbl_extend("force", common, { winfixwidth = true, statuscolumn = "" }))
	set_win_opts(diff_win, vim.tbl_extend("force", common, {
		statuscolumn = "%!v:lua.require'" .. layouts[M.config.layout] .. "'.statuscolumn()",
	}))

	state = {
		tab = tab,
		collapsed = {},
		root = root,
		ref = ref,
		base = base,
		files = files,
		current = 1,
		sidebar_win = sidebar_win,
		sidebar_buf = sidebar_buf,
		diff_win = diff_win,
		diff_buf = diff_buf,
	}
	use_tabline()
	keymaps()
	sidebar.render(state)
	M.show(1, false)
end

function M.close()
	if not state then
		return
	end
	local closing = state
	state = nil
	restore_tabline()
	if vim.api.nvim_win_is_valid(closing.sidebar_win) then
		sidebar_width = vim.api.nvim_win_get_width(closing.sidebar_win)
	end
	if not vim.api.nvim_tabpage_is_valid(closing.tab) then
		return
	end

	local others = vim.tbl_filter(function(w)
		return w ~= closing.sidebar_win and w ~= closing.diff_win and vim.api.nvim_win_get_config(w).relative == ""
	end, vim.api.nvim_tabpage_list_wins(closing.tab))
	if #others > 0 then
		-- Files opened from the diff stay open; only the PR diff panes go away.
		for _, w in ipairs({ closing.sidebar_win, closing.diff_win }) do
			if vim.api.nvim_win_is_valid(w) then
				vim.api.nvim_win_close(w, true)
			end
		end
	elseif #vim.api.nvim_list_tabpages() > 1 then
		vim.cmd.tabclose(vim.api.nvim_tabpage_get_number(closing.tab))
	else
		vim.api.nvim_set_current_tabpage(closing.tab)
		vim.cmd("enew")
		vim.cmd("only")
	end
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	set_highlights()
	local group = vim.api.nvim_create_augroup("prdiff", { clear = true })
	vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = set_highlights })
	vim.api.nvim_create_autocmd("TabClosed", {
		group = group,
		callback = function()
			if state and not vim.api.nvim_tabpage_is_valid(state.tab) then
				state = nil
				restore_tabline()
			end
		end,
	})
	vim.api.nvim_create_user_command("PrDiff", function(o)
		M.open(o.args)
	end, {
		nargs = "?",
		desc = "Show the branch's changes like a GitHub PR",
		complete = function(lead)
			local root = git.root(vim.fn.getcwd())
			return vim.tbl_filter(function(r)
				return r:find(lead, 1, true) == 1
			end, root and git.refs(root) or {})
		end,
	})
	vim.api.nvim_create_user_command("PrDiffClose", M.close, { desc = "Close the PR diff view" })
	vim.api.nvim_create_user_command("PrDiffFile", M.open_file, { desc = "Open the selected file in a split" })
end

return M
