
local augrp_lsp = vim.api.nvim_create_augroup('vimrc.lsp', { clear = false })

local augrp_fmt = vim.api.nvim_create_augroup('vimrc.fmt', { clear = false })
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
  --- Global lsp keymaps redefined to use Fzf-lua functions
  local lsp_keys = {
    { lhs = 's', rhs = '<cmd>Trouble symbols toggle<cr>', opts = { desc = 'Doc Symbols (Trouble)' } },
    { lhs = 'l', rhs = '<cmd>FzfLua lsp_document_symbols<cr>', opts = { desc = 'Doc Symbols (Fzf)' } },
  }
  -- Code Lens
  if client:supports_method 'textDocument/codeLens' then
    lsp_keys = vim.list_extend(lsp_keys, {
      { lhs = 'c', rhs = '<cmd>lua vim.lsp.codelens.run()<cr>', opts = { desc = 'Code Lens' } },
    })
  end
  -- Code Action
  if client:supports_method 'textDocument/codeAction' then
    VimRc.code_action = require 'vimrc_lsp.code_action'
    lsp_keys = vim.list_extend(lsp_keys, {
      { lhs = 'A', rhs = '<cmd>lua VimRc.code_action.run_sorted() <cr>', opts = { desc = 'Code Action Menu ' } },
      { lhs = 'R', rhs = '<cmd>lua VimRc.code_action.refactor() <cr>', opts = { desc = 'Refactor' } },
      { lhs = 'a', rhs = '<cmd>lua vim.lsp.buf.code_action({apply = true})<cr>', opts = { desc = 'Apply' } },
    })
    VimRc.code_action.on_attach(bufnr, client)
  end
  -- Goto Definition
  if client:supports_method 'textDocument/definition' then
    lsp_keys = vim.list_extend(lsp_keys, {
      {
        lhs = 'd',
        rhs = '<cmd>FzfLua lsp_definitioncr>',
        opts = { desc = 'Goto Definition' },
      },})
      if client.name == 'clangd' then
        lsp_keys = vim.list_extend(lsp_keys, {
        {
        lhs = 'D',
        rhs = '<cmd>FzfLua lsp_declaration<cr>',
        opts = { desc = 'Goto Declaration' },
      },
    })

    end
  end
  if client:supports_method 'textDocument/references' then
    lsp_keys = vim.list_extend(lsp_keys, {
      { lhs = 'r', rhs = '<cmd>Trouble lsp_references<cr>', opts = { desc = 'Document Symbols' } },
      { lhs = 'R', rhs = '<cmd>FzfLua lsp_references<cr>', opts = { desc = 'References' } },
    })
  end
  if client:supports_method 'textDocument/signatureHelp' then
    lsp_keys = vim.list_extend(lsp_keys, {
      {
        lhs = '<C-k>',
        rhs = '<cmd>lua vim.lsp.buf.signature_help()<cr>',
        opts = { desc = 'Signature help' },
        mode = 'i',
      },
    })
  end
  if client:supports_method 'textDocument/formatting' then
    vim.bo[bufnr].formatexpr = 'v:lua.vim.lsp.formatexpr(#{timeout_ms:1000})'
    lsp_keys = vim.list_extend(lsp_keys, {
      { lhs = 'f', rhs = '<cmd>lua vim.lsp.buf.format({async=false})<cr>', opts = { desc = 'Lsp Format' } },
    })
    vim.api.nvim_buf_set_var(bufnr, 'lspformat', 1)
    vim.api.nvim_create_autocmd('BufWritePre', { 
      buf = bufnr, 
      group = augrp_fmt,
      callback = function ( )
        vim.lsp.buf.format({ async = false})
      end })
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

  if client:supports_method 'textDocument/foldingRange' then
    local win = vim.api.nvim_get_current_win()
    vim.wo[win][0].foldexpr = 'v:lua.vim.lsp.foldexpr()'
  end
  for _, key in ipairs(lsp_keys) do
    local opts = vim.tbl_extend('force', key.opts , { buf = bufnr})

    if lsp_keys.mode and type(lsp_keys.mode) == 'i' then
      vim.keymap.set( 'i', key.lhs, key.rhs, opts)
    else
      vim.keymap.set( 'n', '<leader>l' .. key.lhs, key.rhs, opts)
    end
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
