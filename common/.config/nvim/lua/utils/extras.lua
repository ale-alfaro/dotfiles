---@class SmartSplitsMultiplexer
local mux = require('smart-splits.mux').get()

local Direction = require('smart-splits.types').Direction

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

---@class wezterm_spanw_args
---@field cwd string
---@field percentage number
---@field program string

local function wezterm_split_pane(direction, cwd, size, program_args)
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

local function wezterm_spawn_terminal()
  local bufname = vim.api.nvim_buf_get_name(0)
  local cwd
  if bufname == '' or bufname == nil then
    cwd = vim.fn.getcwd()
  else
    cwd = vim.fn.expand '%:p:h'
  end
  local ok = wezterm_split_pane(Direction.down, cwd, 30)
  return ok
end

local function wezterm_spawn_nvim_inst(direction, file)
  local cwd = vim.fn.fnamemodify(file, ':h')
  local program_args = { 'nvim', file }
  local ok = wezterm_split_pane(direction, cwd, nil, program_args)
  return ok
end

local function get_chat()
  local codecompanion = require 'codecompanion'
  local chat = codecompanion.last_chat()

  -- Create chat if none exists
  if not chat then
    chat = codecompanion.chat()
    if not chat then
      vim.notify 'Couldnt find chat while adding context from explorer'
      return nil
    end
  end
  return chat
end
local function add_fs_entry_to_chat(chat, fs_entry)
  if not fs_entry or not fs_entry.fs_type or not fs_entry.path then
    vim.notify('Invalid file system entry.', vim.log.levels.WARN)
    return
  end

  local slash_commands = require 'codecompanion.strategies.chat.slash_commands'
  if fs_entry.fs_type == 'directory' then
    -- Recursively traverse the directory
    local files = vim.fn.globpath(fs_entry.path, '*', false, true)
    if files and vim.islist(files) then
      for _, path in ipairs(files) do
        slash_commands.context(chat, 'file', { path = path })
      end
    end
    -- vim.notify('Added all files in ' .. path .. ' to chat.')
  elseif fs_entry.fs_type == 'file' then
    slash_commands.context(chat, 'file', { path = fs_entry.path })
    -- Add the single file
    -- vim.notify('Added ' .. path .. ' to chat.')
  end
end
local function add_context_from_explorer()
  local chat = get_chat()
  if not chat then
    vim.notify('Couldnt get chat', vim.log.levels.ERROR)
    return
  end
  local MiniFiles = require 'mini.files'
  local bufnr = vim.api.nvim_get_current_buf()
  local fs_entry = MiniFiles.get_fs_entry(bufnr)
  add_fs_entry_to_chat(chat, fs_entry)
end
local function add_context_from_explorer_visual(buf_id)
  if vim.fn.mode() ~= 'V' then
    return
  end
  --
  local line_1, line_2 = vim.fn.line 'v', vim.fn.line '.'
  local from_line, to_line = math.min(line_1, line_2), math.max(line_1, line_2)
  -- Compute which entries to go in: all files and only last directory
  local files, path = {}, nil
  local MiniFiles = require 'mini.files'
  for i = from_line, to_line do
    local fs_entry = MiniFiles.get_fs_entry(buf_id, i) or {}
    if fs_entry.fs_type == 'file' then
      table.insert(files, fs_entry.path)
    end
    if fs_entry.fs_type == 'directory' then
      path = fs_entry.path
    end
    if fs_entry.fs_type == nil and fs_entry.path == nil then
      local entry = vim.inspect(vim.get_bufline(buf_id, i))
      vim.notify('Line ' .. entry .. ' does not have proper format. Did you modify without synchronization?', vim.log.levels.WARN)
    end
    if fs_entry.fs_type == nil and fs_entry.path ~= nil then
      local path_resolved = vim.fn.resolve(fs_entry.path)
      local symlink_info = path_resolved == fs_entry.path and '' or (' Looks like miscreated symlink (resolved to ' .. path_resolved .. ').')
      vim.notify('Path ' .. fs_entry.path .. ' is not present on disk.' .. symlink_info, vim.log.levels.WARN)
    end
  end

  local chat = get_chat()
  if not chat then
    vim.notify('Couldnt get chat', vim.log.levels.ERROR)
    return
  end
  local slash_commands = require 'codecompanion.strategies.chat.slash_commands'
  for _, file_path in ipairs(files) do
    slash_commands.context(chat, 'file', { path = file_path })
  end

  if path ~= nil then
    -- add_dir_contents_as_context(chat, slash_commands, path, { '*' })
  end
  return [[<C-\><C-n>]]
end

local function mini_files_wezterm_integration()
  local map_split = function(buf_id, lhs, direction, close_on_file)
    local rhs = function()
      local MiniFiles = require 'mini.files'
      local fs_entry = MiniFiles.get_fs_entry()
      if not fs_entry then
        return
      end

      local wezterm_direction
      if direction == 'horizontal' then
        wezterm_direction = Direction.down
      elseif direction == 'vertical' then
        wezterm_direction = Direction.right
      else
        return
      end

      if fs_entry.is_dir then
        wezterm_split_pane(wezterm_direction, fs_entry.path, 30)
      else
        wezterm_spawn_nvim_inst(wezterm_direction, fs_entry.path)
      end

      if close_on_file and not fs_entry.is_dir then
        MiniFiles.close()
      end
    end

    local desc = 'Open in wezterm ' .. direction .. ' split'
    if close_on_file then
      desc = desc .. ' and close'
    end
    vim.keymap.set('n', lhs, rhs, { buffer = buf_id, desc = desc })
  end

  vim.api.nvim_create_autocmd('User', {
    pattern = 'MiniFilesBufferCreate',
    callback = function(args)
      local buf_id = args.data.buf_id
      local ai_files = require('custom.ai.files')
      vim.keymap.set('n', 'ga', add_context_from_explorer, { buffer = buf_id, desc = 'CodeCompanion: Add to Chat' })
      -- vim.keymap.set('x', 'ga', add_context_from_explorer_visual, { buffer = buf_id, desc = 'CodeCompanion: Add to Chat (Visual)' })
      map_split(buf_id, '<C-w>s', 'horizontal', false)
      map_split(buf_id, '<C-w>v', 'vertical', false)
      -- map_split(buf_id, opts.mappings and opts.mappings.go_in_horizontal_plus or '<C-w>S', 'horizontal', true)
      -- map_split(buf_id, opts.mappings and opts.mappings.go_in_vertical_plus or '<C-w>V', 'vertical', true)
    end,
  })
end

  mini_files_wezterm_integration()
  local cmds = {
    {
      'WeztermTerm',
      function()
        wezterm_spawn_terminal()
      end,
      { desc = 'Spawn Wezterm Terminal' },
    },
    -- {
    --   'WeztermWorkspace',
    --   function()
    --     wezterm_workspace_picker()
    --   end,
    --   { desc = 'Switch Wezterm Workspace' },
    -- },
  }

  vim.tbl_map(function(cmd)
    vim.api.nvim_create_user_command(cmd[1], cmd[2], cmd[3])
  end, cmds)
