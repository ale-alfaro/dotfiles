return {
  cmd = { 'ruff', 'server' },
  root_markers = { 'uv.lock', 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
  settings = {
    init_options = {
      settings = {
        args = {
          '--extend-select',
          'I',
        },
        logLevel = 'error',
        -- fixAll = true,
        lint = {
          preview = true,
        },
        formatter = {
          preview = true,
          backend = 'uv',
        },
        exclude = { '**/build/**' },
      },
    },
  },
}
