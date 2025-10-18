---@module "mini.nvim"
-- ┌───────────────────┐
-- │ Plugin Setup      │
-- └───────────────────┘

-- Mini.nvim modules
--
local win_config = function()
  local has_statusline = vim.o.laststatus > 0
  local pad = vim.o.cmdheight + (has_statusline and 1 or 0)
  return { anchor = 'SE', col = vim.o.columns, row = vim.o.lines - pad }
end
require('mini.notify').setup {
  content = {
    -- Use notification message as is for LSP progress
    format = function(notif)
      if notif.data.source == 'lsp_progress' then
        return notif.msg
      end
      return MiniNotify.default_format(notif)
    end,

    -- Show more recent notifications first
    sort = function(notif_arr)
      table.sort(notif_arr, function(a, b)
        return a.ts_update > b.ts_update
      end)
      return notif_arr
    end,
  },
  window = { config = win_config },
}
vim.notify = MiniNotify.make_notify {
  ERROR = { duration = 10000 },
  WARN = { duration = 10000 },
  INFO = { duration = 10000 },
}
require('mini.starter').setup()
require('mini.statusline').setup()
require('mini.tabline').setup()

require('mini.files').setup {
  windows = {

    -- Maximum number of windows to show side by side
    max_number = math.huge,
    -- Whether to show preview of file/directory under cursor
    preview = true,
    -- Width of focused window
    width_focus = 50,
    -- Width of non-focused window
    width_nofocus = 15,
    -- Width of preview window
    width_preview = 25,
  },
  options = {
    permanent_delete = false,
    use_as_default_explorer = true,
  },
  mappings = {
    close = 'q',
    go_in = 'l',
    go_in_plus = 'L',
    go_out = 'H',
    go_out_plus = '<Left>',
    mark_goto = 'mg',
    mark_set = 'mm',
    reset = '<BS>',
    reveal_cwd = '<C-d>',
    show_help = '?',
    synchronize = 's',
    trim_left = '<',
    trim_right = '>',
  },
}
vim.defer_fn(function()
  require('mini.extra').setup()

  local ai = require 'mini.ai'
  ai.setup {
    n_lines = 500,
    custom_textobjects = {
      o = ai.gen_spec.treesitter { -- code block
        a = { '@block.outer', '@conditional.outer', '@loop.outer' },
        i = { '@block.inner', '@conditional.inner', '@loop.inner' },
      },
      f = ai.gen_spec.treesitter { a = '@function.outer', i = '@function.inner' }, -- function
      c = ai.gen_spec.treesitter { a = '@class.outer', i = '@class.inner' }, -- class
      t = { '<([%p%w]-)%f[^<%w][^<>]->.-</%1>', '^<.->().*()</[^/]->$' }, -- tags
      d = { '%f[%d]%d+' }, -- digits
      e = { -- Word with case
        { '%u[%l%d]+%f[^%l%d]', '%f[%S][%l%d]+%f[^%l%d]', '%f[%P][%l%d]+%f[^%l%d]', '^[%l%d]+%f[^%l%d]' },
        '^().*()$',
      },
      g = _G.Utils.mini.ai_buffer, -- buffer
      u = ai.gen_spec.function_call(), -- u for "Usage"
      U = ai.gen_spec.function_call { name_pattern = '[%w_]' }, -- without dot in function name
    },
  }

  require('mini.colors').setup()
  -- vim.cmd 'colorscheme minisummer'
  --- You can try these other 'mini.hues'-based color schemes (uncomment with `gcc`):
  vim.cmd('colorscheme minispring')
  --- vim.cmd('colorscheme minisummer')
  --- vim.cmd('colorscheme miniautumn')
  --- vim.cmd('colorscheme randomhue') 
  -- It is not enabled by default because it is not really needed on a daily basis.
  -- Uncomment next line (use `gcc`) to enable.
  require('mini.align').setup()
  require('mini.bracketed').setup()
  require('mini.bufremove').setup()
  require('mini.comment').setup()
  require('mini.diff').setup()
  require('mini.hipatterns').setup {
    highlighters = {
      fixme = require('mini.extra').gen_highlighter.words({ 'FIXME', 'Fixme', 'fixme' }, 'MiniHipatternsFixme'),
      hack = require('mini.extra').gen_highlighter.words({ 'HACK', 'Hack', 'hack' }, 'MiniHipatternsHack'),
      todo = require('mini.extra').gen_highlighter.words({ 'TODO', 'Todo', 'todo' }, 'MiniHipatternsTodo'),
      note = require('mini.extra').gen_highlighter.words({ 'NOTE', 'Note', 'note' }, 'MiniHipatternsNote'),
      hex_color = require('mini.hipatterns').gen_highlighter.hex_color(),
    },
  }
  require('mini.indentscope').setup()
  require('mini.jump').setup()
  require('mini.jump2d').setup()
  require('mini.move').setup()
  require('mini.operators').setup()
  _G.Utils.mini.pairs {
    modes = { insert = true, command = true, terminal = false },
    -- skip autopair when next character is one of these
    skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
    -- skip autopair when the cursor is inside these treesitter nodes
    skip_ts = { 'string' },
    -- skip autopair when next character is closing pair
    -- and there are more closing pairs than opening pairs
    skip_unbalanced = true,
    -- better deal with markdown code blocks
    markdown = true,
  }
  require('mini.pick').setup()
  require('mini.splitjoin').setup()
  require('mini.surround').setup {
    mappings = {
      add = 'gsa', -- Add surrounding in Normal and Visual modes
      delete = 'gsd', -- Delete surrounding
      find = 'gsf', -- Find surrounding (to the right)
      find_left = 'gsF', -- Find surrounding (to the left)
      highlight = 'gsh', -- Highlight surrounding
      replace = 'gsr', -- Replace surrounding
      update_n_lines = 'gsn', -- Update `n_lines`
    },
  }

  -- Git integration for more straightforward Git actions based on Neovim's state.
  -- - `:h :Git` - more details about `:Git` user command
  -- - `:h MiniGit.show_at_cursor()` - what information at cursor is shown
  require('mini.git').setup()

  -- - `:h MiniVisits-overview` - overview of how module works
  -- - `:h MiniVisits-examples` - examples of common setups
  require('mini.visits').setup()
end, 0)

