local M = {}

-- Find files by tag
-- @tags Storage
function M.find_by_tag(tag)
  local storage = require("storage")
  return storage.get_files_by_tag(tag)
end

-- Find files by multiple tags (AND operation)
function M.find_by_tags_and(tags)
  local storage = require("storage")

  if #tags == 0 then return {} end
  if #tags == 1 then return storage.get_files_by_tag(tags[1]) end

  local result = {}
  local first_files = storage.get_files_by_tag(tags[1])

  for _, file in ipairs(first_files) do
    result[file] = true
  end

  for i = 2, #tags do
    local tag_files = storage.get_files_by_tag(tags[i])
    local tag_set = {}
    for _, file in ipairs(tag_files) do
      tag_set[file] = true
    end

    for file, _ in pairs(result) do
      if not tag_set[file] then
        result[file] = nil
      end
    end
  end

  local files = {}
  for file, _ in pairs(result) do
    table.insert(files, file)
  end

  return files
end

-- Find files by multiple tags (OR operation)
function M.find_by_tags_or(tags)
  local storage = require("storage")
  local result = {}
  local seen = {}

  for _, tag in ipairs(tags) do
    local files = storage.get_files_by_tag(tag)
    for _, file in ipairs(files) do
      if not seen[file] then
        table.insert(result, file)
        seen[file] = true
      end
    end
  end

  return result
end

-- Get all tags
function M.get_all_tags()
  local storage = require("storage")
  return storage.get_all_tags()
end

-- Fuzzy search tags
function M.fuzzy_search_tags(query)
  local all_tags = M.get_all_tags()
  local matches = {}

  query = query:lower()

  for _, tag in ipairs(all_tags) do
    if tag:lower():match(vim.pesc(query)) then
      table.insert(matches, tag)
    end
  end

  return matches
end

return M
