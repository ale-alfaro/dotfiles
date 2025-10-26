-- Snippets.
keymaps_define {
  {
    mode = 'i',
    lhs = '<C-r>s',
    rhs = function()
      require('luasnip.extras.otf').on_the_fly 's'
    end,
    { desc = 'Insert on-the-fly snippet' },
  },
  -- Use <C-c> to select a choice in a snippet.
  {
    mode = { 'i', 's' },
    lhs = '<C-c>',
    rhs = function()
      if require('luasnip').choice_active() then
        require 'luasnip.extras.select_choice'()
      end
    end,
    { desc = 'Select choice' },
  },
}

local types = require 'luasnip.util.types'
local luasnip = require 'luasnip'

---@diagnostic disable: undefined-field
luasnip.setup {
  -- Check if the current snippet was deleted.
  delete_check_events = 'TextChanged',
  -- Display a cursor-like placeholder in unvisited nodes
  -- of the snippet.
  ext_opts = {
    [types.insertNode] = {
      unvisited = {
        virt_text = { { '|', 'Conceal' } },
        virt_text_pos = 'inline',
      },
    },
    [types.exitNode] = {
      unvisited = {
        virt_text = { { '|', 'Conceal' } },
        virt_text_pos = 'inline',
      },
    },
    [types.choiceNode] = {
      active = {
        virt_text = { { '(snippet) choice node', 'LspInlayHint' } },
      },
    },
  },
}

-- Load my custom snippets:
require('luasnip.loaders.from_vscode').lazy_load {
  paths = vim.fn.stdpath 'config' .. '/snippets',
}
