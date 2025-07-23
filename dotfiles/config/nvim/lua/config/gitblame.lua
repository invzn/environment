local opt = { noremap = true, silent = true }
vim.keymap.set('n', 'gb', vim.cmd.GitBlameToggle, opt)
