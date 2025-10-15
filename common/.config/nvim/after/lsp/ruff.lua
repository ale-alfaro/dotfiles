return {
  init_options = {
    settings = {
      args = {
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
}
