# tag-finder.nvim

https://github.com/user-attachments/assets/0ba01455-6990-4877-8cc2-b959c40f0b2d

Tag the parts of your code that matter and find them instantly. tag-finder.nvim indexes lightweight inline tags (e.g., `@tags API, auth`) across your project and lets you jump to files by tag, browse all tags, and even run live grep limited to files matching a tag. Use it standalone or with Telescope for a slick picker experience.

## Why Tag Finder?
- Lightweight, language-agnostic tags you write in comments anywhere in your code.
- Zero boilerplate: save a file and it’s indexed automatically.
- Works great with Telescope: browse tags, pick files, or live-grep within a tag’s files.
- Project-aware: respects `.gitignore` (and `.tagfinderignore`) and ignores heavy folders/assets.

## How It Works
- Tag format: any line that matches the pattern (default `@tags%s*(.+)`) is parsed.
- Tags are comma-separated. Whitespace is trimmed. Case-sensitive by default.
- Index is stored as JSON at your project root (default: `.tag-finder-index.json`).
- Project root is detected via `git rev-parse --show-toplevel` or falls back to `cwd`.
- Automatic incremental indexing on `BufWritePost`; full index on startup (configurable).

Examples of inline tags:

```lua
-- @tags API, auth, users
```

```js
// @tags onboarding, ui, experiments
```

```python
# @tags data-pipeline, etl
```

## Installation

Using lazy.nvim:

```lua
{
  "rasjonell/tag-finder.nvim",
  -- if you want telescope enabled
  dependencies = {
    'nvim-telescope/telescope.nvim',
  },
  config = function()
    require("tag-finder").setup({
      -- see Configuration below for options
    })
  end,
}
```

## Configuration

Default config (you can override any field in `setup`):

```lua
require("tag-finder").setup({
  -- Index file location (relative to project root)
  index_file = ".tag-finder-index.json",

  -- Pattern to match tags on a line
  -- Default matches lines like: "@tags foo, bar"
  tag_pattern = "@tags%s*(.+)",

  -- Automatically run a full index when the project opens
  auto_index_on_open = true,

  -- Enable Telescope-powered pickers (if Telescope is installed)
  telescope_enabled = true,

  -- Always-ignored directories
  default_ignores = {
    ".git", "node_modules", ".cache", "dist", "build",
    ".next", ".nuxt", "target", "vendor",
  },

  -- File extensions to ignore entirely from indexing
  ignore_extensions = {
    ".png", ".jpg", ".jpeg", ".gif", ".svg", ".ico",
    ".woff", ".woff2", ".ttf", ".eot",
    ".mp4", ".mp3", ".wav",
    ".zip", ".tar", ".gz", ".pdf",
  },
})
```

Notes:
- Tag pattern is customizable. For example, to use `#tags:` in Python, set `tag_pattern = "#%s*tags:%s*(.+)"`.
- Ignores: reads `.gitignore` if present, else `.tagfinderignore` if present, plus `default_ignores` and `ignore_extensions`.

## Commands

- `:TagFinderIndex` — Full index of the project.
- `:TagFinderRebuild` — Clear index and rebuild from scratch.
- `:TagFinderListTags` — Show a quick popup listing tags with file counts.
- `:FindByTag {tag}` — Fuzzy-pick files containing the given tag (built-in UI).

Telescope (if enabled and installed):
- `:TelescopeFindByTag` — Choose a tag, then pick from its files with preview.
- `:TelescopeBrowseTags` — Browse all tags with counts; press <CR> to open file picker for a tag.
- `:TelescopeGrepByTag` — Choose a tag, then run `live_grep` restricted to that tag’s files.
- `:TelescopeFindByMultipleTags` — Multi-select tags with <CR>; press `<C-t>` to show files that match all selected tags (AND).

## Usage Without Telescope

```lua
-- init.lua
require("tag-finder").setup({
  telescope_enabled = false,
})

-- Optional keymaps
vim.keymap.set("n", "<leader>ti", ":TagFinderIndex<CR>", { desc = "TagFinder: Index project" })
vim.keymap.set("n", "<leader>tr", ":TagFinderRebuild<CR>", { desc = "TagFinder: Rebuild index" })
vim.keymap.set("n", "<leader>tl", ":TagFinderListTags<CR>", { desc = "TagFinder: List tags" })
vim.keymap.set("n", "<leader>tf", function()
  vim.ui.input({ prompt = "Tag: " }, function(input)
    if input and input ~= "" then
      require("tag-finder").find_by_tag(input)
    end
  end)
end, { desc = "TagFinder: Find by tag" })
```

## Usage With Telescope

```lua
-- init.lua
require("tag-finder").setup({
  telescope_enabled = true,
})

-- Optional keymaps
vim.keymap.set("n", "<leader>tt", ":TelescopeFindByTag<CR>", { desc = "TagFinder: Find by tag (picker)" })
vim.keymap.set("n", "<leader>tb", ":TelescopeBrowseTags<CR>", { desc = "TagFinder: Browse tags" })
vim.keymap.set("n", "<leader>tg", ":TelescopeGrepByTag<CR>", { desc = "TagFinder: Live grep by tag" })
vim.keymap.set("n", "<leader>tm", ":TelescopeFindByMultipleTags<CR>", { desc = "TagFinder: Files by multiple tags" })
```

Picker behavior highlights:
- Browse Tags: shows each tag, file count, and a small preview of representative files. <CR> opens a file picker scoped to that tag.
- Find by Tag: select a tag, then choose a file with preview; <CR> opens it.
- Live Grep by Tag: select a tag, then `live_grep` runs only within that tag’s files.
- Multiple Tags: press <CR> to toggle selection marks; press `<C-t>` to see files that contain all selected tags (AND).

## Tips
- Keep tags consistent (case-sensitive). For example, always use `API` or always `api`.
- Add `.tag-finder-index.json` to your `.gitignore` if you don’t want to commit it.
- Use high-level tags (`API`, `CLI`, `DB`, `Docs`, `FeatureX`) and specific ones (`auth`, `migrations`, `retry-logic`) together.

## Troubleshooting
- “No tags found” — ensure you’ve added lines like `@tags foo, bar` and run `:TagFinderIndex` (or keep `auto_index_on_open = true`).
- “Too many files indexed” — tweak `default_ignores`, add `.tagfinderignore`, and ensure your `ignore_extensions` fit your project.
- Telescope not found — either install `nvim-telescope/telescope.nvim` or set `telescope_enabled = false`.

## Internals (Quick Reference)
- Indexing: uses `find` if available, otherwise libuv traversal; stores JSON under project root.
- Ignores: merges `.gitignore`/`.tagfinderignore`-style rules, default folders, and extension skips.
- Search: provides AND/OR tag queries, a simple builtin picker, and Telescope pickers if enabled.

Enjoy fast, human-readable code navigation powered by your own tags.
