---@module "snacks"
---@module "utils.json"
---@module "uv.init"
local UV_M = require 'uv'
-- JSON = assert(loadfile 'lua/utils/json.lua')()
JSON = require 'utils.json'
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
  vim.notify('Running cmd: ' .. cmd)
  Snacks.picker.util.cmd(cmd, function(output, ret_code)
    if output[1] == nil then
      vim.notify('Got no ouput when it was expecting one', 'error')
    end
    M.handle_output(output, ret_code, item.text)
  end, { cwd = cwd })
end
---@param picker snacks.Picker
---@param item UVToolFinderItem
function M.uv_run_tool_call(picker, item)
  if item.prompt_for_input == nil then
    local default_args = item.default_args or {}

    uv_run_command(picker, item, table.concat(default_args, ' '))
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

--- Runs specified diagnostic tools for a given file.
---@param filepath string The absolute path to the file to diagnose.
---@param tool_names string[] A list of tool names (e.g., 'ruff check', 'ty check') to run.
function M.run_diagnostics_for_file(filepath, tool_names)
  local cwd = M.get_project_root() or vim.fn.getcwd()
  for _, tool_name in ipairs(tool_names) do
    local item = vim.tbl_filter(function(t)
      return t.text == tool_name
    end, M.registered_tools)[1]
    if item then
      local args = item.default_args or {}
      -- Add the filepath to the arguments for the tool
      table.insert(args, filepath)
      local cmd = create_tool_call({ 'uv', 'run', '--all-packages' }, item.text, args)
      vim.notify('Running cmd: ' .. cmd)
      Snacks.picker.util.cmd(cmd, function(output, ret_code)
        if output[1] == nil then
          vim.notify('Got no ouput when it was expecting one', 'error')
        end
        M.handle_output(output, ret_code, item.text)
      end, { cwd = cwd })
    else
      vim.notify('Unknown diagnostic tool: ' .. tool_name, 'warn')
    end
  end
end

