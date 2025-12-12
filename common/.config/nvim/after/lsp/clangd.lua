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
  -- local zephyr_cross_tc = {'arm-zephyr-eabi-gcc','x86_64-zephyr-elf'}
  -- vim.fn.exepath()
  -- local zephyr_toolchain_dir = vim.fn.getenv 'ZEPHYR_TOOLCHAIN_DIR'
  -- if zephyr_toolchain_dir ~= vim.v.null and vim.uv.fs_stat(zephyr_toolchain_dir) then
  --   local compiler = zephyr_toolchain_dir .. '/arm-zephyr-eabi/bin/arm-zephyr-eabi-*'
  --   if vim.fn.glob(compiler) then
  --     -- _G.info('Clangd query-driver ' .. zephyr_toolchain_dir)
  --     -- vim.print(compiler)
  --     config.cmd[#config.cmd + 1] = '--query-driver=' .. zephyr_toolchain_dir .. '/arm-zephyr-eabi/bin/arm-zephyr-eabi-*'
  --   end
  -- end
  -- local cwd = vim.fn.getcwd()
  -- local files_found = vim.fs.find { 'testcase.yml', 'sample.yml', 'app.overlay', 'prj.conf', 'CMakeLists.txt' }
  -- if #files_found > 0 then
  --   local build_dir = vim.fn.glob(vim.fs.joinpath(cwd, 'build_*')) or vim.fs.joinpath(cwd, 'build')
  --   if vim.uv.fs_stat(vim.fs.normalize(build_dir)) then
  --     local compdb = vim.fn.glob(vim.fs.joinpath(build_dir, 'compile_commands.json'))
  --     if vim.uv.fs_stat(compdb) then
  --       local compdb_dir = vim.fs.abspath(vim.fs.dirname(compdb))
  --       _G.info('Setting compdb_dir to ' .. compdb_dir)
  --
  --       config.cmd[#config.cmd + 1] = '--compile-commands-dir=' .. compdb_dir
  --     end
  --   end
  -- end
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
    -- usePlaceholders = true,
    -- completeUnimported = true,
    clangdFileStatus = true,
  },
}
