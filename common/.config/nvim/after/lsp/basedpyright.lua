---@type vim.lsp.Config
return {
  cmd = { 'uv', 'run', 'basedpyright-langserver', '--stdio' },
  root_markers = {
    'uv.lock',
    'pyproject.toml',
  },
  settings = {
    basedpyright = {
      disableOrganizeImports = true,
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = 'openFilesOnly',
        typeCheckingMode = 'basic',
        autoImportCompletions = true,
      },
    },
  },
}