-- Other plugins
require('marks').setup {
  builtin_marks = { '<', '>', '^' },
  refresh_interval = 250,
  sign_priority = { lower = 10, upper = 15, builtin = 8, bookmark = 20 },
  excluded_filetypes = {},
  excluded_buftypes = {},
  mappings = {},
}

local telescope = require 'plugin.better_search'.config()
vim.lsp.config('bashls', {
  filetypes = { 'sh', 'zsh', 'bash' },
})

vim.lsp.enable {
  'lua_ls',
  'clangd',
  'ruff',
  'ty',
  'bashls',
  'taplo',
  'yamls',
  'jsonls',
  'basedpyright',
}

-- Treesitter
require('nvim-treesitter')
  .install({
    'bash',
    'c',
    'cpp',
    'cmake',
    'diff',
    'html',
    'kconfig',
    'lua',
    'luadoc',
    'markdown',
    'python',
    'markdown_inline',
    'query',
    'vim',
    'vimdoc',
    'just',
    'json5',
    'toml',
    'ninja',
    'rst',
    'yaml',
  })
  :wait(300000) -- max. 5 minutes

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'zsh', 'lua', 'bash', 'just' },
  callback = function()
    -- syntax highlighting, provided by Neovim
    vim.treesitter.start()
    -- folds, provided by Neovim
    vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    -- indentation, provided by nvim-treesitter
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})
-- require('nvim-treesitter').install {
--   highlight = { enable = true },
--   indent = { enable = true },
-- }
require('nvim-treesitter-textobjects').setup {
  move = {
    enable = true,
    set_jumps = true,
    keys = {
      goto_next_start = { [']f'] = '@function.outer', [']c'] = '@class.outer', [']a'] = '@parameter.inner' },
      goto_next_end = { [']F'] = '@function.outer', [']C'] = '@class.outer', [']A'] = '@parameter.inner' },
      goto_previous_start = { ['[f'] = '@function.outer', ['[c'] = '@class.outer', ['[a'] = '@parameter.inner' },
      goto_previous_end = { ['[F'] = '@function.outer', ['[C'] = '@class.outer', ['[A'] = '@parameter.inner' },
    },
  },
}
--[[

Available events to hook into
- PackChangedPre - before trying to change plugin's state.
- PackChanged - after plugin's state has changed.
Each event populates the following event-data fields:
    - kind - one of "install" (install on disk), "update" (update existing plugin), "delete" (delete from disk).
    - spec - plugin's specification with defaults made explicit.
    - path - full path to plugin's directory.

--]]

-- Blink/Completion
_G.Utils.pack.plugin_spec_add({ src = "https://github.com/Saghen/blink.cmp" }, "cargo install --release", {
  keymap = { preset = 'default' },
  appearance = { nerd_font_variant = 'mono' },
  completion = { documentation = { auto_show = false } },
  signature = { enabled = true },
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
    per_filetype = {
      lua = { inherit_defaults = true, 'lazydev' },
    },
    providers = {
      lazydev = {
        name = 'LazyDev',
        module = 'lazydev.integrations.blink',
        score_offset = 100,
      },
      lsp = { async = true, score_offset = 70 },
      snippets = { score_offset = 1, max_items = 3 },
    },
  },
  fuzzy = { implementation = 'prefer_rust_with_warning' },
  cmdline = {
    enabled = true,
    keymap = { preset = 'cmdline' },
    completion = {
      list = { selection = { preselect = false } },
      menu = {
        auto_show = function(ctx)
          return vim.fn.getcmdtype() == ':'
        end,
      },
      ghost_text = { enabled = true },
    },
  },
})
vim.lsp.config('*', { capabilities = require('blink.cmp').get_lsp_capabilities() })

