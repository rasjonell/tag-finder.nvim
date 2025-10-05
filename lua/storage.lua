local M = {}

local config = nil
local index = nil
local project_root = nil
local index_path = nil

-- @tags Storage, JSON
function M.init(conf)
  config = conf
  project_root = M.get_project_root()
  index_path = project_root .. "/" .. config.index_file
  M.load_index()
end

function M.get_project_root()
  if project_root then return project_root end

  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  if vim.v.shell_error == 0 and git_root then
    project_root = git_root
    return project_root
  end

  project_root = vim.fn.getcwd()
  return project_root
end

function M.load_index()
  local file = io.open(index_path, "r")
  if not file then
    index = M.create_empty_index()
    return index
  end

  local content = file:read("*a")
  file:close()

  local ok, decoded = pcall(vim.json.decode, content)
  if ok then
    index = decoded
  else
    vim.notify("Failed to parse index file, creating new index", vim.log.levels.WARN)
    index = M.create_empty_index()
  end

  return index
end

function M.save_index()
  if not index then return end

  local content = vim.json.encode(index)
  local file = io.open(index_path, "w")
  if not file then
    vim.notify("Failed to write index file: " .. index_path, vim.log.levels.ERROR)
    return
  end

  file:write(content)
  file:close()
end

function M.create_empty_index()
  return {
    version = 1,
    project_root = M.get_project_root(),
    last_full_index = os.time(),
    files = {},
    tags = {},
  }
end

function M.get_index()
  return index
end

function M.update_file(filepath, tags, mtime)
  if not index then return end

  local rel_path = filepath:gsub("^" .. vim.pesc(project_root .. "/"), "")

  if index.files[rel_path] then
    for _, old_tag in ipairs(index.files[rel_path].tags or {}) do
      if index.tags[old_tag] then
        index.tags[old_tag] = vim.tbl_filter(function(f)
          return f ~= rel_path
        end, index.tags[old_tag])

        if #index.tags[old_tag] == 0 then
          index.tags[old_tag] = nil
        end
      end
    end
  end

  if #tags > 0 then
    index.files[rel_path] = {
      tags = tags,
      last_modified = mtime or os.time()
    }

    for _, tag in ipairs(tags) do
      if not index.tags[tag] then
        index.tags[tag] = {}
      end

      local found = false
      for _, f in ipairs(index.tags[tag]) do
        if f == rel_path then
          found = true
          break
        end
      end

      if not found then
        table.insert(index.tags[tag], rel_path)
      end
    end
  else
    index.files[rel_path] = nil
  end

  M.save_index()
end

function M.remove_files(filepath)
  if not index then return end

  local rel_path = filepath:gsub("^" .. vim.pesc(project_root .. "/"), "")

  if index.files[rel_path] then
    for _, tag in ipairs(index.files[rel_path].tags or {}) do
      if index.tags[tag] then
        index.tags[tag] = vim.tbl_filter(function(f)
          return f ~= rel_path
        end, index.tags[tag])

        if #index.tags[tag] == 0 then
          index.tags[tag] = nil
        end
      end
    end
  end

  index.files[rel_path] = nil
  M.save_index()
end

function M.get_files_by_tag(tag)
  if not index or not index.tags[tag] then
    return {}
  end
  return index.tags[tag]
end

function M.get_all_tags()
  if not index then return {} end

  local tags = {}
  for tag, _ in pairs(index.tags) do
    table.insert(tags, tag)
  end
  table.sort(tags)
  return tags
end

function M.clear_index()
  index = M.create_empty_index()
  M.save_index()
end

return M
