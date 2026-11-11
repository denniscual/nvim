# prdiff

Review your branch in Neovim the way GitHub shows a pull request's "Files changed"
tab: a tree of changed files on the left, the diff of the selected file on the right.

## What it compares

The diff is taken from the merge-base of `HEAD` and the base branch to your
**working tree**, like GitHub's three-dot PR diff plus anything you haven't committed
yet. Untracked files are included (marked `U`).

The base branch is the first of `origin/HEAD`, `origin/main`, `origin/master`,
`main`, `master` that exists, unless you pass one to `:PrDiff`.

## Commands

| Command | Does |
| --- | --- |
| `:PrDiff [ref]` | Open the view (or refresh it if open). `ref` sets the base, e.g. `:PrDiff develop`, `:PrDiff HEAD~3`. Tab-completes branches. |
| `:PrDiffFile` | Open the selected file in a split to the right of the diff. |
| `:PrDiffClose` | Close the view. Files you opened from it stay open. |

Mapped in this config: `<leader>gp` → `:PrDiff`.

## Keys

File list:

| Key | Does |
| --- | --- |
| `<CR>` | Open the file's diff and move into it; on a folder, collapse or expand it |
| `o` | Show the file's diff but stay in the list; on a folder, collapse or expand it |
| `<` / `>` | Narrow / widen the file list by 5 columns (dragging the border works too) |
| `<Tab>` | Move to the diff |

Diff:

| Key | Does |
| --- | --- |
| `]c` / `[c` | Next / previous hunk |
| `<CR>` | Open the file at the line under the cursor |
| `<Tab>` | Move to the file list |

Both:

| Key | Does |
| --- | --- |
| `gf` | Open the file in a split on the right (reused for later files). From the diff it lands on the cursor's line; from the list, on the first change |
| `]f` / `[f` | Next / previous file, in tree order (wraps around) |
| `R` | Refresh after editing or committing |
| `q` | Close the view; opened files stay |
| `g?` | Show the keys |

## Setup

```lua
require("prdiff").setup({
  layout = "unified",  -- only "unified" exists so far; "split" is planned
  sidebar_width = 40,  -- starting width; a resized list keeps its width until you quit Neovim
  context = 3,         -- lines of context around each change
})
```

Syntax highlighting in the diff uses the Tree-sitter parser for the file's language
when one is installed. File icons come from `nvim-web-devicons` if it's installed.

## Highlights

Every group links to a standard one by default, so it follows your colorscheme.
Override any of them with `vim.api.nvim_set_hl`.

| Group | Default link |
| --- | --- |
| `PrDiffAdd` / `PrDiffAddNr` | `DiffAdd` |
| `PrDiffDelete` / `PrDiffDeleteNr` | `DiffDelete` |
| `PrDiffHunk` / `PrDiffHunkNr` | `DiffChange` |
| `PrDiffLineNr` | `LineNr` |
| `PrDiffSelected` | `Visual` |
| `PrDiffStatusAdded` / `PrDiffStatsAdd` | `Added` |
| `PrDiffStatusModified` | `Changed` |
| `PrDiffStatusDeleted` / `PrDiffStatsDel` | `Removed` |
| `PrDiffStatusRenamed` | `Special` |
| `PrDiffDir` | `Directory` |
| `PrDiffTitle` | `Title` |
| `PrDiffDeletedName` | `Comment` |

## Files

- `init.lua`: commands, layout, keys, tabline
- `git.lua`: base resolution, changed files, per-file diffs
- `sidebar.lua`: the file tree
- `unified.lua`: the unified diff layout and its line-number column
