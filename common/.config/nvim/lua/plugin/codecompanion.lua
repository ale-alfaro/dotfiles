
vim.pack.add(plug_spec(
  { 'olimorris/codecompanion.nvim',
  'lalitmee/codecompanion-spinners.nvim',
  'ravitemer/codecompanion-history.nvim', }
))
-- CodeCompanion
require('codecompanion').setup {
  display = {
    action_palette = { provider = 'Telescope' },
    chat = {
      show_settings = true,
      show_header_separator = true,
      auto_scroll = true,
      show_token_count = true,
    },
  },
  adapters = {
    acp = {
      gemini_cli = function()
        return require('codecompanion.adapters').extend('gemini_cli', {
          commands = {
            ['Gemini 2.5 Pro'] = { 'gemini', '--experimental-acp', '-m', 'gemini-2.5-pro' },
            ['default'] = { 'gemini', '--experimental-acp', '-m', 'gemini-2.5-flash' },
          },
          defaults = { auth_method = 'gemini-api-key', mcpServers = {}, timeout = 20000 },
          env = { GEMINI_API_KEY = vim.fn.expand '$GEMINI_API_KEY' },
        })
      end,
    },
  },
  strategies = {
    chat = {
      adapter = 'gemini_cli',
      opts = { system_prompt = require 'custom.ai.prompts.sysprompt' },
      keymaps = {
        close = { modes = { n = '<C-q>', i = '<C-q>' } },
        send = { modes = { n = '<C-s>', i = '<C-s>' } },
        change_model = {
          modes = { n = 'gm' },
          name = 'Change Model',
          callback = require('custom.ai.adapters').change_model_callback,
          description = 'Change the model for the current chat',
        },
      },
    },
    inline = { adapter = 'gemini_cli' },
  },
  extensions = {
    history = {
      enabled = true,
      opts = {
        keymap = 'gh',
        save_chat_keymap = 'sc',
        auto_save = true,
        expiration_days = 7,
        picker = 'Telescope',
      },
    },
    spinner = {
      enabled = true,
      opts = { style = 'native' },
    },
  },
  memory = {
    gemini = {
      description = 'Collection of common files for all projects',
      files = { 'GEMINI.md', 'AGENTS.md' },
      is_default = true,
    },
    parsers = { gemini = require 'custom.ai.parsers.gemini' },
    opts = {
      chat = {
        enabled = true,
        condition = function(chat)
          return chat.adapter.type ~= 'acp'
        end,
        default_memory = 'gemini',
        default_params = 'watch',
      },
      show_defaults = true,
    },
  },
}
_G.Utils.keymaps.define({
  {mode = { 'n', 'v' }, lhs = '<leader>ar', rhs = '<cmd>CodeCompanionChat RefreshCache<cr>', { desc = 'CodeCompanion RefreshCache' }},
  {mode = { 'n', 'v' }, lhs = '<leader>aa', rhs = '<cmd>CodeCompanionActions<cr>', { desc = 'CodeCompanion Actions' }},
  {mode = { 'n', 'v' }, lhs = '<leader>at', rhs = '<cmd>CodeCompanionChat Toggle<cr>', { desc = 'CodeCompanionChat Toggle' }},
  {mode = { 'n', 'v' }, lhs = '<leader>ai', rhs = '<cmd>CodeCompanionChat Add<cr>', { desc = 'CodeCompanionChat Add' }},
  {mode = { 'n', 'v' }, lhs = '<leader>ah', rhs = '<cmd>CodeCompanionHistory<cr>', { desc = 'CodeCompanionHistory' }},
  {mode = { 'n', 'v' }, lhs = '<leader>as', rhs = '<cmd>CodeCompanionSummaries<cr>', { desc = 'Browse CodeCompanionSummaries' }},
})
