---@alias BindingType
---| 'Zephyr'
---| 'DevicetreeOrg'
---| 'Linux'

--- @class DtsLspContext
---@field ctxName? string | number;
---@field dtsFile string;
---@field cwd? string;
---@field includePaths? string[];
---@field overlays? string[];
---@field zephyrBindings? string[];
---@field bindingType? BindingType;
---@field deviceOrgTreeBindings? string[];
---@field deviceOrgBindingsMetaSchema? string[];
---@field lockRenameEdits? string[];
---@field formattingErrorAsDiagnostics? boolean;
---@field compileCommands? string;
---@field disableFileWatchers? boolean;
---@field autoAddMissingPropertiesOnCompletion? boolean;

local M = {}

--- Symlink placed at the west topdir pointing at the active build's
--- `build_info.yml`. Same idea as compile_commands.json for clangd: one active
--- build at a time, re-point it with `:DtsUse`. Kept out of git via the name.
M.marker = '.dts-lsp.build_info.yml'

--- Default Zephyr settings used when no build is pinned. Paths are absolute
--- (see `zephyr` note in M.config), so `cwd` is only a fallback anchor.
---@param zephyr string absolute zephyr base
---@param opts?  {topdir?:string,contexts?:table}
---@return table
M.settings = function(zephyr, opts)
  opts = opts or {}
  local topdir = opts.topdir or (vim.fs.root(0, {'.west'}) or {})[0]
  local contexts = opts.contexts or {}
  return {
    devicetree = {
      cwd = topdir or vim.api.nvim_buf_get_name(0),
      defaultBindingType = 'Zephyr',
      defaultIncludePaths = {
        vim.fs.joinpath(zephyr, 'dts'),
        vim.fs.joinpath(zephyr, 'dts', 'arm'),
        vim.fs.joinpath(zephyr, 'dts', 'arm64'),
        vim.fs.joinpath(zephyr, 'dts', 'riscv'),
        vim.fs.joinpath(zephyr, 'dts', 'common'),
        vim.fs.joinpath(zephyr, 'dts', 'vendor'),
        vim.fs.joinpath(zephyr, 'include'),
      },
      defaultZephyrBindings = { vim.fs.joinpath(zephyr, 'dts', 'bindings') },
      autoChangeContext = true,
      allowAdhocContexts = true,
      contexts = contexts,
    },
  }
end

--- Translate a Zephyr `build_info.yml` into dts-lsp devicetree settings. The
--- build's fully-resolved include/binding dirs become both the defaults and a
--- single context tying the base .dts to its overlays.
---@param build_info string path to a build_info.yml
---@param topdir string
---@return table? settings  nil when the file has no devicetree section
M.settings_from_build_info = function(build_info, topdir)
  -- local expr = '{"board": .cmake.board.name, "dt": .cmake.devicetree}'
  local expr =
    '.cmake.devicetree as $dt | { "board": .cmake.board.name, "dtsFile": ($dt.files[] | select(. == "*.dts")), "overlays": ($dt.files[] | select(. == "*.overlay")),"includePaths": $dt.include-dirs, "zephyrBindings": $dt.bindings-dirs }'
  local out = vim.system({ 'yq', '-o=json', '-I=0', expr, build_info }, { text = true }):wait(3000)
  if out.code ~= 0 then
    VimRc.warn('[dts] yq failed on ' .. build_info .. ': ' .. (out.stderr or ''))
    return
  end
  local ok, parsed = pcall(vim.json.decode, out.stdout)
  local dt = ok and type(parsed) == 'table' and parsed.dt or nil
  if type(dt) ~= 'table' then
    return -- e.g. the sysbuild top image, which carries no devicetree
  end
  -- build_info may be reached through the marker symlink; name the context after
  -- the real build directory, not the symlink's location.
  local real_dir = vim.fs.dirname(vim.uv.fs_realpath(build_info) or build_info)
  local app_context = vim.tbl_extend('force', parsed, {
    {
      ctxName = (parsed.board or 'build') .. ' · ' .. vim.fn.fnamemodify(real_dir, ':~:.'),
      cwd = topdir,
      bindingType = 'Zephyr',
    },
  })
  return {
    devicetree = {
      defaultIncludePaths = app_context['includePaths'],
      defaultZephyrBindings = app_context['zephyrBindings'],
      contexts = { app_context },
    },
  }
end

--- Push settings to the registered config (future clients) and any running
--- client (pull config re-fires on didChangeConfiguration).
---@param settings table
M.apply = function(settings)
  local cfg = vim.lsp.config['devicetree-language-server']
  VimRc.info('Applying settings: ', { settings = settings })
  cfg.settings = settings
  vim.lsp.config['devicetree-language-server'] = cfg
  for _, c in ipairs(vim.lsp.get_clients { name = 'devicetree-language-server' }) do
    c.settings = settings
    c:notify('workspace/didChangeConfiguration', { settings = settings })
  end
end



---@param workspace {topdir:string,relative_zephyr_base:string}
M.config = function(workspace)
  vim.validate('workspace', workspace, 'table')
  -- west.lua passes an absolute zephyr base, so use it as-is.

  ---@type vim.lsp.Config
  vim.api.nvim_create_user_command('DtsUse', function()
  local topdir = vim.fs.root(0, '.west')
  if not topdir then
    VimRc.warn '[dts] no west workspace'
    return
  end
  local cmd = {
    'fd',
    '--no-ignore',
    '--hidden',
    '-E',
    vim.fn.shellescape '**/twister*/**',
    vim.fn.shellescape '^build_info.yml$',
  }
  VimRc.info('Running cmd (topdir=' .. topdir .. ') : ' .. table.concat(cmd, ' '))
  local out = vim.system(cmd, { text = true, cwd = topdir }):wait()
  if out.code ~= 0 then
    VimRc.err('Failed to run cmd : ' .. (out.stderr or 'Unknown error'))
    return
  end
  VimRc.info('Found: ' .. out.stdout)
  local found = vim.split(out.stdout or '', '\n')
  if #found == 0 then
    VimRc.warn '[dts] no build_info.yml found (build an app first)'
    return
  end
  vim.ui.select(found, {
    prompt = 'Active devicetree build:',
  }, function(choice)
    if not choice then
      return
    end
    local settings = M.settings_from_build_info(choice, M._topdir)
    if not settings then
      VimRc.warn('[dts] no devicetree section in ' .. choice)
      return
    end
    -- local marker = vim.fs.joinpath(M._topdir, M.marker)
    -- pcall(vim.uv.fs_unlink, marker)
    -- local ok, err = vim.uv.fs_symlink(choice, marker)
    -- if not ok then
    --   VimRc.warn('[dts] could not create ' .. marker .. ': ' .. (err or ''))
    --   return
    -- end
    M.apply(settings)
    VimRc.info('[dts] active build: ' .. vim.fn.fnamemodify(choice, ':~:.'))
  end)
end, { desc = 'Select the active devicetree build (build_info.yml)' })
end

return M