-- Formatting
-- See also:
-- - `:h Conform`
-- - `:h conform-options`
-- - `:h conform-formatters`
_G.Utils.format.setup {
  default_format_opts = {
    timeout_ms = 3000,
    async = false, -- not recommended to change
    quiet = false, -- not recommended to change
    lsp_format = 'fallback', -- not recommended to change
  },
  formatters_by_ft = {
    lua = { 'stylua' },
    fish = { 'fish_indent' },
    sh = { 'shfmt' },
    -- # Example of using shfmt with extra args
    shfmt = {
      prepend_args = { '-i', '2', '-ci' },
    },
    just = {
      env = {
        JUST_UNSTABLE = 1,
      },
    },
    python = {
      -- To fix auto-fixable lint errors.
      'ruff_fix',
      -- To run the Ruff formatter.
      'ruff_format',
      -- To organize the imports.
      'ruff_organize_imports',
    },
    zsh = { 'shfmt' },
    markdown = { 'mdformat' },
    yaml = { 'yamlfmt' },
    -- ['*'] = { 'codespell' },
    -- ['_'] = { 'trim_whitespace' },
  },
}

-- Linting

local pattern = '([^:]+):(%d+):(%d+): (%a+)[(.*)] %[(%a[%a-]+)%]'
local groups = { 'file', 'lnum', 'col', 'severity', 'message', 'code' }
local severities = {
  error = vim.diagnostic.severity.ERROR,
  warning = vim.diagnostic.severity.WARN,
  note = vim.diagnostic.severity.HINT,
}
local opts = {
  linters_by_ft = {
    cmake = { 'cmakelint' }, -- Install: uv tool install cmakelint, repo: https://github.com/cmake-lint/cmake-lint
    python = { 'mypy' },
    yaml = { 'yamlint' }, --Install: uv tool install yamllint, repo: https://github.com/adrienverge/yamllint
    bash = { 'shellcheck' },
    sh = { 'shellcheck' },
    zsh = { 'zsh', 'shellcheck' },
    ['yaml.ghaction'] = { 'actionlint' }, -- Install: go install github.com/rhysd/actionlint/cmd/actionlint@latest, repo: https://github.com/rhysd/actionlint
  },
  linters = {
    ty = {
      cmd = 'ty',
      stdin = false,
      stream = 'stdout',
      ignore_exitcode = true,
      args = {
        'check',
        '--output-format',
        'concise',
        '--color',
        'never',
      },
      parser = require('lint.parser').from_pattern(pattern, groups, severities, { ['source'] = 'ty' }, { end_col_offset = 0 }),
    },
  },
  events = { 'BufWritePost', 'BufReadPost', 'InsertLeave' },
}
require('custom.lint.better_linting').setup(opts)
-- Smart Splits
require('smart-splits').setup {
  ignored_buftypes = { 'codecompanion' },
  ignored_filetypes = { 'codecompanion' },
  default_amount = 3,
  move_cursor_same_row = true,
}
-- Which-key

local wk = require('which-key').setup {
  preset = 'helix',
  defaults = {},
  spec = {
    mode = { 'n', 'v' },
    { '<leader>c', group = 'code' },
    { '<leader>d', group = 'debug' },
    { '<leader>f', group = 'file/find' },
    { '<leader>g', group = 'git' },
    { '<Leader>l', group = '+Language' },
    { '<Leader>m', group = '+Map' },
    {
      '<Leader>s',
      group = '+Session',
      { '<Leader>v', group = '+Visits' },
      { '<leader>u', group = 'ui' },
      { '<leader>x', group = 'diagnostics/quickfix' },
      { '[', group = 'prev' },
      { ']', group = 'next' },
      { 'g', group = 'goto' },
      { 'gs', group = 'surround' },
      { 'z', group = 'fold' },
      {
        '<leader>b',
        group = 'buffer',
        expand = function()
          return require('which-key.extras').expand.buf()
        end,
      },
      {
        '<leader>w',
        group = 'windows',
        proxy = '<c-w>',
        expand = function()
          return require('which-key.extras').expand.win()
        end,
      },
    },
  },
}

require('uv.init').setup {
  keymaps = {
    prefix = '<leader>x', -- Main prefix for uv commands
    commands = true, -- Show uv commands menu (<leader>x)
    run_file = false, -- Run current file (<leader>xr)
    run_selection = false, -- Run selected code (<leader>xs)
    run_function = false, -- Run function (<leader>xf)
    venv = true, -- Environment management (<leader>xe)
    init = true, -- Initialize uv project (<leader>xi)
    add = true, -- Add a package (<leader>xa)
    remove = true, -- Remove a package (<leader>xd)
    sync = false, -- Sync packages (<leader>xc)
    sync_all = false, -- Sync all packages, extras and groups (<leader>xC)
  },
}

require('custom.python.uv').setup()
require('custom.wezterm.wezterm_terminal').setup()
