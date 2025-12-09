-- uv.nvim - Neovim plugin for uv Python package management integration
-- Author: Ben O'Mahony
-- License: MIT

local M = require 'custom.python.utils'

local prefix = '<leader>u'

-- Set up user commands
function M.setup_commands()
  -- Set up UV commands
  vim.api.nvim_create_user_command('UVInit', function()
    M.run_command 'uv init'
  end, {})

  -- Command to run selected code
  vim.api.nvim_create_user_command('UVRunSelection', function()
    M.run_python_selection()
  end, { range = true })

  -- Command to run a specific function
  vim.api.nvim_create_user_command('UVRunFunction', function()
    M.run_python_function()
  end, {})

  -- Command to run the current file
  vim.api.nvim_create_user_command('UVRunFile', function()
    M.run_file()
  end, {})

  -- Command to add a package
  vim.api.nvim_create_user_command('UVAddPackage', function(opts)
    M.run_command('uv add ' .. opts.args)
  end, { nargs = 1 })

  -- Command to remove a package
  vim.api.nvim_create_user_command('UVRemovePackage', function(opts)
    M.run_command('uv remove ' .. opts.args)
  end, { nargs = 1 })

  vim.api.nvim_create_user_command('UVSync', function(_opts)
    M.run_command 'uv sync'
  end, {})

  vim.api.nvim_create_user_command('UVLock', function(_opts)
    M.run_command 'uv lock'
  end, {})

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
      M.run_diagostics_with_tools(tool)
    end
  end, run_diag_opts)
end

-- Set up keymaps
function M.setup_keymaps()
  -- Initialize UV project

  -- Add a package
  vim.api.nvim_set_keymap(
    'n',
    prefix .. 'a',
    "<cmd>lua vim.ui.input({prompt = 'Enter package name: '}, function(input) if input and input ~= '' then require('uv').run_command('uv add ' .. input) end end)<CR>",
    { noremap = true, silent = true, desc = 'UV Add Package' }
  )

  -- Remove a package
  vim.api.nvim_set_keymap(
    'n',
    prefix .. 'd',
    "<cmd>lua vim.ui.input({prompt = 'Enter package name: '}, function(input) if input and input ~= '' then require('uv').run_command('uv remove ' .. input) end end)<CR>",
    { noremap = true, silent = true, desc = 'UV Remove Package' }
  )

  -- Sync packages
  vim.api.nvim_set_keymap('n', prefix .. 'c', "<cmd>lua require('uv').run_command('uv sync')<CR>", { noremap = true, silent = true, desc = 'UV Sync Packages' })
end

-- Set up auto commands
-- Main setup function
function M.setup()
  -- Merge user configuration with defaults

  -- Make run_command globally accessible (can be removed if not needed)
  M.setup_commands()
  M.setup_keymaps()
end

return M
