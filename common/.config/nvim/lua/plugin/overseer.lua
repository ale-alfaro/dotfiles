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
    direction = 'right',
    keymaps = {
      ['?'] = 'keymap.show_help',
      ['g?'] = 'keymap.show_help',
      -- Mappings can be a string
      ['<CR>'] = "<CMD>lua require('overseer').run_action()<CR>",
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
}

vim.cmd.cnoreabbrev 'OS OverseerShell'
vim.api.nvim_create_user_command('Make', function(params)
  -- Insert args at the '$*' in the makeprg
  local cmd, num_subs = vim.o.makeprg:gsub('%$%*', params.args)
  if num_subs == 0 then
    cmd = cmd .. ' ' .. params.args
  end
  local task = require('overseer').new_task {
    cmd = vim.fn.expandcmd(cmd),
    components = {
      { 'on_output_quickfix', open = not params.bang, open_height = 20 },
      'default',
    },
  }
  task:start()
end, {
  desc = 'Run your makeprg as an Overseer task',
  nargs = '*',
  bang = true,
})

-- Always show the output from the most recent Neotest task in this window.
-- Close it automatically when all test tasks are disposed.

-- overseer.add_template_hook({ name = '^mise.*build$' }, function(task_defn, util)
--   util.add_component(task_defn, { 'on_output_quickfix', open = true })
-- end)

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
  end
end, {})
KEYS.define {
  {
    lhs = '<leader>or',
    rhs = '<cmd>OverseerRun<cr>',
    opts = { desc = 'OverseerRun' },
  },
  {
    lhs = '<leader>or',
    rhs = function()
      local ovr = require 'overseer'
      ovr.run_task({ name = 'mise' }, function(task)
        if task then
          ovr.run_action(task, 'open vsplit')
        end
      end)
    end,
    opts = { desc = 'OverseerRun (Custom' },
  },
  { lhs = '<leader>ot', rhs = '<cmd>OverseerToggle bottom<cr>', opts = { desc = 'OverseerToggle' } },
  { lhs = '<leader>oq', rhs = '<cmd>OverseerRestartLast<cr>', opts = { desc = 'Action recent task' } },

  {
    lhs = '<leader>oo',
    rhs = function()
      local win_id = vim.api.nvim_open_win(0, false, {
        split = 'left',
        win = 0,
      })
      require('overseer').create_task_output_view(win_id, {
        ---@param self overseer.TaskView
        ---@param tasks  overseer.Task[]
        ---@param task_under_cursor  overseer.Task?
        select = function(self, tasks, task_under_cursor)
          for _, task in ipairs(tasks) do
            if string.match(task.name, '^mise') then
              return task
            end
          end
          self:dispose()
        end,
      })
    end,
    opts = { desc = 'OverseerOpen' },
  },
}
