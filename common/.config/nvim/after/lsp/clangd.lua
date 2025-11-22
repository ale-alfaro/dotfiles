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
    '--pretty',
    '--enable-config',
    '--background-index',
    '--log=error',
    -- optional:
    -- "--log=verbose",
    -- '--compile-commands-dir=${workspaceFolder}/build',
    -- Zephyr specific
    -- '--query-driver=${env:ZEPHYR_SDK_INSTALL_DIR}/arm-zephyr-eabi/bin/arm-zephyr-eabi-*',
    --
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
