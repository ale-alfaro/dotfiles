---@module core.zellij-nvim
---@brief Zellij integration module for Neovim
--- Provides functions to interact with Zellij terminal multiplexer,
--- including pane creation, navigation, and terminal management.
--- Supported Zellij commands:
---   - zellij action (new-pane, close-pane, move-focus)
---   - zellij edit

local M = {}
local Direction = require('core.zellij-nvim.types').Direction
---Validates if a string is a valid direction using pattern matching.
---@param dir string The direction string to validate
---@return boolean True if valid direction
local function is_valid_direction(dir)
  return dir:lower():match '^(left|right|up|down)$' ~= nil
end

---Converts Vim wincmd to Zellij direction.
---@param wincmd string The wincmd string (e.g., 'h', 'j')
---@return string|nil The Zellij direction string or nil if invalid
local function wincmd_to_zellij_dir(wincmd)
  return ({ h = 'left', j = 'down', k = 'up', l = 'right' })[wincmd]
end
local function zellij_exec_synchronous(cmd)
  local command = vim.deepcopy(cmd)
  table.insert(command, 1, 'zellij')
  local result = vim.fn.systemlist(command)
  return result
end

function M.current_pane_id()
  local output = zellij_exec_synchronous { 'action', 'list-clients' }
  if not output[2] then
    return nil
  end

  -- The output format is like
  -- ```
  -- CLIENT_ID ZELLIJ_PANE_ID RUNNING_COMMAND
  -- 1         terminal_0     /path/to/nvim --cmd lua print('some arguments')
  -- ```
  -- We are looking for the value `0` here in the `terminal_0` chunk.
  -- The `terminal_` prefix might be something else, for example if a plugin's UI
  -- is currently focused, but we still need to know the pane ID, so we're using the
  -- `%w+` pattern to match any word prefix. Then we capture the ID with the `%d` pattern
  -- in the capture group.
  local pane_id = string.match(output[2], '%S+%s+%w+_(%d+)')
  return pane_id
end

function M.current_pane_at_edge()
  local pane_id = M.current_pane_id()
  if pane_id == nil then
    vim.notify('could not get zeillij pane id', vim.log.levels.WARN)
    return false
  end
  zellij_exec_synchronous { 'action', 'move-focus', Direction.left }
  local new_pane_id = M.current_pane_id()

  if new_pane_id == nil then
    vim.notify('could not get zeillij pane id', vim.log.levels.WARN)
    return false
  end

  -- move back to original pane
  zellij_exec_synchronous { 'action', 'move-focus', Direction.right }

  return pane_id == new_pane_id
end

-- function M.is_in_session()
--   return M.current_pane_id() ~= nil
-- end
--
-- function M.current_pane_is_zoomed()
--   return false
-- end

---Runs a Zellij command asynchronously using jobstart.
---@param cmd table List of command arguments
---@return nil
local function zellij_exec_async(cmd)
  -- Flatten the command table to handle any nested tables
  local function flatten_cmd(c)
    local flat = {}
    for _, v in ipairs(c) do
      if type(v) == 'table' then
        for _, vv in ipairs(v) do
          table.insert(flat, vv)
        end
      else
        table.insert(flat, v)
      end
    end
    return flat
  end
  cmd = flatten_cmd(cmd)

  -- Build command string with proper quoting for arguments with spaces
  local cmd_parts = {}
  for _, part in ipairs(cmd) do
    table.insert(cmd_parts, vim.fn.shellescape(part))
  end
  local cmd_str = table.concat(cmd_parts, ' ')
  local job_id = vim.fn.jobstart(cmd_str, {
    on_exit = function(_, code)
      if code ~= 0 then
        vim.notify('Zellij command failed: ' .. cmd_str, vim.log.levels.ERROR)
      end
    end,
  })
  if job_id == 0 then
    vim.notify('Zellij executable not found in path', vim.log.levels.ERROR)
  elseif job_id == -1 then
    vim.notify('Zellij command failed to start', vim.log.levels.ERROR)
  end
