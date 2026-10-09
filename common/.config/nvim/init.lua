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
vim.api.nvim_create_autocmd('BufWrite', { pattern = '.nvim.lua', callback = function (ev)
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
vim.cmd [[
  packadd nvim.undotree
  packadd nvim.difftool
]]
local misc = require 'mini.misc'

  misc.setup()
  misc.setup_auto_root()
  misc.setup_termbg_sync()
  misc.setup_restore_cursor()
---@class VimRc : vimrc.Utils
---@field map fun(mapping:vimrc.KeyMapping,opts:vim.keymap.set.Opts|string)
---@field now fun(func:function)
---@field later fun(func:function)
---@field now_if_args fun(func:function)
---@field on_filetype fun(ft:string|string[],func:function)
---@field on_event fun(evt:string,func:function)
---@field on_packchanged fun(plugin_name:string,callback:fun())
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
VimRc.never = function(_f)
end
VimRc.now = function(f)
  misc.safely('now', f)
end
VimRc.later = function(f)
  misc.safely('later', f)
end
VimRc.now_if_args = vim.fn.argc(-1) > 0 and VimRc.now or VimRc.later
VimRc.never_if_args = vim.fn.argc(-1) > 0 and VimRc.never or VimRc.later




VimRc.new_autocmd = function(event, pattern, f)
  if type(pattern) == 'table' and #pattern == 0 then pattern = nil end

  local function cb()
    -- Execute exactly once, not once per event or pattern match
    -- Delete before executing `f` to account for nested events
  local ok, err = xpcall(f, function(e) return debug.traceback(e .. '\n', 2) end)
  if not ok then
  local init_trace = '\n\nTraceback of `MiniMisc.safely()` call:\n'
  vim.notify('Error during safe execution: ' .. err .. init_trace, vim.log.levels.WARN)
end
  end

  local group = vim.api.nvim_create_augroup('VimRc', { clear = true })
  local opts = { group = group, pattern = pattern, callback = cb}
  vim.api.nvim_create_autocmd(event, opts)
end
---@param ev string When to execute a function. One of:
---   - `'now'` - immediately.
---   - `'later'` - queue to be executed soon without blocking the execution of next
---     code in file. Queued functions are executed in order they are added.
---   - `'delay:<number>'` - after a specified delay with |vim.defer_fn()|.
---   - `'event:<events>'` - on whichever specified event is triggered first.
---   - `'event:<events>~<patterns>` - same as above, but events must match
---     specified |autocmd-pattern|.
---   - `'filetype:<filetypes>'` - same as `'event:FileType~<filetypes>'`, but follow
---     successful function execution with |filetype-detect| for all normal buffers
---     (if new |ftdetect| scripts were added) and sourcing |ftplugin| (for buffers
---     matching `<filetypes>`). Intended to be used for loading "language plugins".
---@param f function Function to execute (without arguments).
---
---@usage >lua
---   MiniMisc.safely('later', function()
---     vim.notify('This will be executed after the next "now" call')
---   end)
---   MiniMisc.safely('now', function() error('This will be a warning') end)
---
---   MiniMisc.safely('event:InsertEnter', function()
---     require('mini.completion').setup()
---   end)
---   MiniMisc.safely('event:CmdlineEnter~/', function()
---     vim.notify('Start searching for the first time')
---   end)
---
---   MiniMisc.safely('filetype:tex,plaintex', function()
---     -- Load plugin to improve writing LaTeX
---   end)
VimRc.on_event = function(ev, f)
  misc.safely('event:' .. ev, f)
end
VimRc.on_filetype = function(ft, f)
  if type(ft) == 'table' and vim.islist(ft) then 
    local pat = table.concat(ft,",")
  misc.safely('filetype:' .. pat, f)
elseif type(ft) == 'string' then
  misc.safely('filetype:' .. ft, f)
else
  vim.notify("Bad pattern", vim.log.levels.ERROR)
  end
end

VimRc.on_event('PackChanged', function(ev)

    local name, kind = ev.data.spec.name, ev.data.kind
    if not vim.tbl_contains({ 'update' }, kind) then
      return
    end
    if not ev.data.active then
      vim.cmd.packadd(name)
    end
    vim.api.nvim_exec_autocmds('User', {pattern = name})
end)
VimRc.on_packchanged = function(plugin_name, callback)
  misc.safely('event:User:' .. plugin_name, callback)
end
-- VimRc.on_packchanged('nvim-treesitter', function()
--   vim.cmd 'TSUpdate'
-- end)

local blink_plug = vim.pack.get({ 'blink.cmp' })[1]
if blink_plug then
  -- VimRc.on_packchanged('blink.cmp', function()
  --   VimRc.info('Running blink build after plugin install', { plugin = blink_plug.path })
  --   vim.system({ 'mise', 'exec', '--', 'cargo', 'build', '--release' }, { cwd = blink_plug.path })
  -- end)

  local blink_dylib = vim.fs.joinpath(blink_plug.path, 'target', 'release')
  if blink_plug.path and vim.uv.fs_stat(blink_dylib) ~= nil then
    local lib_path = vim.env['LD_LIBRARY_PATH']
    lib_path = lib_path and lib_path .. ':' or ''
    VimRc.debug('Blink lib already installed at ' .. blink_dylib .. '. Adding to LD_LIBRARY_PATH=' .. lib_path)
    vim.fn.setenv('LD_LIBRARY_PATH', lib_path .. blink_dylib)
  end
end
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
