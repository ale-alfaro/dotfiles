local M = {}

---@comment Get the lsp configuration in the current working directory
---@return string[]
local lsp_configs_get = function()
  return vim
    .iter(vim.fn.globpath(vim.fn.expand '$XDG_CONFIG_HOME/nvim', '**/lsp/*.lua', false, true))
    :map(function(f)
      return f:match '/([%w%-_]+)%.lua$'
    end)
    :totable()
end
---@comment Get the lsp configuration in the current working directory
---@return string[]?
local dts_lsp_config_get = function()
  local configs = vim.fn.globpath('.', '**/.nvim/devicetree_language_server.json', false, true)
  if not configs or #configs == 0 then
    return nil
  end
  return vim
    .iter(configs)
    :map(function(f)
      local fh = io.open(f, 'r')
      local json = nil
      if fh then
        json = fh:read 'a'
        fh:close()
        json = vim.json.decode(json)
      end
      return json
    end)
    :totable()
end

M.dts_config = function()
  local zephyr_base = vim.env.ZEPHYR_BASE
  if not zephyr_base  then
    return
  end
  local dts = require('vimrc_lsp.dts')
  local contexts = dts_lsp_config_get()
  if not contexts then
    return
  end
  vim.lsp.config['devicetree-language-server'] = {
    cmd = { "devicetree-language-server", '--stdio' },
    -- nvim maps .dts/.dtsi/.overlay all to the `dts` filetype.
    filetypes = { 'dts' },
    root_markers = { '.west', '.git' },
    settings = dts.settings(zephyr_base, { contexts }),
    capabilities = {
      textDocument = {
        foldingRange = {
          dynamicRegistration = false,
          lineFoldingOnly = true,
        },
        formatting = {
          dynamicRegistration = false,
        },
        semanticToken = {
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
      },
    },
  }
  -- Config alone only registers it; enable starts the client on `dts` buffers.
  vim.lsp.enable 'devicetree-language-server'


end

---
M.setup = function()
  --[[
  -- Setup autocmds for Lsp Events
  -- LspAttach event happens when the buffer is open and Neovim starts the Lsp client
  -- for that filetype and using other heuristics
  --]]
  --
  -- Extend neovim's client capabilities with the completion ones.

  local servers = lsp_configs_get()
  servers = vim.list_extend(servers, { 'taplo', 'lua_ls', 'yamlls', 'jsonls' })
  vim.lsp.enable(servers)
  local sstore = require 'vimrc_lsp.schemastore'
  VimRc.on_filetype('json', sstore.json_ls)
  VimRc.on_filetype('yaml', sstore.yaml_ls)

  VimRc.on_filetype('pkl', function()
    require 'vimrc_lsp.pkl'
  end)
  VimRc.on_filetype('dts', M.dts_config)

  -- HACK: Override buf_request to ignore notifications from LSP servers that don't implement a method.
  local buf_request = vim.lsp.buf_request
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.lsp.buf_request = function(bufnr, method, params, handler)
    return buf_request(bufnr, method, params, handler, function() end)
  end
end

return M
