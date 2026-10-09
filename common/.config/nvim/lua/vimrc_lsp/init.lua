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
  vim.lsp.config['pklls'] = vim.tbl_extend('force', {
    name = 'pklls',
    filetypes = { 'pkl' },
    },
  require 'vimrc_lsp.pkl')
  servers = vim.list_extend(servers, {  'lua_ls', 'pklls' })
  vim.lsp.enable(servers)


  -- HACK: Override buf_request to ignore notifications from LSP servers that don't implement a method.
  local buf_request = vim.lsp.buf_request
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.lsp.buf_request = function(bufnr, method, params, handler)
    return buf_request(bufnr, method, params, handler, function() end)
  end
end

return M
