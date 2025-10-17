---@module "codecompanion"

local K = _G.Utils.keymaps.safe_keymap_set

-- Flash
require('flash').setup({})
K({ 'n', 'o', 'x' }, 'S', function() require('flash').treesitter() end, { desc = 'Flash Treesitter' })
K({ 'o', 'x' }, 'R', function() require('flash').treesitter_search() end, { desc = 'Treesitter Search' })
-- K({  "c" , "<c-s>", function() require("flash").toggle() end, { desc = "Toggle Flash Search" } })
K({ 'n', 'o', 'x' }, '<c-space>', function()
  require('flash').treesitter {
    actions = {
      ['<c-space>'] = 'next',
      ['<BS>'] = 'prev',
    },
  }
end, { desc = 'Treesitter Incremental Selection' })

-- Trouble
require('trouble').setup({
  modes = {
    lsp = {
      win = { position = "right" },
    },
  },
})
K('n', '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', { desc = 'Diagnostics (Trouble)' })
K('n', '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', { desc = 'Buffer Diagnostics (Trouble)' })
K('n', '<leader>cs', '<cmd>Trouble symbols toggle<cr>', { desc = 'Symbols (Trouble)' })
K('n', '<leader>xS', '<cmd>Trouble lsp toggle<cr>', { desc = 'LSP references/definitions/... (Trouble)' })
K('n', '<leader>xL', '<cmd>Trouble loclist toggle<cr>', { desc = 'Location List (Trouble)' })
K('n', '<leader>xQ', '<cmd>Trouble qflist toggle<cr>', { desc = 'Quickfix List (Trouble)' })


-- CodeCompanion
require('codecompanion').setup({
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
        condition = function(chat) return chat.adapter.type ~= 'acp' end,
        default_memory = 'gemini',
        default_params = 'watch',
      },
      show_defaults = true,
    },
  },
})

-- Obsidian
require('obsidian').setup({
  disable_frontmatter = true,
  workspaces = {
    { name = 'Personal-Geek', path = vim.fn.expand '$OBSIDIAN_HOME' .. '/Personal-Geek' },
    { name = 'Sibel-Work',    path = vim.fn.expand '$OBSIDIAN_HOME' .. '/Sibel-Work' },
  },
})
