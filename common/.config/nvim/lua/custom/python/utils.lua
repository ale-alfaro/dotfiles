M = {}

-- Default configuration
M.config = {
  auto_activate_venv = false,
  -- Keymaps to register (set to false to disable)
  keymaps = {
    prefix = "<leader>x", -- Main prefix for UV commands
    commands = true,      -- Show UV commands menu (<leader>x)
    run_file = true,      -- Run current file (<leader>xr)
    run_selection = true, -- Run selection (<leader>xs)
    run_function = true,  -- Run function (<leader>xf)
    venv = true,          -- Environment management (<leader>xe)
    init = true,          -- Initialize UV project (<leader>xi)
    add = true,           -- Add a package (<leader>xa)
    remove = true,        -- Remove a package (<leader>xd)
    sync = true,          -- Sync packages (<leader>xc)
    sync_all = true,      -- uv sync --all-extras --all-groups --all-packages (<leader>xC)
  },

  -- Execution options
  execution = {
    -- Python run command template
    run_command = "uv run python",

    -- Show output in notifications
    notify_output = true,

    -- Notification timeout in ms
    notification_timeout = 10000,
  },
}

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

-- Command runner - runs shell commands and captures output
---@param cmd string[]
---@param output_cb? fun( data: string?, lines: string[])
---@param cwd? string
---@param text_output? boolean
local function run_command(cmd, output_cb, cwd, text_output)
  if cwd == nil then
    cwd = M.get_project_root()
  end
  ---@type vim.SystemOpts
  local opts = {
    cwd = cwd,
    text = text_output or true

  }
  --- @type fun(out: vim.SystemCompleted)
  local on_exit = function(obj)
    if obj.code == 0 and obj.stdout then
      _G.info("Command completed successfully")
      if output_cb then
        if obj.stdout and obj.stdout:match("%S") then
          local line_output = text_output and vim.split(obj.stdout, "\n") or {}
          _G.info("comand output: " .. obj.stdout)
          output_cb(obj.stdout, line_output)
        end
      end
    else
      _G.error("Command failed")
    end
  end
  -- Run command in background and capture output
  vim.system(cmd, {}, on_exit)
end



