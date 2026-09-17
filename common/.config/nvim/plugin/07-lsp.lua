
local augrp_lsp = vim.api.nvim_create_augroup('vimrc.lsp', { clear = false })

local augrp_fmt = vim.api.nvim_create_augroup('vimrc.fmt', { clear = false })
local add_fmt = function(client, bufnr)

  if client:supports_method 'textDocument/formatting' then
      vim.bo[bufnr].formatexpr = 'v:lua.vim.lsp.formatexpr(#{timeout_ms:1000})'
      vim.api.nvim_buf_set_var(bufnr, 'lspformat', 1)
      local ft = vim.bo[bufnr].ft
      vim.cmd [[autocmd BufWritePre <buffer> lua vim.lsp.buf.format({ async = false}) ]]
  else
      vim.bo[bufnr].formatexpr = 'v:lua.vim.lsp.formatexpr(#{timeout_ms:1000})'
        vim.api.nvim_create_autocmd('BufWritePre', {
            group = augrp_fmt,
          desc = 'Format on save',
          callback = function(ev)
            if vim.g.minifiles_active then
              return
            end
            if vim.g.skip_formatting then
              vim.g.skip_formatting = false
              return
            end

            if not vim.g.autoformat and not vim.b[ev.buf].autoformat then
              return
            end
            Fmt.format(ev.buf)
          end,
        })
  end

end
--- Buflocal autocmd
---@param event string|string[]
---@param bufnr integer
---@param callback function
---@param desc string?
local new_buf_autocmd = function(event, bufnr, callback, desc)
  local opts = { group = augrp_lsp, callback = callback, buffer = bufnr, desc = desc or '' }
  vim.api.nvim_create_autocmd(event, opts)
end
---@description Function that handles LspAttach events.
---@param client vim.lsp.Client
---@param bufnr integer
VimRc.lsp_on_attach = function(client, bufnr)
  -- Enable auto-completion. Note: Use CTRL-Y to select an item. |complete_CTRL-Y|
  new_buf_autocmd({ 'CursorHold', 'InsertLeave' }, bufnr, vim.lsp.buf.document_highlight, 'Highlight references under the cursor')
  new_buf_autocmd({ 'CursorMoved', 'InsertEnter', 'BufLeave' }, bufnr, vim.lsp.buf.clear_references, 'Clear highlight references')

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
  -- Don't check for the capability here to allow dynamic registration of the request.
  vim.lsp.document_color.enable(true, { bufnr = bufnr, style = 'virtual' })
  add_fmt(client, bufnr)

  --- Global lsp keymaps redefined to use Fzf-lua functions
  -- Code Action
  if client:supports_method 'textDocument/codeAction' then
    VimRc.code_action = require 'vimrc_lsp.code_action'
    VimRc.code_action.on_attach(bufnr, client)
  end
  if client:supports_method 'textDocument/signatureHelp' then
    vim.keymap.set({ 'i'}, '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<cr>', {desc = 'Signature help' })
  end

  if client:supports_method 'textDocument/foldingRange' then
    local win = vim.api.nvim_get_current_win()
    vim.wo[win][0].foldexpr = 'v:lua.vim.lsp.foldexpr()'
  end

  local lsp_gr_keys = {
    {  's',  '<Cmd>Trouble symbols toggle<CR>', 'Doc Symbols (Trouble)' },
    {  'l',  '<Cmd>FzfLua lsp_document_symbols<CR>', 'Doc Symbols (Fzf)' },
    {  'A',  '<Cmd>lua VimRc.code_action.run_sorted() <CR>', 'Code Action Menu ' },
    {  'f',  '<Cmd>lua vim.lsp.buf.format({async=false})<CR>', 'Lsp Format' },
    {  'r',  '<Cmd>FzfLua lsp_references<cr>',  'References'  },
    {  'R',  '<Cmd>lua VimRc.code_action.refactor() <CR>', 'Refactor' },
    {  'c',  '<Cmd>lua vim.lsp.codelens.run()<CR>', 'Code Lens' },
    {  'd',  '<Cmd>FzfLua lsp_definitions<CR>', 'Goto Definition' },
    {  'D',  '<Cmd>FzfLua lsp_declaration<CR>',  'Goto Declaration' }, 
   }
  for _, key in ipairs(lsp_gr_keys) do
      vim.keymap.set( 'n', 'gr' .. key[1], key[2], { desc = key[3] })
  end

end
-- Set up LSP servers.
VimRc.now_if_args(function()
  vim.diagnostic.config {
    severity_sort = true,
    float = {
      border = 'rounded',
      source = 'if_many',
      underline = true,
    },
    virtual_text = {
      spacing = 2,
      source = 'if_many',
      prefix = 'o',
    },
    -- Disable signs in the gutter.
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = 'E',
        [vim.diagnostic.severity.WARN] = 'W',
        [vim.diagnostic.severity.INFO] = 'I',
        [vim.diagnostic.severity.HINT] = 'H',
      },
    },
  }
  -- or equivalently

  VimRc.new_autocmd('LspAttach', function(ev)
    local bufnr = ev.buf
    local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))

    VimRc.debug('[LspAttach autocmd] - ', { client = client.name, buf = bufnr })
    VimRc.lsp_on_attach(client, bufnr)
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
      VimRc.lsp_on_attach(client, vim.api.nvim_get_current_buf()) -- end
      return overridden_register_caps(err, res, ctx)
    end
  end)(vim.lsp.handlers['client/registerCapability'])
  require('vimrc_lsp').setup()
end)
