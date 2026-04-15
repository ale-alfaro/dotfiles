local helpers = dofile('tests/helpers.lua')

local child = helpers.new_child_neovim()
local eq = helpers.expect.equality
local new_set = MiniTest.new_set

-- Helpers
local ensure_feature_flags = function()
  child.lua([[
    if not _G.FeatureFlags then
      _G.FeatureFlags = { entries = {} }
      FeatureFlags.__index = FeatureFlags
      function FeatureFlags:add(f)
        if type(f) == 'string' then f = { name = f, gl_enabled = false } end
        self.entries[f.name] = f; return f
      end
      function FeatureFlags:get(n) return self.entries[n] or self:add({ name = n, gl_enabled = false }) end
      function FeatureFlags:set(n, e) self:get(n).gl_enabled = e or false end
    end
  ]])
end

local load_format = function(config)
  ensure_feature_flags()
  child.lua([[require('custom.format').setup(...)]], { config })
end

local child_resolve_args = function(args, filename)
  return child.lua_get([[require('custom.format')._.resolve_args(...)]], { args, filename })
end

local child_parse_output = function(text, eol)
  return child.lua_get([[require('custom.format')._.parse_output_lines(...)]], { text, eol })
end

local child_apply_format = function(original, new_lines)
  return child.lua_get(
    [[require('custom.format')._.apply_format(vim.api.nvim_get_current_buf(), ...)]],
    { original, new_lines }
  )
end

-- Test set --------------------------------------------------------------------

local T = new_set({
  hooks = {
    pre_case = child.setup,
    post_once = child.stop,
  },
})

-- resolve_args ----------------------------------------------------------------

T['resolve_args'] = new_set()

T['resolve_args']['replaces $FILENAME with actual filename'] = function()
  local result = child_resolve_args({ '--stdin-filepath', '$FILENAME', '-' }, '/tmp/test.lua')
  eq(result, { '--stdin-filepath', '/tmp/test.lua', '-' })
end

T['resolve_args']['passes through non-placeholder args unchanged'] = function()
  local result = child_resolve_args({ '-i', '2', '-ci' }, '/tmp/test.sh')
  eq(result, { '-i', '2', '-ci' })
end

T['resolve_args']['handles empty args'] = function()
  eq(child_resolve_args({}, '/tmp/test.lua'), {})
end

-- parse_output_lines ----------------------------------------------------------

T['parse_output_lines'] = new_set()

T['parse_output_lines']['splits text into lines'] = function()
  eq(child_parse_output('line1\nline2\nline3', false), { 'line1', 'line2', 'line3' })
end

T['parse_output_lines']['strips trailing empty line when eol=true'] = function()
  eq(child_parse_output('line1\nline2\n', true), { 'line1', 'line2' })
end

T['parse_output_lines']['preserves trailing content when eol=false'] = function()
  eq(child_parse_output('line1\nline2\n', false), { 'line1', 'line2', '' })
end

T['parse_output_lines']['returns {""} for empty output'] = function()
  eq(child_parse_output('', false), { '' })
end

-- apply_format ----------------------------------------------------------------

T['apply_format'] = new_set()

T['apply_format']['applies a simple change'] = function()
  child.set_lines({ 'hello', 'world' })
  local changed = child_apply_format({ 'hello', 'world' }, { 'hello', 'earth' })
  eq(changed, true)
  eq(child.get_lines(), { 'hello', 'earth' })
end

T['apply_format']['returns false when no changes'] = function()
  child.set_lines({ 'same', 'content' })
  local changed = child_apply_format({ 'same', 'content' }, { 'same', 'content' })
  eq(changed, false)
end

T['apply_format']['aborts on empty output for non-empty input'] = function()
  child.set_lines({ 'has content' })
  local changed = child_apply_format({ 'has content' }, { '' })
  eq(changed, false)
  eq(child.get_lines(), { 'has content' })
end

T['apply_format']['handles insertion of new lines'] = function()
  child.set_lines({ 'line1', 'line3' })
  local changed = child_apply_format({ 'line1', 'line3' }, { 'line1', 'line2', 'line3' })
  eq(changed, true)
  eq(child.get_lines(), { 'line1', 'line2', 'line3' })
end

T['apply_format']['handles deletion of lines'] = function()
  child.set_lines({ 'line1', 'line2', 'line3' })
  local changed = child_apply_format({ 'line1', 'line2', 'line3' }, { 'line1', 'line3' })
  eq(changed, true)
  eq(child.get_lines(), { 'line1', 'line3' })
end

