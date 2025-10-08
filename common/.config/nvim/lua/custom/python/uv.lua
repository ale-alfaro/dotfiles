---@module "snacks"
---@module "uv.init"
local UV_M = require 'uv'

local M = {}

---@return string?
function M.get_project_root()
  local workspace_root
  if vim.env.VIRTUAL_ENV ~= nil then
    workspace_root = vim.fs.dirname(vim.env.VIRTUAL_ENV)
  else
    workspace_root = vim.fs.root(vim.env.PWD, { 'pyproject.toml', 'uv.lock' })
  end
  return workspace_root
end

---@class UVToolFinderItem : snacks.picker.finder.Item
---@field default_args? string[]
---@field prompt_for_input? string
---@field options? string[]
---
---
---@param cmd_runner string[]
---@param tool string
---@param args? string[]
---@return string
local function create_tool_call(cmd_runner, tool, args)
  local cmd = cmd_runner or { 'uv', 'run' }
  -- ret = UV_M.run_command "uv pip list --format=json --editable | jq '.[].editable_project_location'"
  for w in string.gmatch(tool, '%a+') do
    cmd[#cmd + 1] = w
  end
  if args ~= nil then
    for idx = 1, #args do
      cmd[#cmd + 1] = args[idx]
    end
  end
  return table.concat(cmd, ' ')
end

-- Function to run a specific Python function

-- ---@param opts snacks.picker.proc.Config
-- ---@type snacks.picker.finder
-- function M.uv_run_tool_finder(opts, ctx)
--   return require('snacks.picker.source.proc').proc({
--     opts,
--     {
--       cmd = 'uv',
--       args = { 'tool', 'list' },
--     },
--   }, ctx)
-- end
---@param picker snacks.Picker
---@param item UVToolFinderItem
---@param additional_input string?
---@return string[]?
local function uv_run_command(picker, item, additional_input)
  local args = {}
  local uv_tool_runner = { 'uv', 'run', '--all-packages' }
  if additional_input ~= nil then
    for arg_part in string.gmatch(additional_input, '[^%s]+') do
      --[[
    --  Currently matching for 3 types of arguments
    --  alphanumeric only arguments 
    --  Long flag like --verbose
    --  Short flags like -v
    --]]
      if arg_part:match '^%w+$' or arg_part:match '^%-%-%a+$' or arg_part:match '^%-%a$' then
        args[#args + 1] = arg_part
      end
    end

    if #args == 0 then
      vim.notify('Error: At least one positional argument is required.', 'error')
    end
  end

  local cwd = M.get_project_root() or picker:cwd()
  local cmd = create_tool_call(uv_tool_runner, item.text, args)
  Snacks.picker.util.cmd(cmd, function(output, ret_code)
    if ret_code ~= 0 or output ~= '' then
      return Snacks.notify.error 'UV tool call failed!'
    end
  end, { cwd = cwd })
end
---@param picker snacks.Picker
---@param item UVToolFinderItem
function M.uv_run_tool_call(picker, item)
  if item.prompt_for_input == nil then
    uv_run_command(picker, item)
    return
  end
  ---@type snacks.input.Opts
  local opts = {
    prompt = item.prompt_for_input,
  }
  if item.default_args ~= nil then
    table.insert(opts, {
      default = table.concat(item.default_args),
    })
  end
  Snacks.input.input(opts, function(input)
    --  match checks for zero or more whitespace characters from the beginning (`^`) to the end (`$`) of the string.
    --  to filter out for empty or invalid input
    if (input or ''):match '^%s*$' then
      return
    end
    uv_run_command(picker, item, input)
  end)
end

---@type UVToolFinderItem[]
M.registered_tools = {
  {
    text = 'Pytest',
    prompt_for_input = 'Additional arguments for pytest: ',
  },
  {

    text = 'basedpyright',
    default_args = { '--level', 'error' },
    -- prompt_for_input = 'Additional arguments for basedpyright: ',
  },
  {
    text = 'mypy',
    desc = 'Run mypy',
    -- prompt_for_input = 'Additional arguments for mypy: ',
  },
  {
    text = 'ruff format',
    default_args = { '--check' },
    prompt_for_input = 'Additional arguments for ruff format: ',
  },
  {
    text = 'ruff check',
    default_args = { '--fix' },
    prompt_for_input = 'Additional arguments for ruff check: ',
  },
  {
    text = 'ty',
    -- prompt_for_input = 'Additional arguments for ty: ',
  },
  {
    text = 'deptry',
    -- prompt_for_input = 'Additional arguments for deptry: ',
  },
  {
    text = 'prek run',
    -- prompt_for_input = 'Additional arguments for prek: ',
  },
}
-- Run current file
-- Set up command pickers for integration with UI plugins
function M.setup_pickers()
  --   -- Check if Snacks is available
  --   -- Register UV command source
  ---@type snacks.picker.Config
  Snacks.picker.sources.uv_tools = {

    finder = function()
      return M.registered_tools
    end,
    format = 'text',
    preview = 'none',
    confirm = 'uv_run',
    ---@type snacks.picker.Action.fn[]
    actions = {

      ---@param p snacks.Picker
      ---@param item snacks.picker.Item
      uv_run = function(p, item)
        p:close()
        M.uv_run_tool_call(p, item)
      end,
    },
  }
end

-- Handle output and set diagnostics/quickfix
function M.handle_output(output_lines, is_json, tool_name)
  local diagnostics = {}
  local qf_list = {}

  if is_json then
    local json_str = table.concat(output_lines, '')
    -- vim.json.decode()
    local ok, result = pcall(vim.json.decode, json_str)
    if ok and result then
      if tool_name == 'ruff' then
        for _, diag in ipairs(result) do
          table.insert(diagnostics, {
            filename = diag.file, -- Current buffer
            lnum = diag.location.row - 1,
            col = diag.location.column - 1,
            severity = vim.diagnostic.severity.ERROR,
            message = diag.code .. ': ' .. diag.message,
            source = 'ruff',
          })
          table.insert(qf_list, {
            filename = diag.file,
            lnum = diag.location.row,
            col = diag.location.column,
            text = diag.code .. ': ' .. diag.message,
            type = 'E',
          })
        end
      elseif tool_name == 'basedpyright' then
        for _, file_diag in ipairs(result.files) do
          for _, diag in ipairs(file_diag.diagnostics) do
            table.insert(diagnostics, {
              bufnr = 0, -- Current buffer
              lnum = diag.range.start.line,
              col = diag.range.start.character,
              severity = vim.diagnostic.severity[string.upper(diag.severity)] or vim.diagnostic.severity.ERROR,
              message = diag.message,
              source = 'basedpyright',
            })
            table.insert(qf_list, {
              filename = file_diag.uri:gsub('file://', ''),
              lnum = diag.range.start.line + 1,
              col = diag.range.start.character + 1,
              text = diag.message,
              type = string.sub(string.upper(diag.severity), 1, 1),
            })
          end
        end
      end
    else
      -- Fallback for non-JSON output or parsing errors
      print 'Error decoding JSON or non-JSON output:'
      for _, line in ipairs(output_lines) do
        print(line)
      end
    end
  else
    -- Handle non-JSON output (e.g., print to messages)
    for _, line in ipairs(output_lines) do
      print(line)
    end
  end

  if #diagnostics > 0 then
    vim.diagnostic.set(0, 0, diagnostics, { bufnr = 0 })
  end
  if #qf_list > 0 then
    vim.fn.setqflist({}, ' ', { title = 'UV Tool Output', items = qf_list })
    vim.cmd 'copen'
  end
end
--
-- Set up user commands
function M.setup_commands()
  -- Set up UV commands

  vim.api.nvim_create_user_command('UVSync', function(_opts)
    UV_M.run_command 'uv sync'
  end, {})

  vim.api.nvim_create_user_command('UVLock', function(_opts)
    UV_M.run_command 'uv lock'
  end, {})
  vim.api.nvim_create_user_command('UVRunTool', function(opts)
    UV_M.run_command('uv run ' .. opts.args)
  end, { nargs = 1 })
end

-- Set up keymaps
function M.setup_keymaps()
  local keymaps = UV_M.config.keymaps -- Use UV_M.config for keymaps
  local prefix = keymaps.prefix or '<leader>x'

  -- Main UV command menu
  if _G.Snacks and _G.Snacks.picker then
    vim.api.nvim_set_keymap('n', prefix .. 'R', "<cmd>lua Snacks.picker.pick('uv_tools')<CR>", { noremap = true, silent = true, desc = 'UV Pick Tool' })
  end

  -- Run tool with input
  vim.api.nvim_set_keymap(
    'n',
    prefix .. 'r',
    "<cmd>lua vim.ui.input({prompt = 'Enter tool name: '}, function(input) if input and input ~= '' then require('uv').run_command('uv run ' .. input) end end)<CR>",
    { noremap = true, silent = true, desc = 'UV Run Tool with Input' }
  )

  -- Sync packages
  vim.api.nvim_set_keymap('n', prefix .. 'c', '<cmd>UVSync<CR>', { noremap = true, silent = true, desc = 'UV Sync Packages' })

  -- Sync all extras, groups and packages
  vim.api.nvim_set_keymap('n', prefix .. 'l', '<cmd>UVLock<CR>', { noremap = true, silent = true, desc = 'UV Lock Dependencies' })
end
-- -- Main setup function
function M.setup(opts)
  UV_M.setup(opts)
  M.setup_commands()
  M.setup_keymaps()
  M.setup_pickers()
end

return M
