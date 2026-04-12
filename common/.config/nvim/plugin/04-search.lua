VimRc.later(function()
  vim.pack.add(_G.plug_spec { 'ibhagwan/fzf-lua' })

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
    { 'fzf-native', 'hide' },
    -- Make stuff better combine with the editor.
    --
    ui_select = true,
    keymap = {
      -- Below are the default binds, setting any value in these tables will override
      -- the defaults, to inherit from the defaults change [1] from `false` to `true`
      builtin = {
        -- neovim `:tmap` mappings for the fzf win
        -- true,        -- uncomment to inherit all the below in your custom config
        ['<alt-q>'] = 'hide', -- hide fzf-lua, `:FzfLua resume` to continue
        ['<F1>'] = 'toggle-help',
        ['<F2>'] = 'toggle-fullscreen',
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
        ['alt-z'] = 'abort',
        ['alt-d'] = 'half-page-down',
        ['alt-u'] = 'half-page-up',
        ['alt-A'] = 'select-all+accept',
        ['alt-a'] = 'toggle-all',
        ['alt-g'] = 'first',
        ['alt-G'] = 'last',
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
        -- ['enter'] = FzfLua.actions.file_edit_or_qf,
        -- ['ctrl-d'] = FzfLua.actions.file_split,
        -- ['ctrl-v'] = FzfLua.actions.file_vsplit,
        -- ['ctrl-q'] = FzfLua.actions.file_sel_to_qf,
        -- ['ctrl-i'] = FzfLua.actions.toggle_ignore,
      },
    },
    winopts = {
      height = 0.7,
      width = 0.7,

      wrap = true, -- preview line wrap (fzf's 'wrap|nowrap')
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
    -- lsp = {
    --   symbols = {
    --     symbol_icons = VimRc.icons.symbol_kinds,
    --   },
    -- },
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
  local nonprefix_keys = {
    { '<C-b>', '<cmd>FzfLua buffers<cr>', 'Buffers' },
    { '<C-\\>', '<cmd>FzfLua global<cr>', 'Global' },
    { '<C-e>', '<cmd>FzfLua files<cr>', 'Files' },
    { '<C-g>', '<cmd>FzfLua live_grep<cr>', 'Grep (cwd)' },
    { '<C-c>', '<cmd>FzfLua resume<cr>', 'Continue' },
    { '<C-f>', '<cmd>FzfLua command_history<cr>', 'Command History' },
    { '<C-y>', '<cmd>FzfLua register<cr>', 'Registers' },
  }

  for _, k in ipairs(nonprefix_keys) do
    vim.keymap.set('n', k[1], k[2], { desc = k[3], noremap = true })
  end
  local wkey_prefix = '<leader>f'
  local lsp_wkey_prefix = '<leader>l'
  local prefix_keys = {
    { '<C-l>', '<cmd>FzfLua blines<cr>', 'Buffer Lines' },
    { '<M-o>', '<cmd>FzfLua oldfiles<cr>', 'Old Files' },
    { wkey_prefix .. 'b', '<cmd>FzfLua builtin<cr>', 'Find Fzf pickers' },
    { wkey_prefix .. 'm', '<cmd>FzfLua manpages<cr>', 'Find Man' },
    { wkey_prefix .. 'h', '<cmd>FzfLua help_tags<cr>', 'Help' },
    { wkey_prefix .. 'o', '<cmd>FzfLua history<cr>', 'History' },
    { wkey_prefix .. 'O', '<cmd>FzfLua search_history<cr>', 'History' },
    { wkey_prefix .. 'k', '<Cmd>FzfLua keymaps<CR>', 'Keymaps' },
    { wkey_prefix .. 'fD', '<cmd>FzfLua git_diff<cr>', 'Search Git Diff' },
    { wkey_prefix .. 'fc', '<CMD>FzfLua changes<CR>', 'Search Git Diff (file-only)' },
    { wkey_prefix .. 'fH', '<cmd>FzfLua git_hunks<cr>', 'Git Hunks' },
    {
      lsp_wkey_prefix .. 'D',
      function()
        FzfLua.lsp_workspace_diagnostics { vim.diagnostic.severity.ERROR }
      end,
      'Workspace Diagnostics',
    },
    {
      lsp_wkey_prefix .. 'r',
      '<cmd>FzfLua lsp_references<cr>',
      'References',
    },
    {
      lsp_wkey_prefix .. 'f',
      '<cmd>FzfLua lsp_definitions<cr>',
      'Definitions',
    },
    {
      lsp_wkey_prefix .. 's',
      '<cmd>FzfLua lsp_document_symbols<cr>',
      'Live Document Symbols',
    },
    { wkey_prefix .. 'd', '<cmd>FzfLua lsp_document_diagnostics<cr>', 'Document diagnostics' },
  }

  for _, k in ipairs(prefix_keys) do
    vim.keymap.set('n', k[1], k[2], { desc = k[3] })
  end
end)
