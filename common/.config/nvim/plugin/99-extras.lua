local function map(lhs, rhs, mode, opts)
  vim.validate('mode', mode, { 'string', 'table' }, true)
  vim.validate('lhs', lhs, 'string')
  vim.validate('rhs', rhs, { 'string', 'function' })
  vim.validate('opts', opts, 'table', true)
  opts = opts or {}
  mode = mode or 'n'
  vim.keymap.set(mode, lhs, rhs, opts)
end

---@class MiniGitBufData
---@field repo string - full path to '.git' directory.
---@field root string - full path to worktree root.
---@field head string - full commit of current HEAD.
---@field head_name string - short name of current HEAD (like "master") For detached HEAD it is "HEAD".
---@field status string - two character file status as returned by `git status`.
---@field in_progress string  - name of action(s) currently in progress (bisect, merge, etc.). Can be a combination of those separated by ",".

local nmap_leader = function(key, cmd, desc)
  map('<leader>' .. key, cmd, { desc = desc })
end
-- VimRc.later(function()
--   vim.pack.add(_G.plug_spec {
--     'stevearc/conform.nvim',
--     'mfussenegger/nvim-lint',
--   })
--   FeatureFlags:add { name = 'Format', gl_enabled = true }
--   require 'custom.format'
--   FeatureFlags:add { name = 'Lint', gl_enabled = true }
--   require 'custom.lint'
-- end)
--- MiniGit
VimRc.later(function()
  local git = require 'mini.git'
  git.setup()

  local git_log_cmd = [[Git log --pretty=format:\%h\ \%as\ │\ \%s --topo-order]]
  local git_log_buf_cmd = git_log_cmd .. ' --follow -- %'

  map('<C-g>c', '<Cmd>Git commit<CR>', { 'n', 'i' }, { desc = 'Commit' })
  map('<C-g>l', '<Cmd>' .. git_log_cmd .. '<CR>', { 'n', 'i' }, { desc = 'Log' })
  map('<C-g>L', '<Cmd>' .. git_log_buf_cmd .. '<CR>', { 'n', 'i' }, { desc = 'Log buffer' })

  nmap_leader('da', '<Cmd>Git diff --cached<CR>', 'Added diff')
  nmap_leader('dA', '<Cmd>Git diff --cached -- %<CR>', 'Added diff buffer')
end)

--- MiniGit
VimRc.later(function()
  ---@type MiniGitBufData|nil
  local output = MiniGit.get_buf_data(0)
  local is_git_repo = false
  if type(output) == 'table' and output.root then
    is_git_repo = vim.uv.fs_stat(output.root) ~= nil
  end
  FeatureFlags:add {
    name = 'Diff',
    gl_enabled = is_git_repo,
    toggle_hook = function(enabled, bufnr)
      if enabled then
        require('mini.diff').enable(bufnr)
      else
        require('mini.diff').disable(bufnr)
      end
      -- HACK: redraw to update the signs
      vim.defer_fn(function()
        vim.cmd [[redraw!]]
      end, 200)
    end,
  }
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

  local format_summary = function(data)
    local summary = vim.b[data.buf].minidiff_summary
    local t = {}
    if summary.add > 0 then
      table.insert(t, '+' .. summary.add)
    end
    if summary.change > 0 then
      table.insert(t, '~' .. summary.change)
    end
    if summary.delete > 0 then
      table.insert(t, '-' .. summary.delete)
    end
    vim.b[data.buf].minidiff_summary_string = table.concat(t, ' ')
  end

  vim.api.nvim_create_autocmd('User', { pattern = 'MiniDiffUpdated', callback = format_summary })
  local function toggle_mini_diff()
    MiniDiff.toggle(0)
    MiniDiff.toggle_overlay(0)
  end
  nmap_leader('do', toggle_mini_diff, 'Toggle overlay')

  local export_diff_qf = function()
    vim.fn.setqflist(MiniDiff.export 'qf')
  end
  nmap_leader('de', export_diff_qf, 'Diff to QuickFix')
end)

VimRc.later(function()
  vim.pack.add(_G.plug_spec {
    'stevearc/overseer.nvim',
  })
  require 'extras.quicker'
  require 'extras.overseer'
  require 'extras.optional.grug'
end)
VimRc.on_filetype('markdown', function()
  vim.pack.add(_G.plug_spec {
    'MeanderingProgrammer/render-markdown.nvim',
  })
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
end)

-- require('custom.obsidian').setup()
