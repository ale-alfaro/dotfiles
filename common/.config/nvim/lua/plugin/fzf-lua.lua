---@module 'fzf-lua'
local toggle_only_sources = function(_, opts)
  require('fzf-lua.actions').toggle_opt(opts, 'tzsrc')
end
require('fzf-lua').setup {
  { 'border-fused', 'hide' },
  -- Make stuff better combine with the editor.
  keymap = {
    -- Below are the default binds, setting any value in these tables will override
    -- the defaults, to inherit from the defaults change [1] from `false` to `true`
    builtin = {
      -- neovim `:tmap` mappings for the fzf win
      -- true,        -- uncomment to inherit all the below in your custom config
      ['<alt-q>'] = 'hide', -- hide fzf-lua, `:FzfLua resume` to continue
      ['alt-?'] = 'toggle-help',
      ['alt-f'] = 'toggle-fullscreen',
      -- Only valid with the 'builtin' previewer
      ['<F3>'] = 'toggle-preview-wrap',
      ['<F4>'] = 'toggle-preview',
      -- Rotate preview clockwise/counter-clockwise
      ['<F5>'] = 'toggle-preview-cw',
      -- Preview toggle behavior default/extend
      ['<F6>'] = 'toggle-preview-behavior',
      -- `ts-ctx` binds require `nvim-treesitter-context`
      ['<F7>'] = 'toggle-preview-ts-ctx',
      ['<F8>'] = 'preview-ts-ctx-dec',
      ['<F9>'] = 'preview-ts-ctx-inc',
      ['<S-Left>'] = 'preview-reset',
      ['<S-down>'] = 'preview-page-down',
      ['<S-up>'] = 'preview-page-up',
      ['<M-S-down>'] = 'preview-down',
      ['<M-S-up>'] = 'preview-up',
    },
    fzf = {
      -- fzf '--bind=' options
      -- true,        -- uncomment to inherit all the below in your custom config
      ['ctrl-z'] = 'abort',
      ['ctrl-d'] = 'half-page-down',
      ['ctrl-u'] = 'half-page-up',
      ['ctrl-A'] = 'select-all+accept',
      ['ctrl-a'] = 'toggle-all',
      ['ctrl-g'] = 'first',
      ['ctrl-G'] = 'last',
      -- Only valid with fzf previewers (bat/cat/git/etc)
      ['f3'] = 'toggle-preview-wrap',
      ['f4'] = 'toggle-preview',
      ['shift-down'] = 'preview-page-down',
      ['shift-up'] = 'preview-page-up',
    },
  },
  actions = {
    -- Below are the default actions, setting any value in these tables will override
    -- the defaults, to inherit from the defaults change [1] from `false` to `true`
    files = {
      true, -- uncomment to inherit all the below in your custom config
      -- Pickers inheriting these actions:
      --   files, git_files, git_status, grep, lsp, oldfiles, quickfix, loclist,
      --   tags, btags, args, buffers, tabs, lines, blines
      -- `file_edit_or_qf` opens a single selection or sends multiple selection to quickfix
      -- replace `enter` with `file_edit` to open all files/bufs whether single or multiple
      -- replace `enter` with `file_switch_or_edit` to attempt a switch in current tab first
      ['enter'] = FzfLua.actions.file_edit_or_qf,
      ['ctrl-s'] = FzfLua.actions.file_split,
      ['ctrl-v'] = FzfLua.actions.file_vsplit,
      ['ctrl-t'] = FzfLua.actions.file_tabedit,
      ['ctrl-q'] = FzfLua.actions.file_sel_to_qf,
      ['ctrl-l'] = FzfLua.actions.file_sel_to_ll,
      ['ctrl-i'] = FzfLua.actions.toggle_ignore,
      ['ctrl-h'] = FzfLua.actions.toggle_hidden,
    },
  },
  winopts = {
    height = 0.7,
    width = 0.55,
    on_create = function()
      -- called once upon creation of the fzf main window
      -- can be used to add custom fzf-lua mappings, e.g:
      vim.keymap.set('t', '<C-j>', '<Down>', { silent = true, buffer = true })

      vim.keymap.set({ 'n', 'v', 'i' }, '<C-x><C-f>', function()
        FzfLua.complete_path()
      end, { silent = true, buffer = true })
    end,
    -- called once _after_ the fzf interface is closed
    -- on_close = function() ... end
  },
  defaults = { git_icons = false },
  -- Configuration for specific commands.
  files = {
    winopts = {
      preview = { hidden = true },
    },
    no_ignore = false, -- enable hidden files by default
    actions = {

      ['ctrl-z'] = toggle_only_sources,
    },
  },
  grep = {
    -- Search in hidden files by default.
    hidden = true,
    -- no_ignore = true, -- respect ".gitignore"  by default
    header_prefix = VimRc.icons.misc.search .. ' ',
    rg_glob = true, -- default to glob parsing with `rg`
    glob_flag = '--iglob', -- for case sensitive globs use '--glob'
    glob_separator = '%s%-%-', -- query separator pattern (lua): ' --'
    actions = {
      -- actions inherit from 'actions.files' and merge
      -- this action toggles between 'grep' and 'live_grep'
    },
  },
  helptags = {
    actions = {
      -- Open help pages in a vertical split.
      ['enter'] = FzfLua.actions.help_vert,
    },
  },
  manpages = {
    actions = {
      -- Open help pages in a vertical split.
      ['enter'] = FzfLua.actions.help_vert,
    },
  },
  lsp = {
    symbols = {
      symbol_icons = VimRc.icons.symbol_kinds,
    },
  },
  diagnostics = {
    -- Remove the dashed line between diagnostic items.
    multiline = 1,
    diag_icons = {
      VimRc.icons.diagnostics.ERROR,
      VimRc.icons.diagnostics.WARN,
      VimRc.icons.diagnostics.INFO,
      VimRc.icons.diagnostics.HINT,
    },
    actions = {
      ['ctrl-x'] = {
        fn = function(_, opts)
          -- If not filtering by severity, show all diagnostics.
          if opts.severity_only then
            opts.severity_only = nil
          else
            -- Else only show errors.
            opts.severity_only = vim.diagnostic.severity.ERROR
          end
          FzfLua.actions.resume(opts)
        end,
        noclose = true,
        desc = 'toggle-all-only-errors',
        header = function(opts)
          return opts.severity_only and 'show all' or 'show only errors'
        end,
      },
    },
  },
  oldfiles = {
    include_current_session = true,
    winopts = {
      preview = { hidden = true },
    },
  },
}
local wkey_prefix = '<leader>f'
KEYS.define({
  { lhs = '<leader><leader>', rhs = '<cmd>FzfLua buffers<cr>', opts = { desc = 'Buffers' } },
  {
    mode = { 'n', 'x' },
    lhs = '<leader>/',
    rhs = function()
      local opts = {
        winopts = {
          height = 0.6,
          width = 0.5,
          preview = { vertical = 'up:70%' },
          -- Disable Treesitter highlighting for the matches.
          treesitter = {
            enabled = false,
            fzf_colors = { ['fg'] = { 'fg', 'CursorLine' }, ['bg'] = { 'bg', 'Normal' } },
          },
        },
        fzf_opts = {
          ['--layout'] = 'reverse',
        },
      }

      -- Use grep when in normal mode and blines in visual mode since the former doesn't support
      -- searching inside visual selections.
      -- See https://github.com/ibhagwan/fzf-lua/issues/2051
      local mode = vim.api.nvim_get_mode().mode
      if vim.startswith(mode, 'n') then
        FzfLua.lgrep_curbuf(opts)
      else
        FzfLua.blines(opts)
      end
    end,
    opts = { desc = 'Search current buffer', noremap = true },
  },
  {
    lhs = wkey_prefix .. 'g',
    rhs = function()
      ---@type fzf-lua.config.Grep
      FzfLua.live_grep(opts)
    end,
    opts = { desc = '[S]earch Open Buffer Dir' },
  },
  { mode = 'x', lhs = '<leader>,', rhs = '<cmd>FzfLua grep_visual<cr>', opts = { desc = 'Grep' } },

  { lhs = wkey_prefix .. 'b', rhs = '<cmd>FzfLua blines<cr>', opts = { desc = 'Buffer Lines' } },
  { lhs = wkey_prefix .. 'd', rhs = '<cmd>FzfLua lsp_document_diagnostics<cr>', opts = { desc = 'Document diagnostics' } },
  { lhs = wkey_prefix .. 'f', rhs = '<cmd>FzfLua files<cr>', opts = { desc = 'Find files' } },
  { lhs = wkey_prefix .. 'm', rhs = '<cmd>FzfLua manpages<cr>', opts = { desc = 'Find Man' } },
  { lhs = wkey_prefix .. 'G', rhs = '<cmd>FzfLua live_grep<cr>', opts = { desc = 'Grep (cwd)' } },
  { lhs = wkey_prefix .. 'h', rhs = '<cmd>FzfLua help_tags<cr>', opts = { desc = 'Help' } },
  { lhs = wkey_prefix .. 'o', rhs = '<cmd>FzfLua oldfiles<cr>', opts = { desc = 'Recently opened files' } },
  { lhs = wkey_prefix .. 'r', rhs = '<cmd>FzfLua resume<cr>', opts = { desc = 'Resume last fzf command' } },
  { lhs = wkey_prefix .. 'z', rhs = '<cmd>FzfLua zoxide<cr>', opts = { desc = 'Zoxide' } },
  { lhs = wkey_prefix .. 'k', rhs = '<Cmd>FzfLua keymaps<CR>', opts = { desc = 'Keymaps' } },
}, { prefix = wkey_prefix, group = 'Find' })