---@class UVTool
---@field name string
---@field base_cmd string[]
---@field postprocess? fun( raw_out: string?, output_lines: string[])
---
---
---@type table<string, UVTool>
M.registered_tools = {
  --[[
      cmd: ruff check --output-format=rdjson
      example output:
        {
          "diagnostics": [
          {
            "code": {
              "url": "https://docs.astral.sh/ruff/rules/undefined-name",
              "value": "F821"
            },
            "location": {
              "path": "/home/alealfaro/sibel/eng/tools/pytest-zephyr-core/tests/conftest.py",
              "range": {
                "end": {
                  "column": 54,
                  "line": 82
                },
                "start": {
                  "column": 36,
                  "line": 82
                }
              },
            "message": "Undefined name `memory_stream_pair`"
          },

          ],
          "severity": "WARNING",
          "source": {
            "name": "ruff",
            "url": "https://docs.astral.sh/ruff"
          }
        }
  --]]
  ruff_check = {
    name = 'ruff_check',
    base_cmd = { 'uv', 'run', 'ruff', 'check', '--output-format=rdjson', '--exit-zero' },
    -- default_args = { '--fix', '--output-format', 'json-lines' },
    prompt_for_input = 'Additional arguments for ruff check: ',
    postprocess = function(raw_out, _)
      local mapping = {
        ['end_col'] = { 'location', 'range', 'end', 'column' },
        ['end_lnum'] = { 'location', 'range', 'end', 'line' },
        ['col'] = { 'location', 'range', 'start', 'column' },
        ['lnum'] = { 'location', 'range', 'start', 'line' },
        ['message'] = { 'message' },
      }
      _G.json_to_diag(raw_out, mapping, 'ruff')
    end,
  },
  --[[
      cmd: ty check --output-format concise
      example output: src/pytest_zephyr_core/core_io/_ble_stream_handler.py:1:1: I001 [*] Import block is un-sorted or un-formatted
--]]
  ty_check = {
    name = 'ty_check',
    base_cmd = { 'uv', 'run', 'ty', 'check', '--output-format', 'concise', '--exit-zero' },
    postprocess = function(_, lines)
      local pattern = '^([^:]+):(%d+):(%d+): (%a+)%[([%w%-]+)%] (.+)$'
      local groups = { 'filename', 'lnum', 'col', 'severity', 'rule', 'message' }
      _G.lines_to_diag(lines, pattern, groups)
    end,
  },
}
--- Runs specified diagostic tools for a given file.
---@param tool string[]|string A list of tool names (e.g., 'ruff check', 'ty check') to run.
---@param cwd string? A list of tool names (e.g., 'ruff check', 'ty check') to run.
function M.run_diagostics_with_tools(tool, cwd)
  tool = vim._ensure_list(tool)
  cwd = cwd or M.get_project_root() or vim.fn.getcwd()
  for _, tool_name in ipairs(tool) do
    if M.registered_tools[tool_name] ~= nil then
      local tool_table = M.registered_tools[tool_name]
      -- Add the filepath to the arguments for the tool
      _G.info('Running diagnostic tool: ' .. tool_name)
      run_command(tool_table.base_cmd, tool_table.postprocess, cwd)
    else
      _G.warn('Unknown diagostic tool: ' .. tool_name)
    end
  end
end

-- Virtual environment activation
function M.activate_venv(venv_path)
  -- For Mac, run the source command to apply to the current shell
  local command = "source " .. venv_path .. "/bin/activate"

  -- Set environment variables for the current Neovim instance
  vim.env.VIRTUAL_ENV = venv_path
  vim.env.PATH = venv_path .. "/bin:" .. vim.env.PATH
  -- Notify user
  vim.notify("Activated virtual environment: " .. venv_path, vim.log.levels.INFO)
end

-- Auto-activate the .venv if it exists at the project root
function M.auto_activate_venv()
  local venv_path = vim.fn.getcwd() .. "/.venv"
  if vim.fn.isdirectory(venv_path) == 1 then
    M.activate_venv(venv_path)
    return true
  end
  return false
end

-- Function to create a temporary file with the necessary context and selected code
function M.run_python_selection()
  -- Get visual selection
  local get_visual_selection = function()
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local lines = vim.fn.getline(start_pos[2], end_pos[2])

    if #lines == 0 then
      return ""
    end

    -- Adjust last line to end at the column position of end_pos
    if #lines > 0 then
      lines[#lines] = lines[#lines]:sub(1, end_pos[3])
    end

    -- Adjust first line to start at the column position of start_pos
    if #lines > 0 then
      lines[1] = lines[1]:sub(start_pos[3])
    end

    return table.concat(lines, "\n")
  end

  -- Get current buffer content to extract imports and global variables
  local get_buffer_globals = function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local imports = {}
    local globals = {}
    local in_class = false
    local class_indent = 0

    for _, line in ipairs(lines) do
      -- Detect imports
      if line:match("^%s*import ") or line:match("^%s*from .+ import") then
        table.insert(imports, line)
      end

      -- Detect class definitions to skip class variables
      if line:match("^%s*class ") then
        in_class = true
        class_indent = line:match("^(%s*)"):len()
      end

      -- Check if we're exiting a class block
      if in_class and line:match("^%s*[^%s#]") then
        local current_indent = line:match("^(%s*)"):len()
        if current_indent <= class_indent then
          in_class = false
        end
      end

      -- Detect global variable assignments (not in class, not inside functions)
      if not in_class and not line:match("^%s*def ") and line:match("^%s*[%w_]+ *=") then
        -- Check if it's not indented (global scope)
        if not line:match("^%s%s+") then
          table.insert(globals, line)
        end
      end
    end

    return imports, globals
  end

  -- Get selected code
  local selection = get_visual_selection()
  if selection == "" then
    vim.notify("No code selected", vim.log.levels.WARN)
    return
  end

  -- Get imports and globals
  local imports, globals = get_buffer_globals()

  -- Create temp file
  local temp_dir = vim.fn.expand("$HOME") .. "/.cache/nvim/uv_run"
  vim.fn.mkdir(temp_dir, "p")
  local temp_file = temp_dir .. "/run_selection.py"
  local file = io.open(temp_file, "w")
  if not file then
    vim.notify("Failed to create temporary file", vim.log.levels.ERROR)
    return
  end

  -- Write imports
  for _, imp in ipairs(imports) do
    file:write(imp .. "\n")
  end
  file:write("\n")

  -- Write globals
  for _, glob in ipairs(globals) do
    file:write(glob .. "\n")
  end
  file:write("\n")

  -- Write selected code
  file:write("# SELECTED CODE\n")

  -- Check if the selection is all indented (which would cause syntax errors)
  local is_all_indented = true
  for line in selection:gmatch("[^\r\n]+") do
    if not line:match("^%s+") and line ~= "" then
      is_all_indented = false
      break
    end
  end

  -- Process the selection to determine what type of code it is
  local is_function_def = selection:match("^%s*def%s+[%w_]+%s*%(")
  local is_class_def = selection:match("^%s*class%s+[%w_]+")
  local has_print = selection:match("print%s*%(")
  local is_expression = not is_function_def
      and not is_class_def
      and not selection:match("=")
      and not selection:match("%s*for%s+")
      and not selection:match("%s*if%s+")
      and not has_print

  -- If the selection is all indented, we need to dedent it or wrap it in a function
  if is_all_indented then
    file:write("def run_selection():\n")
    -- Write the selection with original indentation
    for line in selection:gmatch("[^\r\n]+") do
      file:write("    " .. line .. "\n")
    end
    file:write("\n# Auto-call the wrapper function\n")
    file:write("run_selection()\n")
  else
    -- Write the original selection
    file:write(selection .. "\n")

    -- For expressions, we'll add a print statement to see the result
    if is_expression then
      file:write("\n# Auto-added print for expression\n")
      file:write('print(f"Expression result: {' .. selection:gsub("^%s+", ""):gsub("%s+$", "") .. '}")\n')
      -- For function definitions without calls, we'll add a call
    elseif is_function_def then
      local function_name = selection:match("def%s+([%w_]+)%s*%(")
      -- Check if the function is already called in the selection
      if function_name and not selection:match(function_name .. "%s*%(.-%)") then
        file:write("\n# Auto-added function call\n")
        file:write('if __name__ == "__main__":\n')
        file:write('    print(f"Auto-executing function: ' .. function_name .. '")\n')
        file:write("    result = " .. function_name .. "()\n")
        file:write("    if result is not None:\n")
        file:write('        print(f"Return value: {result}")\n')
      end
      -- If there's no print statement in the code, add an output marker
    elseif not has_print and not selection:match("^%s*#") then
      file:write("\n# Auto-added execution marker\n")
      file:write('print("Code executed successfully.")\n')
    end
  end

  file:close()

  -- Run the temp file
  vim.notify("Running selected code...", vim.log.levels.INFO)
  vim.fn.jobstart(run_command .. " " .. vim.fn.shellescape(temp_file), {
    on_stdout = function(_, data)
      if data and #data > 1 then
        local output = table.concat(data, "\n")
        if output and output:match("%S") then
          vim.notify(output, vim.log.levels.INFO, {
            title = "Python Output",
            timeout = M.config.execution.notification_timeout,
          })
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 1 then
        local output = table.concat(data, "\n")
        if output and output:match("%S") then
          vim.notify(output, vim.log.levels.ERROR, {
            title = "Python Error",
            timeout = M.config.execution.notification_timeout,
          })
        end
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        vim.notify("Selected code executed successfully", vim.log.levels.INFO)
      else
        vim.notify("Selected code execution failed with exit code: " .. exit_code, vim.log.levels.ERROR)
      end
    end,
    stdout_buffered = true,
    stderr_buffered = true,
  })
end

-- Function to run a specific Python function
function M.run_python_function()
  -- Get current buffer content
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local buffer_content = table.concat(lines, "\n")

  -- Find all function definitions
  local functions = {}
  for line in buffer_content:gmatch("[^\r\n]+") do
    local func_name = line:match("^def%s+([%w_]+)%s*%(")
    if func_name then
      table.insert(functions, func_name)
    end
  end

  if #functions == 0 then
    vim.notify("No functions found in current file", vim.log.levels.WARN)
    return
  end

  -- Create temp file for function selection picker
  local run_function = function(func_name)
    -- Create a temporary file with a main block to call the function
    local temp_dir = vim.fn.expand("$HOME") .. "/.cache/nvim/uv_run"
    vim.fn.mkdir(temp_dir, "p")
    local temp_file = temp_dir .. "/run_function.py"
    local current_file = vim.fn.expand("%:p")

    -- Create a wrapper script that imports the current file and calls the function
    local file = io.open(temp_file, "w")
    if not file then
      vim.notify("Failed to create temporary file", vim.log.levels.ERROR)
      return
    end

    -- Get the module name (file name without .py)
    local module_name = vim.fn.fnamemodify(current_file, ":t:r")
    local module_dir = vim.fn.fnamemodify(current_file, ":h")

    -- Write imports
    file:write("import sys\n")
    file:write("sys.path.insert(0, " .. vim.inspect(module_dir) .. ")\n")
    file:write("import " .. module_name .. "\n\n")
    file:write('if __name__ == "__main__":\n')
    file:write('    print(f"Running function: ' .. func_name .. '")\n')
    file:write("    result = " .. module_name .. "." .. func_name .. "()\n")
    file:write("    if result is not None:\n")
    file:write('        print(f"Return value: {result}")\n')
    file:close()

    -- Run the temp file
    vim.notify("Running function: " .. func_name, vim.log.levels.INFO)
    vim.fn.jobstart(M.config.execution.run_command .. " " .. vim.fn.shellescape(temp_file), {
      on_stdout = function(_, data)
        if data and #data > 1 then
          local output = table.concat(data, "\n")
          if output and output:match("%S") then
            vim.notify(output, vim.log.levels.INFO, {
              title = "Function Output",
              timeout = M.config.execution.notification_timeout,
            })
          end
        end
      end,
      on_stderr = function(_, data)
        if data and #data > 1 then
          local output = table.concat(data, "\n")
          if output and output:match("%S") then
            vim.notify(output, vim.log.levels.ERROR, {
              title = "Function Error",
              timeout = M.config.execution.notification_timeout,
            })
          end
        end
      end,
      on_exit = function(_, exit_code)
        if exit_code == 0 then
          vim.notify("Function executed successfully", vim.log.levels.INFO)
        else
          vim.notify("Function execution failed with exit code: " .. exit_code, vim.log.levels.ERROR)
        end
      end,
      stdout_buffered = true,
      stderr_buffered = true,
    })
  end

  -- If there's only one function, run it directly
  if #functions == 1 then
    run_function(functions[1])
    return
  end

  -- Otherwise, show a picker to select the function
  vim.ui.select(functions, {
    prompt = "Select function to run:",
    format_item = function(item)
      return "def " .. item .. "()"
    end,
  }, function(choice)
    if choice then
      run_function(choice)
    end
  end)
end

-- Run current file
function M.run_file()
  local current_file = vim.fn.expand("%:p")
  if current_file and current_file ~= "" then
    vim.notify("Running: " .. vim.fn.expand("%:t"), vim.log.levels.INFO)
    -- Run python on the current file and capture output to notifications
    vim.fn.jobstart(M.config.execution.run_command .. " " .. vim.fn.shellescape(current_file), {
      on_stdout = function(_, data)
        if data and #data > 1 then
          local output = table.concat(data, "\n")
          if output and output:match("%S") then
            vim.notify(output, vim.log.levels.INFO, {
              title = "Python Output",
              timeout = M.config.execution.notification_timeout,
            })
          end
        end
      end,
      on_stderr = function(_, data)
        if data and #data > 1 then
          local output = table.concat(data, "\n")
          if output and output:match("%S") then
            vim.notify(output, vim.log.levels.ERROR, {
              title = "Python Error",
              timeout = M.config.execution.notification_timeout,
            })
          end
        end
      end,
      on_exit = function(_, exit_code)
        if exit_code == 0 then
          vim.notify("Program execution completed successfully", vim.log.levels.INFO, {
            title = "Python Execution",
          })
        else
          vim.notify("Program execution failed with exit code: " .. exit_code, vim.log.levels.ERROR, {
            title = "Python Execution",
          })
        end
      end,
      stdout_buffered = true,
      stderr_buffered = true,
    })
  else
    vim.notify("No file is open", vim.log.levels.WARN)
  end
end

return M
