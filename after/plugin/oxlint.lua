local ok, oxlint = pcall(require, "nvim-oxlint")

if not ok then
	return
end

local cwd = vim.fn.getcwd()
local root = vim.fs.root(cwd, { ".git" }) or cwd

-- nvim-oxlint only recognises `.oxlintrc.json` / `oxlintrc.json`, so projects on
-- a JS/TS config never start the server at all.
local CONFIG_NAMES = {
	".oxlintrc.json",
	"oxlintrc.json",
	".oxlintrc.jsonc",
	"oxlint.config.ts",
	"oxlint.config.mts",
	"oxlint.config.cts",
	"oxlint.config.js",
	"oxlint.config.mjs",
	"oxlint.config.cjs",
}

local function find_config()
	for _, name in ipairs(CONFIG_NAMES) do
		if vim.uv.fs_stat(root .. "/" .. name) then
			return name
		end
	end
end

-- oxlint dropped the standalone `oxc_language_server` binary in 1.37.0 — the
-- server is now `oxlint --lsp`. The plugin still looks for the old binary, so
-- resolve the command here and hand it over as `bin_path`.
local function find_lsp_cmd()
	local new = root .. "/node_modules/.bin/oxlint"
	if vim.uv.fs_stat(new) then
		return { new, "--lsp" }
	end

	local old = root .. "/node_modules/.bin/oxc_language_server"
	if vim.uv.fs_stat(old) then
		return { old }
	end
end

local config = find_config()
local cmd = find_lsp_cmd()

-- Nothing to lint with: stay out of the way. Without this the plugin would call
-- vim.lsp.start with a nil cmd on every js/ts buffer.
if not (config and cmd) then
	return
end

-- setup() gates on its own config lookup, which misses the JS/TS configs above.
oxlint.check_config_presence = function()
	return true
end

oxlint.setup({
	bin_path = cmd,
	config_path = config,
	run = "onType",
	enable = true,
	type_aware = false,
})
