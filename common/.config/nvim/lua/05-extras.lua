require 'plugin.codecompanion'

vim.pack.add(_G.plug_spec {
  'folke/flash.nvim',
  'folke/trouble.nvim',
  'MagicDuck/grug-far.nvim',
})

require('grug-far').setup {
  -- Disable folding.
  folding = { enabled = false },
  -- Don't numerate the result list.
  resultLocation = { showNumberLabel = false },
  engines = {
    ripgrep = {
      -- ripgrep executable to use, can be a different path if you need to configure
      path = 'rg',

      -- extra args that you always want to pass
      -- like for example if you always want context lines around matches
      extraArgs = '--hidden',

      -- whether to show diff of the match being replaced as opposed to just the
      -- replaced result. It usually makes it easier to understand the change being made
      showReplaceDiff = true,

      -- placeholders to show in input areas when they are empty
      -- set individual ones to '' to disable, or set enabled = false for complete disable
      -- placeholders = {
      --   -- whether to show placeholders
      --   enabled = true,
      --
      --   search = 'e.g. foo   foo([a-z0-9]*)   fun\\(',
      --   replacement = 'e.g. bar   ${1}_foo   $$MY_ENV_VAR ',
      --   replacement_lua = 'e.g. if vim.startsWith(match, "use") \\n then return "employ" .. match \\n else return match end',
      --   replacement_vimscript = 'e.g. return "bob_" .. match',
      --   filesFilter = 'e.g. *.lua   *.{css,js}   **/docs/*.md   (specify one per line)',
      --   flags = 'e.g. --help --ignore-case (-i) --replace= (empty replace) --multiline (-U)',
      --   paths = 'e.g. /foo/bar   ../   ./hello\\ world/   ./src/foo.lua   ~/.config',
      -- },
      -- defaults to fill into the inputs when loading or switching to this engine
      -- they only apply when non-nil
      --   defaults = {
      --     search = nil,
      --     replacement = nil,
      --     filesFilter = nil,
      --     flags = nil,
      --     paths = nil,
      --   },
    },
  },
}

_G.keymaps_define {
  {
    mode = { 'n', 'v' },
    lhs = '<leader>cg',
    rhs = function()
      local grug = require 'grug-far'
      grug.open { transient = true }
    end,
    { desc = 'GrugFar' },
  },
}

-- grug-far main buffers will have `filetype=grug-far`.
-- grug-far history buffers will have `filetype=grug-far-history`
-- grug-far help buffers will have `filetype=grug-far-help`
_G.new_autocmd('FileType', function()
  vim.keymap.set('n', '<C-enter>', function()
    local inst = require('grug-far').get_instance(0)
    inst:open_location()
    inst:close()
  end, { buffer = true })
end, 'grug-far', "Keep one instance of grug")
--
--
--
--
-- Flash
--
require('flash').setup {
  jump = { nohlsearch = true },
  prompt = {
    win_config = {
      border = 'none',
      -- Place the prompt above the statusline.
      row = -3,
    },
  },
  search = {
    exclude = {
      'flash_prompt',
      'qf',
      function(win)
        -- Non-focusable windows.
        return not vim.api.nvim_win_get_config(win).focusable
      end,
    },
  },
  modes = {
    -- Enable flash when searching with ? or /
    search = { enabled = false },
  },
}
-- stylua: ignore start
_G.keymaps_define({
  { mode = { 'n', 'o', 'x' }, lhs = 'S',   rhs = function() require('flash').treesitter() end,       { desc = 'Flash Treesitter' } },
  { mode = 'o',             lhs = 'r',     rhs = function() require('flash').treesitter_search() end, { desc = 'Treesitter Search' } },
  { mode = 'o',             lhs = 'R',     rhs = function() require('flash').remote() end,           { desc = 'Remote Flash' } },
  { mode = 'c',             lhs = '<c-s>', rhs = function() require('flash').toggle() end,           { desc = 'Flash Toggle' } },
  {
    mode = { 'n', 'o', 'x' },
    lhs = '<c-space>',
    rhs = function()
      require('flash').treesitter {
        actions = {
          ['<c-space>'] = 'next',
          ['<BS>'] = 'prev',
        },
      }
    end,
    { desc = 'Treesitter Incremental Selection' }
  } })

-- Trouble
require('trouble').setup {

  focus = false, -- Focus the window when opened
  modes = {
    lsp = {
      win = { position = 'right' },
    },
  },
}
_G.keymaps_define({
  { lhs = '<leader>xx', rhs = '<cmd>Trouble diagnostics toggle<cr>',              { desc = 'Diagnostics (Trouble)' } },
  { lhs = '<leader>xX', rhs = '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', { desc = 'Buffer Diagnostics (Trouble)' } },
  { lhs = '<leader>cs', rhs = '<cmd>Trouble symbols toggle<cr>',                  { desc = 'Symbols (Trouble)' } },
  { lhs = '<leader>xS', rhs = '<cmd>Trouble lsp toggle<cr>',                      { desc = 'LSP references/definitions/... (Trouble)' } },
  { lhs = '<leader>xL', rhs = '<cmd>Trouble loclist toggle<cr>',                  { desc = 'Location List (Trouble)' } },
  { lhs = '<leader>xQ', rhs = '<cmd>Trouble qflist toggle<cr>',                   { desc = 'Quickfix List (Trouble)' } },
})

local config = require("fzf-lua.config")
local actions = require("trouble.sources.fzf").actions
config.defaults.actions.files["ctrl-t"] = actions.open
-- stylua: ignore end
