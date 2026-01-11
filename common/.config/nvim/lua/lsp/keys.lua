---@class LspKeymaps
local K = {}


---@class LspKeymapSpec
---@field lhs string
---@field rhs string|function
---@field mode? string|string[]
---@field has? string
---@field desc string 

  -- stylua: ignore
---@type LspKeymapSpec[]
K._keys = {
  { lhs = "gd",         rhs = function() require('fzf-lua').lsp_definitions { jump1 = true } end,                             desc = "Goto Definition",            has = "definition" },
  { lhs = "gD",         rhs = function() require('fzf-lua').lsp_definitions { jump1 = false} end,                             desc = "Peek Definition",            has = "definition" },
  { lhs = "gr",         rhs = '<cmd>FzfLua lsp_references<cr>',                             desc = "References" ,            has = "references" },
  { lhs = "gI",         rhs = '<cmd>FzfLua lsp_implementations<cr>',                         desc = "Goto Implementation" ,            has = "definition"},
  { lhs = "gy",         rhs = '<cmd>FzfLua lsp_typedefs<cr>',                        desc = "Goto T[y]pe Definition" ,            has = "typeDefinition"},
  { lhs = "gD",         rhs = '<cmd>FzfLua lsp_declarations<cr>',                            desc = "Goto Declaration" },
  { lhs = "<leader>fs", rhs = '<cmd>FzfLua lsp_document_symbols<cr>',                    has = "documentSymbol"        ,desc = "Document Symbols" },
  { lhs = "grd",        rhs = function() vim.lsp.document_color.color_presentation() end,                    has = "documentColor"        ,desc = "Document Color" },
  { lhs = "K",          rhs = function() return vim.lsp.buf.hover() end,          desc = "Hover" },
  { lhs = "gK",         rhs = function() return vim.lsp.buf.signature_help() end, desc = "Signature Help",             has = "signatureHelp" },
  { lhs = "<C-k>",      rhs = function() if require('blink.cmp.completion.windows.menu').win:is_open() then require('blink.cmp').hide() end vim.lsp.buf.signature_help()  end, mode = "i",                          desc = "Signature Help", has = "signatureHelp" },
  { lhs = "<leader>ca", rhs = require('tiny-code-action').code_action,          desc = "Code Action",                mode = { "n", "v" },     has = "codeAction" },
  { lhs = "<leader>cc", rhs = vim.lsp.codelens.run,                               desc = "Run Codelens",               mode = { "n", "v" },     has = "codeLens" },
  { lhs = "<leader>cC", rhs = vim.lsp.codelens.refresh,                           desc = "Refresh & Display Codelens", mode = { "n" },          has = "codeLens" },
  { lhs = "<leader>cr", rhs = vim.lsp.buf.rename,                                 desc = "Rename",                     has = "rename" },
}

-- local bufopts = { noremap = true, silent = true, buffer = bufnr }
-- vim.keymap.set(
--   'n',
--   '<leader>gl',
--   vim.diagnostic.enable(not vim.diagnostic.is_enabled ({ bufnr = bufnr }), { bufnr = bufnr }),
--   vim.tbl_extend('force', bufopts, { desc = '✨lsp toggle inlay hints' })
-- )
--
-- vim.keymap.set(
--   'n',
--   '<leader>dh',
--   vim.lsp.inlay_hints.enable(not vim.lsp.inlay_hints.is_enabled { bufnr = bufnr }, { bufnr = bufnr }),
--   vim.tbl_extend('force', bufopts, { desc = '✨lsp toggle inlay hints' })
-- )

---@param method string|string[]
function K.has(buffer, method)
  if type(method) == 'table' then
    for _, m in ipairs(method) do
      if K.has(buffer, m) then
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

local function resolve_lsp_keys_conflicts()
  if vim.g.miniai_disable then
    local map_lsp_selection = function(lhs, desc)
      local s = vim.startswith(desc, 'Increase') and 1 or -1
      local rhs = function()
        vim.lsp.buf.selection_range(s * vim.v.count1)
      end
      vim.keymap.set('x', lhs, rhs, { desc = desc })
    end
    map_lsp_selection('<Leader>ls', 'Increase selection')
    map_lsp_selection('<Leader>lS', 'Decrease selection')
  end
end

--- Configures autocommands to update the code action lightbulb.
---@param bufnr integer
---@param client vim.lsp.Client
K.on_attach = function(bufnr, _)
  local keymaps = K._keys
  for _, keys in pairs(keymaps) do
    local has = not keys.has or K.has(bufnr, keys.has)
    if has then
      vim.keymap.set(keys.mode or 'n', keys.lhs, keys.rhs, { buffer = bufnr, desc = keys.desc })
    end
  end
  resolve_lsp_keys_conflicts()
end

return K
