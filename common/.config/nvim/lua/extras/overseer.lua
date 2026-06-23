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
vim.api.nvim_create_user_command('Build', function(evt)
  local args = vim.fn.join(evt.fargs or {}, ' ')
  -- Insert args at the '$*' in the makeprg
  local cmd = (args ~= '') and string.format('mise build %s', args) or 'mise build'
  local task = require('overseer').new_task {
    cmd = cmd,
    components = {
      { 'on_result_diagnostics_trouble', open = true, open_height = 20 },
      'default',
    },
  }
  task:start()
end, {
  desc = 'Run Mise Build Overseer task',
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
