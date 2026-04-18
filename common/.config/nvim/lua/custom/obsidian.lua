local cmds = require("obsidian_cmds")

---@class obsidian.CLI
---@field cmd string
local M = {}
M.__index = M

---@param cmd string Path to the obsidian CLI binary
---@return obsidian.CLI
M.new = function(cmd)
	return setmetatable({ cmd = cmd }, M)
end

---Build the command table for vim.system.
---@param cmd string CLI binary path
---@param command string Full command string (e.g. "property:read")
---@param args string[] Remaining arguments (key=value pairs, bare flags)
---@return string[]
local function build_cmd(cmd, command, args)
	local t = { cmd, command }
	for _, arg in ipairs(args) do
		table.insert(t, arg)
	end
	return t
end

---Run a CLI command asynchronously.
---@param command string Full command string (e.g. "property:read")
---@param args string[] Remaining arguments
---@param callback fun(out: vim.SystemCompleted)
---@return vim.SystemObj
M.run = function(self, command, args, callback)
	local argv = build_cmd(self.cmd, command, args)
	return vim.system(argv, {}, function(out)
		vim.schedule(function()
			callback(out)
		end)
	end)
end

---Run a CLI command synchronously.
---@param command string Full command string (e.g. "property:read")
---@param args string[] Remaining arguments
---@return vim.SystemCompleted
M.run_sync = function(self, command, args)
	local argv = build_cmd(self.cmd, command, args)
	return vim.system(argv, {}):wait()
end

-- ---------------------------------------------------------------------------
-- Command helpers
-- ---------------------------------------------------------------------------

---Extract all top-level command names from obsidian_cmds.supported, sorted.
---@return string[]
local function get_command_names()
	local names = {}
	for k, v in pairs(cmds.supported) do
		if type(k) == "number" then
			table.insert(names, v)
		else
			table.insert(names, k)
		end
	end
	table.sort(names)
	return names
end

---Return the subcommand list for a command, or nil if it has none.
---@param cmd string
---@return string[]|nil
local function get_subcommands(cmd)
	local val = cmds.supported[cmd]
	if type(val) == "table" then
		return val
	end
	return nil
end

---Check whether cmd exists in obsidian_cmds.supported.
---@param cmd string
---@return boolean
local function is_command(cmd)
	-- Check hash keys first
	if cmds.supported[cmd] ~= nil and type(cmds.supported[cmd]) == "table" then
		return true
	end
	-- Check array values
	for _, v in ipairs(cmds.supported) do
		if v == cmd then
			return true
		end
	end
	return false
end

-- ---------------------------------------------------------------------------
-- Completion
-- ---------------------------------------------------------------------------

---Return arg completions for a CLI command, filtering out already-typed args.
---@param cli_cmd string Full CLI command name (e.g. "files" or "property:read")
---@param typed_args string[] Arguments already on the command line
---@param arg_lead string Current partial text being completed
---@return string[]
local function get_arg_completions(cli_cmd, typed_args, arg_lead)
	local available = cmds.args[cli_cmd]
	if not available then
		return {}
	end

	local used = {}
	for _, arg in ipairs(typed_args) do
		local key = arg:match("^([%w_%-]+)")
		if key then
			used[key] = true
		end
	end

	return vim.tbl_filter(function(candidate)
		local key = candidate:match("^([%w_%-]+)")
		if not key or used[key] then
			return false
		end
		return vim.startswith(candidate, arg_lead)
	end, available)
end

---Completion function for the :Obsidian user command.
---@param arg_lead string
---@param cmdline string
---@param cursor_pos number
---@return string[]
local function get_completions(arg_lead, cmdline, cursor_pos)
	local parts = vim.split(cmdline, " ", { plain = true, trimempty = true })
	local trailing_space = cmdline:sub(-1) == " "
	local nparts = #parts

	-- Phase 1: command name
	if nparts == 1 and trailing_space then
		return get_command_names()
	end
	if nparts == 2 and not trailing_space then
		return vim.tbl_filter(function(name)
			return vim.startswith(name, parts[2])
		end, get_command_names())
	end

	local cmd = parts[2]
	if not is_command(cmd) then
		return {}
	end

	local subs = get_subcommands(cmd)

	-- Phase 2: subcommands for commands that have them
	if subs then
		if nparts == 2 and trailing_space then
			return subs
		end
		if nparts == 3 and not trailing_space then
			return vim.tbl_filter(function(s)
				return vim.startswith(s, parts[3])
			end, subs)
		end
		-- Subcommand is complete, offer arg completions
		if nparts >= 3 and vim.tbl_contains(subs, parts[3]) then
			local cli_cmd = cmd .. ":" .. parts[3]
			local typed_args = trailing_space
					and vim.list_slice(parts, 4)
				or vim.list_slice(parts, 4, nparts - 1)
			return get_arg_completions(cli_cmd, typed_args or {}, arg_lead)
		end
		return {}
	end

	-- Phase 3: arg completions for simple commands
	local typed_args = trailing_space
			and vim.list_slice(parts, 3)
		or vim.list_slice(parts, 3, nparts - 1)
	return get_arg_completions(cmd, typed_args or {}, arg_lead)
end

-- ---------------------------------------------------------------------------
-- Dispatch
-- ---------------------------------------------------------------------------

---Handle the :Obsidian user command.
---@param cli obsidian.CLI
---@param data vim.api.keyset.create_user_command.command_args
local function handle_command(cli, data)
	local fargs = data.fargs
	if #fargs == 0 then
		VimRc.info("Usage: :Obsidian <command> [subcommand] [args...]")
		return
	end

	local cmd = fargs[1]
	if not is_command(cmd) then
		VimRc.err("Unknown command: " .. cmd)
		return
	end

	local cmd_name = cmd
	local arg_start = 2

	local subs = get_subcommands(cmd)
	if subs then
		if #fargs < 2 then
			VimRc.err("Command '" .. cmd .. "' requires a subcommand: " .. table.concat(subs, ", "))
			return
		end
		local sub = fargs[2]
		if not vim.tbl_contains(subs, sub) then
			VimRc.err("Invalid subcommand '" .. sub .. "' for '" .. cmd .. "'. Expected: " .. table.concat(subs, ", "))
			return
		end
		cmd_name = cmd .. ":" .. sub
		arg_start = 3
	end

	local remaining_args = vim.list_slice(fargs, arg_start)

	cli:run(cmd_name, remaining_args, function(out)
		if out.code ~= 0 then
			VimRc.err(out.stderr)
			return
		end

		local stdout = vim.trim(out.stdout or "")
		if stdout == "" then
			return
		end

		local lines = vim.split(stdout, "\n", { plain = true })
		if #lines <= 3 then
			VimRc.info(stdout)
		else
			VimRc.show_in_split(lines, "obsidian://" .. cmd_name)
		end
	end)
end

-- ---------------------------------------------------------------------------
-- Setup
-- ---------------------------------------------------------------------------

---@class obsidian.SetupOpts
---@field cmd? string Path to the obsidian CLI binary

---@param opts? obsidian.SetupOpts
M.setup = function(opts)
	opts = opts or {}
	local cmd = opts.cmd or "/home/alealfaro/.local/bin/obsidian"
	local cli = M.new(cmd)

	vim.api.nvim_create_user_command("Obsidian", function(data)
		handle_command(cli, data)
	end, {
		nargs = "*",
		complete = function(arg_lead, cmdline, cursor_pos)
			return get_completions(arg_lead, cmdline, cursor_pos)
		end,
	})
end

return M