end

---Executes a Zellij action with optional parameters.
---@param action string The action to perform (e.g., 'new-pane', 'move-focus')
---@param action_args? table Arguments for the action (e.g., 'left', 'down')
---@return nil
local function zellij_action(action, action_args)
  if not action then
    error 'No action specified'
  end

  if action ~= 'new-pane' and action ~= 'new-tab' and action ~= 'move-focus' and action ~= 'close-pane' then
    error('Invalid action: ' .. action)
  end

  local cmd = { 'zellij', 'action', action }
  if action_args then
    for _, arg in ipairs(action_args) do
      table.insert(cmd, arg)
    end
  end

  zellij_exec_async(cmd)
end

local function zellij_close_current_pane()
  zellij_action('close-pane', nil)
end

---Executes a Zellij edit with optional parameters.
---@param file string for the action (e.g., 'left', 'down')
---@param edit_args? table Additional arguments for the command
---@return nil
local function zellij_edit(file, edit_args)
  if not file then
    error 'No file specified'
  end

  local cmd = { 'zellij', 'edit' }
  if edit_args then
    for _, arg in ipairs(edit_args) do
      table.insert(cmd, arg)
    end
  end
  table.insert(cmd, file)
  zellij_exec_async(cmd)
end

---Creates a new Zellij pane, optionally opening a file in Neovim.
---@param direction? (string | table) The direction to create the pane (e.g., 'left')
---@param cwd? string The working directory for the pane
---@param cmd_to_run? string? The command to run in the pane. If none, start a new shell in cwd
---@return nil
function M.zellij_new_pane(direction, cwd, cmd_to_run)
  if not cwd or cwd == '' then
    cwd = vim.fn.getcwd()
  end

  local args = { '--cwd', cwd }
  if type(direction) == 'table' and direction.floating then
    table.insert(args, '--floating')
  elseif type(direction) == 'string' and is_valid_direction(direction) then
    table.insert(args, '--direction')
    table.insert(args, direction:lower())
  else
    error 'No direction or floating specified'
  end

  if cmd_to_run then
    table.insert(args, '--')
    table.insert(args, cmd_to_run)
  end

  zellij_action('new-pane', args)
end

---Moves focus to a Zellij pane in the specified direction.
---@param direction string The direction to move focus ('h', 'j', 'k', 'l' or full names)
---@return nil
function M.zellij_move_focus(direction)
  local action_args = { '--direction', direction }
  zellij_action('move-focus', action_args)
end

---Opens a file in a new Zellij pane with Neovim.
---@param file_path string The full path to the file to edit
---@param direction? string The direction to create the pane
---@param cwd? string The working directory for the pane
---@return nil
function M.zellij_edit_command(file_path, direction, cwd)
  if not direction or direction == '' then
    error 'No direction specified'
  end
  -- Assume file_path is full path, no need for --cwd
  local cursor = vim.api.nvim_win_get_cursor(0)
  local current_line = cursor[1]
  local edit_args = { '--direction', direction, '--cwd', cwd or vim.fn.fnamemodify(file_path, ':h'), '--line-number', tostring(current_line) }
  zellij_edit(file_path, edit_args)
end

---Creates a new terminal pane in Zellij with optional parameters.
---@param opts table Options for the terminal: direction, floating, cmd, cwd
---@param cmd_to_run? string? The command to run in the pane. If none, start a new shell in cwd
---@return nil
function M.zellij_new_terminal(opts, cmd_to_run)
  opts = opts or {}
  local direction
  if opts.direction then
    direction = opts.direction
  elseif opts.floating then
    direction = { floating = true }
  else
    direction = 'down' -- Default direction
  end
  local cmd = cmd_to_run or 'zsh -l'
  local cwd = opts.cwd or vim.fn.getcwd()

  M.zellij_new_pane(direction, cwd, cmd)
