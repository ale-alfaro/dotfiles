-- uv.nvim - Neovim plugin for uv Python package management integration
-- Author: Ben O'Mahony
-- License: MIT

local utils = require 'custom.python'

-- Command to run selected code
vim.api.nvim_create_user_command('UVRunSelection', function()
  utils.run_python_selection()
end, { range = true })

-- Command to run a specific function
vim.api.nvim_create_user_command('UVRunFunction', function()
  utils.run_python_function()
end, {})

-- Command to run the current file
vim.api.nvim_create_user_command('UVRunFile', function()
  utils.run_file()
end, {})

-- Command to add a package
vim.api.nvim_create_user_command('UVAddPackage', function(opts)
  utils.run_command('uv add ' .. opts.args)
end, { nargs = 1 })

-- Command to remove a package
vim.api.nvim_create_user_command('UVRemovePackage', function(opts)
  utils.run_command('uv remove ' .. opts.args)
end, { nargs = 1 })

local run_diag_opts = {
  nargs = 1,
  desc = 'Run Diagnostics for a UV runned package or workspace',
  complete = function(ArgLead, CmdLine, CursorPos)
    return { 'ruff_check', 'ty_check' }
  end,
}
vim.api.nvim_create_user_command('UVRunDiagnostics', function(opts)
  local tool = opts.args
  if tool then
    utils.run_diagostics_with_tools(tool)
  end
end, run_diag_opts)
