require("telescope").setup {
  defaults = {
    layout_strategy = 'horizontal',
    layout_config = { preview_width = 0 },
  },
  pickers = {
    buffers = {
      sort_lastused = true,
      theme = "dropdown",
      previewer = false,
    }
  }
}
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<c-p>', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<c-l>', builtin.buffers, { desc = 'Telescope recently opened files' }) --{ sort_lastused=true, ignore_current_buffer=true })
--vim.keymap.set('n', '<c-l>', builtin.buffers, { sort_lastused=true, ignore_current_buffer=true })
--vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
--vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
--vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
--vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
