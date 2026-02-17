---@module 'fzf-lua'
local toggle_only_sources = function(_, opts)
  require('fzf-lua.actions').toggle_opt(opts, 'tzsrc')
end
---@param selected string[]
---@param opts fzf-lua.config.CommandHistory|{}
local hist_copy = function(selected, opts)
  local iter = opts.reverse_list and vim.iter(selected) or vim.iter(selected):rev()
  iter:each(function(e)
    local idx = assert(FzfLua.utils.tointeger(opts.reverse_list and e or -e - 1))
    local sel = vim.fn.histget(':', idx) -- get before deleted
    vim.fn.setreg('+', sel)
    VimRc.info(string.format('Copied: %s', sel))
  end)
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
      ['ctrl-h'] = 'toggle-help',
      ['ctrl-f'] = 'toggle-fullscreen',
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
      ['ctrl-d'] = FzfLua.actions.file_split,
      ['ctrl-v'] = FzfLua.actions.file_vsplit,
      ['ctrl-q'] = FzfLua.actions.file_sel_to_qf,
      ['ctrl-i'] = FzfLua.actions.toggle_ignore,
    },
  },
  winopts = {
    height = 0.7,
    width = 0.7,
    on_create = function()
      -- called once upon creation of the fzf main window
      -- can be used to add custom fzf-lua mappings, e.g:
      vim.keymap.set('t', '<C-j>', '<Down>', { silent = true, buffer = true })

      vim.keymap.set({ 'n', 'v', 'i' }, '<C-n><C-f>', function()
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

      ['ctrl-s'] = toggle_only_sources,
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
  search_history = {

    actions = {
      ['ctrl-c'] = { fn = hist_copy, field_index = '{+n}', reload = true },
    },
  },
}
KEYS.define {
  { lhs = '<C-b>', rhs = '<cmd>FzfLua buffers<cr>', opts = { desc = 'Buffers', noremap = true } },
  { lhs = '<C-\\>', rhs = '<cmd>FzfLua global<cr>', opts = { desc = 'Global', noremap = true } },
  { lhs = '<C-e>', rhs = '<cmd>FzfLua files<cr>', opts = { desc = 'Files', noremap = true } },
  { lhs = '<C-g>', rhs = '<cmd>FzfLua live_grep<cr>', opts = { desc = 'Grep (cwd)', noremap = true } },
  { lhs = '<C-Tab>', rhs = '<cmd>FzfLua resume<cr>', opts = { desc = 'Resume', noremap = true } },
  { lhs = '<C-f>', rhs = '<cmd>FzfLua command_history<cr>', opts = { desc = 'Command History', noremap = true } },
  { lhs = '<C-kEqual>', rhs = '<cmd>FzfLua register<cr>', opts = { desc = 'Registers', noremap = true } },
  { lhs = '<C-/>', rhs = '<cmd>FzfLua blines<cr>', opts = { desc = 'Buffer Lines' } },
  { lhs = '<M-o>', rhs = '<cmd>FzfLua oldfiles<cr>', opts = { desc = 'Old Files' } },
}
local wkey_prefix = '<leader>f'
KEYS.define({
  { lhs = wkey_prefix .. 'b', rhs = '<cmd>FzfLua builtin<cr>', opts = { desc = 'Find Fzf pickers' } },
  { lhs = wkey_prefix .. 'm', rhs = '<cmd>FzfLua manpages<cr>', opts = { desc = 'Find Man' } },
  { lhs = wkey_prefix .. 'h', rhs = '<cmd>FzfLua help_tags<cr>', opts = { desc = 'Help' } },
  { lhs = wkey_prefix .. 'o', rhs = '<cmd>FzfLua history<cr>', opts = { desc = 'History' } },
  { lhs = wkey_prefix .. 'O', rhs = '<cmd>FzfLua search_history<cr>', opts = { desc = 'History' } },
  { lhs = wkey_prefix .. 'k', rhs = '<Cmd>FzfLua keymaps<CR>', opts = { desc = 'Keymaps' } },
}, { prefix = wkey_prefix, group = 'Find' })

local lsp_wkey_prefix = '<leader>l'
KEYS.define {

  {
    lhs = lsp_wkey_prefix .. 'D',
    rhs = function()
      FzfLua.lsp_workspace_diagnostics { severity_limit = vim.diagnostic.severity.ERROR }
    end,
    opts = { desc = 'Workspace Diagnostics' },
  },
  {
    lhs = lsp_wkey_prefix .. 'r',
    rhs = '<cmd>FzfLua lsp_references<cr>',
    opts = { desc = 'References' },
  },
  {
    lhs = lsp_wkey_prefix .. 'f',
    rhs = '<cmd>FzfLua lsp_definitions<cr>',
    opts = { desc = 'Definitions' },
  },
  {
    lhs = lsp_wkey_prefix .. 's',
    rhs = '<cmd>FzfLua lsp_live_document_symbols<cr>',
    opts = { desc = 'Live Document Symbols' },
  },
  { lhs = wkey_prefix .. 'd', rhs = '<cmd>FzfLua lsp_document_diagnostics<cr>', opts = { desc = 'Document diagnostics' } },
}
