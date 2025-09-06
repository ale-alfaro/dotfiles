return {
  'stevearc/oil.nvim',
  opts = {
    columns = {
      'icon',
    },
    keymaps = {
      ['<C-h>'] = false,
      ['<C-l>'] = false,
      ['<C-r>'] = 'refresh',
      ['<leader>h'] = 'toggle_hidden',
    },
    use_default_keymaps = true,
    view_options = {
      show_hidden = true,
      natural_order = true,
    },
  },
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function(_, opts)
    require('oil').setup(opts)
    vim.keymap.set('n', '\\', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
  end,
}

