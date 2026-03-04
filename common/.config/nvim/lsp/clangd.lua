local function create_cmd(_, config)
  config.cmd = {
    'clangd',
    '--background-index',
    '--enable-config',
    '--clang-tidy',
    '--header-insertion=iwyu',
    '--completion-style=detailed',
    '--fallback-style=llvm',
  }
  local compiler = vim.fn.executable 'arm-zephyr-eabi-gcc' and vim.fn.exepath 'arm-zephyr-eabi-gcc' or ''
  if type(compiler) == 'string' and vim.uv.fs_stat(compiler) then
    VimRc.info('Clangd query-driver' .. compiler)
    config.cmd[#config.cmd + 1] = '--query-driver=' .. compiler:gsub('gcc$', 'g*')
  else
    VimRc.warn "Can't find compiler to query or is not a valid path"
  end
  local clangd_debug_mode = vim.fn.getenv 'CLANGD_DEBUG'
  if clangd_debug_mode ~= vim.v.null then
    vim.tbl_extend('force', config.cmd, {
      '--pretty',
      '--log=verbose',
    })
  else
    vim.tbl_extend('force', config.cmd, {
      '--log=error',
    })
  end
end
---@return vim.lsp.Config
return {
  filetypes = { 'c', 'cpp' },
  root_markers = {
    'compile_commands.json',
    '.clangd',
    '.clang-tidy',
    '.clang-format',
  },
  before_init = create_cmd,
  init_options = {
    usePlaceholders = true,
    completeUnimported = true,
    clangdFileStatus = true,
  },
}
