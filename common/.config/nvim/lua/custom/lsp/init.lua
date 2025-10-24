M = {}
--
-- setmetatable(M, {
--   __index = function(t, k)
--     ---@diagnostic disable-next-line: no-unknown
--     t[k] = require('custom.lsp.' .. k)
--     return t[k]
--   end,
-- })
--- Sets up LSP keymaps and autocommands for the given buffer.
---@param client vim.lsp.Client
---@param bufnr integer
function M.on_attach(client, bufnr)
  if client:supports_method 'textDocument/codeAction' then
    require('custom.lsp.code_action').on_attach(bufnr, client)
  end

  if client:supports_method 'textDocument/completion' then
    local ok, blink = pcall(require, 'blink.cmp')
    if ok then
      client.server_capabilities = blink.get_lsp_capabilities(client.server_capabilities)
    else
      vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = false })
    end
  end

  if not client:supports_method 'textDocument/willSaveWaitUntil' and client:supports_method 'textDocument/formatting' then
    require('custom.lsp.format').setup()
    -- vim.api.nvim_create_autocmd('BufWritePre', {
    --   buffer = bufnr,
    --   callback = function()
    --     -- VimRc.format { buf = bufnr }
    --     vim.lsp.buf.format { bufnr = bufnr, id = client.id, timeout_ms = 1000 }
    --   end,
    -- })
  end

  -- Don't check for the capability here to allow dynamic registration of the request.
  vim.lsp.document_color.enable(true, bufnr)
  require('custom.lsp.autocmds').on_attach(bufnr, client)
  require('custom.lsp.keys').on_attach(bufnr, client)
end

function M.config()
  local diagnostic_icons = VimRc.icons.diagnostics
  -- Disable inlay hints initially (and enable if needed with my ToggleInlayHints command).
  vim.g.inlay_hints = false
  -- Define the diagnostic signs.
  for severity, icon in pairs(diagnostic_icons) do
    local hl = 'DiagnosticSign' .. severity:sub(1, 1) .. severity:sub(2):lower()
    vim.fn.sign_define(hl, { text = icon, texthl = hl })
  end

  -- Diagnostic configuration.
  vim.diagnostic.config {
    virtual_text = {
      prefix = '',
      spacing = 2,
      format = function(diagnostic)
        -- Use shorter, nicer names for some sources:
        local special_sources = {
          ['Lua Diagnostics.'] = 'lua',
          ['Lua Syntax Check.'] = 'lua',
        }

        local message = diagnostic_icons[vim.diagnostic.severity[diagnostic.severity]]
        if diagnostic.source then
          message = string.format('%s %s', message, special_sources[diagnostic.source] or diagnostic.source)
        end
        if diagnostic.code then
          message = string.format('%s[%s]', message, diagnostic.code)
        end

        return message .. ' '
      end,
    },
    float = {
      source = 'if_many',
      -- Show severity icons as prefixes.
      prefix = function(diag)
        local level = vim.diagnostic.severity[diag.severity]
        local prefix = string.format(' %s ', diagnostic_icons[level])
        return prefix, 'Diagnostic' .. level:gsub('^%l', string.upper)
      end,
    },
    -- Disable signs in the gutter.
    signs = false,
  }

  -- Override the virtual text diagnostic handler so that the most severe diagnostic is shown first.
  local show_handler = vim.diagnostic.handlers.virtual_text.show
  assert(show_handler)
  local hide_handler = vim.diagnostic.handlers.virtual_text.hide
  vim.diagnostic.handlers.virtual_text = {
    show = function(ns, bufnr, diagnostics, opts)
      table.sort(diagnostics, function(diag1, diag2)
        return diag1.severity > diag2.severity
      end)
      return show_handler(ns, bufnr, diagnostics, opts)
    end,
    hide = hide_handler,
  }

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
  vim.lsp.config('*', {
    capabilities = {
      workspace = {
        fileOperations = {
          didRename = true,
          willRename = true,
        },
      },
    },
  })
end

return M
