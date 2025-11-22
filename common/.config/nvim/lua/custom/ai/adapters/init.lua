M = {}

function M.setup(opts)
  opts.adapters = {
    acp = {
      opts = {
        show_defaults = false,
      },
      gemini_cli = function()
        return require('codecompanion.adapters').extend('gemini_cli', {
          commands = {
            default = {
              'gemini',
              '--experimental-acp',
              '-m',
              'gemini-2.5-pro',
            },
          },
          defaults = { auth_method = 'gemini-api-key', mcpServers = {}, timeout = 20000 },
          env = { GEMINI_API_KEY = vim.fn.expand '$GEMINI_API_KEY' },
        })
      end,
    },
    http = {
      opts = {
        show_defaults = false,
      },
      qwen3 = function()
        return require('codecompanion.adapters').extend('ollama', {
          name = 'qwen3', -- Give this adapter a different name to differentiate it from the default ollama adapter
          opts = {
            vision = true,
            stream = true,
          },
          schema = {
            model = {
              default = 'qwen3:latest',
            },
            num_ctx = {
              default = 30000,
            },
            think = {
              default = false,
            },
            keep_alive = {
              default = '5m',
            },
          },
        })
      end,
    },
  }
end

return M
