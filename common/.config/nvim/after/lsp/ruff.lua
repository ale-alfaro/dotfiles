return {
  root_markers = { 'uv.lock', 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
  settings = {
    init_options = {
      settings = {
        args = {
          '--extend-select',
          'I',
          '--ignore',
          'F821',
          '--ignore',
          'E402',
          '--ignore',
          'E722',
          '--ignore',
          'E712',
        },
        logLevel = 'error',
        -- fixAll = true,
        lint = {
          -- preview = true,
        },
        formatter = {
          -- preview = true,
          backend = 'uv',
        },
        exclude = { '**/build/**' },
      },
    },
  },
}
