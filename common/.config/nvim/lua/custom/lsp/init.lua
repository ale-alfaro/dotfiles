M = {}

---@param client vim.lsp.Client
---@param bufnr number
local function add_inlay_hint_support(client, bufnr)
  local inlay_hints_group = vim.api.nvim_create_augroup('mariasolos/toggle_inlay_hints', { clear = false })

  -- Initial inlay hint display.
  -- Idk why but without the delay inlay hints aren't displayed at the very start.
  vim.defer_fn(function()
    local mode = vim.api.nvim_get_mode().mode
    vim.lsp.inlay_hint.enable(mode == 'n' or mode == 'v', { bufnr = bufnr })
  end, 500)

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

---@param lsp_servers string[]
function M.config(lsp_servers)
  vim.g.inlay_hints = false
  -- Diagnostic configuration.
  require('custom.lsp.diagnostics').setup()

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
          add_inlay_hint_support(client, bufnr)
        end, { desc = 'Enable InlayHints' })
      end

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
      if client:supports_method 'textDocument/codeAction' then
        require('custom.lsp.code_action').on_attach(bufnr, client)
      end

      -- vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = false })

      -- Don't check for the capability here to allow dynamic registration of the request.
      vim.lsp.document_color.enable(true, bufnr)
      require('custom.lsp.keys').on_attach(bufnr, client)
    end,
  })

  -- Set up LSP servers.
  vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
    once = true,
    callback = function()
      -- Extend neovim's client capabilities with the completion ones.
      vim.lsp.config('*', { capabilities = require('blink.cmp').get_lsp_capabilities(nil, true) })
      local lsp_path = vim.fs.joinpath(vim.fn.stdpath 'config', 'lua', 'lsp')
      local servers = vim
        .iter(vim.fn.glob(vim.fs.joinpath(lsp_path, '*.lua'), false, true))
        :map(function(file)
          return vim.fn.fnamemodify(file, ':t:r')
        end)
        :totable()
      -- _G.info('registering lsp_servers: ' .. vim.print(servers))
      vim.lsp.enable(servers)

      vim.lsp.enable(lsp_servers)
    end,
  })

  -- Update mappings when registering dynamic capabilities.
  local register_capability = vim.lsp.handlers['client/registerCapability']
  vim.lsp.handlers['client/registerCapability'] = function(err, res, ctx)
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    if not client then
      return
    end

    return register_capability(err, res, ctx)
  end
end

return M
