-- vim.api.nvim_create_autocmd('FileType', {
--   group = vim.api.nvim_create_augroup('grug-far-keybindings', { clear = true }),
--   pattern = { 'grug-far' },
--   callback = function()
--     vim.keymap.set('n', '<C-enter>', function()
--       local inst = require('grug-far').get_instance(0)
--       inst:open_location()
--       inst:close()
--     end, { buffer = true })
--   end,
-- })
---@type VimPackPlugin
VimRc.pack_add {
  name = 'grug-far',
  plugin = _G.plug_spec { 'MagicDuck/grug-far.nvim' },
  opts = {
    folding = { enabled = true },
    resultLocation = { showNumberLabel = true },

    -- engines that are enabled to use
    -- The order of the array dictates the order to rotate through when swappping
    -- engines
    enabledEngines = { 'ripgrep', 'astgrep', 'astgrep-rules' },
    engines = {
      ripgrep = {
        -- ripgrep executable to use, can be a different path if you need to configure
        -- path = 'rg',

        -- extra args that you always want to pass
        -- like for example if you always want context lines around matches
        extraArgs = '--no-hidden',

        -- whether to show diff of the match being replaced as opposed to just the
        -- replaced result. It usually makes it easier to understand the change being made
        showReplaceDiff = true,

        -- placeholders to show in input areas when they are empty
        -- set individual ones to '' to disable, or set enabled = false for complete disable
        placeholders = {
          -- whether to show placeholders
          enabled = true,

          search = 'e.g. foo   foo([a-z0-9]*)   fun\\(',
          replacement = 'e.g. bar   ${1}_foo   $$MY_ENV_VAR ',
          replacement_lua = 'e.g. if vim.startsWith(match, "use") \\n then return "employ" .. match \\n else return match end',
          replacement_vimscript = 'e.g. return "bob_" .. match',
          filesFilter = 'e.g. *.lua   *.{css,js}   **/docs/*.md   (specify one per line)',
          flags = 'e.g. --help --ignore-case (-i) --replace= (empty replace) --multiline (-U)',
          paths = 'e.g. /foo/bar   ../   ./hello\\ world/   ./src/foo.lua   ~/.config',
        },
        -- defaults to fill into the inputs when loading or switching to this engine
        -- they only apply when non-nil
        defaults = {
          search = nil,
          replacement = nil,
          filesFilter = nil,
          flags = '--ignore-case --replace= --multiline',
          paths = nil,
        },
      },
      -- see https://ast-grep.github.io
      astgrep = {
        -- ast-grep executable to use, can be a different path if you need to configure
        -- Note: as of this change in ast-grep: https://github.com/ast-grep/ast-grep/commit/15295de3f48aa39bee7c2af642fceb7742d9c156
        -- `sg` is compiled as an alias to `ast-grep` so cannot be used in here. Always use the path to `ast-grep`.
        path = 'ast-grep',

        -- extra args that you always want to pass
        -- like for example if you always want context lines around matches
        extraArgs = '',

        -- placeholders to show in input areas when they are empty
        -- set individual ones to '' to disable, or set enabled = false for complete disable
        placeholders = {
          -- whether to show placeholders
          enabled = true,

          search = 'e.g. $A && $A()   foo.bar($$$ARGS)   $_FUNC($_FUNC)',
          replacement = 'e.g. $A?.()   blah($$$ARGS)',
          replacement_lua = 'e.g. return vars.A == "blah" and "foo(" .. table.concat(vars.ARGS, ", ") .. ")" or match',
          replacement_vimscript = 'e.g. return "bob_" .. match',
          filesFilter = 'e.g. *.lua   *.{css,js}   **/docs/*.md   (specify one per line, filters via ripgrep)',
          flags = 'e.g. --help (-h) --debug-query=ast --rewrite= (empty replace) --strictness=<STRICTNESS>',
          paths = 'e.g. /foo/bar   ../   ./hello\\ world/   ./src/foo.lua   ~/.config',
        },
        -- defaults to fill into the inputs when loading or switching to this engine
        -- they only apply when non-nil
        defaults = {
          search = nil,
          replacement = nil,
          filesFilter = nil,
          flags = nil,
          paths = nil,
        },
      },

      ['astgrep-rules'] = {
        -- ast-grep executable to use, can be a different path if you need to configure
        path = 'ast-grep',

        -- extra args that you always want to pass
        -- like for example if you always want context lines around matches
        extraArgs = '',

        -- Globs to define non-standard mappings of file extension to language,
        -- as you might define in an ast-grep project config. Here they're used
        -- to fill a reasonable language (which is required) in the default-value
        -- for the the rules YAML input. Ideally these would be read directly
        -- from `sgconfig.yml`, but we're not going to implement that parsing.
        --
        -- Example:
        -- ```
        -- languageGlobs = { tsx = { "*.ts", ".js", "*.jsx", "*.tsx" } }
        -- ```
        --
        -- This will make then input pre-fill `language: tsx` if the
        -- current/previous file matches any of that list of globs. Setting these
        -- globs in`sgconfig.yml` is a way to make rules more-reusable - rather
        -- than write separate rules for each of the 4 languages, parse them all
        -- as the "superset" language (tsx), and write one rule based on that
        -- AST. This plugin will then infer (based on this option) that you
        -- probably want to target `language: tsx` when writing a rule for files
        -- that match any of these globs
        --
        -- ast-grep docs:
        -- https://ast-grep.github.io/reference/sgconfig.html#languageglobs
        languageGlobs = {},

        -- placeholders to show in input areas when they are empty
        -- set individual ones to '' to disable, or set enabled = false for complete disable
        placeholders = {
          -- whether to show placeholders
          enabled = true,

          --  rules would normally be multi-line, but we don't support multi-line
          --  placeholders. rules is filled with a default-value though, so it's
          --  rare to see it empty
          rules = 'e.g. id: my_rule_1 \\n language: lua\\nrule: \\n  pattern: await $A',
          filesFilter = 'e.g. *.lua   *.{css,js}   **/docs/*.md   (specify one per line, filters via ripgrep)',
          flags = 'e.g. --help (-h) --debug-query=ast --strictness=<STRICTNESS>',
          paths = 'e.g. /foo/bar   ../   ./hello\\ world/   ./src/foo.lua   ~/.config',
        },
        -- defaults to fill into the inputs when loading or switching to this engine
        -- they only apply when non-nil
        defaults = {
          rules = nil,
          filesFilter = nil,
          flags = nil,
          paths = nil,
        },
      },
    },

    windowCreationCommand = 'tab split',
    -- shortcuts for the actions you see at the top of the buffer
    -- set to '' or false to unset. Mappings with no normal mode value will be removed from the help header
    -- you can specify either a string which is then used as the mapping for both normal and insert mode
    -- or you can specify a table of the form { [mode] = <lhs> } (e.g. { i = '<C-enter>', n = 'ggr'})
    -- it is recommended to use g though as that is more vim-ish
    -- see https://learnvimscriptthehardway.stevelosh.com/chapters/11.html#local-leader
    keymaps = {
      replace = { n = '<M-r>' },
      qflist = { n = '<M-q>' },
      syncLocations = { n = '<M-s>' },
      syncLine = { n = '<M-l>' },
      close = { n = '<M-c>' },
      historyOpen = { n = '<M-t>' },
      historyAdd = { n = '<M-a>' },
      refresh = { n = '<M-f>' },
      openLocation = { n = '<M-o>' },
      openNextLocation = { n = '<down>' },
      openPrevLocation = { n = '<up>' },
      gotoLocation = { n = '<enter>' },
      pickHistoryEntry = { n = '<enter>' },
      abort = { n = '<M-b>' },
      help = { n = '<M-?>' },
      toggleShowCommand = { n = '<M-w>' },
      swapEngine = { n = '<M-e>' },
      previewLocation = { n = '<M-i>' },
      swapReplacementInterpreter = { n = '<M-x>' },
      applyNext = { n = '<M-j>' },
      applyPrev = { n = '<M-k>' },
      syncNext = { n = '<M-n>' },
      syncPrev = { n = '<M-p>' },
      syncFile = { n = '<M-v>' },
      nextInput = { n = '<tab>' },
      prevInput = { n = '<s-tab>' },
    },
  },
  keys = {
    {
      mode = { 'n', 'v' },
      lhs = '<leader>cg',
      rhs = function()
        local grug = require 'grug-far'
        grug.open()
      end,
      opts = { desc = 'GrugFar' },
    },
  },
}
