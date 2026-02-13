if not VimRc.clangd_keymaps_set then
  KEYS.define {
    { model = 'n', lhs = '<leader>p', rhs = ':ClangdSwitchSourceHeader<CR>', { desc = 'Switch between source and header' } },
  }
  VimRc.clangd_keymaps_set = true
end
