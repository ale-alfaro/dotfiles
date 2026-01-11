vim.pack.add(_G.plug_spec {
  'neovim/nvim-lspconfig',
  'rachartier/tiny-code-action.nvim',
  'p00f/clangd_extensions.nvim',
})

local diagnostics = require 'lsp.diagnostics'
local lsp_servers = { 'lua_ls', 'clangd', 'neocmake', 'bashls', 'taplo', 'yamls', 'jsonls', 'marksman', 'ruff', 'pyrefly' }
local lspau = vim.api.nvim_create_augroup('vimrc.lsp', {})
vim.api.nvim_create_autocmd('LspAttach', {
  group = lspau,
  desc = 'Configure LSP keymaps',
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    -- I don't think this can happen but it's a wild world out there.
    if not client then
      return
    end
    local bufnr = args.buf
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
      vim.api.nvim_create_user_command('InlayHints', function()
        vim.g.inlay_hints = false
        require('lsp.inlay_hints').add_inlay_hint_support(client, bufnr)
      end, { desc = 'Enable InlayHints' })
    end
    diagnostics.setup_diagnostics_cursorhold(bufnr)
    if client:supports_method 'textDocument/codeAction' then
      require('lsp.code_action').on_attach(bufnr, client)
    end
    if client:supports_method 'workspace/diagnostic' then
      local folders = vim.lsp.buf.list_workspace_folders()
      _G.info 'LSP Client supports workspace diagnostics. Adding user command to fetch them. Current workspace folder: '
      _G.info(folders)
      diagnostics.setup_workspace_diagnostics(client, bufnr)
    end

    -- vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = false })

    -- Don't check for the capability here to allow dynamic registration of the request.
    vim.lsp.document_color.enable(true, bufnr)
    require('lsp.keys').on_attach(bufnr, client)
  end,
})

-- Diagnostic configuration.
diagnostics.setup()

local hover = vim.lsp.buf.hover
---@diagnostic disable-next-line: duplicate-set-field
vim.lsp.buf.hover = function()
  return hover {
    max_height = math.floor(vim.o.lines * 0.5),
    max_width = math.floor(vim.o.columns * 0.4),
  }
end

local signature_help = vim.lsp.buf.signature_help
---@diagnostic disable-next-line: duplicate-set-field
vim.lsp.buf.signature_help = function()
  return signature_help {
    max_height = math.floor(vim.o.lines * 0.5),
    max_width = math.floor(vim.o.columns * 0.4),
  }
end

-- Set up LSP servers.
vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
  once = true,
  callback = function()
    -- Extend neovim's client capabilities with the completion ones.
    vim.lsp.config('*', { capabilities = require('blink.cmp').get_lsp_capabilities(nil, true) })
    vim.lsp.enable(lsp_servers)
  end,
})
