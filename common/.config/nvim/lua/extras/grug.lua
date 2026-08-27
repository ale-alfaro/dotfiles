vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('grug-far-keybindings', { clear = true }),
  pattern = { 'grug-far' },
  callback = function()
    vim.keymap.set('n', 'q', function()
      local grug = require 'grug-far'
      local inst = grug.get_instance()
      if inst then
        inst:hide()
      end
    end, { buffer = true })
  end,
})
require('grug-far').setup {
  folding = { 
  enabled = true,
    -- sets foldlevel, folds with higher level will be closed.
    -- result matche lines for each file have fold level 1
    -- set it to 0 if you would like to have the results initially collapsed
    -- See :h foldlevel
    foldlevel = 3,

    -- visual indicator of folds, see :h foldcolumn
    -- set to '0' to disable
    foldcolumn = '0',

    -- whether to include file path in the fold, by default, only lines under the file path are included
    include_file_path = false,

},
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
        flags = '--strictness=smart --lang=c ',
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
      languageGlobs = { zephyr = { '*.c', '*.dts', '*.dtsi' }, c = { '*.cpp', '*.hpp' } },

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
        rules = [[
id: my_rule_1
language: c
rule:
  pattern: |
    #if defined(CONFIG_SHRD_HEADER)
      $$$A
    #endif
fix: $$$A
]],
        filesFilter = nil,
        flags = '--strictness=smart',
        paths = nil,
      },
    },
  },

  windowCreationCommand = 'vsplit', -- vsplit
  -- shortcuts for the actions you see at the top of the buffer
  -- set to '' or false to unset. Mappings with no normal mode value will be removed from the help header
  -- you can specify either a string which is then used as the mapping for both normal and insert mode
  -- or you can specify a table of the form { [mode] = <lhs> } (e.g. { i = '<C-enter>', n = 'ggr'})
  -- it is recommended to use g though as that is more vim-ish
  -- see https://learnvimscriptthehardway.stevelosh.com/chapters/11.html#local-leader
  keymaps = {
    replace = '<localleader>r',
    syncLocations = { n = '<localleader>s' },
    syncLine = { n = '<localleader>l' },
    close = { n = '<localleader>c' },
    historyOpen = { n = '<localleader>t' },
    historyAdd = { n = '<localleader>a' },
    refresh = { n = '<localleader>f' },
    swapEngine = '<localleader>e',
    openLocation = '<localleader>x',
    syncFile = '<localleader>f',
    openNextLocation = { n = '<down>' },
    openPrevLocation = { n = '<up>' },
    gotoLocation = { n = '<enter>' },
    pickHistoryEntry = { n = '<enter>' },
    abort = { n = '<localleader>b' },
    help = { n = 'g?' },
    qflist = { n = '<localleader>q' },
    previewLocation = { n = '<localleader>i' },
    swapReplacementInterpreter = { n = '<localleader>x' },
    applyNext = { n = '<localleader>j' },
    applyPrev = { n = '<localleader>k' },
    syncNext = { n = '<localleader>n' },
    syncPrev = { n = '<localleader>p' },
    nextInput = { n = '<tab>' },
    prevInput = { n = '<s-tab>' },
  },
}
local map = function(key, cb, desc)
  vim.keymap.set('n', '<leader>c' .. key, cb, { desc = 'GrugFar ' .. desc })
end
map('g', function()
  require('grug-far').open { transient = true }
end, 'Rg')
map('a', function()
  require('grug-far').open { engine = 'astgrep-rules' }
end, 'Ast-grep')
  -- prefills = {
  --   search = nil,
  --   replacement = nil,
  --   filesFilter = nil,
  --   flags = nil,
  --   paths = nil,
  -- },
map('l', function()
  require('grug-far').open { prefills = { paths = vim.fn.expand '%' } }
end, 'Local')
map('c', function()
  require('grug-far').open({ prefills = { search = vim.fn.expand("<cword>") } })
end, 'Local')
  --
vim.keymap.set('n', '<localleader>r', function()
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype
  local language_glob = nil
  if string.match(ft, 'c') then
    language_glob = '*.{c,h}'
  elseif string.match(ft, 'python') then
      language_glob = '*.py'
  end
  require('grug-far').open({ prefills = {{
        search = nil,
        replacement = nil,
        filesFilter = language_glob,
        paths = nil,
      }} })
end, {desc = 'Grug'})
