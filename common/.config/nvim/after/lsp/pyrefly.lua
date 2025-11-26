---@type vim.lsp.Config
return {
  cmd = { 'pyrefly', 'lsp' },
  root_markers = {
    'pyrefly.toml',
    'uv.lock',
    'pyproject.toml',
    'setup.py',
    'setup.cfg',
    'requirements.txt',
    'Pipfile',
    '.git',
  },
  settings = {
    python = {
      pyrefly = {
        disabledLanguageServices = {
          inlayHints = true,
        },
      },
    },
  },
  ---@param client vim.lsp.Client
  ---@param bufnr integer
  -- on_attach = function(client, bufnr)
  -- end
}
