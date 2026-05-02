---@class MiniGitBufData
---@field repo string - full path to '.git' directory.
---@field root string - full path to worktree root.
---@field head string - full commit of current HEAD.
---@field head_name string - short name of current HEAD (like "master") For detached HEAD it is "HEAD".
---@field status string - two character file status as returned by `git status`.
---@field in_progress string  - name of action(s) currently in progress (bisect, merge, etc.). Can be a combination of those separated by ",".

VimRc.later(function()
  require('custom.format').setup()
  require('trouble').setup {
    focus = true, -- Focus the window when opened
    modes = {
      symbols = {
        ---@class trouble.Window.split
        win = { type = 'split', position = 'right', size = { width = 0.5, height = 0.0 } },
      },
    },
  }

  require('quicker').setup {
    opts = {
      buflisted = false,
      number = false,
      relativenumber = false,
      signcolumn = 'auto',
      winfixheight = true,
      wrap = true,
    },
    -- -- Set to false to disable the default options in `opts`
    -- use_default_opts = true,
    -- Keymaps to set for the quickfix buffer
    keys = {
      { '>', "<cmd>lua require('quicker').expand({ add_to_existing = true})", desc = 'Expand quickfix content' },
      { '<', "<cmd>lua require('quicker').collapse()<CR>", desc = 'Collapse quickfix content' },
      {
        '-',
        function()
          require('quicker').expand { after = 0, before = 3, add_to_existing = true }
        end,
        desc = 'Expand/Collapse quickfix content toggle',
      },
      {
        '+',
        function()
          require('quicker').expand { after = 3, before = 0, add_to_existing = true }
        end,
        desc = 'Expand/Collapse quickfix content toggle',
      },
      {
        'r',
        '<cmd>Refresh<cr>', -- User cmd added by quicker to the buffer
        desc = 'Refresh quickfix content',
      },
    },
    -- Callback function to run any custom logic or keymaps for the quickfix buffer
    -- on_qf = function(bufnr) end,
    edit = {
      -- Enable editing the quickfix like a normal buffer
      enabled = true,
      -- Set to true to write buffers after applying edits.
      -- Set to "unmodified" to only write unmodified buffers.
      autosave = true,
    },
  }
  local trouble_keys = {
    { '<leader>xd', '<cmd>Trouble diagnostics toggle filter.severity=2<cr>', 'Diagnostics (Trouble)' },
    { '<leader>xb', '<cmd>Trouble diagnostics toggle filter.buf=0 filter.severity=2<cr>', 'Buffer Diagnostics (Trouble)' },
    { '<leader>xs', '<cmd>Trouble symbols toggle<cr>', 'Symbols (Trouble)' },
    {
      '<leader>xl',
      '<cmd>Trouble lsp toggle<cr>',
      'LSP references/definitions  (Trouble)',
    },
  }
  for _, key in ipairs(trouble_keys) do
    vim.keymap.set('n', key[1], key[2], { desc = key[3] })
  end
  local config = require 'fzf-lua.config'
  local actions = require('trouble.sources.fzf').actions
  config.defaults.actions.files['ctrl-t'] = actions.open
end)

local is_git_repo = function()
  local output = require('mini.git').get_buf_data(0)
  local inside_git_repo = type(output) == 'table' and output.root and vim.uv.fs_stat(output.root) ~= nil
  return inside_git_repo
end

local export_diff_qf = function()
  vim.fn.setqflist(MiniDiff.export 'qf')
end

local minidiff_toggle_hook = function(enabled, bufnr)
  if enabled then
    if MiniDiff then
      MiniDiff.enable(bufnr)
      MiniDiff.toggle_overlay(bufnr)
    end
  else
    require('mini.diff').disable(bufnr)
  end
  -- HACK: redraw to update the signs
  vim.defer_fn(function()
    vim.cmd [[redraw!]]
  end, 200)
end
VimRc.later(function()
  require 'extras.minigit'
  local diff = require 'mini.diff'
  diff.setup {

    -- Source(s) for how reference text is computed/updated/etc
    -- Uses content from Git index by default
    source = { diff.gen_source.git(), diff.gen_source.save() },
    view = {
      style = 'sign',
      signs = { add = '+', change = '~', delete = '-' },
    },
  }
  require('octo').setup {
    -- or "fzf-lua" or "snacks" or "default"
    picker = 'fzf-lua',
    -- bare Octo command opens picker of commands
    enable_builtin = true,
  }
  local prefix_keys = {
    { 's', '<cmd>FzfLua git_status<cr>', 'Status' },
    { 'd', '<cmd>FzfLua git_diff<cr>', 'Diff' },
    { 'h', '<Cmd>FzfLua git_hunks<CR>', 'Hunks' },
    { 'b', '<cmd>FzfLua git_blame<cr>', 'Blame' },
    { 'B', '<cmd>vertical Git blame --porcelain -- %<cr>', 'Blame (MiniGit)' },
    { 'c', '<cmd>FzfLua git_bcommit<cr>', 'Buf Commits' },
    { 'C', '<cmd>FzfLua git_commit<cr>', 'Commits' },
  }

  for _, k in ipairs(prefix_keys) do
    vim.keymap.set('n', '<leader>g' .. k[1], k[2], { desc = k[3] })
  end
  local diff_keys = {
    { 'T', minidiff_toggle_hook, 'Diff toggle' },
    { 't', '<cmd>lua MiniDiff.toggle_overlay()<cr>', 'Toggle overlay' },
    { 'e', export_diff_qf, 'QuickFix' },
    { 'a', '<Cmd>Git diff --cached<CR>', 'Added diff' },
    { 'b', '<Cmd>Git diff --cached -- %<CR>', 'Added diff buffer' },
  }

  for _, k in ipairs(diff_keys) do
    vim.keymap.set('n', '<leader>d' .. k[1], k[2], { desc = k[3] })
  end
end)
VimRc.later(function()
  require('render-markdown').setup(
    ---@type render.md.Settings
    {
      preset = 'obsidian',
      completions = {
        lsp = {
          enabled = true,
        },
      },
      pipe_table = {
        preset = 'round',
      },
      latex = { enabled = false },
    }
  )
  vim.api.nvim_set_hl(0, '@markup.heading.1.markdown', { fg = '#e46876' })
  vim.api.nvim_set_hl(0, '@markup.heading.2.markdown', { fg = '#ff9e3b' })
  vim.api.nvim_set_hl(0, '@markup.heading.3.markdown', { fg = '#e6c384' })
  vim.api.nvim_set_hl(0, '@markup.heading.4.markdown', { fg = '#7fb4ca' })
  require('custom.obsidian').setup()
end)
