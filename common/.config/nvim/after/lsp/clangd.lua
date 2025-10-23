return {
  filetypes = { 'c', 'cpp' },
  root_markers = {
    '.clangd',
    '.clang-tidy',
    '.clang-format',
    'compile_commands.json',
  },
  capabilities = {
    offsetEncoding = { 'utf-16' },
  },
  cmd = {
    'clangd',
    '--background-index',
    '--clang-tidy',
    '--header-insertion=iwyu',
    '--completion-style=detailed',
    '--function-arg-placeholders',
    '--fallback-style=llvm',
  },
  init_options = {
    usePlaceholders = true,
    completeUnimported = true,
    clangdFileStatus = true,
  },
  on_attach = function(client, buf_id)
    _G.keymaps_define {
      { lhs = '<leader>ch', rhs = '<cmd>ClangdSwitchSourceHeader<cr>', { desc = 'Switch Source/Header (C/C++)' } },
    }
  end,
}
