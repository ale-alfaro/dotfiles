---@module "snacks"

---@class SmartSplitsMultiplexer
local mux = require('smart-splits.mux').get()

local Direction = require('smart-splits.types').Direction
--
-- local dir_keys_wezterm = {
--   [Direction.left] = 'Left',
--   [Direction.right] = 'Right',
--   [Direction.down] = 'Down',
--   [Direction.up] = 'Up',
-- }

local dir_keys_wezterm_splits = {
  [Direction.left] = '--left',
  [Direction.right] = '--right',
  [Direction.up] = '--top',
  [Direction.down] = '--bottom',
}

-- mux matches the following type annotations
local wezterm_cli_path = 'wezterm'

local function wezterm_exec(cmd)
  local command = vim.deepcopy(cmd)
  table.insert(command, 1, wezterm_cli_path)
  table.insert(command, 2, 'cli')
  return vim.fn.system(command)
end

M = {}

---@class WezternWorkspace
---@field name string name of workspace
---@field cwd string
---@field title string

---@return WezternWorkspace[]|nil
local function get_workspaces()
  local output = wezterm_exec { 'list', '--format', 'json' }
  if vim.v.shell_error ~= 0 or not output or #output == 0 then
    return
  end

  local data = vim.json.decode(output) --[[@as table]]
  local workspaces = {}
  local seen = {} -- To track unique workspace names
  for _, w in ipairs(data) do
    if not seen[w.workspace] then
      local parsed_cwd = w.cwd:match '^file://[^/]+(.*)$'
      if parsed_cwd then
        table.insert(workspaces, {
          name = w.workspace,
          cwd = parsed_cwd,
          title = w.title,
        })
        seen[w.workspace] = true
      end
    end
  end
  return workspaces
end

---@class wezterm_spanw_args
---@field cwd string
---@field percentage number
---@field program string

function M.split_pane(direction, cwd, size, program_args)
  local args = { 'split-pane', dir_keys_wezterm_splits[direction], '--cwd', cwd }
  if size then
    table.insert(args, '--percent')
    table.insert(args, size)
  end
  if program_args and type(program_args) == 'table' and #program_args > 0 then
    table.insert(args, '--')
    vim.list_extend(args, program_args)
  end
  local ok, _ = pcall(wezterm_exec, args)
  return ok
end

function M.spawn_terminal()
  local bufname = vim.api.nvim_buf_get_name(0)
  local cwd
  if bufname == '' or bufname == nil then
    cwd = vim.fn.getcwd()
  else
    cwd = vim.fn.expand '%:p:h'
  end
  local ok = M.split_pane(Direction.down, cwd, 30)
  return ok
end

function M.spawn_nvim_inst(direction, file)
  local cwd = vim.fn.fnamemodify(file, ':h')
  local program_args = { 'nvim', file }
  local ok = M.split_pane(direction, cwd, nil, program_args)
  return ok
end

function M.workspace_picker()
  if not mux or not mux.is_in_session() then
    vim.notify('Not in a wezterm session', vim.log.levels.WARN)
    return
  end

  local workspaces = get_workspaces()
  if not workspaces or #workspaces == 0 then
    vim.notify('No wezterm workspaces found', vim.log.levels.INFO)
    return
  end

  local preview = Snacks.picker.preview

  Snacks.picker.pick {
    items = workspaces,
    -- prompt = 'Open workspace in a new tab or window',
    title = 'Open Wezterm Workspaces',
    preview = function(ctx)
      if not ctx.item or not ctx.item.cwd then
        return
      end
      local path = ctx.item.cwd
      if vim.fn.isdirectory(path) == 0 then
        ctx.preview:notify('Directory not found:\n' .. path, 'error')
        return true
      end

      local cmd
      if vim.fn.executable 'eza' == 1 then
        cmd = { 'eza', '--tree', '-L', '2', '--color=always', path } -- -C for color
      else
        cmd = { 'ls', '-a', '--color=always', path }
      end
      preview.cmd(cmd, ctx)
      return true
    end,
    format = function(item)
      return {
        { item.name, 'SnacksPickerFile' },
        { ' ' },
        { ('(%s)'):format(item.title), 'SnacksPickerComment' },
        { '  [Tab |  [W]in ]', 'Comment', col = 0, virt_text_pos = 'right_align' },
      }
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        local cmd = { wezterm_cli_path, 'start', '--new-tab', '--workspace=' .. item.name, '--cwd=' .. item.cwd }
        vim.fn.system(cmd)
        if vim.v.shell_error ~= 0 then
          vim.notify('Failed to open wezterm tab', vim.log.levels.ERROR)
        end
      end
    end,
    actions = {
      open_window = function(picker, item)
        picker:close()
        if item then
          local cmd = {
            wezterm_cli_path,
            'cli',
            'spawn',
            '--new-window',
            '--workspace=' .. item.name,
            '--cwd=' .. item.cwd,
          }
          vim.fn.system(cmd)
          if vim.v.shell_error ~= 0 then
            vim.notify('Failed to open wezterm window', vim.log.levels.ERROR)
          end
        end
      end,
    },
    win = {
      list = { keys = { ['W'] = { 'open_window', mode = { 'n' } } }, input = { keys = { ['W'] = { 'open_window', mode = { 'n' } } } } },
    },
  }
end

local cmds = {
  {
    'WeztermTerm',
    function()
      M.spawn_terminal()
    end,
    { desc = 'Spawn Wezterm Terminal' },
  },
  {
    'WeztermWorkspace',
    function()
      M.workspace_picker()
    end,
    { desc = 'Switch Wezterm Workspace' },
  },
}

function M.setup()
  --
  vim.tbl_map(function(cmd)
    vim.api.nvim_create_user_command(cmd[1], cmd[2], cmd[3])
  end, cmds)
end

return M