end

function M.zellij_smart_wincmd(direction, cwd, opts)
  local bufnr = vim.api.nvim_get_current_buf()
  -- Check buffer type. Empty means that this is a normal buffer (open file).
  if vim.bo[bufnr].buftype ~= '' then
    -- In this case we should use a wincmd so that we aren't stuck in the help txt or other native buffers
    vim.cmd.wincmd(direction)
    return
  end
  local zellij_dir = wincmd_to_zellij_dir(direction)
  if not zellij_dir then
    vim.notify('Invalid wincmd: ' .. direction, vim.log.levels.ERROR)
    return
  end
  -- Check filetype of current buffer
  local file_path = vim.api.nvim_buf_get_name(bufnr)
  if not vim.filetype.match { buf = bufnr } then
    -- No filetype: Assume file explorer buffer, open a new terminal in cwd in a new pane
    cwd = cwd or vim.fn.getcwd()
    M.zellij_new_terminal { direction = zellij_dir, cwd = cwd }
    return
  end

  -- Has filetype: File buffer, edit the file
  M.zellij_edit_command(file_path, zellij_dir, cwd)
end

---Sets up keymaps and autocommands for Zellij integration.
---@param opts? table Optional setup options
---@return nil
function M.zellij_setup(opts)
  -- Keymaps for pane navigation
  vim.keymap.set('n', '<C-h>', function()
    M.zellij_smart_wincmd('h', vim.fn.expand '%:p:h', nil)
  end, { desc = 'Move focus or create zellij left pane' })
  vim.keymap.set('n', '<C-l>', function()
    M.zellij_smart_wincmd('l', vim.fn.expand '%:p:h', nil)
  end, { desc = 'Move focus or create zellij right pane' })
  vim.keymap.set('n', '<C-j>', function()
    M.zellij_smart_wincmd('j', vim.fn.expand '%:p:h', nil)
  end, { desc = 'Move focus or create zellij lower pane' })
  vim.keymap.set('n', '<C-k>', function()
    M.zellij_smart_wincmd('k', vim.fn.expand '%:p:h', nil)
  end, { desc = 'Move focus or create zellij upper pane' })

  vim.keymap.set('n', '<C-q>', zellij_close_current_pane, { noremap = true, silent = true })

  -- Terminal keymaps
  -- vim.keymap.set('t', '<C-q>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
  -- Terminal creation keymaps
  vim.keymap.set('n', '<leader>ft', function()
    M.zellij_new_terminal { floating = true }
  end, { desc = 'Open floating terminal' })
  vim.keymap.set('n', '<leader>tt', function()
    local cwd = vim.fn.expand '%:p:h'
    M.zellij_new_terminal { direction = 'down', cwd = cwd }
  end, { desc = 'Open horizontal terminal' })
  vim.keymap.set('n', '<leader>tg', function()
    local cwd = vim.fn.expand '%:p:h'
    M.zellij_new_terminal { direction = 'right', cwd = cwd, cmd = 'lazygit' }
  end, { desc = 'Open LazyGit' })

  -- Terminal autocommands for Vim terminals
  -- vim.api.nvim_create_autocmd({ 'BufWinEnter', 'WinEnter' }, {
  --   callback = function()
  --     if vim.bo.buftype == 'terminal' then
  --       vim.cmd 'startinsert'
  --     end
  --   end,
  --   group = vim_term,
  -- })
  -- vim.api.nvim_create_autocmd('TermClose', {
  --   callback = function(ctx)
  --     vim.cmd 'stopinsert'
  --     vim.api.nvim_create_autocmd('TermEnter', {
  --       command = 'stopinsert',
  --       buffer = ctx.buf,
  --     })
  --   end,
  --   nested = true,
  --   group = vim_term,
  -- })
end

-- Export the run_command helper for use in other modules
M.zellij_exec_async = zellij_exec_async

return M
