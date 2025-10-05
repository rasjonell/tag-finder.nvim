local M = {}

-- Extract tags from file content
-- @tags Parser
function M.extract_tags(filepath)
  local file = io.open(filepath, "r")
  if not file then
    return {}
  end

  local content = file:read("*all")
  file:close()

  local tag_finder = require("tag-finder")
  local pattern = tag_finder.config.tag_pattern

  local tags = {}
  local seen = {}

  for line in content:gmatch("[^\r\n]+") do
    local tag_string = line:match(pattern)
    if tag_string then
      for tag in tag_string:gmatch("[^,]+") do
        tag = M.trim(tag)
        if tag ~= "" and not seen[tag] then
          table.insert(tags, tag)
          seen[tag] = true
        end
      end
    end
  end

  return tags
end

-- Trim whitespace from string
function M.trim(s)
  return s:match("^%s*(.-)%s*$")
end

-- Get file modification time
function M.get_mtime(filepath)
  local stat = vim.loop.fs_stat(filepath)
  if stat then
    return stat.mtime.sec
  end
  return nil
end

-- Check if file should be indexed based on extension
function M.should_index_file(filepath)
  local tag_finder = require("tag-finder")
  local config = tag_finder.config

  for _, ext in ipairs(config.ignore_extensions) do
    if filepath:match(vim.pesc(ext) .. "$") then
      return false
    end
  end

  return true
end

return M