T['apply_format']['handles indentation changes'] = function()
  child.set_lines({ 'function foo()', '  return 1', 'end' })
  local changed = child_apply_format(
    { 'function foo()', '  return 1', 'end' },
    { 'function foo()', '    return 1', 'end' }
  )
  eq(changed, true)
  eq(child.get_lines(), { 'function foo()', '    return 1', 'end' })
end

-- setup -----------------------------------------------------------------------

T['setup'] = new_set()

T['setup']['creates BufWritePre autocmd in sync mode'] = function()
  load_format()
  local n = child.lua_get(
    [[#vim.api.nvim_get_autocmds({ group = 'CustomFormat', event = 'BufWritePre' })]]
  )
  eq(n, 1)
end

T['setup']['creates BufWritePost autocmd in async mode'] = function()
  load_format({ async = true })
  local n = child.lua_get(
    [[#vim.api.nvim_get_autocmds({ group = 'CustomFormat', event = 'BufWritePost' })]]
  )
  eq(n, 1)
end

T['setup']['registers Format feature flag'] = function()
  load_format()
  local enabled = child.lua_get([[FeatureFlags:get('Format').gl_enabled]])
  eq(enabled, true)
end

-- formatters_by_ft ------------------------------------------------------------

T['formatters_by_ft'] = new_set()

T['formatters_by_ft']['has expected filetypes configured'] = function()
  load_format()
  child.lua([[
    _G._test_fts = {}
    for ft in pairs(require('custom.format').formatters_by_ft) do _G._test_fts[ft] = true end
  ]])
  local ft_set = child.lua_get('_G._test_fts')
  eq(ft_set['lua'], true)
  eq(ft_set['python'], true)
  eq(ft_set['sh'], true)
  eq(ft_set['markdown'], true)
end

T['formatters_by_ft']['python chains ruff_fix then ruff_format'] = function()
  load_format()
  child.lua([[
    _G._test_py = {}
    for _, f in ipairs(require('custom.format').formatters_by_ft.python) do
      _G._test_py[#_G._test_py + 1] = { cmd = f.cmd, first_arg = f.args[1] }
    end
  ]])
  local py = child.lua_get('_G._test_py')
  eq(#py, 2)
  eq(py[1].cmd, 'ruff')
  eq(py[1].first_arg, 'check')
  eq(py[2].cmd, 'ruff')
  eq(py[2].first_arg, 'format')
end

-- Integration: sync format on save with real formatter ------------------------

T['sync format on save'] = new_set({
  hooks = {
    pre_case = function()
      child.setup()
      load_format()
    end,
  },
})

T['sync format on save']['formats lua file with stylua'] = function()
  if child.fn.executable('stylua') == 0 then MiniTest.skip('stylua not installed') end

  child.lua([[
    _G._test_tmp = vim.fn.tempname() .. '.lua'
    vim.fn.writefile({ 'local x={1,2,3}' }, _G._test_tmp)
  ]])
  local tmp = child.lua_get('_G._test_tmp')
  child.cmd('edit ' .. tmp)
  child.cmd('write')

  local lines = child.get_lines()
  local content = table.concat(lines, '\n')
  helpers.expect.match(content, 'local x = ')
  child.fn.delete(tmp)
end

T['sync format on save']['formats shell file with shfmt'] = function()
  if child.fn.executable('shfmt') == 0 then MiniTest.skip('shfmt not installed') end

  child.lua([[
    _G._test_tmp = vim.fn.tempname() .. '.sh'
    vim.fn.writefile({ '#!/bin/bash', 'if true;then', 'echo hello', 'fi' }, _G._test_tmp)
  ]])
  local tmp = child.lua_get('_G._test_tmp')
  child.cmd('edit ' .. tmp)
  child.cmd('write')

  local lines = child.get_lines()
  local content = table.concat(lines, '\n')
  helpers.expect.match(content, '  echo hello')
  child.fn.delete(tmp)
end

T['sync format on save']['skips formatting when feature flag disabled'] = function()
  child.lua([[FeatureFlags:set('Format', false)]])

  child.lua([[
    _G._test_tmp = vim.fn.tempname() .. '.lua'
    vim.fn.writefile({ 'local x={1,2,3}' }, _G._test_tmp)
  ]])
  local tmp = child.lua_get('_G._test_tmp')
  child.cmd('edit ' .. tmp)
  child.cmd('write')

  eq(child.get_lines(), { 'local x={1,2,3}' })
  child.fn.delete(tmp)
end

T['sync format on save']['skips non-file buffers'] = function()
  child.lua([[
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].filetype = 'lua'
  ]])
  child.set_lines({ 'local x={1,2,3}' })
  MiniTest.expect.no_error(function()
    child.lua([[vim.api.nvim_exec_autocmds('BufWritePre', { buffer = 0 })]])
  end)
end

return T
