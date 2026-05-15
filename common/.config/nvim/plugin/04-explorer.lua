-- Step one or two ============================================================
-- Load now if Neovim is started like `nvim -- path/to/file`, otherwise - later.
-- This ensures a correct behavior for files opened during startup.

-- Completion and signature help. Implements async "two stage" autocompletion:
-- - Based on attached LSP servers that support completion.
-- - Fallback (based on built-in keyword completion) if there is no LSP candidates.
--
-- Example usage in Insert mode with attached LSP:
-- - Start typing text that should be recognized by LSP (like variable name).
-- - After 100ms a popup menu with candidates appears.
-- - Press `<Tab>` / `<S-Tab>` to navigate down/up the list. These are set up
--   in 'mini.keymap'. You can also use `<C-n>` / `<C-p>`.
-- - During navigation there is an info window to the right showing extra info
--   that the LSP server can provide about the candidate. It appears after the
--   candidate stays selected for 100ms. Use `<C-f>` / `<C-b>` to scroll it.
-- - Navigating to an entry also changes buffer text. If you are happy with it,
--   keep typing after it. To discard completion completely, press `<C-e>`.
-- - After pressing special trigger(s), usually `(`, a window appears that shows
--   the signature of the current function/method. It gets updated as you type
--   showing the currently active parameter.
--
-- Example usage in Insert mode without an attached LSP or in places not
-- supported by the LSP (like comments):
-- - Start typing a word that is present in current or opened buffers.
-- - After 100ms popup menu with candidates appears.
-- - Navigate with `<Tab>` / `<S-Tab>` or `<C-n>` / `<C-p>`. This also updates
--   buffer text. If happy with choice, keep typing. Stop with `<C-e>`.
--
-- It also works with snippet candidates provided by LSP server. Best experience
-- when paired with 'mini.snippets' (which is set up in this file).

---@class ExplorerPlugin
---@field setup fun()
---@field open_curr_buf fun()|string
---@field open_at_loc  fun(loc:string)
---@field quickfix? fun()
---@field loc_list? fun()

---@comment create a oil open function
---@param loc string
---@return function
local create_explorer_open_fn = function(explorer, loc)
  return function()
    explorer.open_at_loc(loc)
  end
end
if not vim.o.diff then
  VimRc.now_if_args(function()
    local minifiles = require 'extras.minifiles' ---@as ExplorerPlugin
    local oil = require 'extras.oil' ---@as ExplorerPlugin
    oil.setup()
    minifiles.setup()

    -- stylua:ignore
    local wkey_prefix = '<leader>e'
    vim.keymap.set('n', wkey_prefix .. 'v', create_explorer_open_fn(oil, vim.fn.expand '$MYVIMRC'), { desc = '$MYVIMRC' })
    vim.keymap.set('n', wkey_prefix .. 'z', create_explorer_open_fn(oil, vim.fn.getenv 'ZDOTDIR'), { desc = '.zshrc' })
    vim.keymap.set('n', wkey_prefix .. 'o', create_explorer_open_fn(oil, vim.fn.getenv 'OBSIDIAN_HOME'), { desc = 'Obsidian' })
    vim.keymap.set(
      'n',
      wkey_prefix .. 'd',
      create_explorer_open_fn(oil, vim.fs.joinpath(vim.fn.getenv 'HOME', 'dotfiles', 'common')),
      { desc = 'Common Dotfiles' }
    )
    vim.keymap.set('n', wkey_prefix .. 'l', create_explorer_open_fn(oil, vim.fs.joinpath(vim.fn.getenv 'HOME', 'dotfiles', 'linux')), { desc = 'Linux Dotfiles' })
    vim.keymap.set('n', wkey_prefix .. 'm', create_explorer_open_fn(oil, vim.fs.joinpath(vim.fn.getenv 'XDG_CONFIG_HOME', 'mise')), { desc = 'Mise config' })
    vim.keymap.set('n', wkey_prefix .. 'w', create_explorer_open_fn(oil, vim.fs.joinpath(vim.fn.getenv 'HOME', 'sibel', 'eng')), { desc = 'Work' })
    vim.keymap.set('n', '\\', minifiles.open_curr_buf, { desc = 'Cwd' })
  end)
end
