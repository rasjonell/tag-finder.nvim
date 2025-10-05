local M = {}

-- Default configuration
M.config = {
  -- Index file location (relative to project root)
  index_file = ".tag-finder-index.json",
  -- Tag pattern to search for
  tag_pattern = "@tags%s*(.+)",
  -- Auto-index on project open
  auto_index_on_open = true,
  -- Telescope Integration Enabled
  telescope_enabled = true,
  -- Directories to always ignore
  default_ignores = {
    ".git", "node_modules", ".cache", "dist", "build",
    ".next", ".nuxt", "target", "vendor"
  },
  -- File extensions to ignore
  ignore_extensions = {
    ".png", ".jpg", ".jpeg", ".gif", ".svg", ".ico",
    ".woff", ".woff2", ".ttf", ".eot",
    ".mp4", ".mp3", ".wav",
    ".zip", ".tar", ".gz", ".pdf"
  }
}

M.storage = nil
M.indexer = nil
M.parser = nil
M.search = nil
M.ignore = nil
M.telescope = nil

-- Setup function
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  M.storage = require("storage")
  M.indexer = require("indexer")
  M.parser = require("parser")
  M.search = require("search")
  M.ignore = require("ignore")

  M.storage.init(M.config)

  local has_telescope = pcall(require, 'telescope')
  print(string.format("Has Telescope? %s", has_telescope))
  if has_telescope and M.config.telescope_enabled then
    M.telescope = require("tag-finder-telescope")
  end

  M.setup_autocmds()

  if M.config.auto_index_on_open then
    vim.schedule(function()
      M.index_project()
    end)
  end

  return M
end

-- Setup autocommands
function M.setup_autocmds()
  local group = vim.api.nvim_create_augroup("TagFinder", { clear = true })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = "*",
    callback = function(args)
      M.index_file(args.file)
    end
  })
end

-- Index entire project
function M.index_project()
  if not M.indexer then
    vim.notify("Tag Finder not initialized. Call setup() first.", vim.log.levels.ERROR)
    return
  end

  vim.notify("Indexing project...", vim.log.levels.INFO)
  vim.schedule(function()
    local success, err = pcall(M.indexer.index_project)
    if success then
      vim.notify("Project indexed successfully!", vim.log.levels.INFO)
    else
      vim.notify("Error indexing project: " .. tostring(err), vim.log.levels.ERROR)
    end
  end)
end

-- Index single file
function M.index_file(filepath)
  if not M.indexer then return end

  local project_root = M.storage.get_project_root()
  local rel_path = filepath:gsub("^" .. vim.pesc(project_root .. "/"), "")

  if M.ignore.should_ignore(rel_path) then
    return
  end

  M.indexer.index_file(filepath)
end

-- Find files by tag
function M.find_by_tag(tag)
  if not M.search then
    vim.notify("Tag Finder not initialized. Call setup() first.", vim.log.levels.ERROR)
    return
  end

  local files = M.search.find_by_tag(tag)

  if #files == 0 then
    vim.notify("No files found with tag: " .. tag, vim.log.levels.WARN)
    return
  end

  -- Simple picker using vim.ui.select
  vim.ui.select(files, {
    prompt = "Files with tag '" .. tag .. "':",
    format_item = function(item)
      return item
    end
  }, function(choice)
    if choice then
      local project_root = M.storage.get_project_root()
      vim.cmd("edit " .. project_root .. "/" .. choice)
    end
  end)
end

-- Get all tags
function M.get_all_tags()
  if not M.search then return {} end
  return M.search.get_all_tags()
end

-- Rebuild index
function M.rebuild_index()
  if not M.storage then return end
  M.storage.clear_index()
  M.index_project()
end

-- List all tags with file counts
function M.list_all_tags()
  if not M.storage then
    vim.notify("Tag Finder not initialized.", vim.log.levels.ERROR)
    return
  end

  local index = M.storage.get_index()
  if not index or not index.tags then
    vim.notify("No tags found. Index your project first.", vim.log.levels.WARN)
    return
  end

  local tags_info = {}
  for tag, files in pairs(index.tags) do
    table.insert(tags_info, {
      tag = tag,
      count = #files
    })
  end

  table.sort(tags_info, function(a, b)
    return a.count > b.count
  end)

  local lines = { "Available Tags:", "" }
  for _, info in ipairs(tags_info) do
    table.insert(lines, string.format("  %-30s (%d files)", info.tag, info.count))
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

  local width = 50
  local height = math.min(#lines + 2, 30)
  vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
    style = 'minimal',
    border = 'rounded',
    title = ' Tag Finder ',
    title_pos = 'center'
  })

  -- Close on q or ESC
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':close<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<ESC>', ':close<CR>', { noremap = true, silent = true })
end

return M
