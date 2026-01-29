vim.pack.add(_G.plug_spec { 'ibhagwan/fzf-lua' })

local icons = VimRc.icons
---@diagnostic disable-next-line: duplicate-set-field
vim.ui.select = function(items, opts, on_choice)
  local ui_select = require 'fzf-lua.providers.ui_select'

  -- Register the fzf-lua picker the first time we call select.
  if not ui_select.is_registered() then
    ui_select.register(function(ui_opts)
      if ui_opts.kind == 'luasnip' then
        ui_opts.prompt = 'Snippet choice: '
        ui_opts.winopts = {
          relative = 'cursor',
          height = 0.35,
          width = 0.3,
        }
      elseif ui_opts.kind == 'color_presentation' then
        ui_opts.winopts = {
          relative = 'cursor',
          height = 0.35,
          width = 0.3,
        }
      else
        ui_opts.winopts = { height = 0.5, width = 0.4 }
      end

      -- Use the kind (if available) to set the previewer's title.
      if ui_opts.kind then
        ui_opts.winopts.title = string.format(' %s ', ui_opts.kind)
      end

      return ui_opts
    end)
  end

  -- Don't show the picker if there's nothing to pick.
  if #items > 0 then
    return vim.ui.select(items, opts, on_choice)
  end
end

require 'plugin.fzf-lua'
-- require 'plugin.mini-pick'

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
KEYS.define({
  { lhs = prefix .. 's', rhs = function() search_visit_paths(nil) end,    opts = { desc = 'Search visits' }, },
  { lhs = prefix .. 'S', rhs = function() search_visit_paths(true) end,    opts = { desc = 'Search visits' }, },
  { lhs = prefix .. 'l', rhs = '<Cmd>lua MiniVisits.add_label("core")<CR>',    opts = { desc = 'Add to core' }, },
  { lhs = prefix .. 'L', rhs = '<Cmd>lua MiniVisits.remove_label("core")<CR>', opts = { desc = 'Remove from core' }, },
  { lhs = prefix .. 'c', rhs = function() search_visit_paths(nil, 'core') end,        opts = { desc = 'Core visits (all)' } },
  { lhs = prefix .. 'C', rhs = function() search_visit_paths(true, 'core')end,       opts = { desc = 'Core visits (cwd)' } },
}, { prefix = prefix, group = 'Visits' })
---
---
---
local find_justfiles_cmd = "fd '[Jj]ustfile|\\..*just' -tf --strip-cwd-prefix"
VimRc.fzf_just = function(opts)
  local fzf_lua = require 'fzf-lua'
  opts = opts or {}
  opts.prompt = 'Just Recipes> '
  opts.fn_transform = function(justfile)
    -- fzf_jobstart(get_justfile_recipes_cmd .. justfile, {})
    -- return fzf_lua.utils.ansi_codes.magenta(x)
    return FzfLua.make_entry.file(justfile, { file_icons = true, color_icons = true })
  end
  opts.actions = {
    ['default'] = function(selected)
      VimRc.info(selected)
      -- local get_justfile_recipes_cmd = { 'just', '-f ', selected[1], '--summary', '--unsorted' }
      -- local recipes = VimRc.exec.run_cmd(et_justfile_recipes_cmd)
      -- VimRc.info(selected[1] .. ' \n Recipes: ' .. recipes)
    end,
  }
  fzf_lua.fzf_exec(find_justfiles_cmd, opts)
end

vim.cmd [[command! -nargs=* Just lua _G.VimRc.fzf_just()]]
