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

  -- HACK: Override buf_request to ignore notifications from LSP servers that don't implement a method.
  local buf_request = vim.lsp.buf_request
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.lsp.buf_request = function(bufnr, method, params, handler)
    return buf_request(bufnr, method, params, handler, function() end)
  end
end

return M
