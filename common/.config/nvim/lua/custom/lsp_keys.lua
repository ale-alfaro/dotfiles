
---@class LspUtilities
local M = {}

-- vim.api.nvim_create_autocmd('LspAttach', {
-- 	group = vim.api.nvim_create_augroup('my.lsp', {}),
-- 	callback = function(args)
-- 		local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
-- 		if client:supports_method('textDocument/definition') then
-- 			require 'which-key'.add({ 'gd', vim.lsp.buf.definition, desc = 'Go to LSP Definition' })
-- 		end
-- 		if client:supports_method('textDocument/completion') then
-- 			vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = false })
-- 		end
-- 		if not client:supports_method('textDocument/willSaveWaitUntil')
-- 				and client:supports_method('textDocument/formatting') then
-- 			vim.api.nvim_create_autocmd('BufWritePre', {
-- 				group = vim.api.nvim_create_augroup('my.lsp', { clear = false }),
-- 				buffer = args.buf,
-- 				callback = function()
-- 					vim.lsp.buf.format({ bufnr = args.buf, id = client.id, timeout_ms = 1000 })
-- 				end,
-- 			})
-- 		end
-- 	end,
-- })

---@type KeymapSpec[]|nil
M._keys = nil

---@return KeymapSpec[]
function M.get_lsp_keys(bufnr, bufopts)
  if M._keys then
    return M._keys
  end
  -- stylua: ignore
  M._keys = {
    -- { lhs = "<leader>cl", rhs = function() Snacks.picker.lsp_config() end,          desc = "Lsp Info" },
    { lhs = "gd",         rhs = vim.lsp.buf.definition,                             desc = "Goto Definition",            has = "definition" },
    { lhs = "gr",         rhs = vim.lsp.buf.references,                             desc = "References",                 nowait = true },
    { lhs = "gI",         rhs = vim.lsp.buf.implementation,                         desc = "Goto Implementation" },
    { lhs = "gy",         rhs = vim.lsp.buf.type_definition,                        desc = "Goto T[y]pe Definition" },
    { lhs = "gD",         rhs = vim.lsp.buf.declaration,                            desc = "Goto Declaration" },
    { lhs = "K",          rhs = function() return vim.lsp.buf.hover() end,          desc = "Hover" },
    { lhs = "gK",         rhs = function() return vim.lsp.buf.signature_help() end, desc = "Signature Help",             has = "signatureHelp" },
    { lhs = "<c-k>",      rhs = function() return vim.lsp.buf.signature_help() end, mode = "i",                          desc = "Signature Help", has = "signatureHelp" },
    { lhs = "<leader>ca", rhs = vim.lsp.buf.code_action,                            desc = "Code Action",                mode = { "n", "v" },     has = "codeAction" },
    { lhs = "<leader>cc", rhs = vim.lsp.codelens.run,                               desc = "Run Codelens",               mode = { "n", "v" },     has = "codeLens" },
    { lhs = "<leader>cC", rhs = vim.lsp.codelens.refresh,                           desc = "Refresh & Display Codelens", mode = { "n" },          has = "codeLens" },
    { lhs = "<leader>cr", rhs = vim.lsp.buf.rename,                                 desc = "Rename",                     has = "rename" },
    -- {
    --   "]]",
    --   function() Snacks.words.jump(vim.v.count1) end,
    --   has = "documentHighlight",
    --   desc = "Next Reference",
    --   cond = function() return Snacks.words.is_enabled() end
    -- },
    -- {
    --   "[[",
    --   function() Snacks.words.jump(-vim.v.count1) end,
    --   has = "documentHighlight",
    --   desc = "Prev Reference",
    --   cond = function() return Snacks.words.is_enabled() end
    -- },
    -- {
    --   "<a-n>",
    --   -- function() Snacks.words.jump(vim.v.count1, true) end,
    --   has = "documentHighlight",
    --   desc = "Next Reference",
    --   cond = function() return Snacks.words.is_enabled() end
    -- },
    -- {
    --   "<a-p>",
    --   function() Snacks.words.jump(-vim.v.count1, true) end,
    --   has = "documentHighlight",
    --   desc = "Prev Reference",
    --   cond = function() return Snacks.words.is_enabled() end
    -- },
  }

  vim.api.nvim_create_autocmd('CursorHold', {
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
      vim.diagnostic.open_float(nil, hover_opts)
    end,
  })

  local bufopts = { noremap = true, silent = true, buffer = bufnr }
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, vim.tbl_extend('force', bufopts, { desc = '✨lsp hover for docs' }))
  vim.keymap.set('n', 'rn', function()
    return ':IncRename ' .. vim.fn.expand '<cword>'
  end, { expr = true })
  vim.keymap.set(
    'n',
    '<leader>gl',
    vim.diagnostic.enable(not vim.diagnostic.is_enabled { bufnr = bufnr }, { bufnr = bufnr }),
    vim.tbl_extend('force', bufopts, { desc = '✨lsp toggle inlay hints' })
  )

  vim.keymap.set(
    'n',
    '<leader>dh',
    vim.lsp.inlay_hints.enable(not vim.lsp.inlay_hints.is_enabled { bufnr = bufnr }, { bufnr = bufnr }),
    vim.tbl_extend('force', bufopts, { desc = '✨lsp toggle inlay hints' })
  )

  return M._keys
end

---@param method string|string[]
function M.has(buffer, method)
  if type(method) == 'table' then
    for _, m in ipairs(method) do
      if M.has(buffer, m) then
        return true
      end
    end
    return false
  end
  method = method:find '/' and method or 'textDocument/' .. method
  local clients = vim.lsp.get_clients { bufnr = buffer }
  for _, client in ipairs(clients) do
    if client:supports_method(method) then
      return true
    end
  end
  return false
end

function M.on_attach_lsp_keys(_, buffer)
  local keymaps = M.get_lsp_keys()
  for _, keys in pairs(keymaps) do
    local has = not keys.has or M.has(buffer, keys.has)
    if has then
      opts = { buffer = buffer }
      vim.keymap.set(keys.mode or 'n', keys.lhs, keys.rhs, opts)
    end
  end
end

return M
