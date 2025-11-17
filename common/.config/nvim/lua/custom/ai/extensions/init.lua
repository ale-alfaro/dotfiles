return {
  setup = function(opts)
    opts.extensions = {
      history = {
        enabled = true,
        opts = {
          keymap = 'gh',
          save_chat_keymap = 'sc',
          auto_save = true,
          expiration_days = 7,
          picker = 'fzf_lua',
        },
      },
      vectorcode = {
        enabled = vim.fn.executable 'vectorcode' == 1,
        ---@type VectorCode.CodeCompanion.ExtensionOpts
        opts = {
          prompt_library = {
            -- ['CodeCompanion Assistant'] = {
            --   project_root = plugin.dir,
            --   file_patterns = { 'lua/codecompanion/**.lua', 'doc/**/*.md' },
            -- },
            -- ['Kitty Assistant'] = {
            --   project_root = '/usr/share/doc/kitty/',
            --   file_patterns = { '**/*.txt' },
            -- },
            ['Arch Wiki'] = {
              project_root = '/usr/share/doc/arch-wiki/',
              file_patterns = { '/usr/share/doc/arch-wiki/html/en/**/*.html' },
            },
          },
          tool_group = { collapse = true },
          tool_opts = {
            ['*'] = { use_lsp = true },
            ls = {},
            vectorise = {},
            ---@type VectorCode.CodeCompanion.QueryToolOpts
            query = {
              default_num = { document = 5, chunk = 10 },
              max_num = { document = 10, chunk = 20 },
              chunk_mode = true,
              summarise = {
                enabled = false,
                adapter = function()
                  return require('codecompanion.adapters.http').extend('gemini', {
                    name = 'Summariser',
                    schema = {
                      model = { default = 'gemini-2.0-flash-lite' },
                    },
                    opts = { stream = false },
                  })
                end,
                query_augmented = true,
              },
            },
          },
        },
      },
      spinner = {
        enabled = true,
        opts = { style = 'native' },
      },
    }
  end,
}
