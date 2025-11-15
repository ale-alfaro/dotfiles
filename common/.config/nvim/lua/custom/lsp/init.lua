M = {}
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

  -- if not client:supports_method 'textDocument/willSaveWaitUntil' and client:supports_method 'textDocument/formatting' then
  --   Format = require('custom.lsp.format')
  --   Format.toggle(bufnr)
  --   vim.api.nvim_create_autocmd('BufWritePre', {
  --     buffer = bufnr,
  --     callback = function()
  --       -- Format.format(client, bufnr)
  --       vim.lsp.buf.format { bufnr = bufnr, id = client.id, timeout_ms = 1000 }
  --     end,
  --   })
  -- end

  -- Don't check for the capability here to allow dynamic registration of the request.
  vim.lsp.document_color.enable(true, bufnr)
  require('custom.lsp.autocmds').on_attach(bufnr, client)
  require('custom.lsp.keys').on_attach(bufnr, client)
end

function M.config()
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
