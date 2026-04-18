local M = {}

---@comment Get the lsp configuration in the current working directory
---@return string[]
local lsp_configs_get = function()
  return vim
    .iter(vim.fn.globpath(vim.fn.expand '$XDG_CONFIG_HOME/nvim', '**/lsp/*.lua', false, true))
    :map(function(f)
      return f:match '/(%w+)%.lua$'
    end)
    :totable()
end

local bufgr = vim.api.nvim_create_augroup('vimrc.lsp', { clear = false })
--- Buflocal autocmd
---@param event string|string[]
---@param bufnr integer
---@param callback function
---@param desc string?
local new_buf_autocmd = function(event, bufnr, callback, desc)
  local opts = { group = bufgr, callback = callback, buffer = bufnr, desc = desc or '' }
  vim.api.nvim_create_autocmd(event, opts)
end
---@description Function that handles LspAttach events.
---@param client vim.lsp.Client
---@param bufnr integer
local lsp_on_attach = function(client, bufnr)
  -- Enable auto-completion. Note: Use CTRL-Y to select an item. |complete_CTRL-Y|
  new_buf_autocmd({ 'CursorHold', 'InsertLeave' }, bufnr, vim.lsp.buf.document_highlight, 'Highlight references under the cursor')
  new_buf_autocmd({ 'CursorMoved', 'InsertEnter', 'BufLeave' }, bufnr, vim.lsp.buf.clear_references, 'Clear highlight references')

  -- Don't check for the capability here to allow dynamic registration of the request.
  vim.lsp.document_color.enable(true, { bufnr = bufnr, style = 'virtual' })
  --- Global lsp keymaps redefined to use Fzf-lua functions

  vim.bo[bufnr].formatexpr = 'v:lua.vim.lsp.formatexpr(#{timeout_ms:250})'
  local lsp_keys = {
    {
      lhs = 'grd',
      rhs = '<cmd>FzfLua lsp_definitions jump1=false<cr>',
      opts = { desc = 'Peek Definition' },
    },
    {
      lhs = 'grD',
      rhs = '<cmd>FzfLua lsp_definitions jump1=true<cr>',
      opts = { desc = 'Goto Definition' },
    },
    { lhs = 'grr', rhs = '<cmd>FzfLua lsp_references<cr>', opts = { desc = 'References' } },
    { lhs = 'gra', rhs = '<cmd>lua require("tiny-code-action").code_action()<cr>', opts = { desc = 'Code Action' } },
    { lhs = 'grc', rhs = '<cmd>lua vim.lsp.codelens.run()<cr>', opts = { desc = 'Code Lens' } },
    { lhs = 'gri', rhs = '<cmd>FzfLua lsp_implementations<cr>', opts = { desc = 'Goto Implementation' } },
    { lhs = 'grt', rhs = '<cmd>FzfLua lsp_typedefs<cr>', opts = { desc = 'Goto T[y]pe Definition' } },
    { lhs = 'gO', rhs = '<cmd>FzfLua lsp_document_symbols<cr>', opts = { desc = 'Document Symbols' } },
    { lhs = '<C-k>', rhs = '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts = { desc = 'Signature Help' } },
  }
  for _, key in ipairs(lsp_keys) do
    vim.api.nvim_buf_set_keymap(bufnr, 'n', key.lhs, key.rhs, key.opts)
  end

  new_buf_autocmd('CursorHold', bufnr, function()
    local hover_opts = {
      focusable = false,
      close_events = { 'BufLeave', 'CursorMoved', 'InsertEnter', 'FocusLost' },
      border = 'rounded',
      source = 'always',
      prefix = ' ',
    }
    vim.diagnostic.open_float(hover_opts)
  end, '✨lsp show diagnostics on Cursorhold')
  if client:supports_method 'textDocument/codeAction' then
    require('vimrc_lsp.code_action').on_attach(bufnr, client)
  end
  -- Enable auto-completion. Note: Use CTRL-Y to select an item. |complete_CTRL-Y|
  if client:supports_method 'textDocument/completion' then
    -- Optional: trigger autocompletion on EVERY keypress. May be slow!
    -- local chars = {}
    -- for i = 32, 126 do
    --   table.insert(chars, string.char(i))
    -- end
    -- client.server_capabilities.completionProvider.triggerCharacters = chars

    -- vim.cmd [[setlocal completeopt+=menuone,noselect,popup]]
    vim.bo[bufnr].omnifunc = 'v:lua.MiniCompletion.completefunc_lsp'
    vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
  end
  if not client:supports_method 'textDocument/willSaveWaitUntil' and client:supports_method 'textDocument/formatting' then
    new_buf_autocmd('BufWritePre', bufnr, function()
      vim.lsp.buf.format { bufnr = bufnr, id = client.id, timeout_ms = 1000 }
    end)
  end

  if client:supports_method 'textDocument/foldingRange' then
    local win = vim.api.nvim_get_current_win()
    vim.wo[win][0].foldexpr = 'v:lua.vim.lsp.foldexpr()'
  end
end

M.setup = function()
  --[[
  -- Setup autocmds for Lsp Events
  -- LspAttach event happens when the buffer is open and Neovim starts the Lsp client
  -- for that filetype and using other heuristics
  --]]
  VimRc.new_autocmd('LspAttach', function(ev)
    local bufnr = ev.buf
    local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))

    VimRc.debug('[LspAttach autocmd] - ', { client = client.name, buf = bufnr })
    lsp_on_attach(client, bufnr)
  end, '*', 'LspAttach Configure Lsps')

  --- Lsp Configuration happens on a different paths sometimes when Lsp Servers are expected
  --- to register dynamic capabilities. Current the same on_attach handler is used so
  --- is not being leveraged but kept as "just in case"
  vim.lsp.handlers['client/registerCapability'] = (function(overridden_register_caps)
    return function(err, res, ctx)
      local client = vim.lsp.get_client_by_id(ctx.client_id)
      if not client then
        return
      end

      VimRc.debug(string.format('[registerCapability] - Client %s', client.name))
      VimRc.debug(client.capabilities)
      -- Update mappings when registering dynamic capabilities.
      lsp_on_attach(client, vim.api.nvim_get_current_buf()) -- end
      return overridden_register_caps(err, res, ctx)
    end
  end)(vim.lsp.handlers['client/registerCapability'])

  vim.api.nvim_create_user_command('SchemaStore', 'lua require("vimrc_lsp.schemastore").setup()', { desc = 'Enable SchemaStore for Json and YAML Lsp' })

  -- vim.cmd([[
  --   autocmd BufWritePre *.rs lua vim.lsp.buf.format({ async = false }
  -- ]])
  --
  -- Extend neovim's client capabilities with the completion ones.
  require('vimrc_lsp.code_action').setup()

  local servers = lsp_configs_get()
  servers = vim.list_extend(servers, { 'lua_ls', 'yamlls', 'jsonls' })
  VimRc.info('Enabling lsps: ', { servers = servers })
  vim.lsp.enable(servers)

  -- HACK: Override buf_request to ignore notifications from LSP servers that don't implement a method.
  local buf_request = vim.lsp.buf_request
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.lsp.buf_request = function(bufnr, method, params, handler)
    return buf_request(bufnr, method, params, handler, function() end)
  end
end

return M
