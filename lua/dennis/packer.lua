-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd([[packadd packer.nvim]])

return require("packer").startup(function(use)
	-- Packer can manage itself
	use("wbthomason/packer.nvim")

	use({
		"nvim-telescope/telescope.nvim",
		requires = { { "nvim-lua/plenary.nvim" } },
	})

	use({
		"rose-pine/neovim",
		as = "rose-pine",
		config = function()
			vim.cmd("colorscheme rose-pine")
		end,
	})

	use({ "ellisonleao/gruvbox.nvim" })

	use({ "Mofiqul/dracula.nvim" })

	use("xiyaowong/transparent.nvim")

	use("folke/trouble.nvim")

	use({
		"nvim-treesitter/nvim-treesitter",
		tag = "v0.9.2",
		run = function()
			local ts_update = require("nvim-treesitter.install").update({ with_sync = true })
			ts_update()
		end,
	})
	use("nvim-treesitter/playground")
	use({
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		requires = { { "nvim-lua/plenary.nvim" } },
	})
	use("mbbill/undotree")
	use("nvim-treesitter/nvim-treesitter-context")

	use({
		"VonHeikemen/lsp-zero.nvim",
		branch = "v1.x",
		requires = {
			-- LSP Support
			-- Pinned to v2.5.0: the next release deprecates the `require('lspconfig')`
			-- framework that lsp-zero v1 drives servers through, and will delete it in
			-- v3.0.0. Unpin once lsp-zero is retired (see TASKS/lsp-zero-migration.md).
			{ "neovim/nvim-lspconfig", tag = "v2.5.0" },
			{ "williamboman/mason.nvim" },
			{ "williamboman/mason-lspconfig.nvim" },

			-- Autocompletion
			{ "hrsh7th/nvim-cmp" },
			{ "hrsh7th/cmp-buffer" },
			{ "hrsh7th/cmp-path" },
			{ "saadparwaiz1/cmp_luasnip" },
			{ "hrsh7th/cmp-nvim-lsp" },
			{ "hrsh7th/cmp-nvim-lua" },

			-- Snippets
			{ "L3MON4D3/LuaSnip" },
			{ "rafamadriz/friendly-snippets" },
		},
	})

	use("folke/zen-mode.nvim")
	use("eandrju/cellular-automaton.nvim")
	use("laytan/cloak.nvim")

	-- Autotag
	use({
		"windwp/nvim-ts-autotag",
		config = function()
			require("nvim-ts-autotag").setup({})
		end,
	})

	-- Autopair
	use({
		"windwp/nvim-autopairs",
		config = function()
			require("nvim-autopairs").setup({})
		end,
	})

	-- Comment
	use({
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	})

	-- Multi Cursor
	use({
		"mg979/vim-visual-multi",
		branch = "master",
	})

	-- Web dev icons
	use("nvim-tree/nvim-web-devicons")

	-- File explorer
	use({
		"nvim-tree/nvim-tree.lua",
		config = function()
			require("nvim-tree").setup({})
		end,
	})

	-- Surround
	use({
		"kylechui/nvim-surround",
		config = function()
			require("nvim-surround").setup({})
		end,
	})

	-- Copilot
	-- use("github/copilot.vim")

	-- Neovim statusline
	use({
		"nvim-lualine/lualine.nvim",
		requires = { "nvim-tree/nvim-web-devicons", opt = true },
	})

	-- Git Fuginitive
	use("tpope/vim-fugitive")

	-- Tailwindcss
	use({
		"luckasRanarison/tailwind-tools.nvim",
		build = ":UpdateRemotePlugins",
		requires = {
			{ "nvim-treesitter/nvim-treesitter" },
			{ "nvim-telescope/telescope.nvim" },
			{ "neovim/nvim-lspconfig" },
		},
	})

	-- Lazygit
	use({
		"kdheepak/lazygit.nvim",
		-- optional for floating window border decoration
		requires = {
			"nvim-lua/plenary.nvim",
		},
	})

	use({
		"samir-roy/code-bridge.nvim",
	})

	use({
		"MeanderingProgrammer/render-markdown.nvim",
		after = { "nvim-treesitter" },
		-- requires = { 'nvim-mini/mini.icons', opt = true },        -- if you use standalone mini plugins
		-- requires = { 'nvim-tree/nvim-web-devicons', opt = true }, -- if you prefer nvim-web-devicons
	})

	-- Toggle terminal
	use({
		"akinsho/toggleterm.nvim",
		tag = "*",
	})

	-- Oil
	use({
		"stevearc/oil.nvim",
		config = function()
			require("oil").setup()
		end,
	})

	-- Git signs
	use("lewis6991/gitsigns.nvim")

	-- Indent blankline
	-- use("lukas-reineke/indent-blankline.nvim")

	-- None-ls
	use("nvimtools/none-ls.nvim")

	-- Oxlint (oxc_language_server) as an LSP client
	use("soulsam480/nvim-oxlint")

	-- use({
	-- 	"CopilotC-Nvim/CopilotChat.nvim",
	-- 	requires = {
	-- 		{ "github/copilot.vim" }, -- or zbirenbaum/copilot.lua
	-- 		{ "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
	-- 	},
	-- 	run = "make tiktoken",
	-- })
end)
