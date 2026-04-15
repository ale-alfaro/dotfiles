local Helpers = {}

Helpers.expect = vim.deepcopy(MiniTest.expect)

Helpers.expect.match = MiniTest.new_expectation(
  'string matching',
  function(str, pattern) return str:find(pattern) ~= nil end,
  function(str, pattern) return string.format('Pattern: %s\nObserved string: %s', vim.inspect(pattern), str) end
)

Helpers.expect.no_match = MiniTest.new_expectation(
  'no string matching',
  function(str, pattern) return str:find(pattern) == nil end,
  function(str, pattern) return string.format('Pattern: %s\nObserved string: %s', vim.inspect(pattern), str) end
)

Helpers.new_child_neovim = function()
  local child = MiniTest.new_child_neovim()

  local prevent_hanging = function(method)
    if not child.is_blocked() then return end
    error(string.format('Can not use `child.%s` because child process is blocked.', method))
  end

  child.setup = function()
    child.restart({ '-u', 'tests/minimal_init.lua', '--noplugin' })
    child.bo.readonly = false
  end

  child.set_lines = function(arr, start, finish)
    prevent_hanging('set_lines')
    if type(arr) == 'string' then arr = vim.split(arr, '\n') end
    child.api.nvim_buf_set_lines(0, start or 0, finish or -1, false, arr)
  end

  child.get_lines = function(start, finish)
    prevent_hanging('get_lines')
    return child.api.nvim_buf_get_lines(0, start or 0, finish or -1, false)
  end

  child.set_cursor = function(line, column)
    prevent_hanging('set_cursor')
    child.api.nvim_win_set_cursor(0, { line, column })
  end

  child.get_cursor = function()
    prevent_hanging('get_cursor')
    return child.api.nvim_win_get_cursor(0)
  end

  child.poke_eventloop = function() child.api.nvim_eval('1') end

  return child
end

Helpers.sleep = function(ms, child)
  vim.loop.sleep(math.max(ms, 1))
  if child ~= nil then child.poke_eventloop() end
end

return Helpers
