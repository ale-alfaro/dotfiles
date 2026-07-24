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
local minifiles_toggle = function()
  if not MiniFiles.close() then
    MiniFiles.open(vim.api.nvim_buf_get_name(0), false)
  end
end
---@class ExplorerPlugin
---@field setup fun()
---@field open_curr_buf fun()|string
---@field open_at_loc  fun(loc:string)
---@field quickfix? fun()
---@field loc_list? fun()
if not vim.o.diff then
  VimRc.now_if_args(function()
    local minifiles = require 'extras.minifiles' ---@as ExplorerPlugin
    local oil = require 'extras.oil' ---@as ExplorerPlugin
    oil.setup()
    minifiles.setup()

    -- stylua:ignore
    local dots = vim.fs.joinpath(vim.fn.getenv 'HOME', 'dotfiles')
    local work = vim.fs.joinpath(vim.fn.getenv 'HOME', 'sibel', 'eng')
    local obs = (vim.fn.getenv 'OBSIDIAN_HOME' == vim.NIL) and vim.fs.joinpath(vim.fn.getenv 'HOME', 'Documents', 'Obsidian') or vim.fn.getenv 'OBSIDIAN_HOME'
    local prefix_keys = {
      { 'v', '<cmd>Oil ' .. vim.fs.dirname(vim.fn.expand '$MYVIMRC') .. '<cr>', 'VimRc' },
      { 'z', '<cmd>Oil ' .. vim.fn.getenv 'ZDOTDIR' .. '<cr>', 'ZshRc' },
      { 'o', '<cmd>Oil ' .. obs .. '<cr>', 'Obsidian' },
      { 'c', '<cmd>Oil ' .. vim.fn.getenv 'XDG_CONFIG_HOME' .. '<cr>', 'Config' },
      { 'd', '<cmd>Oil ' .. dots .. '<cr>', 'Dotfiles' },
      { 'f', '<cmd>Oil ' .. vim.fs.joinpath(work, 'fw') .. '<cr>', 'Fw' },
      { 't', '<cmd>Oil ' .. vim.fs.joinpath(work, 'tools') .. '<cr>', 'Tools' },
    }

    for _, k in ipairs(prefix_keys) do
      vim.keymap.set('n', '<leader>e' .. k[1], k[2], { desc = k[3] })
    end
    local non_prefix_keys = {
      { '\\', minifiles_toggle, 'Open Explorer (Cwd)' },
      { '<localleader>l', '<Cmd>lua MiniFiles.open(MiniFiles.get_latest_path())<cr>', 'Open Explorer (Last Path)' },
    }
    for _, k in ipairs(non_prefix_keys) do
      vim.keymap.set('n', k[1], k[2], { desc = k[3] })
    end
  end)
end
