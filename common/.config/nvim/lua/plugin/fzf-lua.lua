local actions = require 'fzf-lua.actions'
-- Picker, finder, etc.
require('fzf-lua').setup {
  { 'border-fused', 'hide' },
  -- Make stuff better combine with the editor.
  fzf_colors = {
    bg = { 'bg', 'Normal' },
    gutter = { 'bg', 'Normal' },
    info = { 'fg', 'Conditional' },
    scrollbar = { 'bg', 'Normal' },
    separator = { 'fg', 'Comment' },
  },
  fzf_opts = {
    ['--info'] = 'default',
    ['--layout'] = 'reverse-list',
  },
  keymap = {
    builtin = {
      ['<C-/>'] = 'toggle-help',
      ['<C-a>'] = 'toggle-fullscreen',
      ['<C-i>'] = 'toggle-preview',
    },
    fzf = {
      ['alt-s'] = 'toggle',
      ['alt-a'] = 'toggle-all',
      ['ctrl-i'] = 'toggle-preview',
    },
  },
  winopts = {
    height = 0.7,
    width = 0.55,
    preview = {
      scrollbar = false,
      layout = 'vertical',
      vertical = 'up:40%',
    },
  },
  defaults = { git_icons = false },
  -- Configuration for specific commands.
  files = {
    winopts = {
      preview = { hidden = true },
    },
  },
  grep = {
    -- Search in hidden files by default.
    hidden = true,
    header_prefix = VimRc.icons.misc.search .. ' ',
    rg_glob_fn = function(query, opts)
      local regex, flags = query:match(string.format('^(.*)%s(.*)$', opts.glob_separator))
      -- Return the original query if there's no separator.
      return (regex or query), flags
    end,
  },
  helptags = {
    actions = {
      -- Open help pages in a vertical split.
      ['enter'] = actions.help_vert,
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
      ['ctrl-e'] = {
        fn = function(_, opts)
          -- If not filtering by severity, show all diagnostics.
          if opts.severity_only then
            opts.severity_only = nil
          else
            -- Else only show errors.
            opts.severity_only = vim.diagnostic.severity.ERROR
          end
          require('fzf-lua').resume(opts)
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
_G.keymaps_define({
  {
    mode = { 'n', 'x' },
    lhs = '<leader>.',
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
        require('fzf-lua').lgrep_curbuf(opts)
      else
        require('fzf-lua').blines(opts)
      end
    end,
    opts = { desc = 'Search current buffer' },
  },
  {
    lhs = '<leader>,',
    rhs = function()
      require('fzf-lua').live_grep()
    end,
    opts = { desc = '[S]earch [/] in Open Files' },
  },
  { mode = 'x', lhs = '<leader>,', rhs = '<cmd>FzfLua grep_visual<cr>', opts = { desc = 'Grep' } },
  { lhs = 'z=', rhs = '<cmd>FzfLua spell_suggest<cr>', opts = { desc = 'Spelling suggestions' } },

  { lhs = wkey_prefix .. 'b', rhs = '<cmd>FzfLua blines<cr>', opts = { desc = 'Buffer Lines' } },
  { lhs = wkey_prefix .. 'B', rhs = '<cmd>FzfLua buffers<cr>', opts = { desc = 'Buffers' } },
  { lhs = wkey_prefix .. 'd', rhs = '<cmd>FzfLua lsp_document_diagnostics<cr>', opts = { desc = 'Document diagnostics' } },
  { lhs = wkey_prefix .. 'f', rhs = '<cmd>FzfLua files<cr>', opts = { desc = 'Find files' } },
  { lhs = wkey_prefix .. 'g', rhs = '<cmd>FzfLua grep_project<cr>', opts = { desc = 'Grep Project' } },
  { lhs = wkey_prefix .. 'c', rhs = '<cmd>FzfLua changes<cr>', opts = { desc = 'Changes' } },
  { lhs = wkey_prefix .. 'h', rhs = '<cmd>FzfLua help_tags<cr>', opts = { desc = 'Help' } },
  { lhs = wkey_prefix .. 'o', rhs = '<cmd>FzfLua oldfiles<cr>', opts = { desc = 'Recently opened files' } },
  { lhs = wkey_prefix .. 'r', rhs = '<cmd>FzfLua resume<cr>', opts = { desc = 'Resume last fzf command' } },
  { lhs = wkey_prefix .. 'z', rhs = '<cmd>FzfLua zoxide<cr>', opts = { desc = 'Zoxide' } },
  { lhs = wkey_prefix .. 'k', rhs = '<Cmd>FzfLua keymaps<CR>', opts = { desc = 'Keymaps' } },
}, { prefix = wkey_prefix, group = 'Find' })
