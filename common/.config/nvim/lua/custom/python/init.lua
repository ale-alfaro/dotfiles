-- uv.nvim - Neovim plugin for uv Python package management integration
-- Author: Ben O'Mahony
-- License: MIT

local M = require('custom.python.utils')

local prefix = "<leader>x"

-- Set up command pickers for integration with UI plugins
function M.setup_pickers()
  -- Check if Snacks is available
  if _G.Snacks and _G.Snacks.picker then
    -- Register UV command source
    Snacks.picker.sources.uv_commands = {
      finder = function()
        return {
          { text = "Run current file", desc = "Run current file with Python", is_run_current = true },
          { text = "Run selection",    desc = "Run selected Python code",     is_run_selection = true },
          { text = "Run function",     desc = "Run specific Python function", is_run_function = true },
          { text = "uv add [package]", desc = "Install a package" },
          { text = "uv sync",          desc = "Sync packages from lockfile" },
          {
            text = "uv sync --all-extras --all-packages --all-groups",
            desc = "Sync all extras, groups and packages",
          },
          { text = "uv remove [package]", desc = "Remove a package" },
          { text = "uv init",             desc = "Initialize a new project" },
        }
      end,
      format = function(item)
        return { { item.text .. " - " .. item.desc } }
      end,
      confirm = function(picker, item)
        if item then
          picker:close()
          if item.is_run_current then
            M.run_file()
            return
          elseif item.is_run_selection then
            -- Check if there's a visual selection
            local mode = vim.fn.mode()

            if mode == "v" or mode == "V" or mode == "" then
              vim.cmd("normal! \27") -- Exit visual mode
              vim.defer_fn(function()
                M.run_python_selection()
              end, 100)
            else
              -- If not in visual mode, prompt the user to select text
              vim.notify(
                "Please select text first. Enter visual mode (v) and select code to run.",
                vim.log.levels.INFO
              )
              -- After notification, we'll set up a one-time autocmd to catch when visual mode is exited
              vim.api.nvim_create_autocmd("ModeChanged", {
                pattern = "[vV\x16]*:n", -- When changing from any visual mode to normal mode
                callback = function(ev)
                  M.run_python_selection()
                  return true -- Delete the autocmd after it's been triggered
                end,
                once = true,
              })
            end
            return
          elseif item.is_run_function then
            M.run_python_function()
            return
          end

          local cmd = item.text
          -- Check if command needs input
          if cmd:match("%[(.-)%]") then
            local param_name = cmd:match("%[(.-)%]")
            vim.ui.input({ prompt = "Enter " .. param_name .. ": " }, function(input)
              if not input or input == "" then
                vim.notify("Cancelled", vim.log.levels.INFO)
                return
              end
              -- Replace the placeholder with actual input
              local actual_cmd = cmd:gsub("%[" .. param_name .. "%]", input)
              M.run_command(actual_cmd)
            end)
          else
            -- Run the command directly
            M.run_command(cmd)
          end
        end
      end,
    }

    -- Snacks.picker.sources.uv_tools = {
    --
    --   finder = function()
    --     return require('custom.python.uv_tools').registered_tools
    --   end,
    --   format = 'text',
    --   preview = 'none',
    --   confirm = 'uv_run',
    --   ---@type snacks.picker.Action.fn[]
    --   actions = {
    --
    --     ---@param p snacks.Picker
    --     ---@param item snacks.picker.Item
    --     uv_run = function(p, item)
    --       p:close()
    --       M.uv_run_tool_call(item)
    --     end,
    --   },
    -- }
  end
  vim.api.nvim_set_keymap(
    "n",
    prefix,
    "<cmd>lua Snacks.picker.pick('uv_commands')<CR>",
    { noremap = true, silent = true, desc = "UV Commands" }
  )
  vim.api.nvim_set_keymap(
    "v",
    prefix,
    ":<C-u>lua Snacks.picker.pick('uv_commands')<CR>",
    { noremap = true, silent = true, desc = "UV Commands" }
  )

  vim.api.nvim_set_keymap('n', prefix .. 'r', "<cmd>lua Snacks.picker.pick('uv_tools')<CR>",
    { noremap = true, silent = true, desc = 'UV Pick Tool' })
end

