---@brief
---
--- https://github.com/terror/just-lsp
---
--- `just-lsp` is an LSP for just built on top of the tree-sitter-just parser.

---@type vim.lsp.Config
return {
  cmd = { 'just-lsp' },
  filetypes = { 'just' },
  root_markers = { 'Justfile', '.git' },
  ---@param client vim.lsp.Client
  on_attach = function(client, bufnr)
    local ns_id = vim.lsp.diagnostic.get_namespace(client.id)
    vim.diagnostic.enable(false, { bufnr = bufnr, ns_id = ns_id })
  end,
}
