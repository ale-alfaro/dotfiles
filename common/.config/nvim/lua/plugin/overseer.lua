local overseer = require 'overseer'

overseer.setup {
  output = {
    -- Use a terminal buffer to display output. If false, a normal buffer is used
    use_terminal = true,
    -- If true, don't clear the buffer when a task restarts
    preserve_output = false,
  },
  dap = false,
  form = {
    win_opts = {
      winblend = 0,
    },
  },
  confirm = {
    win_opts = {
      winblend = 0,
    },
  },
  -- Configure the task list
  task_list = {
    -- Default direction. Can be "left", "right", or "bottom"
    direction = 'right',
    -- -- Width dimensions can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
    -- -- min_width and max_width can be a single value or a list of mixed integer/float types.
    -- -- max_width = {100, 0.2} means "the lesser of 100 columns or 20% of total"
    -- max_width = { 100, 0.2 },
    -- -- min_width = {40, 0.1} means "the greater of 40 columns or 10% of total"
    -- min_width = { 40, 0.1 },
    -- max_height = { 20, 0.2 },
    -- min_height = 8,
    -- -- String that separates tasks
    -- separator = '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    -- -- Indentation for child tasks
    -- child_indent = { '┃ ', '┣━', '┗━' },
    -- -- Function that renders tasks. See lua/overseer/render.lua for built-in options
    -- -- and for useful functions if you want to build your own.
    -- render = function(task)
    --   return require('overseer.render').format_standard(task)
    -- end,
    -- -- The sort function for tasks
    -- sort = function(a, b)
    --   return require('overseer.task_list').default_sort(a, b)
    -- end,
    -- Set keymap to false to remove default behavior
    -- You can add custom keymaps here as well (anything vim.keymap.set accepts)
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
      ['g.'] = 'keymap.toggle_show_wrapped',
      ['q'] = { '<CMD>close<CR>', desc = 'Close task list' },
    },
  },
  task_win = {
    -- How much space to leave around the floating window
    padding = 5,
    border = 'solid',
    win_opts = {
      winblend = 0,
    },
    -- Set any window options here (e.g. winhighlight)
    -- win_opts = {},
  },
  component_aliases = {
    -- Most tasks are initialized with the default components
    default = {
      'on_exit_set_status',
      'on_complete_notify',
      { 'on_complete_dispose', require_view = { 'SUCCESS', 'FAILURE' } },
    },
    -- Tasks from tasks.json use these components
    default_vscode = {
      'default',
      'on_result_diagnostics',
    },
    -- Tasks created from experimental_wrap_builtins
    default_builtin = {
      'on_exit_set_status',
      'on_complete_dispose',
      { 'unique', soft = true },
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

overseer.add_template_hook({ name = '^mise.*build$' }, function(task_defn, util)
  util.add_component(task_defn, { 'on_output_quickfix', open = true })
end)

---@param opts overseer.SearchParams
---@return nil|string
-- local function get_mise_file(opts)
--   local function is_mise_file(name)
--     name = name:lower()
--     -- mise.toml, mise.<env>.toml, or .local.toml, or dot-prefixed
--     return name:match '^%.?mise%.toml$' ~= nil
--       or name:match '^%.?mise%.local%.toml$' ~= nil
--       or name:match '^%.?mise%.%w+%.toml$' ~= nil
--       or name:match '^%.?mise%.%w+%.local%.toml$' ~= nil
--   end
--
--   local function is_mise_dir(name)
--     name = name:lower()
--     -- (.)mise, (.)mise-tasks, or .config dir
--     return name:match '^%.?mise$' ~= nil or name:match '^%.?mise%-tasks$' ~= nil or name == '.config'
--   end
--
--   return vim.fs.find(is_mise_file, { type = 'file', upward = true, path = opts.dir[1] })[1]
--     or vim.fs.find(is_mise_dir, { type = 'directory', upward = true, path = opts.dir[1] })[1]
-- end

---@type overseer.TemplateFileProvider
-- overseer.register_template {
--   name = 'mise',
--   -- params = function()
--   --   local stdout = vim.system({ 'git', 'branch', '--format=%(refname:short)' }):wait().stdout
--   --   local branches = vim.split(stdout, '\n', { trimempty = true })
--   --   return {
--   --     branch = {
--   --       desc = 'Branch to checkout',
--   --       type = 'enum',
--   --       choices = branches,
--   --     },
--   --   }
--   -- end,
--   cache_key = function(opts)
--     return get_mise_file(opts)
--   end,
--   generator = function(opts, cb)
--     if vim.fn.executable 'mise' == 0 then
--       return 'Command "mise" not found'
--     end
--     local mise_file = get_mise_file(opts)
--     if not mise_file then
--       return 'No mise file or directory found'
--     end
--
--     local ret = {}
--     local cwd = vim.fs.dirname(mise_file)
--     overseer.builtin.system(
--       { 'mise', 'tasks', '--json' },
--       { cwd = cwd, text = true },
--       vim.schedule_wrap(function(out)
--         local ok, data = pcall(vim.json.decode, out.stdout, { luanil = { object = true } })
--         if not ok then
--           cb(data)
--           return
--         end
--         for _, value in pairs(data) do
--           if value.name:match '.*build$' then
--             local new_makeprg = string.format('mise run %s', value.name)
--             VimRc.info('setting makeprg to ' .. new_makeprg)
--             vim.o.makeprg = new_makeprg
--           end
--           table.insert(ret, {
--             name = string.format('mise %s', value.name),
--             desc = value.description ~= '' and value.description or nil,
--             builder = function()
--               return {
--                 cmd = { 'mise', 'run', value.name },
--                 cwd = cwd,
--               }
--             end,
--           })
--         end
--         cb(ret)
--       end)
--     )
--   end,
-- }
-- vim.api.nvim_create_user_command('OverseerRestartLast', function()
--   local ovr = require 'overseer'
--   local task_list = require 'overseer.task_list'
--   local tasks = ovr.list_tasks {
--     status = {
--       overseer.STATUS.SUCCESS,
--       overseer.STATUS.FAILURE,
--       overseer.STATUS.CANCELED,
--     },
--     sort = task_list.sort_finished_recently,
--   }
--   if vim.tbl_isempty(tasks) then
--     VimRc.warn 'No tasks found'
--   else
--     local most_recent = tasks[1]
--     ovr.run_action(most_recent, 'restart')
--   end
-- end, {})

--- -- Run the task named "make all"
--- -- equivalent to :OverseerRun make\ all
--- overseer.run_task({name = "make all"})
--- -- Run the default "build" task
--- -- equivalent to :OverseerRun BUILD
--- overseer.run_task({tags = {overseer.TAG.BUILD}})
--- -- Run the task named "serve" with some default parameters
--- overseer.run_task({name = "serve", params = {port = 8080}})
--- -- Create a task but do not start it
--- overseer.run_task({name = "make", autostart = false}, function(task)
---   -- do something with the task
--- end)
--- -- Run a task and immediately open the floating window
--- overseer.run_task({name = "make"}function(task)
---   if task then
---     overseer.run_action(task, 'open float')
---   end
--- end,
KEYS.define {
  {
    lhs = '<leader>r',
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
  { lhs = '<leader>t', rhs = '<cmd>OverseerToggle bottom<cr>', opts = { desc = 'OverseerToggle' } },
  { lhs = '<leader>oq', rhs = '<cmd>OverseerRestartLast<cr>', opts = { desc = 'Action recent task' } },
  -- { lhs = '<leader>oi', rhs = '<cmd>OverseerInfo<cr>', opts = { desc = 'Overseer Info' } },
  -- { lhs = '<leader>ob', rhs = '<cmd>OverseerBuild<cr>', opts = { desc = 'Task builder' } },
  -- { lhs = '<leader>ot', rhs = '<cmd>OverseerTaskAction<cr>', opts = { desc = 'Task action' } },
  -- { lhs = '<leader>oc', rhs = '<cmd>OverseerClearCache<cr>', opts = { desc = 'Clear cache' } },

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
