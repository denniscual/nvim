local M = {}

local ns = vim.api.nvim_create_namespace("prdiff_unified")
local metas = {}

local function parse(text)
	local hunks, notes = {}, {}
	local cur
	for _, l in ipairs(vim.split(text or "", "\n", { plain = true })) do
		local os_, ns_ = l:match("^@@ %-(%d+),?%d* %+(%d+),?%d* @@")
		if os_ then
			cur = { header = l, old = tonumber(os_), new = tonumber(ns_), lines = {} }
			table.insert(hunks, cur)
		elseif cur then
			local c = l:sub(1, 1)
			if c == "+" or c == "-" or c == " " or c == "\\" then
				table.insert(cur.lines, l)
			end
		elseif l:match("^Binary files") then
			notes.binary = true
		elseif l:match("^old mode") then
			notes.mode = true
		end
	end
	return hunks, notes
end

local function lang_for(path)
	local ft = vim.filetype.match({ filename = path })
	if not ft then
		return nil
	end
	local lang = vim.treesitter.language.get_lang(ft) or ft
	if not pcall(vim.treesitter.language.add, lang) then
		return nil
	end
	return lang
end

local function highlight_side(buf, lang, side)
	if #side.lines == 0 then
		return
	end
	local src = table.concat(side.lines, "\n")
	local ok, parser = pcall(vim.treesitter.get_string_parser, src, lang)
	if not ok then
		return
	end
	local query = vim.treesitter.query.get(lang, "highlights")
	if not query then
		return
	end
	local tree = parser:parse()[1]
	for id, node in query:iter_captures(tree:root(), src, 0, -1) do
		local name = query.captures[id]
		if not name:match("^_") and name ~= "spell" and name ~= "nospell" and name ~= "conceal" then
			local sr, sc, er, ec = node:range()
			for r = sr, er do
				local row = side.rows[r + 1]
				if row then
					local s = r == sr and sc or 0
					local e = r == er and ec or #side.lines[r + 1]
					if e > s then
						pcall(vim.api.nvim_buf_set_extmark, buf, ns, row, s + 1, {
							end_col = e + 1,
							hl_group = "@" .. name .. "." .. lang,
							priority = 100,
						})
					end
				end
			end
		end
	end
end

local function message(file, notes)
	if file.binary or notes.binary then
		return "Binary file not shown."
	elseif file.status == "R" then
		return "File renamed without changes."
	elseif notes.mode then
		return "File mode changed."
	end
	return "No changes to show."
end

function M.render(buf, file, text)
	local hunks, notes = parse(text)
	local lines, rows, hunk_rows = {}, {}, {}
	local old_side, new_side = { lines = {}, rows = {} }, { lines = {}, rows = {} }
	local max_lnum = 0

	for _, h in ipairs(hunks) do
		table.insert(lines, h.header)
		table.insert(rows, { kind = "hunk" })
		table.insert(hunk_rows, #lines)
		local o, n = h.old, h.new
		for _, l in ipairs(h.lines) do
			local c, body = l:sub(1, 1), l:sub(2)
			table.insert(lines, l)
			local row = #lines - 1
			if c == " " then
				table.insert(rows, { kind = "ctx", old = o, new = n })
				table.insert(new_side.lines, body)
				new_side.rows[#new_side.lines] = row
				o, n = o + 1, n + 1
			elseif c == "+" then
				table.insert(rows, { kind = "add", new = n })
				table.insert(new_side.lines, body)
				new_side.rows[#new_side.lines] = row
				n = n + 1
			elseif c == "-" then
				table.insert(rows, { kind = "del", old = o })
				table.insert(old_side.lines, body)
				old_side.rows[#old_side.lines] = row
				o = o + 1
			else
				table.insert(rows, { kind = "nonl" })
			end
		end
		max_lnum = math.max(max_lnum, o, n)
	end

	if #hunks == 0 then
		lines = { message(file, notes) }
		rows = { { kind = "note" } }
	end

	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

	local line_hl = { hunk = "PrDiffHunk", add = "PrDiffAdd", del = "PrDiffDelete", nonl = "Comment", note = "Comment" }
	for i, r in ipairs(rows) do
		if line_hl[r.kind] then
			vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, { line_hl_group = line_hl[r.kind], priority = 10 })
		end
	end

	local lang = lang_for(file.path)
	if lang then
		highlight_side(buf, lang, new_side)
		highlight_side(buf, lang, old_side)
	end

	metas[buf] = { rows = rows, width = math.max(#tostring(max_lnum), 3), hunks = hunk_rows }
	vim.api.nvim_buf_attach(buf, false, {
		on_detach = function()
			metas[buf] = nil
		end,
	})
	return metas[buf]
end

function M.meta(buf)
	return metas[buf]
end

function M.statuscolumn()
	local buf = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
	local meta = metas[buf]
	if not meta then
		return ""
	end
	local w = meta.width
	local r = meta.rows[vim.v.lnum]
	if not r or vim.v.virtnum ~= 0 then
		return string.rep(" ", w * 2 + 2)
	end
	local hl = ({ add = "PrDiffAddNr", del = "PrDiffDeleteNr", hunk = "PrDiffHunkNr" })[r.kind] or "PrDiffLineNr"
	local fmt = "%" .. w .. "s %" .. w .. "s "
	return "%#" .. hl .. "#" .. string.format(fmt, r.old or "", r.new or "") .. "%*"
end

-- The line to land on in the real file: deleted lines map to the next surviving line.
function M.target_line(buf, lnum)
	local meta = metas[buf]
	if not meta then
		return 1
	end
	for i = lnum, #meta.rows do
		if meta.rows[i].new then
			return meta.rows[i].new
		end
	end
	for i = lnum, 1, -1 do
		if meta.rows[i].new then
			return meta.rows[i].new
		end
	end
	return 1
end

return M
