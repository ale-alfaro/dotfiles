---@return vim.lsp.Config
return {
  filetypes = { 'c', 'cpp' },
  root_markers = {
    'compile_commands.json',
    '.clangd',
    '.clang-tidy',
    '.clang-format',
  },
  cmd = {
    'clangd',
    '--background-index',
    '--pretty',
    '--log=verbose',
    '--enable-config',
    '--clang-tidy',
    '--header-insertion=iwyu',
    '--completion-style=detailed',
    '--offset-encoding=utf-16',
    '--fallback-style=llvm',
  },
  init_options = {
    -- usePlaceholders = true,
    -- completeUnimported = true,
    clangdFileStatus = true,
  },
}
