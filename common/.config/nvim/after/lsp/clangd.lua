local function create_cmd()
  clang_cmd = {
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
  }
  local zephyr_toolchain_dir = vim.fn.getenv 'ZEPHYR_SDK_INSTALL_DIR'
  if zephyr_toolchain_dir ~= vim.v.null and vim.uv.fs_stat(zephyr_toolchain_dir) then
    clang_cmd[#clang_cmd + 1] = '--query-driver=' .. zephyr_toolchain_dir .. '/arm-zephyr-eabi/bin/arm-zephyr-eabi-*'
  end
  return clang_cmd
end
---@return vim.lsp.Config
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
  cmd = create_cmd(),
  init_options = {
    usePlaceholders = true,
    completeUnimported = true,
    clangdFileStatus = true,
  },
}
