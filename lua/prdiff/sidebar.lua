local M = {}

local ns = vim.api.nvim_create_namespace("prdiff_sidebar")
local ns_current = vim.api.nvim_create_namespace("prdiff_sidebar_current")

local status_hl = { A = "PrDiffStatusAdded", M = "PrDiffStatusModified", D = "PrDiffStatusDeleted", R = "PrDiffStatusRenamed" }

local function icon_for(path)
	local ok, devicons = pcall(require, "nvim-web-devicons")
	if not ok then
		return "", nil
	end
	local name = vim.fn.fnamemodify(path, ":t")
	return devicons.get_icon(name, vim.fn.fnamemodify(name, ":e"), { default = true })
end

local function build_tree(files)
	local root = { children = {}, order = {} }
	for idx, file in ipairs(files) do
		local node = root
		local parts = vim.split(file.path, "/", { plain = true })
		for i = 1, #parts - 1 do
			local p = parts[i]
			if not node.children[p] then
				node.children[p] = { name = p, children = {}, order = {} }
				table.insert(node.order, p)
			end
			node = node.children[p]
		end
		table.insert(node.order, { file = idx, name = parts[#parts] })
	end
	return root
end

local function flatten(node, depth, out, collapsed, prefix)
	local dirs, leaves = {}, {}
	for _, entry in ipairs(node.order) do
		if type(entry) == "string" then
			table.insert(dirs, node.children[entry])
		else
			table.insert(leaves, entry)
		end
	end
	for _, dir in ipairs(dirs) do
		local name, path = dir.name, prefix .. dir.name
		while #dir.order == 1 and type(dir.order[1]) == "string" do
			dir = dir.children[dir.order[1]]
			name = name .. "/" .. dir.name
			path = path .. "/" .. dir.name
		end
		local closed = collapsed and collapsed[path] or false
		table.insert(out, { dir = name, path = path, depth = depth, closed = closed })
		if not closed then
			flatten(dir, depth + 1, out, collapsed, path .. "/")
		end
	end
	for _, leaf in ipairs(leaves) do
		table.insert(out, { file = leaf.file, name = leaf.name, depth = depth })
	end
	return out
end

-- Files in the order the tree shows them, so stepping through files follows the sidebar.
function M.sort(files)
	local sorted = {}
	for _, item in ipairs(flatten(build_tree(files), 0, {}, nil, "")) do
		if item.file then
			table.insert(sorted, files[item.file])
		end
	end
	return sorted
end

function M.render(state)
	local buf = state.sidebar_buf
	local files = state.files
	local added, deleted = 0, 0
	for _, f in ipairs(files) do
		added, deleted = added + f.added, deleted + f.deleted
	end

	local lines = {
		string.format(" Files changed (%d)", #files),
		string.format(" vs %s @ %s", state.base.label, state.base.sha:sub(1, 7)),
		"",
	}
	local items = flatten(build_tree(files), 0, {}, state.collapsed, "")
	local marks = {}
	state.rows = {}

	for _, item in ipairs(items) do
		local indent = string.rep("  ", item.depth + 1)
		local row = #lines
		if item.dir then
			table.insert(lines, indent .. (item.closed and "▸ " or "▾ ") .. item.dir .. "/")
			state.rows[row + 1] = { dir = item.path }
			table.insert(marks, { row, 0, -1, "PrDiffDir" })
		else
			local file = files[item.file]
			local icon, icon_hl = icon_for(file.path)
			local status = file.untracked and "U" or file.status
			local prefix = indent .. status .. " "
			local text = prefix .. (icon ~= "" and icon .. " " or "") .. item.name
			table.insert(lines, text)
			table.insert(marks, { row, #indent, #indent + 1, status_hl[file.status] or "PrDiffStatusModified" })
			if icon_hl and icon ~= "" then
				table.insert(marks, { row, #prefix, #prefix + #icon, icon_hl })
			end
			if file.status == "D" then
				table.insert(marks, { row, #text - #item.name, #text, "PrDiffDeletedName" })
			end
			table.insert(marks, { row, stats = file })
			state.rows[row + 1] = { file = item.file }
		end
	end

	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

	vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, { end_col = #lines[1], hl_group = "PrDiffTitle" })
	vim.api.nvim_buf_set_extmark(buf, ns, 1, 0, {
		end_col = #lines[2],
		hl_group = "Comment",
		virt_text = { { "+" .. added, "PrDiffStatsAdd" }, { " " }, { "-" .. deleted, "PrDiffStatsDel" }, { " " } },
		virt_text_pos = "right_align",
	})
	for _, m in ipairs(marks) do
		if m.stats then
			local chunks = {}
			if m.stats.binary then
				chunks = { { "bin ", "Comment" } }
			else
				if m.stats.added > 0 then
					table.insert(chunks, { "+" .. m.stats.added, "PrDiffStatsAdd" })
				end
				if m.stats.deleted > 0 then
					table.insert(chunks, { (#chunks > 0 and " " or "") .. "-" .. m.stats.deleted, "PrDiffStatsDel" })
				end
				table.insert(chunks, { " " })
			end
			vim.api.nvim_buf_set_extmark(buf, ns, m[1], 0, { virt_text = chunks, virt_text_pos = "right_align" })
		else
			vim.api.nvim_buf_set_extmark(buf, ns, m[1], m[2], {
				end_col = m[3] == -1 and #lines[m[1] + 1] or m[3],
				hl_group = m[4],
			})
		end
	end
	M.mark_current(state, false)
end

function M.mark_current(state, move_cursor)
	local buf = state.sidebar_buf
	vim.api.nvim_buf_clear_namespace(buf, ns_current, 0, -1)
	for row, item in pairs(state.rows) do
		if item.file == state.current then
			vim.api.nvim_buf_set_extmark(buf, ns_current, row - 1, 0, { line_hl_group = "PrDiffSelected", priority = 5 })
			if move_cursor and vim.api.nvim_win_is_valid(state.sidebar_win) then
				vim.api.nvim_win_set_cursor(state.sidebar_win, { row, 0 })
			end
		end
	end
end

function M.item_at_cursor(state)
	local row = vim.api.nvim_win_get_cursor(state.sidebar_win)[1]
	return state.rows[row]
end

function M.toggle(state, path)
	state.collapsed[path] = not state.collapsed[path] or nil
	M.render(state)
	for row, item in pairs(state.rows) do
		if item.dir == path then
			vim.api.nvim_win_set_cursor(state.sidebar_win, { row, 0 })
		end
	end
end

-- Expand any collapsed folder hiding the file, so the selection stays visible.
function M.reveal(state, path)
	local changed = false
	for dir in pairs(state.collapsed) do
		if vim.startswith(path, dir .. "/") then
			state.collapsed[dir] = nil
			changed = true
		end
	end
	if changed then
		M.render(state)
	end
end

return M
