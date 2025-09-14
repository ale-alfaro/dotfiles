return {
  'olimorris/codecompanion.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  init = function()
    local group = vim.api.nvim_create_augroup('CodeCompanionHooks', { clear = true })

    vim.api.nvim_create_autocmd({ 'User' }, {
      pattern = 'CodeCompanionInlineFinished',
      group = group,
      callback = function(request)
        require('conform').format { bufnr = request.buf }
      end,
    })

    vim.api.nvim_create_autocmd({ 'User' }, {
      pattern = 'CodeCompanionChatOpened',
      group = group,
      callback = function(request)
        vim.notify('Disabling g keymaps for CodeCompanion', vim.log.levels.INFO)
        local buffer_keymaps = vim.api.nvim_buf_get_keymap(request.buf, 'n')
        local keymaps_to_disable = vim.tbl_filter(function(key)
          return key.lhs:sub(1, 1) == 'g'
        end, buffer_keymaps)
        for _, mapping in ipairs(keymaps_to_disable) do
          vim.api.nvim_buf_del_keymap(request.buf, 'n', mapping.lhs)
        end
      end,
    })

    local spinner = require 'plugins.extras.ai_fidget_spinner'
    spinner:init()
  end,
  opts = {
    adapters = {
      acp = {
        gemini_cli = function()
          return require('codecompanion.adapters').extend('gemini_cli', {
            commands = {
              default = {
                'gemini',
                '--experimental-acp',
              },
            },
            defaults = {
              auth_method = 'gemini-api-key',
              mcpServers = {},
              timeout = 20000, -- 20 seconds
            },
            env = {
              GEMINI_API_KEY = vim.fn.expand '$GEMINI_API_KEY',
              PATH = vim.fn.expand '~/.local/bin:' .. vim.fn.expand '$PATH',
            },
          })
        end,
      },
    },
    strategies = {
      chat = {
        adapter = 'gemini_cli',
        model = 'gemini-2.5-flash',
        keymaps = {
          close = {
            modes = { n = 'q', i = '<C-q>' },
          },
          send = {
            modes = { n = '<C-s>', i = '<C-s>' },
            callback = function(chat)
              vim.cmd 'stopinsert'
              chat:submit()
              chat:add_buf_message { role = 'llm', content = '' }
            end,
          },
        },
      },
      opts = {
        log_level = 'DEBUG',
      },
    },
    display = {
      chat = {
        show_settings = true, -- Show LLM settings at the top of the chat buffer?
      },
    },
  },
  keys = {
    { '<leader>ar', mode = { 'n', 'v' }, '<cmd>CodeCompanionChat RefreshCache<cr>', desc = 'CodeCompanion RefreshCache' },
    { '<leader>aa', mode = { 'n', 'v' }, '<cmd>CodeCompanionActions<cr>', desc = 'CodeCompanion Actions' },
    { '<leader>at', mode = { 'n', 'v' }, '<cmd>CodeCompanionChat Toggle<cr>', desc = 'CodeCompanionChat Toggle' },
    { '<leader>ai', mode = { 'n', 'v' }, '<cmd>CodeCompanionChat Add<cr>', desc = 'CodeCompanionChat Add' },
    { '<leader>ah', mode = { 'n', 'v' }, '<cmd>CodeCompanionHistory<cr>', desc = 'CodeCompanionHistory' },
    { '<leader>as', mode = { 'n', 'v' }, '<cmd>CodeCompanionSummaries<cr>', desc = 'Browse CodeCompanionSummaries' },
  },
}
