local has_telescope = pcall(require, 'telescope')
if not has_telescope then
  error('tag-finder.nvim requires telescope.nvim')
end

local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local entry_display = require('telescope.pickers.entry_display')

local M = {}

-- Find files by tag using Telescope
-- @tags Telescope
function M.find_by_tag(opts)
  opts = opts or {}

  local storage = require('storage')
  local search = require('search')

  local all_tags = search.get_all_tags()

  if #all_tags == 0 then
    vim.notify('No tags found. Index your project first with :TagFinderIndex', vim.log.levels.WARN)
    return
  end

  pickers.new(opts, {
    prompt_title = 'Find by Tag',
    finder = finders.new_table({
      results = all_tags,
      entry_maker = function(tag)
        local files = storage.get_files_by_tag(tag)
        return {
          value = tag,
          display = string.format('%-30s (%d files)', tag, #files),
          ordinal = tag,
          files = files,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        if selection then
          M.show_files_for_tag(selection.value, opts)
        end
      end)
      return true
    end,
  }):find()
end

-- Show files for a specific tag
function M.show_files_for_tag(tag, opts)
  opts = opts or {}

  local storage = require('storage')
  local files = storage.get_files_by_tag(tag)
  local project_root = storage.get_project_root()

  if #files == 0 then
    vim.notify('No files found with tag: ' .. tag, vim.log.levels.WARN)
    return
  end

  pickers.new(opts, {
    prompt_title = 'Files with tag: ' .. tag,
    finder = finders.new_table({
      results = files,
      entry_maker = function(file)
        return {
          value = file,
          display = file,
          ordinal = file,
          path = project_root .. '/' .. file,
        }
      end,
    }),
    previewer = conf.file_previewer(opts),
    sorter = conf.file_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        if selection then
          vim.cmd('edit ' .. selection.path)
        end
      end)
      return true
    end,
  }):find()
end

-- Browse all tags with file counts
function M.browse_tags(opts)
  opts = opts or {}

  local storage = require('storage')
  local search = require('search')

  local all_tags = search.get_all_tags()

  if #all_tags == 0 then
    vim.notify('No tags found. Index your project first with :TagFinderIndex', vim.log.levels.WARN)
    return
  end

  local displayer = entry_display.create({
    separator = ' ',
    items = {
      { width = 40 },
      { width = 10 },
      { remaining = true },
    },
  })

  local make_display = function(entry)
    return displayer({
      entry.tag,
      { entry.count .. ' files', 'TelescopeResultsNumber' },
      { entry.preview,           'Comment' },
    })
  end

  pickers.new(opts, {
    prompt_title = 'Browse Tags',
    finder = finders.new_table({
      results = all_tags,
      entry_maker = function(tag)
        local files = storage.get_files_by_tag(tag)
        local preview = ''
        if #files > 0 then
          preview = files[1]
          if #files > 1 then
            preview = preview .. ', ...'
          end
        end

        return {
          value = tag,
          display = make_display,
          ordinal = tag,
          tag = tag,
          count = #files,
          preview = preview,
          files = files,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        if selection then
          M.show_files_for_tag(selection.tag, opts)
        end
      end)
      return true
    end,
  }):find()
end

-- Live grep with tag filtering
function M.live_grep_by_tag(opts)
  opts = opts or {}

  local storage = require('storage')
  local search = require('search')

  local all_tags = search.get_all_tags()

  if #all_tags == 0 then
    vim.notify('No tags found. Index your project first with :TagFinderIndex', vim.log.levels.WARN)
    return
  end

  pickers.new(opts, {
    prompt_title = 'Select Tag for Live Grep',
    finder = finders.new_table({
      results = all_tags,
      entry_maker = function(tag)
        local files = storage.get_files_by_tag(tag)
        return {
          value = tag,
          display = string.format('%-30s (%d files)', tag, #files),
          ordinal = tag,
          files = files,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        if selection then
          local project_root = storage.get_project_root()
          local files = {}
          for _, file in ipairs(selection.files) do
            table.insert(files, project_root .. '/' .. file)
          end

          require('telescope.builtin').live_grep({
            search_dirs = files,
            prompt_title = 'Live Grep (tag: ' .. selection.value .. ')',
          })
        end
      end)
      return true
    end,
  }):find()
end

-- Search for files with multiple tags (AND operation)
function M.find_by_multiple_tags(opts)
  opts = opts or {}

  local storage = require('storage')
  local search = require('search')
  local all_tags = search.get_all_tags()

  if #all_tags == 0 then
    vim.notify('No tags found. Index your project first with :TagFinderIndex', vim.log.levels.WARN)
    return
  end

  local selected_tags = {}
  local project_root = storage.get_project_root()

  local function show_picker()
    pickers.new(opts, {
      prompt_title = 'Select Tags (Press <C-t> when done)',
      finder = finders.new_table({
        results = all_tags,
        entry_maker = function(tag)
          local files = storage.get_files_by_tag(tag)
          local is_selected = vim.tbl_contains(selected_tags, tag)
          local prefix = is_selected and '✓ ' or '  '

          return {
            value = tag,
            display = string.format('%s%-30s (%d files)', prefix, tag, #files),
            ordinal = tag,
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        -- Toggle tag selection
        local toggle_tag = function()
          local selection = action_state.get_selected_entry()
          if selection then
            local tag = selection.value
            local idx = nil
            for i, t in ipairs(selected_tags) do
              if t == tag then
                idx = i
                break
              end
            end

            if idx then
              table.remove(selected_tags, idx)
            else
              table.insert(selected_tags, tag)
            end

            actions.close(prompt_bufnr)
            show_picker()
          end
        end

        local show_results = function()
          actions.close(prompt_bufnr)

          if #selected_tags == 0 then
            vim.notify('No tags selected', vim.log.levels.WARN)
            return
          end

          local files = search.find_by_tags_and(selected_tags)

          if #files == 0 then
            vim.notify('No files found with all selected tags', vim.log.levels.WARN)
            return
          end

          pickers.new(opts, {
            prompt_title = 'Files with tags: ' .. table.concat(selected_tags, ', '),
            finder = finders.new_table({
              results = files,
              entry_maker = function(file)
                return {
                  value = file,
                  display = file,
                  ordinal = file,
                  path = project_root .. '/' .. file,
                }
              end,
            }),
            previewer = conf.file_previewer(opts),
            sorter = conf.file_sorter(opts),
          }):find()
        end

        map('i', '<CR>', toggle_tag)
        map('n', '<CR>', toggle_tag)
        map('i', '<C-t>', show_results)
        map('n', '<C-t>', show_results)

        return true
      end,
    }):find()
  end

  show_picker()
end

return M
