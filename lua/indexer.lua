local M = {}

-- Index entire project
function M.index_project()
  local storage = require("storage")
  local parser = require("parser")
  local ignore = require("ignore")

  local project_root = storage.get_project_root()

  ignore.init()

  local files = M.get_all_files(project_root)

  local indexed_count = 0

  for _, filepath in ipairs(files) do
    local rel_path = filepath:gsub("^" .. vim.pesc(project_root .. "/"), "")

    if not ignore.should_ignore(rel_path) and parser.should_index_file(filepath) then
      M.index_file(filepath)
      indexed_count = indexed_count + 1
    end
  end

  return indexed_count
end

-- Index single file
function M.index_file(filepath)
  local storage = require("storage")
  local parser = require("parser")

  local file = io.open(filepath, "r")
  if not file then
    storage.remove_file(filepath)
    return
  end
  file:close()

  local tags = parser.extract_tags(filepath)
  local mtime = parser.get_mtime(filepath)

  storage.update_file(filepath, tags, mtime)
end

-- Get all files recursively
function M.get_all_files(root)
  local files = {}

  local handle = io.popen('find "' .. root .. '" -type f 2>/dev/null')
  if handle then
    for line in handle:lines() do
      table.insert(files, line)
    end
    handle:close()
  else
    M.scan_directory(root, files)
  end

  return files
end

function M.scan_directory(dir, files)
  local handle = vim.loop.fs_scandir(dir)
  if not handle then return end

  while true do
    local name, type = vim.loop.fs_scandir_next(handle)
    if not name then break end

    local path = dir .. "/" .. name

    if type == "directory" then
      M.scan_directory(path, files)
    elseif type == "file" then
      table.insert(files, path)
    end
  end
end

return M
