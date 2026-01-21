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

local ok, grug = pcall(require, 'plugin.grug')
if ok then
  VimRc.pack_add(grug)
  -- grug-far main buffers will have `filetype=grug-far`.
  -- grug-far history buffers will have `filetype=grug-far-history`
  -- grug-far help buffers will have `filetype=grug-far-help`
  _G.new_autocmd('FileType', function()
    vim.keymap.set('n', '<C-enter>', function()
      local inst = require('grug-far').get_instance(0)
      if inst then
        inst:open_location()
        inst:close()
      end
    end, { buffer = true })
  end, 'grug-far*', 'Keep one instance of grug')
end

local make_select_path = function(select_global, recency_weight)
  local visits = require 'mini.visits'
  local sort = visits.gen_sort.default { recency_weight = recency_weight }
  local select_opts = { sort = sort }
  return function()
    local cwd = select_global and '' or vim.fn.getcwd()
    visits.select_path(cwd, select_opts)
  end
end

local make_pick_core = function(cwd, desc)
  return function()
    local sort_latest = MiniVisits.gen_sort.default { recency_weight = 1 }
    local local_opts = { cwd = cwd, filter = 'core', sort = sort_latest }
    MiniExtra.pickers.visit_paths(local_opts, { source = { name = desc } })
  end
end
-- - `:h MiniVisits-overview` - overview of how module works
-- - `:h MiniVisits-examples` - examples of common setups
require('mini.visits').setup()
-- v is for 'Visits'. Common usage:
local prefix = '<leader>v'

local search_visit_paths = function(cwd)
  local fzf_lua = require 'fzf-lua'
  -- local has_visits, visits = pcall(require, 'mini.visits')
  -- if not has_visits then
  --   VimRc.error [[`pickers.visit_labels` requires 'mini.visits' which can not be found.]]
  -- end

  cwd = cwd or vim.fn.getcwd()
  -- NOTE: Use separate cwd to allow `cwd = ''` to not mean "current directory"
  local picker_cwd = VimRc.normalize_path(cwd == '' and vim.fn.getcwd() or VimRc.full_path(cwd))

  local filter = MiniVisits.gen_filter.default()
  -- local items = MiniVisits.list_labels(local_opts.path, local_opts.cwd, { filter = filter })

  -- Define source
  local new_filter = function(path_data)
    return filter(path_data) and type(path_data.labels) == 'table'
  end
  local all_paths = MiniVisits.list_paths(cwd, { filter = new_filter, sort = nil })
  local all_labels = vim.tbl_map(function(x)
    return VimRc.normalize_path(VimRc.short_path(x, picker_cwd))
  end, all_paths)
  local opts = {}
  opts.prompt = 'MinVisit Paths > '
  opts.actions = {
    ['default'] = function(selected)
      vim.cmd('cd ..' .. selected[1])
    end,
  }
  fzf_lua.fzf_exec(vim.tbl_filter(new_filter, all_labels), opts)
end
-- stylua: ignore
KEYS.define({
  { lhs = prefix .. 's', rhs = function() search_visit_paths() end,    opts = { desc = 'Search visits' }, },
  { lhs = prefix .. 'l', rhs = '<Cmd>lua MiniVisits.add_label("core")<CR>',    opts = { desc = 'Add to core' }, },
  { lhs = prefix .. 'L', rhs = '<Cmd>lua MiniVisits.remove_label("core")<CR>', opts = { desc = 'Remove from core' }, },
  { lhs = prefix .. 'c', rhs = make_pick_core('', 'Core visits (all)'),        opts = { desc = 'Core visits (all)' } },
  { lhs = prefix .. 'C', rhs = make_pick_core(nil, 'Core visits (cwd)'),       opts = { desc = 'Core visits (cwd)' } },
  { lhs = prefix .. 'r', rhs = make_select_path(true, 0.5),                    opts = { desc = 'Frecent visits (all)' } },
  { lhs = prefix .. 'R', rhs = make_select_path(false, 0.5),                   opts = { desc = 'Frecent visits (cwd)' } },
}, { prefix = prefix, group = 'Visits' })
---
