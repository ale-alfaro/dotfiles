---@brief
--- https://github.com/neocmakelsp/neocmakelsp
--- --Enable (broadcasting) snippet capability for completion
--- local capabilities = vim.lsp.protocol.make_client_capabilities()
--- capabilities.textDocument.completion.completionItem.snippetSupport = true
---
--- vim.lsp.config('neocmake', {
---   capabilities = capabilities,
--- })
---@type vim.lsp.Config
return {
  cmd = { 'neocmakelsp', 'stdio' },
  filetypes = { 'cmake' },
  root_markers = { '.neocmakelsp' },
  init_options = {
    format = {
      enable = false,
    },
    lint = {
      enable = false,
    },
  },
}
