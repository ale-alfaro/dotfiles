local M = {}
---@type Wezterm
local wezterm = require("wezterm")
local action = wezterm.action
-- Workspace management
function M.switch_workspace(window, pane, workspace)
	local current = window:active_workspace()
	if current == workspace then
		return
	end

	window:perform_action(action.SwitchToWorkspace({ name = workspace }), pane)
	wezterm.GLOBAL.previous_workspace = current
end

function M.switch_previous_workspace(window, pane)
	local previous = wezterm.GLOBAL.previous_workspace
	if not previous or previous == window:active_workspace() then
		return
	end
	M.switch_workspace(window, pane, previous)
end

-- Default workspaces configuration
M.config = {
	default = "dotfiles",
	spaces = {
		{
			name = "home",
			path = os.getenv("HOME"),
		},
		-- Add your projects here:
		{
			name = "dotfiles",
			path = os.getenv("HOME") .. "/dotfiles",
		},
		{
			name = "NCS",
			path = os.getenv("HOME") .. "/ncs/sdk/v3.1.0",
			-- tabs = { "frontend", "backend", "docs" }
		},
		{
			name = "zephyrproject",
			path = os.getenv("HOME") .. "/zephyrproject/zephyr",
			-- tabs = { "frontend", "backend", "docs" }
		},
	},
}

function M.add_project_dirs(project_dir)
	-- WezTerm comes with a glob function! Let's use it to get a lua table
	-- containing all subdirectories of your project folder.
	for _, dir in ipairs(wezterm.glob(project_dir .. "/*")) do
		-- ... and add them to the projects table.
		table.insert(M.config.spaces, {
			name = dir:match("([^/]+)$"),
			path = dir,
		})
	end
end

function M.choose_project()
	local choices = {}
	for _, value in ipairs(M.config.spaces) do
		table.insert(choices, { id = value.path, label = value.name })
	end
	return action.InputSelector({
		action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
			if not id and not label then
				wezterm.log_info("cancelled")
			else
				wezterm.log_info("id = " .. id)
				wezterm.log_info("label = " .. label)
				inner_window:perform_action(
					action.SwitchToWorkspace({
						name = label,
						spawn = {
							label = "Workspace: " .. label,
							cwd = id,
						},
					}),
					inner_pane
				)
			end
		end),
		title = "Choose Workspace",
		choices = choices,
		fuzzy = true,
		fuzzy_description = "Fuzzy find and/or make a workspace",
	})
end

function M.show_workspace_launcher()
	M.choose_project()
	-- local windows = wezterm.mux.all_windows()
	-- if not window then
	-- 	return
	-- end
	-- local pane = window:active_pane()
	-- if not pane then
	-- 	return
	-- end
	-- window:perform_action(M.choose_project(), pane)
end

return M
