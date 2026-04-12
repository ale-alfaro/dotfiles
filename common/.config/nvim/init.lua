_G.VimRc = require 'custom'
require 'config.opts'

local gr = vim.api.nvim_create_augroup('vimrc', {})
---@param event string
---@param callback function
---@param pattern (string|string[])?
---@param desc string?
VimRc.new_autocmd = function(event, callback, pattern, desc)
  pattern = pattern or '*'
  local opts = { group = gr, pattern = pattern, callback = callback, desc = desc }
  vim.api.nvim_create_autocmd(event, opts)
end
VimRc.oneshot_autocmd = function(event, callback)
  local opts = { once = true, group = gr, callback = callback }
  vim.api.nvim_create_autocmd(event, opts)
end

local bufgr = vim.api.nvim_create_augroup('vimrc.buf', { clear = false })
--- Buflocal autocmd
---@param event string|string[]
---@param bufnr integer
---@param callback function
---@param desc string?
VimRc.new_buf_autocmd = function(event, bufnr, callback, desc)
  local opts = { group = bufgr, callback = callback, buffer = bufnr, desc = desc or '' }
  vim.api.nvim_create_autocmd(event, opts)
end
require 'config.autocmds'

VimRc.user_cmd = vim.api.nvim_create_user_command --[[@type function]]
VimRc.user_buf_cmd = vim.api.nvim_buf_create_user_command--[[@type function]]
require 'config.usercmds'
require 'config.keymaps'
vim.pack.add(_G.plug_spec {
  'nvim-lua/plenary.nvim',
  'nvim-mini/mini.nvim',
  'stevearc/oil.nvim',
})

-- Loading helpers used to organize config into fail-safe parts. Example usage:
-- - `now` - execute immediately. Use for what must be executed during startup.
--   Like colorscheme, statusline, tabline, dashboard, etc.
-- - `later` - execute a bit later. Use for things not needed during startup.
-- - `now_if_args` - use only if needed during startup when Neovim is started
--   like `nvim -- path/to/file`, but otherwise delaying is fine.
-- - Others are better used only if the above is not enough for good performance.
--   Use only if you are comfortable with adding complexity to your config:
--   - `on_event` - execute once on a first matched event. Like "delay until
--     first Insert mode enter": `on_event('InsertEnter', function() ... end)`.
--   - `on_filetype` - execute once on a first matched filetype. Like "delay
--     until first Lua file": `on_filetype('lua', function() ... end)`.
--
-- See also:
-- - `:h MiniMisc.safely()`
-- - 'plugin/30_mini.lua' and 'plugin/40_plugins.lua'
local misc = require 'mini.misc'
VimRc.now = function(f)
  misc.safely('now', f)
end
VimRc.later = function(f)
  misc.safely('later', f)
end
VimRc.now_if_args = vim.fn.argc(-1) > 0 and VimRc.now or VimRc.later
VimRc.on_event = function(ev, f)
  misc.safely('event:' .. ev, f)
end
VimRc.on_filetype = function(ft, f)
  misc.safely('filetype:' .. ft, f)
end

-- Define custom `vim.pack.add()` hook helper. See `:h vim.pack-events`.
-- Example usage: see 'plugin/40_plugins.lua'.
VimRc.on_packchanged = function(plugin_name, kinds, callback, desc)
  local f = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if not (name == plugin_name and vim.tbl_contains(kinds, kind)) then
      return
    end
    if not ev.data.active then
      vim.cmd.packadd(plugin_name)
    end
    callback()
  end
  VimRc.new_autocmd('PackChanged', f, '*', desc)
end
