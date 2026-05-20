if vim.o.diff then
  return
end
VimRc.later(function()
  require 'extras.quicker-trouble'
  local trouble_keys = {
    { 'q', '<cmd>lua require("quicker").toggle()<cr>', 'Quickfix' },
    { 'Q', '<cmd>lua require("quicker").toggle({loclist = true})<cr>', 'Loclist' },
    { 'D', '<cmd>Trouble diagnostics <cr>', 'Diagnostics (Everything)' },
    { 'd', '<cmd>Trouble diagnostics filter = { severity=vim.diagnostic.severity.ERROR }<cr>', 'Diagnostics (Error-only)' },
    { 's', '<cmd>Trouble symbols toggle<cr>', 'Symbols (Trouble)' },
    {
      'l',
      '<cmd>Trouble lsp toggle<cr>',
      'LSP references/definitions  (Trouble)',
    },
  }
  for _, key in ipairs(trouble_keys) do
    vim.keymap.set('n', '<leader>q' .. key[1], key[2], { desc = key[3] })
  end
  VimRc.keymap_clues[#VimRc.keymap_clues + 1] = { mode = 'n', keys = '<Leader>q', desc = '+QuickFix' }
end)

VimRc.later(function()
  require 'extras.overseer'
  local overseer_keys = {
    {
      'r',
      '<cmd>OverseerRun<cr>',
      'OverseerRun',
    },
    {
      'v',
      function()
        local ovr = require 'overseer'
        ovr.run_task({ name = 'mise' }, function(task)
          if task then
            ovr.run_action(task, 'open vsplit')
          end
        end)
      end,
      'OverseerRun (Custom)',
    },
    { 't', '<cmd>OverseerToggle bottom<cr>', 'OverseerToggle' },
    { 'q', '<cmd>OverseerRestartLast<cr>', 'Action recent task' },
  }
  for _, key in ipairs(overseer_keys) do
    vim.keymap.set('n', '<leader>x' .. key[1], key[2], { desc = key[3] })
  end
  VimRc.keymap_clues[#VimRc.keymap_clues + 1] = { mode = 'n', keys = '<Leader>x', desc = '+Exec' }
end)

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
  local git_keys = {
    { 's', '<cmd>FzfLua git_status<cr>', 'Status' },
    { 'd', '<cmd>FzfLua git_diff<cr>', 'Diff' },
    { 'h', '<Cmd>FzfLua git_hunks<CR>', 'Hunks' },
    { 'b', '<cmd>FzfLua git_blame<cr>', 'Blame' },
    { 'B', '<cmd>vertical Git blame --porcelain -- %<cr>', 'Blame (MiniGit)' },
    { 'c', '<cmd>FzfLua git_bcommit<cr>', 'Buf Commits' },
    { 'C', '<cmd>FzfLua git_commit<cr>', 'Commits' },
  }

  for _, k in ipairs(git_keys) do
    vim.keymap.set('n', '<leader>g' .. k[1], k[2], { desc = k[3] })
  end
  VimRc.keymap_clues[#VimRc.keymap_clues + 1] = { mode = 'n', keys = '<Leader>g', desc = '+Git' }
  VimRc.keymap_clues[#VimRc.keymap_clues + 1] = { mode = 'x', keys = '<Leader>g', desc = '+Git' }
  local diff_keys = {
    { 't', '<cmd>lua MiniDiff.toggle_overlay()<cr>', 'Toggle overlay' },
    {
      'q',
      function()
        vim.fn.setqflist(MiniDiff.export 'qf')
      end,
      'QuickFix',
    },
    { 'a', '<Cmd>Git diff --cached<CR>', 'Added diff' },
    { 'b', '<Cmd>Git diff --cached -- %<CR>', 'Added diff buffer' },
  }

  for _, k in ipairs(diff_keys) do
    vim.keymap.set('n', '<leader>d' .. k[1], k[2], { desc = k[3] })
  end
  VimRc.keymap_clues[#VimRc.keymap_clues + 1] = { mode = 'n', keys = '<Leader>d', desc = '+Diff' }
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

VimRc.later(function()
  require('custom.west').setup()
end)

-- Show next key clues in a bottom right window. Requires explicit opt-in for
-- keys that act as clue trigger. Example usage:
-- - Press `<Leader>` and wait for 1 second. A window with information about
--   next available keys should appear.
-- - Press one of the listed keys. Window updates immediately to show information
--   about new next available keys. You can press `<BS>` to go back in key sequence.
-- - Press keys until they resolve into some mapping.
--
-- Note: it is designed to work in buffers for normal files. It doesn't work in
-- special buffers (like for 'mini.starter' or 'mini.files') to not conflict
-- with its local mappings.
--
-- See also:
-- - `:h MiniClue-examples` - examples of common setups
-- - `:h MiniClue.ensure_buf_triggers()` - use it to enable triggers in buffer
-- - `:h MiniClue.set_mapping_desc()` - change mapping description not from config
VimRc.later(function()
  local miniclue = require 'mini.clue'
  -- stylua: ignore
  miniclue.setup({
    -- Define which clues to show. By default shows only clues for custom mappings
    -- (uses `desc` field from the mapping; takes precedence over custom clue).
    clues = {
      -- This is defined in 'plugin/20_keymaps.lua' with Leader group descriptions
      VimRc.keymap_clues,
      miniclue.gen_clues.builtin_completion(),
      miniclue.gen_clues.g(),
      miniclue.gen_clues.marks(),
      miniclue.gen_clues.registers(),
      miniclue.gen_clues.square_brackets(),
      -- This creates a submode for window resize mappings. Try the following:
      -- - Press `<C-w>s` to make a window split.
      -- - Press `<C-w>+` to increase height. Clue window still shows clues as if
      --   `<C-w>` is pressed again. Keep pressing just `+` to increase height.
      --   Try pressing `-` to decrease height.
      -- - Stop submode either by `<Esc>` or by any key that is not in submode.
      miniclue.gen_clues.windows({ submode_resize = true }),
      miniclue.gen_clues.z(),
    },
    -- Explicitly opt-in for set of common keys to trigger clue window
    triggers = {
      { mode = { 'n', 'x' }, keys = '<Leader>' }, -- Leader triggers
      { mode =   'n',        keys = '\\' },       -- mini.basics
      { mode = { 'n', 'x' }, keys = '[' },        -- mini.bracketed
      { mode = { 'n', 'x' }, keys = ']' },
      { mode =   'i',        keys = '<C-x>' },    -- Built-in completion
      { mode = { 'n', 'x' }, keys = 'g' },        -- `g` key
      { mode = { 'n', 'x' }, keys = 'q' },        -- `g` key
      { mode = { 'n', 'x' }, keys = "'" },        -- Marks
      { mode = { 'n', 'x' }, keys = '`' },
      { mode = { 'n', 'x' }, keys = '"' },        -- Registers
      { mode = { 'i', 'c' }, keys = '<C-r>' },
      { mode =   'n',        keys = '<C-w>' },    -- Window commands
      { mode = { 'n', 'x' }, keys = 's' },        -- `s` key (mini.surround, etc.)
      { mode = { 'n', 'x' }, keys = 'z' },        -- `z` key
    },

  })
end)
