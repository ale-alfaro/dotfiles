vim.cmd [[ setlocal foldmethod=expr foldexpr=v:lua.MiniGit.diff_foldexpr() ]]

vim.keymap.set({ 'n', 'x' }, '<Leader>gs', '<Cmd>lua MiniGit.show_at_cursor()<CR>', { desc = 'Show at cursor' })