---@type UVToolFinderItem[]
M.registered_tools = {
  {
    text = 'Pytest',
    prompt_for_input = 'Additional arguments for pytest: ',
  },
  {

    text = 'basedpyright',
    default_args = { '--level', 'error', '--outputjson' },
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
    default_args = { '--fix', '--output-format', 'json-lines' },
    prompt_for_input = 'Additional arguments for ruff check: ',
  },
  {
    text = 'ty check',
    default_args = { '--output-format', 'concise' },
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

local h = require 'null-ls.helpers'
local methods = require 'null-ls.methods'
local DIAGNOSTICS = methods.internal.DIAGNOSTICS
local FORMATTING = methods.internal.FORMATTING
local CODE_ACTION = methods.internal.CODE_ACTION

M.null_ls_sources = {
  diagnostics = {
    ruff_check = h.make_builtin {
      name = 'uv_ruff_check',
      method = DIAGNOSTICS,
      filetypes = { 'python' },
      generator_opts = {
        command = 'uv',
        args = { 'run', '--all-packages', 'ruff', 'check', '--output-format', 'json-lines', '$FILENAME' },
        format = 'json',
        to_stdin = false,
        on_output = function(output)
          return M.handle_output(output, 0, 'ruff check')
        end,
        cwd = h.cache.by_bufnr(M.get_project_root),
      },
      factory = h.generator_factory,
    },
    ty_check = h.make_builtin {
      name = 'uv_ty_check',
      method = DIAGNOSTICS,
      filetypes = { 'python' },
      generator_opts = {
        command = 'uv',
        args = { 'run', '--all-packages', 'ty', 'check', '--output-format', 'concise', '$FILENAME' },
        format = 'line',
        to_stdin = false,
        on_output = function(output)
          return M.handle_output(output, 0, 'ty check')
        end,
        cwd = h.cache.by_bufnr(M.get_project_root),
      },
      factory = h.generator_factory,
    },
  },
  formatting = {
    ruff_format = h.make_builtin {
      name = 'uv_ruff_format',
      method = FORMATTING,
      filetypes = { 'python' },
      generator_opts = {
        command = 'uv',
        args = { 'run', '--all-packages', 'ruff', 'format', '$FILENAME' },
        to_stdin = true,
        cwd = h.cache.by_bufnr(M.get_project_root),
      },
      factory = h.formatter_factory,
    },
  },
  code_actions = {
    ruff_fix = h.make_builtin {
      name = 'uv_ruff_fix',
      method = CODE_ACTION,
      filetypes = { 'python' },
      generator_opts = {
        command = 'uv',
        args = { 'run', '--all-packages', 'ruff', 'check', '--fix', '--output-format', 'json-lines', '$FILENAME' },
        to_stdin = false,
        on_output = function(output)
          return M.handle_output(output, 0, 'ruff check')
        end,
        cwd = h.cache.by_bufnr(M.get_project_root),
      },
      factory = h.generator_factory,
    },
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
function M.handle_output(output, ret_code, tool_name)
  local diagnostics = {}
  local qf_list = {}
  -- vim.notify('Got output from ' .. tool_name .. ' ret: ' .. ret_code .. ' output len: ' .. #output)
  for idx = 1, #output do
    local output_str = output[idx]
    if output_str ~= '' then
      local result, err = JSON:decode(output_str, nil, {
        strictParsing = false,
      })
      -- local ok, result = pcall(vim.json.decode, json_str)
      if err ~= nil then
        vim.notify('JSON decode error: ' .. err)
        return
      end
      if result ~= nil then
        vim.notify(vim.inspect(result))

        if tool_name == 'ruff check' then
          for _, d in ipairs(result) do
            local sev = vim.diagnostic.severity.INFO
            if d.code:match 'E%d+' then
              sev = vim.diagnostic.severity.ERROR
            elseif d.code:match 'W%d+' then
              sev = vim.diagnostic.severity.WARN
            end

            table.insert(diagnostics, {
              bufnr = 0,
              lnum = d.location.row - 1,
              col = d.location.column,
              end_lnum = d.end_location.row - 1,
              end_col = d.end_location.column,
              message = string.format('[%s] %s', d.code, d.message),
              severity = sev,
              source = 'ruff',
            })

            table.insert(qf_list, {
              filename = d.filename,
              lnum = d.location.row,
              col = d.location.column,
              text = string.format('[%s] %s', d.code, d.message),
              type = string.sub(d.code, 1, 1), -- E for Error, W for Warning
            })
          end
        elseif tool_name == 'basedpyright' then
          local diag_list = result.generalDiagnostics
          if diag_list == nil then
            vim.notify('Diag is nil', 'error')
            return
          end
          for _, d in ipairs(diag_list) do
            local sev = vim.diagnostic.severity.INFO
            if d.severity == 'error' then
              sev = vim.diagnostic.severity.ERROR
            elseif d.severity == 'warning' then
              sev = vim.diagnostic.severity.WARN
            end

            table.insert(diagnostics, {
              bufnr = 0,
              lnum = d.range.start.line - 1,
              col = d.range.start.character,
              end_lnum = d.range['end'].line - 1,
              end_col = d.range['end'].character,
              message = string.format('[%s] %s', d.code, d.message),
              severity = sev,
              source = 'basedpyright',
            })

            table.insert(qf_list, {
              filename = d.file,
              lnum = d.range.start.line + 1,
              col = d.range.start.character + 1,
              text = string.format('[%s] %s', d.code, d.message),
              type = string.sub(d.severity, 1, 1):upper(), -- E for Error, W for Warning
            })
          end
        elseif tool_name == 'ty check' then
          local filename, lnum_str, col_str, severity_str, code, message = output_str:match '^([^:]+):(%d+):(%d+): (%a+)%[([%w%-]+)%] (.+)$'
          if filename then
            local lnum = tonumber(lnum_str)
            local col = tonumber(col_str)
            local sev = vim.diagnostic.severity.INFO
            if severity_str == 'error' then
              sev = vim.diagnostic.severity.ERROR
            elseif severity_str == 'warn' then
              sev = vim.diagnostic.severity.WARN
            end

            table.insert(diagnostics, {
              bufnr = 0,
              lnum = lnum - 1,
              col = col - 1,
              -- ty check doesn't provide end_location, so we'll just use the start
              end_lnum = lnum - 1,
              end_col = col,
              message = string.format('[%s] %s', code, message),
              severity = sev,
              source = 'ty',
            })

            table.insert(qf_list, {
              filename = filename,
              lnum = lnum,
              col = col,
              text = string.format('[%s] %s', code, message),
              type = string.sub(severity_str, 1, 1):upper(), -- E for Error, W for Warning
            })
          else
            vim.notify('Failed to parse ty check output: ' .. output_str, 'warn')
          end
        else
          vim.notify('Unsupported tool output ' .. tool_name, 'error')
        end
      end
    end
  end

  --
  local ns_id = vim.api.nvim_create_namespace 'uv_wspace_diags '

  if #diagnostics > 0 then
    vim.diagnostic.set(ns_id, 0, diagnostics, { bufnr = 0 })
  end
  if #qf_list > 0 then
    vim.fn.setqflist({}, ' ', { title = 'UV Tool Output', items = qf_list })
  end
  return diagnostics, qf_list
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
    vim.api.nvim_set_keymap('n', prefix .. 'r', "<cmd>lua Snacks.picker.pick('uv_tools')<CR>", { noremap = true, silent = true, desc = 'UV Pick Tool' })
  end

  -- Run tool with input
  -- vim.api.nvim_set_keymap(
  --   'n',
  --   prefix .. 'r',
  --   "<cmd>lua vim.ui.input({prompt = 'Enter tool name: '}, function(input) if input and input ~= '' then require('uv').run_command('uv run ' .. input) end end)<CR>",
  --   { noremap = true, silent = true, desc = 'UV Run Tool with Input' }
  -- )
  --
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
