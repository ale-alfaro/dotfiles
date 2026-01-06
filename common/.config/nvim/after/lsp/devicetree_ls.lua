--[[
--
--interface Context {
}

--]]
--

---@class DtsLspContext
---@field ctxName string|number?
---@field cwd string?
---@field includePaths string[]?
---@field dtsFile string
---@field overlays string[]?
---@field zephyrBindings string[]?
---@field deviceOrgTreeBindings string[]?
---@field deviceOrgBindingsMetaSchema string[]?
---@field lockRenameEdits string[]?
---@field formattingErrorAsDiagnostics boolean?
---@field compileCommands string?

---@class DtsLspSettings
---@field cwd string?
---@field defaultZephyrBindings string[]?
---@field defaultDeviceOrgTreeBindings string[]?
---@field defaultDeviceOrgBindingsMetaSchema string[]?
---@field defaultIncludePaths string[]?
---@field contexts dts.lsp.Context[]?
---@field preferredContext string | number?
---@field defaultLockRenameEdits string[]?
---@field defaultShowFormattingErrorAsDiagnostics boolean?
---@field autoChangeContext boolean?
---@field allowAdhocContexts boolean?
---

local zephyr_base = _G.fetch_env('ZEPHYR_BASE', './zephyr')
local west_topdir = _G.fetch_env('WEST_TOPDIR', '')
local dts_settings = vim.uv.fs_stat(west_topdir) and vim.fs.joinpath(west_topdir, '.dts_lsp.json') or './.dts_lsp.json'
_G.info('devicetree_ls init. ZEPHYR_BASE: ' .. zephyr_base)

---@param client vim.lsp.Client
---@param bufnr number
local function create_project_settings(client, bufnr)
  west_topdir = west_topdir or VimRc.exec.west_topdir(bufnr)
  dts_settings = dts_settings or VimRc.exec.west_config 'dts-lsp.settings'
  if not dts_settings then
    _G.error('Couldnt not find the dts_lsp settings file ' .. dts_settings)
    return
  end
  local file_content = io.input(dts_settings)
  if not file_content then
    _G.error('Couldnt read the dts_lsp settings file ' .. dts_settings)
    return
  end
  local decoded = vim.json.decode(file_content:read '*a')
  if not decoded or not type(decoded) == 'table' or not decoded['devicetree.contexts'] or not vim.islist(decoded['devicetree.contexts']) then
    _G.error 'Couldnt decode the dts_lsp settings file into context '
    vim.print(dts_settings)
    return
  end
  ---@type DtsLspContext[]
  local contexts = {}
  for i, ctx in ipairs(decoded['devicetree.contexts']) do
    ctx.ctxName = ctx.ctxName or i
    vim.list_extend(contexts, ctx)
  end

  if not decoded or #decoded < 1 then
    _G.error('Couldnt find any contexts nor settings in the dts_lsp settings file ', decoded)
    return
  end
  _G.info('devicetree_ls decoded settings : ' .. dts_settings)
  vim.print(decoded)
  vim.tbl_deep_extend('force', client.settings, {
    devicetree = {
      preferredContext = decoded[1].ctxName,
      contexts = decoded,
    },
  })
end

---@type vim.lsp.Config
return {
  cmd = { 'lsp-devtools', 'agent', '--', 'devicetree-language-server', '--stdio' },
  filetypes = { 'dts', 'dtsi' },
  root_markers = { '.west', 'zephyr', '.git', '.' },
  ---@type DtsLspSettings
  settings = {
    devicetree = {
      defaultIncludePaths = {
        zephyr_base .. '/dts',
        zephyr_base .. '/dts/arm',
        zephyr_base .. '/dts/arm64/',
        zephyr_base .. '/dts/riscv',
        zephyr_base .. '/dts/common',
        zephyr_base .. '/dts/vendor',
        zephyr_base .. '/include',
      },
      defaultZephyrBindings = {
        zephyr_base .. '/dts/bindings',
      },
      cwd = '${workspaceFolder}',
      defaultBindingType = 'Zephyr',
      autoChangeContext = true,
      allowAdhocContexts = true,
    },
  },
  capabilities = {
    -- Enable semantic tokens
    textDocument = {
      semanticTokens = {
        dynamicRegistration = false,
        requests = {
          range = false,
          full = true,
        },
        tokenTypes = {
          'namespace',
          'class',
          'enum',
          'interface',
          'struct',
          'typeParameter',
          'type',
          'parameter',
          'variable',
          'property',
          'enumMember',
          'decorator',
          'event',
          'function',
          'method',
          'macro',
          'label',
          'comment',
          'string',
          'keyword',
          'number',
          'regexp',
          'operator',
        },
        tokenModifiers = {
          'declaration',
          'definition',
          'readonly',
          'static',
          'deprecated',
          'abstract',
          'async',
          'modification',
          'documentation',
          'defaultLibrary',
        },
        formats = { 'relative' },
      },

      -- Enable formatting
      formatting = {
        dynamicRegistration = false,
      },

      -- Enable folding range support
      foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      },
    },
  },
  on_attach = function(client, bufnr)
    -- Setup the LSP
    create_project_settings(client, bufnr)
  end,
}
