---called from state on setup
local ts = require 'custom.treesitter.incremental'
local buf = vim.api.nvim_get_current_buf()
local ok, parser = pcall(vim.treesitter.get_parser, buf)
if not ok or not parser then
  return
end
local language = parser:lang()
local keymaps = {
  init_selection = {
    'n',
    '<C-Space>',
    function()
      ts.init_selection(buf, language)
    end,
    'Start selecting nodes with treesitter-modules',
  },
  node_incremental = {
    'x',
    '<C-Space>',
    function()
      ts.incremental(buf, language, function(_parser, node)
        return node:parent()
      end)
    end,
    'Increment selection to named node',
  },
  scope_incremental = {
    'x',
    'grc',
    function()
      ts.incremental(buf, language, function(parser, node)
        if language ~= parser:lang() then
          -- only handle scope for root language
          return nil
        end
        local scopes = ts.scopes(buf, language, parser:trees()[1]:root())
        if #scopes == 0 then
          return nil
        end
        local result = node:parent()
        while result and not vim.tbl_contains(scopes, result) do
          result = result:parent()
        end
        assert(result ~= node, 'infinite loop')
        return result
      end)
    end,
    'Increment selection to surrounding scope',
  },
  node_decremental = {
    'x',
    '<C-S-Space>',
    function()
      -- NOTE: if a user does incremental selection, moves the cursor, enters
      -- visual mode, then triggers this function, they will still jump back to
      -- their previous selection, this behavior matches the original.
      local node = ts.nodes:pop(buf)
      if node then
        ts.select(node)
      end
    end,
    'Shrink selection to previous named node',
  },
}
for fn, key in pairs(keymaps) do
  vim.keymap.set(key[1], key[2], key[3], { buffer = buf, silent = true, desc = key[4] })
end
