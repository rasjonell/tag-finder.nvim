if exists('g:loaded_tag_finder')
  finish
endif
let g:loaded_tag_finder = 1

" Helper function for tag completion (defined in plugin file is OK)
function! s:complete_tags(ArgLead, CmdLine, CursorPos)
  return luaeval('require("tag-finder").get_all_tags()')
endfunction

" Command to find files by tag
command! -nargs=1 -complete=customlist,s:complete_tags FindByTag lua require('tag-finder').find_by_tag(<q-args>)

" Command to rebuild entire index
command! TagFinderRebuild lua require('tag-finder').rebuild_index()

" Command to manually index project
command! TagFinderIndex lua require('tag-finder').index_project()

" Command to list all tags
command! TagFinderListTags lua require('tag-finder').list_all_tags()


" Telescope commands (if telescope is available)
command! TelescopeFindByTag lua require('tag-finder').setup().telescope.find_by_tag()
command! TelescopeBrowseTags lua require('tag-finder').setup().telescope.browse_tags()
command! TelescopeGrepByTag lua require('tag-finder').telescope.live_grep_by_tag()
command! TelescopeFindByMultipleTags lua require('tag-finder').telescope.find_by_multiple_tags()
