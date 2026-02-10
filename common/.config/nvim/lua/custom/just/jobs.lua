local Job = require 'plenary.job'

local M = {}

---Runs a vim command silently and redraws.
---@param command string Vim command to execute.
local function silentCommand(command)
  vim.api.nvim_command('silent ' .. command)
  -- vim.api.nvim_command(command)
  vim.api.nvim_command 'redraw!'
end

---Reloads the plugin.
local function reloadPlugin()
  require('plenary.reload').reload_module 'just'
end

---Splits a string by a given delimiter.
---@param input string Text to split.
---@param separator string Delimiter at which the splits are made.
---@return table Table of split strings.
local function splitString(input, separator)
  local words = {}
  for word in string.gmatch(input, '([^' .. separator .. ']+)') do
    table.insert(words, word)
  end
  return words
end

---Opens the quickfix window.
---@param filename string Optional name of the error file.
local function openQuickfix(filename)
  if not filename then
    vim.api.nvim_command 'copen'
  else
    -- vim.api.nvim_command("cfile " .. filename)
    M.silentCommand('cfile ' .. filename)
    vim.api.nvim_command 'copen'
  end
end

---Appends items to the quickfix list.
---@param arg any Arguments to add to the quickfix list.
local function appendToQuickfix(arg)
  local item = {
    text = arg,
    -- pattern = vim.opt.errorformat._value,
  }
  vim.fn.setqflist({ item }, 'a')
end
---Removes color codes from a string
---@param lines string String to sanitize.
local function sanitize(lines)
  for i = 1, #lines do
    lines[i] = (lines[i]):gsub(string.char(27) .. '[[0-9;]*m]', '')
  end
end

---Appends @param arg to the file @param file
---@param file string Name of the file.
---@param arg string Contect to append to the file @param file.
local function appendToFile(file, arg)
  local out = io.open(file, 'a')
  if out then
    out:write(arg)
    out:write '\n'
    out:close()
  else
    vim.notify('could not open file: ' .. file)
  end
end

---Clears the content of the file @param file.
---@param file string Path of the file to clear.
local function clearFile(file)
  local out = io.open(file, 'w')
  if out then
    out:write()
  end
end
---Get a list of the just summary (i.e. just recipes)
---@return table|nil List containing just summary
M.justSummary = function()
  -- TODO handle case where no justfile is present
  local justRecipes = Job:new({
    command = 'just',
    args = { '--summary' },
  }):sync()
  if justRecipes then
    VimRc.info(justRecipes)
    return splitString(justRecipes[1], ' ')
  end
end

---Returns a list with the available just recipes.
---@return unknown List of the just recipe names.
M.justList = function()
  local list = Job:new({
    command = 'just',
    args = { '--list' },
  }):sync()
  return list
end

---Runs a just recipe asynchronously.
---@param recipeName any Recipe name to run.
---@param autoStart any Whether the job should ran automatically (default=true)
---@return unknown Job handle
M.justRunAsync = function(recipeName, autoStart)
  if autoStart == nil then
    autoStart = true
  end

  -- TODO make this
  local filename = '/tmp/just_' .. recipeName .. '.txt'

  clearFile(filename)

  local job = Job:new {
    command = 'just',
    args = { recipeName },
    on_stdout = vim.schedule_wrap(function(_, lines)
      appendToFile(filename, lines)
    end),
    on_stderr = vim.schedule_wrap(function(_, lines)
      appendToFile(filename, lines)
    end),
    on_exit = vim.schedule_wrap(function(_, return_val)
      if return_val == 0 then
        print('success: ' .. recipeName)
      else
        print('failed: ' .. recipeName)
        -- TODO make opening quickfix automatically configurable
        openQuickfix(filename)
      end
    end),
  }

  if autoStart then
    job:start()
  end

  return job
end

return M
