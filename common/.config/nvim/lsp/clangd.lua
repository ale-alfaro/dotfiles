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
  local zephyr_toolchain_variant_env = vim.fn.getenv 'ZEPHYR_TOOLCHAIN_VARIANT'
  local toolchain_variant = zephyr_toolchain_variant_env ~= vim.v.null and zephyr_toolchain_variant_env or 'zephyr'
  if toolchain_variant ~= 'zephyr|host|llvm' then
    if toolchain_variant == 'zephyr' then
      local compiler = vim.fn.executable 'arm-zephyr-eabi-g++' and vim.fn.exepath 'arm-zephyr-eabi-g++' or ''
      if compiler then
        VimRc.info 'Clangd query-driver'
        vim.print(compiler)
        config.cmd[#config.cmd + 1] = '--query-driver=' .. compiler
      end
    end
  end
  -- local zephyr_cross_tc = {'arm-zephyr-eabi-gcc','x86_64-zephyr-elf'}
  -- if vim.fn.executable("rg") == 1 then
  --
  -- end
  -- local cwd = vim.fn.getcwd()
  -- local files_found = vim.fs.find { 'testcase.yml', 'sample.yml', 'app.overlay', 'prj.conf', 'CMakeLists.txt' }
  -- if #files_found > 0 then
  --   local build_dir = vim.fn.glob(vim.fs.joinpath(cwd, 'build_*')) or vim.fs.joinpath(cwd, 'build')
  --   if vim.uv.fs_stat(vim.fs.normalize(build_dir)) then
  --     local compdb = vim.fn.glob(vim.fs.joinpath(build_dir, 'compile_commands.json'))
  --     if vim.uv.fs_stat(compdb) then
  --       local compdb_dir = vim.fs.abspath(vim.fs.dirname(compdb))
  --       VimRc.info('Setting compdb_dir to ' .. compdb_dir)
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
