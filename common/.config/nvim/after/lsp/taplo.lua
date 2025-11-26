---@type vim.lsp.Config
return {
  cmd = { 'taplo', 'lsp', 'stdio' },
  filetypes = { 'toml' },
  root_markers = { '*.toml' }
  -- root_dir = function(fname)
  --   return vim.fs.dirname(vim.fs.find('.git', { path = fname, upward = true })[1])
  -- end,
}
