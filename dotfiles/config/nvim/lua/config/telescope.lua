local data = assert(vim.fn.stdpath "data") --[[@as string]]

require("telescope").setup {
  defaults = {},
  pickers = {
    find_files = {
      theme = "dropdown",
      previewer = false,
      layout_config = {
        width = 0.7,
        height = 0.7,
      },
    },
    oldfiles = {
      theme = "dropdown",
      sort_lastused = true,
      previewer = false,
      cwd_only = true,
      layout_config = {
        width = 0.7,
        height = 0.7,
      },
    },
    live_grep = {
      theme = "dropdown",
      previewer = false,
      layout_config = {
        width = 0.7,
        height = 0.7,
      },
    },
  },
  extensions = {
    wrap_results = true,
    fzf = {
      fuzzy = true,                    -- false will only do exact matching
      override_generic_sorter = true,  -- override the generic sorter
      override_file_sorter = true,     -- override the file sorter
      case_mode = "ignore_case",       -- or "ignore_case" or "respect_case"
                                       -- the default case_mode is "smart_case"
    },
    history = {
      path = vim.fs.joinpath(data, "telescope_history.sqlite3"),
      limit = 100,
    },
    ["ui-select"] = {
      require("telescope.themes").get_dropdown {},
    },
  },
}

require("telescope").load_extension("fzf")
require("telescope").load_extension("smart_history")
require("telescope").load_extension("ui-select")

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<c-p>', builtin.find_files, { desc = 'find files' })
vim.keymap.set('n', '<c-l>', builtin.oldfiles, { desc = 'recently opened files' })
vim.keymap.set('n', '<c-/>', builtin.live_grep, { desc = 'live grep' })
--vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
--vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
