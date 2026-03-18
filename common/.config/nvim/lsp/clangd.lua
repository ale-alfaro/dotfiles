local function create_cmd(_, config)
  config.cmd = {
    'clangd',
    '--background-index',
    '--enable-config',
    '--clang-tidy',
    '--header-insertion=iwyu',
    '--completion-style=detailed',
    '--fallback-style=llvm',
    '--log=error',
  }
  local envs = vim.fn.environ()
  local compiler = vim.fn.executable 'arm-zephyr-eabi-gcc' and vim.fn.exepath 'arm-zephyr-eabi-gcc' or ''
  local query_driver_flag = nil
  -- 1. If ZEPHYR_SDK_INSTALL_DIR is set glob to find the arm-zephyr-eabi-gcc within the toolchain
  if envs['ZEPHYR_SDK_INSTALL_DIR'] ~= nil then
    query_driver_flag = string.format('--query-driver=%s/**/arm-zephyr-eabi-g*', envs['ZEPHYR_SDK_INSTALL_DIR'])
  -- 2. Otherwise check if the arm-zephyr-eabi-gcc was found as an executable it PATH and use the exepath result for the exact location
  elseif type(compiler) == 'string' and vim.uv.fs_stat(compiler) then
    query_driver_flag = '--query-driver=' .. compiler:gsub('gcc$', 'g*')
  else
    VimRc.warn "Can't find compiler to query or is not a valid path"
  end
  if query_driver_flag then
    VimRc.info('Clangd adding flag ' .. query_driver_flag)
    config.cmd[#config.cmd + 1] = query_driver_flag
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
