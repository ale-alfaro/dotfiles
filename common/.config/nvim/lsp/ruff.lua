return {
  cmd = { 'ruff', 'server' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
  settings = {
    init_options = {
      settings = {
        args = {
          '--extend-select',
          'I',
        },
        fixAll = true,
        lint = {
          preview = true,
        },
        formatter = {
          preview = true,
          backend = 'uv',
        },
      },
    },
  },
}
