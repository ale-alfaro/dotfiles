---@class vimrc.KeyMapping
---@field mode (string|string[])?
---@field lhs string
---@field rhs string|function
---

vim.o.exrc = true
--- Load given exrc file
---@param exrc_path string
local function exrc_trust(exrc_path)
  -- Ensure we trust the file before loading
  exrc_path = exrc_path or '.nvim.lua'
  local ok, result = vim.secure.trust { action = 'allow', path = exrc_path }
  if not ok then
    VimRc.err('Failed to load exrc "%s"', exrc_path)
    error(result)
  end
end
local exrc_au = vim.api.nvim_create_augroup('exrc', {clear = true})
vim.api.nvim_create_autocmd('BufWrite', { pattern = '**/.nvim.lua', callback = function (ev)
  local buf = ev.buf
  exrc_trust(vim.api.nvim_buf_get_name(buf))
end, desc = "Trust .nvim", group = exrc_au })

local function exrc_database()
  vim.cmd('e ' .. vim.fs.joinpath(vim.fn.expand '$XDG_STATE_HOME', 'nvim', 'trust'))
end
local gh = function(repo)
  return 'https://github.com/' .. repo
end
local gh_rev = function(repo, rev)
  return { src = 'https://github.com/' .. repo, version = rev }
end

vim.pack.add {
  gh 'nvim-mini/mini.nvim',
  gh 'folke/snacks.nvim',
  gh 'stevearc/oil.nvim',
  gh 'stevearc/quicker.nvim',
  gh 'stevearc/overseer.nvim',
  gh 'folke/trouble.nvim',
  gh 'ibhagwan/fzf-lua',
  gh 'nvim-treesitter/nvim-treesitter',
  gh 'nvim-treesitter/nvim-treesitter-textobjects',
  gh 'neovim/nvim-lspconfig',
  gh 'b0o/schemastore.nvim',
  gh 'rachartier/tiny-code-action.nvim',
  gh 'MeanderingProgrammer/render-markdown.nvim',
  gh 'MagicDuck/grug-far.nvim',
  gh 'nvim-lua/plenary.nvim',
  gh 'saghen/blink.lib',
  gh_rev('saghen/blink.cmp', 'main'),
}
local misc = require 'mini.misc'
---@class VimRc : vimrc.Utils
---@field map fun(mapping:vimrc.KeyMapping,opts:vim.keymap.set.Opts|string)
---@field now fun(func:function)
---@field later fun(func:function)
---@field now_if_args fun(func:function)
---@field on_filetype fun(ft:string,func:function)
---@field on_event fun(evt:string,func:function)
---@field new_autocmd fun(event:string|string[],callback:function,pattern:string|string[]?,desc:string?)
---@field on_packchanged fun(plugin_name:string,kinds:string[],callback:fun(plugin_spec:vim.pack.Spec,plugin_path:string),desc:string?)
---@field notify? fun(msg:string,lvl:string)
---@field env table<string,string>
---@field getenv fun(name:string,fallback?:string):string?
---@field checkenv fun(name:string):boolean
_G.VimRc = _G.VimRc or require 'custom.utils' ---@type VimRc
---
---
---@param mapping vimrc.KeyMapping
---@param opts vim.keymap.set.Opts|string
function VimRc.map(mapping, opts)
  vim.validate('mapping', mapping, 'table')
  vim.validate('mode', mapping.mode, { 'string', 'table' }, true)
  vim.validate('lhs', mapping.lhs, 'string')
  vim.validate('rhs', mapping.rhs, { 'string', 'function' })
  vim.validate('opts', opts, { 'string', 'table' }, true)
  local keymap_opts ---@as vim.keymap.set.Opts
  if type(opts) == 'string' then
    keymap_opts = { desc = opts }
  else
    keymap_opts = opts or {}
  end

  local mode = mapping.mode or 'n'

  vim.keymap.set(mode, mapping.lhs, mapping.rhs, keymap_opts)
end

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

