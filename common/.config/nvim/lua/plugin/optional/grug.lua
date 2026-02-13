---@type VimPackPlugin
return {
  name = 'grug-far',
  plugin = _G.plug_spec { 'MagicDuck/grug-far.nvim' },
  opts = {
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
  },
  keys = {
    {
      mode = { 'n', 'v' },
      lhs = '<leader>cg',
      rhs = function()
        local grug = require 'grug-far'
        grug.open { transient = true }
      end,
      opts = { desc = 'GrugFar' },
    },
  },
}
