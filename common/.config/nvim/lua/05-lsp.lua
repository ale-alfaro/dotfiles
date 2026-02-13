vim.pack.add(_G.plug_spec {
  'neovim/nvim-lspconfig',
  'rachartier/tiny-code-action.nvim',
  'p00f/clangd_extensions.nvim',
})

require('lsp.custom_diagnostics').diagnostics_setup()

-- Disable inlay hints initially (and enable if needed with my ToggleInlayHints command).
vim.g.inlay_hints = false

--- Sets up LSP keymaps and autocommands for the given buffer.
---@param client vim.lsp.Client
---@param bufnr integer
local function on_attach(client, bufnr)
  ---@param lhs string
  ---@param rhs string|function
  ---@param opts string|vim.keymap.set.Opts
  ---@param mode? string|string[]
  local function keymap(lhs, rhs, opts, mode)
    mode = mode or 'n'
    ---@cast opts vim.keymap.set.Opts
    opts = type(opts) == 'string' and { desc = opts } or opts
    opts.buffer = bufnr
    vim.keymap.set(mode, lhs, rhs, opts)
  end
  vim.lsp.document_color.enable(true, bufnr)
  if client:supports_method 'textDocument/documentColor' then
    keymap('grc', function()
      vim.lsp.document_color.color_presentation()
    end, 'vim.lsp.document_color.color_presentation()', { 'n', 'x' })
  end

  if client:supports_method 'textDocument/references' then
    keymap('grr', '<cmd>FzfLua lsp_references<cr>', 'vim.lsp.buf.references()')
  end

  if client:supports_method 'textDocument/typeDefinition' then
    keymap('gy', '<cmd>FzfLua lsp_typedefs<cr>', 'Go to type definition')
  end

  if client:supports_method 'textDocument/documentSymbol' then
    keymap('<leader>fs', '<cmd>FzfLua lsp_document_symbols<cr>', 'Document symbols')
  end

  if client:supports_method 'textDocument/definition' then
    keymap('gd', function()
      require('fzf-lua').lsp_definitions { jump1 = true }
    end, 'Go to definition')
    keymap('gD', function()
      require('fzf-lua').lsp_definitions { jump1 = false }
    end, 'Peek definition')
  end

  if client:supports_method 'textDocument/signatureHelp' then
    keymap('<C-k>', function()
      -- Close the completion menu first (if open).
      if require('blink.cmp.completion.windows.menu').win:is_open() then
        require('blink.cmp').hide()
      end

      vim.lsp.buf.signature_help()
    end, 'Signature help', 'i')
  end

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

  -- Add "Fix all" command for linters.
  if client.name == 'eslint' or client.name == 'stylelint_lsp' then
    vim.keymap.set('n', '<leader>cl', function()
      if not client then
        return
      end

      client:request('workspace/executeCommand', {
        command = client.name == 'eslint' and 'eslint.applyAllFixes' or 'stylelint.applyAutoFixes',
        arguments = {
          {
            uri = vim.uri_from_bufnr(bufnr),
            version = vim.lsp.util.buf_versions[bufnr],
          },
        },
      }, nil, bufnr)
    end, {
      desc = string.format('Fix all %s errors', client.name == 'eslint' and 'ESLint' or 'Stylelint'),
      buffer = bufnr,
    })
  end
end
--- Two ways shown to configure keymaps with LSP
--- Dynamic registration of capabilities
vim.lsp.handlers['client/registerCapability'] = (function(overridden)
  return function(err, res, ctx)
    local result = overridden(err, res, ctx)
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    if not client then
      return
    end

    if client.name == 'devicetree_ls' then
      VimRc.info 'DEVICETREE_LS CAPS:'
      VimRc.info(client.capabilities)
    else
      VimRc.debug(string.format('registerCapability - Client %s capabilities:', client.name))
      VimRc.debug(client.capabilities)
    end
    for bufnr, _ in pairs(client.attached_buffers) do
      -- Call your custom on_attach logic...
      on_attach(client, bufnr)
    end
    return result
  end
end)(vim.lsp.handlers['client/registerCapability'])

--- During attach
vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'Configure LSP keymaps',
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    local bufnr = args.buf
    if client.name == 'devicetree_ls' then
      VimRc.info 'LSP ATTACH EVENT - DEVICETREE_LS CAPS:'
      VimRc.info(client.capabilities)
    else
      VimRc.debug(string.format('LspAttach - Client %s capabilities:', client.name))
      VimRc.debug(client.capabilities)
    end
    -- Enable auto-completion. Note: Use CTRL-Y to select an item. |complete_CTRL-Y|
    if client:supports_method 'textDocument/completion' then
      -- Optional: trigger autocompletion on EVERY keypress. May be slow!
      -- local chars = {}; for i = 32, 126 do table.insert(chars, string.char(i)) end
      -- client.server_capabilities.completionProvider.triggerCharacters = chars

      vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
    end
    if client:supports_method 'textDocument/inlayHint' then
      vim.api.nvim_create_user_command('InlayHints', function()
        vim.g.inlay_hints = false
        require('lsp.inlay_hints').add_inlay_hint_support(client, bufnr)
      end, { desc = 'Enable InlayHints' })
    end

    -- Don't check for the capability here to allow dynamic registration of the request.
    vim.lsp.document_color.enable(true, bufnr)
    require('lsp.keys').on_attach(bufnr, client)
    require('lsp.custom_diagnostics').setup_diagnostics_cursorhold(bufnr)
    if client:supports_method 'textDocument/codeAction' then
      -- require('lsp.code_action').on_attach(bufnr, client)
    end
  end,
})

-- Set up LSP servers.
local desired_lsp_servers = { 'lua_ls', 'tinymyst', 'esbonio', 'clangd', 'cmake', 'bashls', 'taplo', 'yamlls', 'jsonls', 'marksman', 'ruff', 'pyrefly' }
local found_server_cfgs = vim
  .iter(vim.api.nvim_get_runtime_file('lsp/*.lua', true))
  :map(function(file)
    return vim.fn.fnamemodify(file, ':t:r')
  end)
  :totable()
for _, server in ipairs(desired_lsp_servers) do
  if not vim.iter(found_server_cfgs):find(server) then
    VimRc.warn(string.format("Couldn' find %s lsp server in configs in runtime path", server))
  end
end
vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
  once = true,
  callback = function()
    -- Extend neovim's client capabilities with the completion ones.
    if MiniCompletion then
      vim.lsp.config('*', { capabilities = MiniCompletion.get_lsp_capabilities() })
    else
      vim.lsp.config('*', { capabilities = require('blink.cmp').get_lsp_capabilities(nil, true) })
    end
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
    vim.lsp.enable(desired_lsp_servers)
  end,
})
