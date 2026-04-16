vim.pack.add {
  'https://github.com/nvim-mini/mini.nvim',
}

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

_G.VimRc = _G.VimRc or require 'custom.utils'
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

local gr = vim.api.nvim_create_augroup('vimrc', {})
---@param event string|string[]
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

VimRc.user_cmd = vim.api.nvim_create_user_command --[[@type function]]
VimRc.user_buf_cmd = vim.api.nvim_buf_create_user_command--[[@type function]]

---@param spec string[]
---@return vim.pack.Spec
function _G.plug_spec(spec)
  return vim
    .iter(spec)
    :map(function(p)
      if type(p) == 'string' then
        return {
          src = 'https://github.com/' .. p,
          name = p:match '%S+/(%S+)',
        }
      elseif type(p) == 'table' then
        return vim.tbl_extend('force', p, {
          src = 'https://github.com/' .. p,
        })
      end
      return {}
    end)
    :totable()
end

---@class FeatureFlagOpts
---@field local boolean?
---@field toggle_hook fun(enabled: boolean, bufnr:integer, data:table)?
---
---
---@class FeatureFlag
---@field name string
---@field gl_enabled boolean
---@field opts FeatureFlagOpts?
---
---@type FeatureFlag
FeatureFlag = {}
---@method
---@param o FeatureFlag
function FeatureFlag:new(o)
  o = o or {} -- create object if user does not provide one
  setmetatable(o, self)
  self.__index = self
  return o
end
---@class vimrc.FeatureFlags
---@field entries table<string, FeatureFlag>
_G.FeatureFlags = {
  entries = {},
}
FeatureFlags.__index = FeatureFlags

---@param feature FeatureFlag|string
---@return FeatureFlag
function FeatureFlags:add(feature)
  vim.validate('feature', feature, { 'table', 'string' })
  local name
  if type(feature) == 'string' then
    name = feature
    feature = FeatureFlag:new { name = name, gl_enabled = false }
  else
    name = feature.name
  end

  self.entries[name] = feature
  local usercmd_name = name .. 'Toggle'
  vim.api.nvim_create_user_command(usercmd_name, function(args)
    local flag = FeatureFlags:get(name)
    local enable = not flag.gl_enabled
    local opts = flag.opts or {}
    FeatureFlags:set(flag.name, enable)
    if vim.is_callable(opts.toggle_hook) then
      opts.toggle_hook(enable, vim.api.nvim_get_current_buf(), args)
    end
  end, {
    desc = 'Toggle feature flag for ' .. name,
  })
  return feature
end

---@param name string
---@return FeatureFlag
function FeatureFlags:get(name)
  -- clear nodes on change tick, calling any methods on invalid nodes causes
  -- neovim to hard crash
  local entry = self.entries[name]
  if not entry then
    return FeatureFlags:add { name = name, gl_enabled = false }
  end
  return entry
end

---@param name string
---@param enable boolean?
function FeatureFlags:set(name, enable)
  local fflag = self:get(name)
  fflag.gl_enabled = enable or false
  self.entries[name] = fflag
end
