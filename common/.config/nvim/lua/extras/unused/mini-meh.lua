-- - `:h MiniVisits-overview` - overview of how module works
-- - `:h MiniVisits-examples` - examples of common setups
require('mini.visits').setup()
-- v is for 'Visits'. Common usage:
local prefix = '<leader>v'
---@param only_cwd boolean?
---@param filter string|function|nil
local search_visit_paths = function(only_cwd, filter)
  local fzf_lua = require 'fzf-lua'
  local cwd = only_cwd and '' or nil
  local sort = MiniVisits.gen_sort.default { recency_weight = 1 }
  local all_paths = {}
  -- Define source
  if filter and vim.is_callable(filter) then
    all_paths = MiniVisits.list_paths(cwd, {
      filter = function(path_data)
        return filter(path_data) and type(path_data.labels) == 'table'
      end,
      sort = sort,
    })
  elseif type(filter) == 'string' then
    -- Path
    all_paths = MiniVisits.list_paths(cwd, { filter = filter, sort = sort })
  else
    if cwd then
      if not vim.uv.fs_stat(cwd) then
        -- CWD, no filter
        all_paths = MiniVisits.list_paths('', { sort = sort })
      else
        all_paths = MiniVisits.list_paths(cwd, { sort = sort })
      end
    else
      -- Global , no filter
      all_paths = MiniVisits.list_paths(nil, { sort = sort })
    end
  end
  local all_labels = {}
  if cwd ~= '' then
    all_labels = vim.tbl_map(function(x)
      return vim.fs.abspath(x)
    end, all_paths)
  else
    all_labels = vim.tbl_map(function(x)
      return vim.fs.normalize(x)
    end, all_paths)
  end
  local opts = {}
  opts.prompt = 'MinVisit Paths > '
  opts.actions = {
    ['default'] = function(selected)
      vim.cmd('e ..' .. selected[1])
    end,
  }
  -- vim.tbl_filter(new_filter, all_labels)
  fzf_lua.fzf_exec(all_labels, opts)
end


-- stylua: ignore
local keys = {
  {  prefix .. 's', function() search_visit_paths(nil) end,     { desc = 'Search visits' }, },
  {  prefix .. 'S', function() search_visit_paths(true) end,     { desc = 'Search visits' }, },
  {  prefix .. 'l', '<Cmd>lua MiniVisits.add_label("core")<CR>',     { desc = 'Add to core' }, },
  {  prefix .. 'L', '<Cmd>lua MiniVisits.remove_label("core")<CR>',  { desc = 'Remove from core' }, },
  {  prefix .. 'c', function() search_visit_paths(nil, 'core') end,         { desc = 'Core visits (all)' } },
  {  prefix .. 'C', function() search_visit_paths(true, 'core')end,        { desc = 'Core visits (cwd)' } },
}

for _, k in ipairs(keys) do
  table.insert(k, 1, 'n')

  vim.keymap.set(unpack(k))
end
