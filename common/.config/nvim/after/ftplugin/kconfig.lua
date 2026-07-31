vim.o.shiftwidth = 2

vim.keymap.set('n', '<localleader>f', '<Cmd>!kconfigstyle --preset zephyr -w %<CR>', {
  buffer = 0,
  desc = 'Format',
})
