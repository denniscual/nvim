# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is a Neovim configuration built with Lua and organized in a modular structure:

- **Entry Point**: `init.lua` requires the main `dennis` module
- **Core Configuration**: `lua/dennis/` contains the main configuration modules:
  - `init.lua` - Main initialization with autocommands and utility functions
  - `packer.lua` - Plugin management using Packer.nvim
  - `set.lua` - Neovim options and settings
  - `remap.lua` - Global keymappings and leader key configuration
- **Plugin Configurations**: `after/plugin/` contains individual plugin setup files that load after plugins are installed

## Key Configuration Details

### Plugin Management
- Uses **Packer.nvim** for plugin management
- All plugins are defined in `lua/dennis/packer.lua`
- Plugin configurations are in separate files in `after/plugin/`

### Important Settings
- Leader key is set to space (`" "`) in `remap.lua`
- Uses tabs (not spaces) with width of 2 (`expandtab = false`)
- Relative line numbers enabled
- Undofile enabled with custom undodir
- Split windows open right and below by default

### Key Plugin Integrations
- **LSP**: Uses lsp-zero.nvim with Mason for language server management
- **Telescope**: File finder and grep functionality with `<leader>f` prefix
- **Harpoon v2**: Quick file navigation
- **Copilot**: Disabled by default, toggle with `<leader>cp` or `:CopilotToggle`
- **Treesitter**: Syntax highlighting and parsing
- **Git**: Fugitive and Gitsigns for Git integration

## Common Development Commands

### Plugin Management
```bash
# Install/update plugins (run from within Neovim)
:PackerSync
:PackerInstall
:PackerUpdate
```

### Key Plugin Commands
- `:CopilotToggle` - Toggle GitHub Copilot
- `:Telescope find_files` - Find files (also `<leader>ff`)
- `:Oil` - File explorer (oil.nvim)
- `:NvimTreeToggle` - Toggle nvim-tree file explorer
- `:Trouble` - Open diagnostics window

### Important Keymappings
- `<leader>` = Space
- `<C-p>` - Find files (including hidden)
- `<leader>ff` - Find files
- `<leader>fs` - Grep search
- `<leader>fb` - Find buffers
- `<leader>cp` - Toggle Copilot
- `<leader>f` - Format using LSP
- `<leader>bb` - Switch to previous buffer

## File Structure Notes
- Plugin auto-configurations are in files that match plugin names in `after/plugin/`
- Custom spell dictionary words are stored in `spell/en.utf-8.add`
- The configuration uses a "dennis" namespace for organization

## Development Workflow
1. Edit plugin list in `lua/dennis/packer.lua`
2. Run `:PackerSync` to install/update
3. Add plugin configuration in `after/plugin/[plugin-name].lua`
4. Reload configuration with `<leader><leader>` (sources current file)

## Special Functions
- `R(name)` function available for reloading modules during development
- Yank highlighting enabled with 40ms timeout
- System clipboard integration with `Y` in normal/visual modes