local M = {}

local ignore_patterns = nil

-- Initialize ignore patterns
function M.init()
  local tag_finder = require("tag-finder")
  local storage = require("storage")
  local project_root = storage.get_project_root()

  ignore_patterns = {}

  for _, pattern in ipairs(tag_finder.config.default_ignores) do
    table.insert(ignore_patterns, { pattern = pattern, type = "exact" })
  end

  local gitignore_path = project_root .. "/.gitignore"
  if M.file_exists(gitignore_path) then
    M.load_ignore_file(gitignore_path)
  else
    local project_ignore = project_root .. "/.tagfinderignore"
    if M.file_exists(project_ignore) then
      M.load_ignore_file(project_ignore)
    end
  end
end

-- Check if file exists
function M.file_exists(path)
  local file = io.open(path, "r")
  if file then
    file:close()
    return true
  end
  return false
end

-- Load ignore file
function M.load_ignore_file(filepath)
  local file = io.open(filepath, "r")
  if not file then return end

  for line in file:lines() do
    local trimmed = line:match("^%s*(.-)%s*$")

    if trimmed ~= "" and not trimmed:match("^#") then
      local pattern_info = M.parse_gitignore_pattern(trimmed)
      if pattern_info then
        table.insert(ignore_patterns, pattern_info)
      end
    end
  end

  file:close()
end

-- Parse gitignore pattern to Lua pattern
function M.parse_gitignore_pattern(pattern)
  pattern = pattern:match("^%s*(.-)%s*$")

  -- Handle negation
  local negate = false
  if pattern:match("^!") then
    negate = true
    pattern = pattern:sub(2)
  end

  -- Trailing slash means directory only
  local dir_only = false
  if pattern:match("/$") then
    dir_only = true
    pattern = pattern:sub(1, -2)
  end

  -- Leading slash means match from root
  local from_root = false
  if pattern:match("^/") then
    from_root = true
    pattern = pattern:sub(2)
  end

  return {
    original = pattern,
    pattern = pattern,
    type = "gitignore",
    dir_only = dir_only,
    from_root = from_root,
    negate = negate
  }
end

-- Check if path should be ignored
function M.should_ignore(filepath)
  if not ignore_patterns then
    M.init()
  end

  filepath = filepath:gsub("^%./", "")

  local should_ignore_result = false

  for _, pattern_info in ipairs(ignore_patterns) do
    local matches = false

    if pattern_info.type == "exact" then
      local pattern = pattern_info.pattern
      if filepath == pattern or filepath:match("^" .. vim.pesc(pattern) .. "/") then
        matches = true
      end
    elseif pattern_info.type == "gitignore" then
      local pattern = pattern_info.pattern

      -- @tags Storage

      if pattern:match("%*") then
        local lua_pattern = pattern:gsub("%.", "%%.")
        lua_pattern = lua_pattern:gsub("%*%*", ".-")
        lua_pattern = lua_pattern:gsub("%*", "[^/]*")

        if pattern_info.from_root then
          matches = filepath:match("^" .. lua_pattern)
        else
          matches = filepath:match(lua_pattern) or filepath:match("/" .. lua_pattern)
        end
      else
        -- Exact match
        if pattern_info.from_root then
          matches = filepath == pattern or filepath:match("^" .. vim.pesc(pattern) .. "/")
        else
          matches = filepath == pattern or
              filepath:match("^" .. vim.pesc(pattern) .. "/") or
              filepath:match("/" .. vim.pesc(pattern) .. "/") or
              filepath:match("/" .. vim.pesc(pattern) .. "$")
        end
      end
    end

    if matches then
      if pattern_info.negate then
        should_ignore_result = false
      else
        should_ignore_result = true
      end
    end
  end

  return should_ignore_result
end

return M
