local M = {}

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

local other_projects = { wezterm.home_dir, "~/dotfiles", "~/ncs/sdk/v3.1.0", "~/zephyrproject/zephyr" }
local work_project_dir = wezterm.home_dir .. "/sibel"
local personal_project_dir = wezterm.home_dir .. "/GeekieStuff"

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
			name = "NCS v3.1.0",
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
	-- return wezterm.action.InputSelector {
	--   title = "Projects",
	--   choices = choices,
	--   fuzzy = true,
	--   action = wezterm.action_callback(function(child_window, child_pane, id, label)
	--     -- "label" may be empty if nothing was selected. Don't bother doing anything
	--     -- when that happens.
	--     if not label then return end
	--
	--     -- The SwitchToWorkspace action will switch us to a workspace if it already exists,
	--     -- otherwise it will create it for us.
	--     child_window:perform_action(wezterm.action.SwitchToWorkspace {
	--       -- We'll give our new workspace a nice name, like the last path segment
	--       -- of the directory we're opening up.
	--       name = label:match("([^/]+)$"),
	--       -- Here's the meat. We'll spawn a new terminal with the current working
	--       -- directory set to the directory that was picked.
	--       spawn = { cwd = label },
	--     }, child_pane)
	--   end),
	-- }
end

return M
