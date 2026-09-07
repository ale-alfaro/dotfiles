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
      ['<localleader>e'] = { 'keymap.run_action', opts = { action = 'edit' }, desc = 'Edit task' },
      ['<localleader>r'] = { 'keymap.run_action', opts = { action = 'restart' }, desc = 'Restart task' },
      ['<localleader>d'] = { 'keymap.run_action', opts = { action = 'dispose' }, desc = 'Restart task' },
      ['o'] = 'keymap.open',
      ['<C-v>'] = { 'keymap.open', opts = { dir = 'vsplit' }, desc = 'Open task output in vsplit' },
      ['<C-s>'] = { 'keymap.open', opts = { dir = 'split' }, desc = 'Open task output in split' },
      ['<C-f>'] = { 'keymap.open', opts = { dir = 'float' }, desc = 'Open task output in float' },
      ['<localleader>q'] = {
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
---@param dir? string
---@return string
local function get_west_topdir(dir)
  local west = require 'custom.west'
  if west.topdir then
    return west.topdir
  end
  return west.get_topdir(dir) or vim.fn.getcwd()
end
---@param app string
---@param opts {flags:string[]?,cwd:string?}
VimRc.run_west_build = function(app, opts)
  VimRc.info(("app set to '%s'"):format(app))
  opts = opts or {}
  if vim.uv.fs_stat(app) then
    local build_cmd = vim.g.west_build_alias or 'build.app.clean'
    local build_flags = vim.g.west_build_flags or opts.flags
    local build_app = app or vim.g.west_build_app
    local cmd = string.format('west %s %s %s', build_cmd, build_flags or '', build_app)
    local task = require('overseer').new_task {
      cmd = cmd,
      name = 'west build',
      cwd = opts.cwd or get_west_topdir(),
      components = {
        'default',

        {
          'open_output',
          focus = true,
          on_start = 'always',
        },
        {
          'on_output_quickfix',
          set_diagnostics = true,
          open_on_exit = 'never',
          errorformat = vim.fn.join(west_errorformat, ','),
        },
        {
          'on_result_diagnostics_trouble',
          close = true,
        },
      },
    }
    task:start()
  else
    VimRc.warn(("Unable to find path to '%s', directory is not accessible"):format(app))
  end
end


vim.keymap.set('n', '<leader>xl', function()
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
end, {desc = "Overseer run last"})

---@param opts overseer.SearchParams
---@return nil|string
local function get_mise_file(opts)
  local function is_mise_file(name)
    name = name:lower()
    -- mise.toml, mise.<env>.toml, or .local.toml, or dot-prefixed
    return name:match '^%.?mise%.toml$' ~= nil
      or name:match '^%.?mise%.local%.toml$' ~= nil
      or name:match '^%.?mise%.%w+%.toml$' ~= nil
      or name:match '^%.?mise%.%w+%.local%.toml$' ~= nil
  end

  local function is_mise_dir(name)
    name = name:lower()
    -- (.)mise, (.)mise-tasks, or .config dir
    return name:match '^%.?mise$' ~= nil or name:match '^%.?mise%-tasks$' ~= nil or name == '.config'
  end

  return vim.fs.find(is_mise_file, { type = 'file', upward = true, path = opts.dir[1] })[1]
    or vim.fs.find(is_mise_dir, { type = 'directory', upward = true, path = opts.dir[1] })[1]
end

---@type overseer.TemplateProvider
overseer.register_template {
  name = 'mise local',
  cache_key = function(opts)
    return get_mise_file(opts)
  end,
  generator = function(opts, cb)
    if vim.fn.executable 'mise' == 0 then
      return 'Command "mise" not found'
    end
    local mise_file = get_mise_file(opts)
    if not mise_file then
      return 'No mise file or directory found'
    end

    local ret = {}
    local cwd = vim.fs.dirname(mise_file)
    overseer.builtin.system(
      { 'mise', 'tasks', '--json', '--local' },
      { cwd = cwd, text = true },
      vim.schedule_wrap(function(out)
        local ok, data = pcall(vim.json.decode, out.stdout, { luanil = { object = true } })
        if not ok then
          cb(data)
          return
        end
        for _, value in pairs(data) do
          if not value.usage or value.usage == '' then
            table.insert(ret, {
              name = string.format('mise %s', value.name),
              desc = value.description ~= '' and value.description or nil,
              builder = function()
                return {
                  cmd = { 'mise', 'run', value.name },
                  cwd = cwd,
                }
              end,
            })
          end
        end
        cb(ret)
      end)
    )
  end,
}

vim.keymap.set('n', '<leader>xb',function()
  -- local cwd = vim.fs.root(0, { 'mise.toml', 'mise.local.toml', '.git' })
  -- local cwd = get_west_topdir()
  require('fzf-lua').fzf_exec([[fd -t file --extension yaml '^(sample|testcase)' --strip-cwd-prefix]], {
    -- cwd = cwd,
    -- can also be set to "mini" for "mini.icons"
    fn_transform = function(x)
      return vim.fs.dirname(x:match '[^\t]+$' or x)
    end,
    actions = {
      ['default'] = function(selected, opts)
        if not selected[1] then
          return
        end
        local app = selected[1]
        VimRc.run_west_build(app, opts)
      end,
      ['alt-x'] = {
        desc = 'Exec with flags',
        fn = function(selected, opts)
          vim.ui.input({ prompt = 'Enter flags: ', default = '-p' }, function(ans)
            local flags = vim.fn.shellescape(ans)
            VimRc.run_west_build(selected, vim.tbl_extend('force', opts, { flags = vim.fn.split(flags, ' ', false) }))
          end)
        end,
      },
    },
  })
end, { desc = 'Build' })
vim.keymap.set('n', '<leader>xr', function()
  overseer.new_task({ name = 'mise local' }, function(task)
    if task then
      overseer.run_action(task)
    end
  end)
end, {desc = 'OverseerRun'})

vim.keymap.set('n', '<leader>xt','<cmd>OverseerToggle<cr>', { desc = 'OverseerToggle' })
VimRc.keymap_clues[#VimRc.keymap_clues + 1] = { mode = 'n', keys = '<Leader>x', desc = '+Exec' }
