require 'plugin.codecompanion'
vim.pack.add(_G.plug_spec {
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
      extraArgs = '--no-hidden --no-ignore',

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
    opts = { desc = 'GrugFar' },
  },
}

-- grug-far main buffers will have `filetype=grug-far`.
-- grug-far history buffers will have `filetype=grug-far-history`
-- grug-far help buffers will have `filetype=grug-far-help`
_G.new_autocmd('FileType', function()
  vim.keymap.set('n', '<C-enter>', function()
    local inst = require('grug-far').get_instance(0)
    if inst then
      inst:open_location()
      inst:close()
    end
  end, { buffer = true })
end, 'grug-far*', 'Keep one instance of grug')
--
--
--
--
-- Flash
--
local ok, flash = pcall(require, 'plugin.flash')
if ok then
  VimRc.pack_add(flash)
end

-- Trouble
require('trouble').setup {

  focus = false, -- Focus the window when opened
  modes = {
    lsp = {
      win = { position = 'right' },
    },
  },
}

_G.keymaps_define {
  { lhs = '<leader>xx', rhs = '<cmd>Trouble diagnostics toggle<cr>', opts = { desc = 'Diagnostics (Trouble)' } },
  { lhs = '<leader>xX', rhs = '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', opts = { desc = 'Buffer Diagnostics (Trouble)' } },
  { lhs = '<leader>cs', rhs = '<cmd>Trouble symbols toggle<cr>', opts = { desc = 'Symbols (Trouble)' } },
  { lhs = '<leader>xS', rhs = '<cmd>Trouble lsp toggle<cr>', opts = { desc = 'LSP references/definitions/... (Trouble)' } },
  { lhs = '<leader>xL', rhs = '<cmd>Trouble loclist toggle<cr>', opts = { desc = 'Location List (Trouble)' } },
  { lhs = '<leader>xQ', rhs = '<cmd>Trouble qflist toggle<cr>', opts = { desc = 'Quickfix List (Trouble)' } },
}

local config = require 'fzf-lua.config'
local actions = require('trouble.sources.fzf').actions
config.defaults.actions.files['ctrl-t'] = actions.open

vim.pack.add(_G.plug_spec {
  'obsidian-nvim/obsidian.nvim',
  'MeanderingProgrammer/render-markdown.nvim',
})
-- Obsidian is loaded in after/ftplugin/markdown.lua

local ok, render_md = pcall(require, 'render-markdown')
if ok then
  render_md.setup {
    restart_highlighter = false,
    file_types = { 'markdown', 'codecompanion' },
    code = {
      sign = false,
      width = 'block',
      right_pad = 1,
    },
    heading = {
      sign = false,
      icons = {},
    },
    checkbox = {
      enabled = false,
    },
    { ui = { enable = false } },
    { latex = { enabled = false } },
    completions = { lsp = { enabled = true } },
  }
else
  _G.error "Couldn't load render-markdown.nvim plugin"
end
vim.g.markdown_plugins_loaded = false
-- stylua: ignore end
--

local dap = require 'plugin.dap'
VimRc.pack_add(dap)
