-- Install with
-- mac: brew install dprint
-- Arch: paru -S dprint

---@type vim.lsp.Config
return {
  cmd = { 'dprint', 'lsp' },
  filetypes = {
    'javascript',
    'json',
    'jsonc',
    'markdown',
    'typescript',
  },
}