-- Set up user commands
function M.setup_commands()
  -- Set up UV commands
  vim.api.nvim_create_user_command("UVInit", function()
    M.run_command("uv init")
  end, {})

  -- Command to run selected code
  vim.api.nvim_create_user_command("UVRunSelection", function()
    M.run_python_selection()
  end, { range = true })

  -- Command to run a specific function
  vim.api.nvim_create_user_command("UVRunFunction", function()
    M.run_python_function()
  end, {})

  -- Command to run the current file
  vim.api.nvim_create_user_command("UVRunFile", function()
    M.run_file()
  end, {})

  -- Command to add a package
  vim.api.nvim_create_user_command("UVAddPackage", function(opts)
    M.run_command("uv add " .. opts.args)
  end, { nargs = 1 })

  -- Command to remove a package
  vim.api.nvim_create_user_command("UVRemovePackage", function(opts)
    M.run_command("uv remove " .. opts.args)
  end, { nargs = 1 })

  vim.api.nvim_create_user_command('UVSync', function(_opts)
    M.run_command 'uv sync'
  end, {})

  vim.api.nvim_create_user_command('UVLock', function(_opts)
    M.run_command 'uv lock'
  end, {})

  local run_diag_opts = {
    nargs = 1,
    desc = "Run Diagnostics for a UV runned package or workspace",
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
  -- Run current file
  -- if keymaps.run_file then
  --   vim.api.nvim_set_keymap(
  --     "n",
  --     prefix .. "r",
  --     "<cmd>UVRunFile<CR>",
  --     { noremap = true, silent = true, desc = "UV Run Current File" }
  --   )
  -- end
  --
  -- -- Run selection
  -- if keymaps.run_selection then
  --   vim.api.nvim_set_keymap(
  --     "v",
  --     prefix .. "s",
  --     ":<C-u>UVRunSelection<CR>",
  --     { noremap = true, silent = true, desc = "UV Run Selection" }
  --   )
  -- end
  --
  -- -- Run function
  -- if keymaps.run_function then
  --   vim.api.nvim_set_keymap(
  --     "n",
  --     prefix .. "f",
  --     "<cmd>UVRunFunction<CR>",
  --     { noremap = true, silent = true, desc = "UV Run Function" }
  --   )
  -- end

  -- Environment management
  -- if keymaps.venv then
  --   if _G.Snacks and _G.Snacks.picker then
  --     vim.api.nvim_set_keymap(
  --       "n",
  --       prefix .. "e",
  --       "<cmd>lua Snacks.picker.pick('uv_venv')<CR>",
  --       { noremap = true, silent = true, desc = "UV Environment" }
  --     )
  --   end
  --   local has_telescope_venv = pcall(require, "telescope")
  --   if has_telescope_venv then
  --     vim.api.nvim_set_keymap(
  --       "n",
  --       prefix .. "e",
  --       "<cmd>lua require('uv').pick_uv_venv()<CR>",
  --       { noremap = true, silent = true, desc = "UV Environment (Telescope)" }
  --     )
  --   end
  -- end

  -- Initialize UV project

  -- Add a package
  vim.api.nvim_set_keymap(
    "n",
    prefix .. "a",
    "<cmd>lua vim.ui.input({prompt = 'Enter package name: '}, function(input) if input and input ~= '' then require('uv').run_command('uv add ' .. input) end end)<CR>",
    { noremap = true, silent = true, desc = "UV Add Package" }
  )

  -- Remove a package
  vim.api.nvim_set_keymap(
    "n",
    prefix .. "d",
    "<cmd>lua vim.ui.input({prompt = 'Enter package name: '}, function(input) if input and input ~= '' then require('uv').run_command('uv remove ' .. input) end end)<CR>",
    { noremap = true, silent = true, desc = "UV Remove Package" }
  )

  -- Sync packages
  vim.api.nvim_set_keymap(
    "n",
    prefix .. "c",
    "<cmd>lua require('uv').run_command('uv sync')<CR>",
    { noremap = true, silent = true, desc = "UV Sync Packages" }
  )
end

-- Set up auto commands
function M.setup_autocommands()
  -- Auto-activate .venv if it exists
  if M.config.auto_activate_venv then
    M.auto_activate_venv()

    -- Also set up auto-command to check when entering a directory
    vim.api.nvim_create_autocmd({ "DirChanged" }, {
      pattern = { "global" },
      callback = function()
        M.auto_activate_venv()
      end,
    })
  end
end

-- Main setup function
function M.setup()
  -- Merge user configuration with defaults

  -- Make run_command globally accessible (can be removed if not needed)
  M.setup_commands()
  M.setup_keymaps()
  M.setup_autocommands()
  M.setup_pickers()
end

return M
