---@type vim.lsp.Config
return {
  name = 'dts_lsp',
  cmd = { 'dts-lsp' },
  filetypes = { 'dts', 'dtsi', 'overlay' },
  root_markers = { '.git' },
  settings = {},
}
