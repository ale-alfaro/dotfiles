vim.pack.add(_G.plug_spec {
  'neovim/nvim-lspconfig',
  'rachartier/tiny-code-action.nvim',
  'p00f/clangd_extensions.nvim',
})

require('lsp.custom_diagnostics').diagnostics_setup()

---@param lsp_names string[]
local custom_lsp_caps_registration = function(lsp_names)
  vim.iter(lsp_names):map(function(lsp_name)
    if lsp_name == 'devicetree_ls' then
      vim.lsp.config('devicetree_ls', {
        capabilities = {
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
      })
    end
  end)
end

-- Disable inlay hints initially (and enable if needed with my ToggleInlayHints command).
vim.g.inlay_hints = false

---@param client vim.lsp.Client
---@param bufnr number
local add_inlay_hint_support = function(client, bufnr)
  if client:supports_method 'textDocument/inlayHint' then
    local inlay_hints_group = vim.api.nvim_create_augroup('mariasolos/toggle_inlay_hints', { clear = false })

    if vim.g.inlay_hints then
      -- Initial inlay hint display.
      -- Idk why but without the delay inlay hints aren't displayed at the very start.
      vim.defer_fn(function()
        local mode = vim.api.nvim_get_mode().mode
        vim.lsp.inlay_hint.enable(mode == 'n' or mode == 'v', { bufnr = bufnr })
      end, 500)
    end

    vim.api.nvim_create_autocmd('InsertEnter', {
      group = inlay_hints_group,
      desc = 'Enable inlay hints',
      buffer = bufnr,
      callback = function()
        if vim.g.inlay_hints then
          vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
        end
      end,
    })

    vim.api.nvim_create_autocmd('InsertLeave', {
      group = inlay_hints_group,
      desc = 'Disable inlay hints',
      buffer = bufnr,
      callback = function()
        if vim.g.inlay_hints then
          vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end
      end,
    })
  end
end

---@param client vim.lsp.Client
---@param bufnr number
local add_document_highlight = function(client, bufnr)
  if client:supports_method 'textDocument/documentHighlight' then
    local under_cursor_highlights_group = vim.api.nvim_create_augroup('mariasolos/cursor_highlights', { clear = false })
    vim.api.nvim_create_autocmd({ 'CursorHold', 'InsertLeave' }, {
      group = under_cursor_highlights_group,
      desc = 'Highlight references under the cursor',
      buffer = bufnr,
      callback = vim.lsp.buf.document_highlight,
    })
    vim.api.nvim_create_autocmd({ 'CursorMoved', 'InsertEnter', 'BufLeave' }, {
      group = under_cursor_highlights_group,
      desc = 'Clear highlight references',
      buffer = bufnr,
      callback = vim.lsp.buf.clear_references,
    })
  end
end

---@param client vim.lsp.Client
---@param bufnr number
local add_cursor_hold_diagnostics = function(client, bufnr)
  if client:supports_method('textDocument/diagnostic', bufnr) then
    local diag_group = vim.api.nvim_create_augroup('diagnosis', { clear = false })
    vim.api.nvim_create_autocmd('CursorHold', {
      group = diag_group,
      buffer = bufnr,
      desc = '✨lsp show diagnostics on CursorHold',
      callback = function()
        local hover_opts = {
          focusable = false,
          close_events = { 'BufLeave', 'CursorMoved', 'InsertEnter', 'FocusLost' },
          border = 'rounded',
          source = 'always',
          prefix = ' ',
        }
        vim.diagnostic.open_float(hover_opts)
      end,
    })
  end
end

---@param client vim.lsp.Client
---@param bufnr number
local add_completion = function(client, bufnr)
  -- Enable auto-completion. Note: Use CTRL-Y to select an item. |complete_CTRL-Y|
  if client:supports_method 'textDocument/completion' then
    -- Optional: trigger autocompletion on EVERY keypress. May be slow!
    -- local chars = {}; for i = 32, 126 do table.insert(chars, string.char(i)) end
    -- client.server_capabilities.completionProvider.triggerCharacters = chars
    vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
  end
end

KEYS.define {
  {
    lhs = 'gd',
    rhs = function()
      require('fzf-lua').lsp_definitions { jump1 = true }
    end,
    opts = { desc = 'Goto Definition' },
  },
  {
    lhs = 'gD',
    rhs = function()
      require('fzf-lua').lsp_definitions { jump1 = false }
    end,
    opts = { desc = 'Peek Definition' },
  },
  { lhs = 'gr', rhs = '<cmd>FzfLua lsp_references<cr>', opts = { desc = 'References' } },
  { lhs = 'gI', rhs = '<cmd>FzfLua lsp_implementations<cr>', opts = { desc = 'Goto Implementation' } },
  { lhs = 'gy', rhs = '<cmd>FzfLua lsp_typedefs<cr>', opts = { desc = 'Goto T[y]pe Definition' } },
  { lhs = 'gD', rhs = '<cmd>FzfLua lsp_declarations<cr>', opts = { desc = 'Goto Declaration' } },
  { lhs = '<leader>fs', rhs = '<cmd>FzfLua lsp_document_symbols<cr>', opts = { desc = 'Document Symbols' } },
  {
    lhs = 'grd',
    rhs = function()
      vim.lsp.document_color.color_presentation()
    end,
    opts = { desc = 'Document Color' },
  },
  {
    lhs = 'K',
    rhs = function()
      return vim.lsp.buf.hover()
    end,
    opts = { desc = 'Hover' },
  },
}
---@param client vim.lsp.Client
---@param bufnr number
local add_lsp_keymaps = function(client, bufnr)
  local lsp_keys = {}
  if client:supports_method('textDocument/signatureHelp', bufnr) then
    vim.tbl_extend('force', lsp_keys, {
      {
        lhs = 'gK',
        rhs = function()
          return vim.lsp.buf.signature_help()
        end,
        opts = { desc = 'Signature Help' },
        has = 'signatureHelp',
      },
      {
        lhs = '<C-k>',
        rhs = function()
          if require('blink.cmp.completion.windows.menu').win:is_open() then
            require('blink.cmp').hide()
          end
          vim.lsp.buf.signature_help()
        end,
        mode = 'i',
        opts = { desc = 'Signature Help' },
        has = 'signatureHelp',
      },
    })
  end
  if client:supports_method('textDocument/signatureHelp', bufnr) then
    vim.tbl_extend('force', lsp_keys, {
      {
        lhs = 'gK',
        rhs = function()
          return vim.lsp.buf.signature_help()
        end,
        opts = { desc = 'Signature Help' },
        has = 'signatureHelp',
      },
      {
        lhs = '<C-k>',
        rhs = function()
          if require('blink.cmp.completion.windows.menu').win:is_open() then
            require('blink.cmp').hide()
          end
          vim.lsp.buf.signature_help()
        end,
        mode = 'i',
        opts = { desc = 'Signature Help' },
        has = 'signatureHelp',
      },
    })
  end
  if client:supports_method('textDocument/codeAction', bufnr) then
    vim.tbl_extend('force', lsp_keys, {
      {
        mode = { 'n', 'v' },
        lhs = '<leader>ca',
        rhs = require('tiny-code-action').code_action,
        opts = { desc = 'Code Action' },
        has = 'codeAction',
      },
      {
        lhs = '<leader>cc',
        rhs = vim.lsp.codelens.run,
        opts = { desc = 'Run Codelens' },
        mode = { 'n', 'v' },
        has = 'codeLens',
      },
      {
        lhs = '<leader>cC',
        rhs = vim.lsp.codelens.refresh,
        opts = { desc = 'Refresh & Display Codelens' },
        mode = { 'n' },
        has = 'codeLens',
      },
    })
  end

  if client:supports_method('textDocument/rename', bufnr) then
    vim.tbl_extend('force', lsp_keys, {
      { lhs = '<leader>cr', rhs = vim.lsp.buf.rename, opts = { desc = 'Rename' }, has = 'rename' },
    })
  end
  for _, key in ipairs(lsp_keys) do
    vim.api.nvim_buf_set_keymap(bufnr, 'n', key.lhs, key.rhs, key.opts)
  end
end
---@param client vim.lsp.Client
---@param bufnr integer
local on_attach = function(client, bufnr)
  add_completion(client, bufnr)
  add_document_highlight(client, bufnr)
  add_inlay_hint_support(client, bufnr)

  -- Don't check for the capability here to allow dynamic registration of the request.
  vim.lsp.document_color.enable(true, bufnr)
  add_lsp_keymaps(client, bufnr)
  add_cursor_hold_diagnostics(client, bufnr)
  if client:supports_method 'textDocument/codeAction' then
    require('lsp.code_action').on_attach(bufnr, client)
  end
end

-- Two ways shown to configure keymaps with LSP
--- Dynamic registration of capabilities
vim.lsp.handlers['client/registerCapability'] = (function(overridden_register_caps)
  return function(err, res, ctx)
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    if not client then
      return
    end

    VimRc.info(string.format('[registerCapability] - Client %s', client.name))
    VimRc.debug(client.capabilities)
    -- Update mappings when registering dynamic capabilities.
    on_attach(client, vim.api.nvim_get_current_buf())
    -- end
    return overridden_register_caps(err, res, ctx)
  end
end)(vim.lsp.handlers['client/registerCapability'])

--- During attach
vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'Configure LSP keymaps',
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    local bufnr = args.buf
    VimRc.info(string.format('[LspAttach autocmd] - Client %s', client.name))
    on_attach(client, bufnr)
  end,
})

-- Set up LSP servers.
local desired_lsp_servers = { 'lua_ls', 'tinymyst', 'clangd', 'cmake', 'bashls', 'taplo', 'yamlls', 'jsonls', 'marksman', 'ruff' }
local custom_caps_lsps = { 'devicetree_ls' }
vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
  once = true,
  callback = function()
    -- Extend neovim's client capabilities with the completion ones.
    if MiniCompletion then
      vim.lsp.config('*', { capabilities = MiniCompletion.get_lsp_capabilities() })
    else
      vim.lsp.config('*', { capabilities = require('blink.cmp').get_lsp_capabilities(nil, true) })
    end
    -- custom_lsp_caps_registration(custom_caps_lsps)
    vim.lsp.enable(desired_lsp_servers)
  end,
})
