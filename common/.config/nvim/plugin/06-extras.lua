VimRc.later(function()
  require('extras.completion').setup_blink()
end)

VimRc.later(function()
  require 'extras.quicker-trouble'
end)

VimRc.later(function()
  require 'extras.overseer'
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
  vim.api.nvim_set_hl(0, 'RenderMarkdownH1', { fg = '#fb4934' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH2', { fg = '#fe8019' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH3', { fg = '#fabd2f' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH4', { fg = '#b8bb26' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH5', { fg = '#8ec07c' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH1Bg', { fg = '#fb4934' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH2Bg', { fg = '#fe8019' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH3Bg', { fg = '#fabd2f' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH4Bg', { fg = '#b8bb26' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH5Bg', { fg = '#8ec07c' })
end)
VimRc.later(function()
  if vim.env.ZEPHYR_BASE or vim.fs.root(vim.fn.getcwd(0), ".west") then
  require('custom.west').setup()
end
end)

-- VimRc.later(function()
--   require 'extras.codecompanion'
-- end)

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
VimRc.now_if_args(function()
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

    window = {
      -- Show window immediately
      delay = 0,

      config = {
        -- Compute window width automatically
        width = 'auto',

        -- Use double-line border
        border = 'double',
      },
    },
  })
end)
