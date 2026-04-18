---@return vim.lsp.Config
return {
  cmd = { 'mise', 'x', '--', 'typescript-language-server', '--stdio' },
  root_markers = { '.obsidian' },
  root_dir = function(bufnr, on_dir)
    local project_root = vim.fs.root(bufnr, { '.obsidian' })
    on_dir(project_root or vim.fn.getcwd())
  end,
}
