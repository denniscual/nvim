local M = {}

local function run(args, cwd, ok_codes)
	local cmd = vim.list_extend({ "git", "-c", "core.quotepath=false" }, args)
	local r = vim.system(cmd, { cwd = cwd, text = true }):wait()
	ok_codes = ok_codes or { [0] = true }
	if not ok_codes[r.code] then
		return nil, vim.trim(r.stderr or "")
	end
	return r.stdout
end

function M.root(dir)
	if not dir or vim.fn.isdirectory(dir) == 0 then
		return nil
	end
	local out = run({ "rev-parse", "--show-toplevel" }, dir)
	return out and vim.trim(out)
end

local function rev(root, ref)
	local out = run({ "rev-parse", "--verify", "--quiet", ref .. "^{commit}" }, root)
	return out and vim.trim(out)
end

-- The PR view compares against the merge-base, like GitHub's three-dot diff.
function M.resolve_base(root, ref)
	local candidates = ref and ref ~= "" and { ref } or { "origin/HEAD", "origin/main", "origin/master", "main", "master" }
	for _, cand in ipairs(candidates) do
		if rev(root, cand) then
			local mb = run({ "merge-base", "HEAD", cand }, root)
			local sha = mb and vim.trim(mb) or rev(root, cand)
			return { sha = sha, label = cand }
		end
	end
	if ref and ref ~= "" then
		return nil, "Unknown ref: " .. ref
	end
	local head = rev(root, "HEAD")
	if head then
		return { sha = head, label = "HEAD" }
	end
	return nil, "No commits to compare against"
end

local function split_z(out)
	local parts = vim.split(out or "", "\0", { plain = true })
	if parts[#parts] == "" then
		table.remove(parts)
	end
	return parts
end

function M.files(root, base)
	local by_path, files = {}, {}

	local ns = split_z(run({ "diff", "--name-status", "-z", "-M", base }, root))
	local i = 1
	while i <= #ns do
		local status = ns[i]
		local file = { status = status:sub(1, 1) }
		if file.status == "R" or file.status == "C" then
			file.old_path, file.path = ns[i + 1], ns[i + 2]
			i = i + 3
		else
			file.path = ns[i + 1]
			i = i + 2
		end
		file.added, file.deleted = 0, 0
		by_path[file.path] = file
		table.insert(files, file)
	end

	local stats = split_z(run({ "diff", "--numstat", "-z", "-M", base }, root))
	i = 1
	while i <= #stats do
		local a, d, path = stats[i]:match("^(%S+)\t(%S+)\t(.*)$")
		if path == "" then
			path = stats[i + 2]
			i = i + 3
		else
			i = i + 1
		end
		local file = by_path[path]
		if file then
			file.binary = a == "-"
			file.added, file.deleted = tonumber(a) or 0, tonumber(d) or 0
		end
	end

	for _, path in ipairs(split_z(run({ "ls-files", "--others", "--exclude-standard", "-z" }, root))) do
		local file = { status = "A", path = path, untracked = true, added = 0, deleted = 0 }
		local out = run({ "diff", "--no-index", "--numstat", "--", "/dev/null", path }, root, { [0] = true, [1] = true })
		local a = out and out:match("^(%S+)")
		file.binary = a == "-"
		file.added = tonumber(a) or 0
		table.insert(files, file)
	end

	table.sort(files, function(x, y)
		return x.path < y.path
	end)
	return files
end

function M.diff(root, base, file, context)
	local unified = "-U" .. (context or 3)
	if file.untracked then
		return run(
			{ "diff", "--no-index", "--no-color", "--no-ext-diff", unified, "--", "/dev/null", file.path },
			root,
			{ [0] = true, [1] = true }
		)
	end
	local args = { "diff", "--no-color", "--no-ext-diff", "-M", unified, base, "--" }
	if file.old_path then
		table.insert(args, file.old_path)
	end
	table.insert(args, file.path)
	return run(args, root)
end

function M.refs(root)
	local out = run({ "for-each-ref", "--format=%(refname:short)", "refs/heads", "refs/remotes" }, root)
	return out and vim.split(vim.trim(out), "\n") or {}
end

return M