local gr = vim.api.nvim_create_augroup('vimrc', {})
---@param event string|string[]
---@param callback function
---@param pattern string|string[]?
---@param desc string?
VimRc.new_autocmd = function(event, callback, pattern, desc)
  pattern = pattern or '*'
  local opts = { group = gr, pattern = pattern, callback = callback, desc = desc }
  vim.api.nvim_create_autocmd(event, opts)
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
    callback(ev.data.spec, ev.data.path)
  end
  VimRc.new_autocmd('PackChanged', f, '*', desc)
end
---@param plugin vim.pack.Spec
---@param path string
local ts_update = function(plugin, path)
  vim.cmd 'TSUpdate'
end
VimRc.on_packchanged('nvim-treesitter', { 'update' }, ts_update, ':TSUpdate')
-- local hooks = function(ev)
--   -- Use available |event-data|
--   local name, kind = ev.data.spec.name, ev.data.kind
--
--   -- Run build script after plugin's code has changed
--   if name == 'plug-1' and (kind == 'install' or kind == 'update') then
--     -- Append `:wait()` if you need synchronous execution
--     vim.system({ 'make' }, { cwd = ev.data.path })
--   end
--
--   -- If action relies on code from the plugin (like user command or
--   -- Lua code), make sure to explicitly load it first
--   if name == 'plug-2' and kind == 'update' then
--     if not ev.data.active then
--       vim.cmd.packadd('plug-2')
--     end
--     vim.cmd('PlugTwoUpdate')
--     require('plug2').after_update()
--   end
-- end
--
-- -- If hooks need to run on install, run this before `vim.pack.add()`
-- -- To act on install from lockfile, run before very first `vim.pack.add()`
-- vim.api.nvim_create_autocmd('PackChanged', { callback = hooks })
---
---
---@class FeatureFlag
---@field name string
---@field enabled boolean
---@field toggle_hook? fun(enabled:boolean)
---
---@class vimrc.FeatureFlags
---@field entries table<string, FeatureFlag>
_G.FeatureFlags = {
  entries = {},
}
FeatureFlags.__index = FeatureFlags

---@class vimrc.FeatureFlags.AddOpts
---@field enable? boolean
---@field local? boolean
---@field toggle_hook? fun(enabled: boolean, bufnr:integer, data:table)
---
---@param name string
---@param opts? vimrc.FeatureFlags.AddOpts
---@return FeatureFlag
function FeatureFlags:add(name, opts)
  vim.validate('name', name, 'string')
  vim.validate('opts', opts, 'table')
  opts = opts or {}
  self.entries[name] = {
    name = name,
    enabled = opts.enable or false,
  }
  local usercmd_name = name .. 'Toggle'
  vim.api.nvim_create_user_command(usercmd_name, function(args)
    local flag = FeatureFlags:get(name)
    local enable = not flag.enabled
    FeatureFlags:set(flag.name, enable)
    if vim.is_callable(opts.toggle_hook) then
      opts.toggle_hook(enable, vim.api.nvim_get_current_buf(), args)
    end
  end, {
    desc = 'Toggle feature flag for ' .. name,
  })
  return self.entries[name]
end

---@param name string
---@return FeatureFlag
function FeatureFlags:get(name)
  -- clear nodes on change tick, calling any methods on invalid nodes causes
  -- neovim to hard crash
  local entry = self.entries[name]
  if not entry then
    return FeatureFlags:add(name, { enable = false })
  end
  return entry
end

---@param name string
---@param enable boolean?
function FeatureFlags:set(name, enable)
  local fflag = self:get(name)
  fflag.enabled = enable or false
  self.entries[name] = fflag
end


vim.env.PATH = vim.env.HOME .. '/.local/share/mise/shims:' .. vim.env.PATH
VimRc.env = vim.fn.environ() or {}
---Get environment variable
---@description Use for getting with fallback
---@param name string
---@param fallback? string
---@return string?
VimRc.getenv = function(name, fallback)
  vim.validate('name', name, 'string')
  vim.validate('fallback', fallback, 'string', true)
  if VimRc.env[name] then
    return VimRc.env[name]
  elseif fallback then
    return fallback
  else
    VimRc.err('Failed to get env: ' .. name)
  end
end
-- Prepend mise shims to PATH
-- 'WEST_TOPDIR'
function VimRc.checkenv(name)
  return vim.fn.has_key(vim.fn.environ() or {}, name) ~= 0
end
