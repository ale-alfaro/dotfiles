local overseer = require 'overseer'

overseer.setup {
  output = {
    -- Use a terminal buffer to display output. If false, a normal buffer is used
    use_terminal = true,
    -- If true, don't clear the buffer when a task restarts
    preserve_output = false,
  },
  dap = false,
  -- Configure the task list
  task_list = {
    -- Default direction. Can be "left", "right", or "bottom"
    direction = 'bottom',
    max_height = { 40, 0.3 },
    keymaps = {
      ['?'] = 'keymap.show_help',
      ['g?'] = 'keymap.show_help',
      -- Mappings can be a string
      ['<CR>'] = 'keymap.run_action',
      -- You can pass additional opts to vim.keymap.set by using
      -- a table with the mapping as the first element.
      gd = {
        function()
          for _, task in ipairs(require('overseer').list_tasks()) do
            task:dispose()
          end
        end,
        mode = 'n',
        nowait = true,
        desc = 'Dispose all tasks',
      },
      ['<C-e>'] = { 'keymap.run_action', opts = { action = 'edit' }, desc = 'Edit task' },
      ['o'] = 'keymap.open',
      ['<C-v>'] = { 'keymap.open', opts = { dir = 'vsplit' }, desc = 'Open task output in vsplit' },
      ['<C-s>'] = { 'keymap.open', opts = { dir = 'split' }, desc = 'Open task output in split' },
      ['<C-f>'] = { 'keymap.open', opts = { dir = 'float' }, desc = 'Open task output in float' },
      ['<C-q>'] = {
        'keymap.run_action',
        opts = { action = 'open output in quickfix' },
        desc = 'Open task output in the quickfix',
      },
      ['p'] = 'keymap.toggle_preview',
      ['{'] = 'keymap.prev_task',
      ['}'] = 'keymap.next_task',
      ['<C-k>'] = 'keymap.scroll_output_up',
      ['<C-j>'] = 'keymap.scroll_output_down',
      ['q'] = { '<CMD>close<CR>', desc = 'Close task list' },
    },
  },
  -- Configure the floating window used for task templates that require input
  -- and the floating window used for editing tasks
  form = {
    zindex = 40,
    -- Dimensions can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
    -- min_X and max_X can be a single value or a list of mixed integer/float types.
    min_width = 40,
    max_width = 0.9,
    min_height = 10,
    max_height = 0.9,
    border = nil,
    -- Set any window options here (e.g. winhighlight)
    win_opts = {},
  },
}

vim.cmd.cnoreabbrev 'OS OverseerShell'
local west_errorformat = {
  '%-G%f:%l:%c: note:%.%#',
  '%-G%f:%l: note:%.%#',
  '%-G%f:%l: %trror: (Each undeclared identifier is reported only once',
  '%-G%f:%l: %trror: for each function it appears in.)',
  'devicetree %trror: %f:%l (column %c): %m',
  'devicetree %trror: %f:%l: %m',
  '%f:%l:%c: %trror: %m',
  '%f:%l:%c: %tarning: %m',
  '%f:%l: %trror: %m',
  '%f:%l: %tarning: %m',
  'CMake %tarning%.%# at %f:%l %m',
  'CMake %trror at %f:%l %m',
  'CMake %trror: %m',
  'CMake %tarning: %m',
  'FATAL ERROR: %m',
  '%tarning: %m',
  '%f:%l:%c: %m',
  '%f:%l: %m',
  '%-G%.%#',
}
local overseer_make = function(params)
  -- Insert args at the '$*' in the makeprg
  local cmd
  if params then
    local make, num_subs = vim.o.makeprg:gsub('%$%*', params.args)
    if num_subs == 0 then
      cmd = make .. ' ' .. params.args
    else
      cmd = make
    end
  else
    cmd = vim.o.makeprg
  end
  local task = require('overseer').new_task {
    name = 'make build',
    cmd = vim.fn.expandcmd(cmd),
    components = {
      {
        'on_output_quickfix',
        open = not params.bang,
        open_height = 8,
        errorformat = west_errorformat,
      },
      'default',
    },
  }
  task:start()
end
vim.api.nvim_create_user_command('Make', overseer_make, { desc = 'Make', nargs = '*', bang = true })
vim.keymap.set('n', '<localleader>b', overseer_make, { desc = 'Build' })
---@param selected string[]
---@param opts fzf-lua.config.Zoxide|{}
local west_build_select_app = function(selected, opts)
  if not selected[1] then
    return
  end
  local app = selected[1]
  if opts.cwd then
    app = vim.fs.joinpath(opts.cwd, app)
  end
  VimRc.info(("app set to '%s'"):format(app))
  if vim.uv.fs_stat(app) then
    local ov = require 'overseer'
    local cmd = 'west build_sample ' .. vim.fn.shellescape(app)
    local task = ov.new_task {
      cmd = cmd,
      name = 'west build',
      components = {
        {
          'on_output_quickfix',
          set_diagnostics = true,
          open = true,
          open_on_exit = 'failure',
          errorformat = vim.fn.join(west_errorformat, ','),
        },
        'default',
      },
    }
    task:start()
  else
    VimRc.warn(("Unable to find path to '%s', directory is not accessible"):format(app))
  end
end
vim.api.nvim_create_user_command('Build', function()
  -- local cwd = vim.fs.root(0, { 'mise.toml', 'mise.local.toml', '.git' })
  require('fzf-lua').fzf_exec([[fd -t file --extension yaml '^(sample|testcase)' --strip-cwd-prefix]], {
    -- can also be set to "mini" for "mini.icons"
    fn_transform = function(x)
      return vim.fs.dirname(x:match '[^\t]+$' or x)
    end,
    actions = {
      ['default'] = west_build_select_app,
    },
  })
end, { desc = 'Build', nargs = '*' })
-- Always show the output from the most recent Neotest task in this window.
-- Close it automatically when all test tasks are disposed.

overseer.add_template_hook({ name = '^.*build$' }, function(task_defn, util)
  util.add_component(task_defn, {
    {
      on_result = function(self, task, result)
        local diagnostics = result.diagnostics or {}
        local is_empty = vim.tbl_isempty(diagnostics)
        local trouble = require 'trouble'

        if is_empty then
          trouble.close { mode = 'diagnostics' }
        else
          trouble.open { mode = 'diagnostics' }
        end
      end,
    },
  })
end)

vim.api.nvim_create_user_command('OverseerRestartLast', function()
  local ovr = require 'overseer'
  local task_list = require 'overseer.task_list'
  local tasks = ovr.list_tasks {
    status = {
      overseer.STATUS.SUCCESS,
      overseer.STATUS.FAILURE,
      overseer.STATUS.CANCELED,
    },
    sort = task_list.sort_finished_recently,
  }
  if vim.tbl_isempty(tasks) then
    VimRc.warn 'No tasks found'
  else
    local most_recent = tasks[1]
    ovr.run_action(most_recent, 'restart')
    local opts = { focus = true, focus_task_id = most_recent.id } ---@type overseer.WindowOpts
    ovr.open(opts)
  end
end, {})
