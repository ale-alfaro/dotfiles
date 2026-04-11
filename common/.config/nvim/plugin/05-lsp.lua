-- This Lsps are better not enabled by default and enabled locally
-- Set up LSP servers.
VimRc.now_if_args(function()
  vim.pack.add(_G.plug_spec {
    'neovim/nvim-lspconfig',
    'b0o/schemastore.nvim',
    'rachartier/tiny-code-action.nvim',
  })
  require('tiny-code-action').setup {
    picker = {
      'buffer',
      opts = {
        hotkeys = true,
        -- Use numeric labels.
        hotkeys_mode = function(titles)
          return vim
            .iter(ipairs(titles))
            :map(function(i)
              return tostring(i)
            end)
            :totable()
        end,
      },
    },
  }
  vim.lsp.config('yaml_ls', {
    settings = {
      yaml = {

        schemaStore = {
          -- You must disable built-in schemaStore support if you want to use
          -- this plugin and its advanced options like `ignore`.
          enable = false,
          -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
          url = '',
        },
        schemas = require('schemastore').yaml.schemas(),
        validate = { enable = true },
        format = { enable = true },
      },
    },
  })
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities.textDocument.completion.completionItem.snippetSupport = true

  vim.lsp.config('jsonls', {
    capabilities = capabilities,
    settings = {
      json = {
        schemas = require('schemastore').yaml.schemas(),
        validate = { enable = true },
      },
    },
  })
  vim.lsp.config('neocmake', {
    capabilities = {
      textDocument = {
        completionItem = {
          snippetSupport = true,
        },
      },
    },
  })
end)
---@param client vim.lsp.Client
---@param bufnr integer
local on_attach = function(client, bufnr)
  -- Enable auto-completion. Note: Use CTRL-Y to select an item. |complete_CTRL-Y|
  VimRc.new_buf_autocmd({ 'CursorHold', 'InsertLeave' }, bufnr, vim.lsp.buf.document_highlight, 'Highlight references under the cursor')
  VimRc.new_buf_autocmd({ 'CursorMoved', 'InsertEnter', 'BufLeave' }, bufnr, vim.lsp.buf.clear_references, 'Clear highlight references')

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

  VimRc.new_buf_autocmd('CursorHold', bufnr, function()
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
  -- Auto-format ("lint") on save.
  -- Usually not needed if server supports "textDocument/willSaveWaitUntil".
  if not client:supports_method 'textDocument/willSaveWaitUntil' and client:supports_method 'textDocument/formatting' then
    vim.api.nvim_create_autocmd('BufWritePre', {
      group = vim.api.nvim_create_augroup('my.lsp', { clear = false }),
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.format { bufnr = bufnr, id = client.id, timeout_ms = 1000 }
      end,
    })
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
VimRc.new_autocmd('LspAttach', function(ev)
  local bufnr = ev.buf

  local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))

  VimRc.info('[LspAttach autocmd] - ', { Client = client.name })
  on_attach(client, bufnr)
end, '*', 'LspAttach Configure Lsps')

VimRc.new_autocmd('LspDetach', function(ev)
  -- Get the detaching client
  local client = vim.lsp.get_client_by_id(ev.data.client_id)

  -- Remove the autocommand to format the buffer on save, if it exists
  if client and client:supports_method 'textDocument/formatting' then
    vim.api.nvim_clear_autocmds {
      event = 'BufWritePre',
      buffer = ev.buf,
    }
  end
end, 'Clear after lsp detacb')

-- vim.cmd([[
--   autocmd BufWritePre *.rs lua vim.lsp.buf.format({ async = false }
-- ]])
VimRc.oneshot_autocmd({ 'BufReadPre', 'BufNewFile' }, function()
  -- Extend neovim's client capabilities with the completion ones.
  local capabilities = MiniCompletion.get_lsp_capabilities()
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  vim.lsp.config('*', { capabilities = capabilities })

  local path = vim.fs.joinpath(vim.fn.expand '$XDG_CONFIG_HOME', 'nvim')
  local servers = VimRc.lsp_configs_get(path)
  VimRc.info('Enabling lsps: ', { servers = servers })
  vim.lsp.enable(servers)
end)

-- HACK: Override buf_request to ignore notifications from LSP servers that don't implement a method.
local buf_request = vim.lsp.buf_request
---@diagnostic disable-next-line: duplicate-set-field
vim.lsp.buf_request = function(bufnr, method, params, handler)
  return buf_request(bufnr, method, params, handler, function() end)
end

VimRc.on_filetype('c', function()
  vim.pack.add {
    'p00f/clangd_extensions.nvim',
  }
  require('clangd_extensions').setup {
    ast = {
      role_icons = {
        type = '🄣',
        declaration = '🄓',
        expression = '🄔',
        statement = ';',
        specifier = '🄢',
        ['template argument'] = '🆃',
      },

      kind_icons = {
        Compound = '🄲',
        Recovery = '🅁',
        TranslationUnit = '🅄',
        PackExpansion = '🄿',
        TemplateTypeParm = '🅃',
        TemplateTemplateParm = '🅃',
        TemplateParamObject = '🅃',
      },

      highlights = {
        detail = 'Comment',
      },
    },

    memory_usage = {
      border = 'none',
    },

    symbol_info = {
      border = 'none',
    },
  }
end)

VimRc.on_filetype('cmake', function()
  vim.lsp.config('neocmake', {
    capabilities = {
      textDocument = {
        completionItem = {
          snippetSupport = true,
        },
      },
    },
  })
  vim.lsp.enable 'neocmake'
end)
