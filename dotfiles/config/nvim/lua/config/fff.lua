require("fff").setup({
  width = 0.8,
  height = 0.8,
  preview_width = 0.0,
  prompt = '🪿 ',
  title = 'FFF Files',
  max_results = 60, -- Maximum number of search results
  max_threads = 4,  -- Maximum threads for fuzzy search

  keymaps = {
    close = '<Esc>',
    select = '<CR>',
    select_split = '<C-s>',
    select_vsplit = '<C-v>',
    select_tab = '<C-t>',
    move_up = { '<Up>', '<C-p>' },
    move_down = { '<Down>', '<C-n>' },
    preview_scroll_up = '<C-u>',
    preview_scroll_down = '<C-d>',
  },

  hl = {
    border = 'FloatBorder',
    normal = 'Normal',
    cursor = 'CursorLine',
    matched = 'IncSearch',
    title = 'Title',
    prompt = 'Question',
    active_file = 'Visual',
    frecency = 'Number',
    debug = 'Comment',
  },
})
