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
		vim.wo[win][k] = v
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
	vim.wo[state.diff_win].winbar = winbar(file)
	vim.api.nvim_win_set_cursor(state.diff_win, { 1, 0 })
	sidebar.mark_current(state)
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

local function open_file()
	local file = state.files[state.current]
	if not file then
		return
	end
	if file.status == "D" then
		vim.notify("prdiff: file was deleted", vim.log.levels.WARN)
		return
	end
	local lnum = layout().target_line(state.diff_buf, vim.api.nvim_win_get_cursor(state.diff_win)[1])
	if state.origin_tab and vim.api.nvim_tabpage_is_valid(state.origin_tab) then
		vim.api.nvim_set_current_tabpage(state.origin_tab)
	else
		vim.cmd("tabnew")
	end
	vim.cmd.edit(vim.fn.fnameescape(state.root .. "/" .. file.path))
	pcall(vim.api.nvim_win_set_cursor, 0, { lnum, 0 })
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
				"Sidebar: <CR> open diff · o preview · <Tab> focus diff",
				"Diff:    ]c/[c hunk · gf/<CR> open file at line · <Tab> focus sidebar",
				"Both:    ]f/[f file · R refresh · q close",
			}, "\n"))
		end, "help")
	end

	local function from_cursor(focus)
		return function()
			local idx = sidebar.file_at_cursor(state)
			if idx then
				M.show(idx, focus)
			end
		end
	end
	map(sb, "<CR>", from_cursor(true), "open diff")
	map(sb, "o", from_cursor(false), "preview diff")
	map(sb, "<2-LeftMouse>", from_cursor(true), "open diff")
	map(sb, "<Tab>", function()
		vim.api.nvim_set_current_win(state.diff_win)
	end, "focus diff")

	map(db, "]c", function()
		step_hunk(1)
	end, "next hunk")
	map(db, "[c", function()
		step_hunk(-1)
	end, "previous hunk")
	map(db, "gf", open_file, "open file")
	map(db, "<CR>", open_file, "open file")
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

	local origin_tab = vim.api.nvim_get_current_tabpage()
	vim.cmd("tabnew")
	local tab = vim.api.nvim_get_current_tabpage()
	local diff_win = vim.api.nvim_get_current_win()
	local diff_buf = scratch("prdiff://diff", "prdiff")
	vim.api.nvim_win_set_buf(diff_win, diff_buf)

	vim.cmd("topleft vsplit")
	local sidebar_win = vim.api.nvim_get_current_win()
	local sidebar_buf = scratch("prdiff://files", "prdiff-files")
	vim.api.nvim_win_set_buf(sidebar_win, sidebar_buf)
	vim.api.nvim_win_set_width(sidebar_win, M.config.sidebar_width)

	local common = { number = false, relativenumber = false, signcolumn = "no", foldcolumn = "0",
		wrap = false, list = false, spell = false, cursorline = true }
	set_win_opts(sidebar_win, vim.tbl_extend("force", common, { winfixwidth = true, statuscolumn = "" }))
	set_win_opts(diff_win, vim.tbl_extend("force", common, {
		statuscolumn = "%!v:lua.require'" .. layouts[M.config.layout] .. "'.statuscolumn()",
	}))

	state = {
		tab = tab,
		origin_tab = origin_tab,
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
	keymaps()
	sidebar.render(state)
	M.show(1, false)
end

function M.close()
	if not state then
		return
	end
	local tab = state.tab
	state = nil
	if not vim.api.nvim_tabpage_is_valid(tab) then
		return
	end
	if #vim.api.nvim_list_tabpages() > 1 then
		vim.cmd.tabclose(vim.api.nvim_tabpage_get_number(tab))
	else
		vim.api.nvim_set_current_tabpage(tab)
		vim.cmd("enew")
		vim.cmd("only")
	end
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	set_highlights()
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("prdiff", { clear = true }),
		callback = set_highlights,
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
end

return M
