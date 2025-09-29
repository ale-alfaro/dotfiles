---@type Wezterm
local wezterm = require("wezterm")

---@type Action
local action = wezterm.action
local functions = require("utils.functions")
local colors = require("utils.colors")
local projects = require("utils.workspaces")

local M = {}

-- Configuration
local TIMEOUT = { key = 3000, leader = 1500 }

---@param config table
---@param alt_modifier string
function M.apply(config, alt_modifier)
	config.disable_default_key_bindings = true
	config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = TIMEOUT.leader }

	config.keys = M.get_keys(alt_modifier)
	config.key_tables = M.get_key_tables()
end

---@param alt_modifier string
---@return table
function M.get_keys(alt_modifier)
	local keys = {
		-- Key table modes
		{ key = "o", mods = "LEADER", action = M.activate_table("open") },
		{ key = "y", mods = "LEADER", action = M.activate_table("copy") },
		{ key = "m", mods = "LEADER", action = M.activate_table("muxer") },

		-- Clipboard
		{ key = "v", mods = alt_modifier, action = action.PasteFrom("Clipboard") },

		{
			key = "c",
			mods = alt_modifier,
			action = action.CopyTo("Clipboard"),
		},

		-- Tab management
		{ key = "n", mods = alt_modifier .. "|SHIFT", action = action.SpawnTab("DefaultDomain") },
		{ key = "w", mods = alt_modifier, action = action.CloseCurrentPane({ confirm = false }) },
		{ key = "w", mods = alt_modifier .. "|SHIFT", action = action.CloseCurrentTab({ confirm = false }) },
		{ key = "t", mods = "LEADER", action = action.ShowLauncherArgs({ flags = "TABS" }) },

		-- Workspace
		{
			key = "l",
			mods = "LEADER",
			action = wezterm.action_callback(function(window, pane)
				functions.switch_previous_workspace(window, pane)
				window:perform_action(action.EmitEvent("set-previous-workspace"), pane)
			end),
		},
		{
			key = "s",
			mods = "LEADER",
			action = action.Multiple({
				action.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }),
				action.EmitEvent("set-previous-workspace"),
			}),
		},

		-- Pane operations
		{ key = "s", mods = alt_modifier, action = action.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ key = "n", mods = alt_modifier, action = action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ key = "z", mods = "LEADER", action = action.TogglePaneZoomState },

		-- Vim-style scrolling
		{ key = "u", mods = "OPT", action = action.ScrollByPage(-0.5) }, -- Scroll up half page
		{ key = "d", mods = "OPT", action = action.ScrollByPage(1.5) }, -- Scroll down half page
		{ key = "b", mods = "OPT", action = action.ScrollByPage(-1) }, -- Scroll up full page
		{ key = "f", mods = "OPT", action = action.ScrollByPage(1) }, -- Scroll down full page
		{ key = "g", mods = "OPT", action = action.ScrollToTop }, -- Jump to top
		{ key = "g", mods = "OPT|SHIFT", action = action.ScrollToBottom }, -- Jump to bottom

		-- Font size
		{ key = "0", mods = alt_modifier, action = action.ResetFontSize },
		{ key = "-", mods = alt_modifier, action = action.DecreaseFontSize },
		{ key = "=", mods = alt_modifier, action = action.IncreaseFontSize },

		-- Workspace navigation
		{
			key = "[",
			mods = "LEADER",
			action = action.Multiple({
				action.SwitchWorkspaceRelative(-1),
				action.EmitEvent("set-previous-workspace"),
			}),
		},
		{
			key = "]",
			mods = "LEADER",
			action = action.Multiple({
				action.SwitchWorkspaceRelative(1),
				action.EmitEvent("set-previous-workspace"),
			}),
		},
		{
			key = "p",
			mods = "LEADER",
			-- Present in to our project picker
			action = projects.choose_project(),
		},
		{
			key = "f",
			mods = "LEADER",
			-- Present a list of existing workspaces
			action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }),
		},

		-- Utility
		{ key = "/", mods = alt_modifier, action = action.Search({ CaseInSensitiveString = "" }) },
		{ key = "c", mods = "LEADER", action = action.ShowLauncherArgs({ flags = "FUZZY|LAUNCH_MENU_ITEMS" }) },
		{ key = "d", mods = "LEADER|SHIFT", action = action.ShowDebugOverlay },
		{ key = "p", mods = alt_modifier, action = action.ActivateCommandPalette },
		{ key = "v", mods = "LEADER", action = action.ActivateCopyMode },

		-- Rename
		{ key = "r", mods = "LEADER", action = M.rename_workspace_prompt() },

		-- Help
		{
			key = "h",
			mods = "LEADER",
			action = wezterm.action_callback(function(window, pane)
				local home = os.getenv("HOME")
				local cheatsheets_dir = home .. "/.config/wezterm/cheatsheets"

				local choices = {}
				local handle = io.popen("ls -1 " .. cheatsheets_dir .. " 2>/dev/null")
				if handle then
					for file in handle:lines() do
						table.insert(choices, {
							label = file,
							id = file,
						})
					end
					handle:close()
				end

				window:perform_action(
					wezterm.action.InputSelector({
						title = "Select Cheatsheet",
						choices = choices,
						fuzzy = true,
						action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
							if id then
								inner_window:perform_action(
									wezterm.action.SpawnCommandInNewWindow({
										args = {
											"zsh",
											"-lc",
											"bat --paging=always ~/.config/wezterm/cheatsheets/" .. id,
										},
									}),
									inner_pane
								)
							end
						end),
					}),
					pane
				)
			end),
		},
	}

	-- Number keys for tab activation
	for i = 1, 9 do
		table.insert(keys, { key = tostring(i), mods = alt_modifier, action = action.ActivateTab(i - 1) })
	end

	return keys
end

function M.get_key_tables()
	return {
		copy = {
			{ key = "b", action = action.EmitEvent("copy-buffer-from-pane") },
			{ key = "p", action = action.EmitEvent("copy-text-from-pane") },
			{ key = "l", action = M.copy_line_action() },
			{ key = "r", action = M.copy_regex_action() },
		},
		open = {
			{ key = "c", action = M.spawn_command("VS Code", { "zsh", "-lc", "code ." }) },
			{ key = "u", action = M.open_url_action() },
		},
		muxer = {

			{
				key = "a",
				action = action.AttachDomain("unix"),
			},

			-- Detach from muxer
			{
				key = "d",
				action = action.DetachDomain({ DomainName = "unix" }),
			},

			{
				key = "$",
				mods = "SHIFT",
				action = action.PromptInputLine({
					description = "Enter new name for session",
					action = wezterm.action_callback(function(window, pane, line)
						if line then
							wezterm.mux.rename_workspace(window:mux_window():get_workspace(), line)
						end
					end),
				}),
			},
		},
	}
end

-- Helper functions
function M.activate_table(name)
	return action.ActivateKeyTable({
		name = name,
		one_shot = false,
		until_unknown = name ~= "move",
		timeout_milliseconds = TIMEOUT.key,
	})
end

function M.spawn_command(label, args)
	return action.SpawnCommandInNewWindow({ label = label, args = args })
end

function M.copy_line_action()
	return action.QuickSelectArgs({
		label = "COPY LINE",
		patterns = { "^.*\\S+.*$" },
		scope_lines = 1,
		action = action.Multiple({
			action.CopyTo("ClipboardAndPrimarySelection"),
			action.ClearSelection,
		}),
	})
end

function M.copy_regex_action()
	return action.QuickSelectArgs({
		label = "COPY REGEX",
		patterns = {
			"(\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}(?:/\\d{1,2})?)",
			"((?:[[:xdigit:]]{0,4}:){2,7}[[:xdigit:]]{0,4}(?:/\\d{1,3})?)",
			"[[:xdigit:]]{2}:[[:xdigit:]]{2}:[[:xdigit:]]{2}:[[:xdigit:]]{2}:[[:xdigit:]]{2}:[[:xdigit:]]{2}",
			"\\S+@\\S+\\.\\S+",
			"[[:xdigit:]]{12}",
			"\\S+/\\S+:\\S+",
			"[[:xdigit:]]{7,}",
			"(?:https?|s?ftp)://\\S+",
		},
		action = action.Multiple({
			action.CopyTo("ClipboardAndPrimarySelection"),
			action.ClearSelection,
		}),
	})
end

function M.open_url_action()
	return action.QuickSelectArgs({
		label = "Open URL",
		patterns = { "https?://\\S+" },
		scope_lines = 30,
		action = wezterm.action_callback(function(window, pane)
			local url = window:get_selection_text_for_pane(pane)
			wezterm.open_with(url)
		end),
	})
end

function M.rename_tab_prompt()
	return action.PromptInputLine({
		description = wezterm.format({
			{ Attribute = { Intensity = "Bold" } },
			{ Foreground = { Color = colors.fg() } },
			{ Text = "Rename tab:" },
		}),
		action = wezterm.action_callback(function(window, _, line)
			if line then
				window:active_tab():set_title(line)
			end
		end),
	})
end

function M.rename_workspace_prompt()
	return action.PromptInputLine({
		description = wezterm.format({
			{ Attribute = { Intensity = "Bold" } },
			{ Foreground = { Color = colors.fg() } },
			{ Text = "Rename workspace:" },
		}),
		action = wezterm.action_callback(function(_, _, line)
			if line then
				local mux = wezterm.mux
				mux.rename_workspace(mux.get_active_workspace(), line)
			end
		end),
	})
end

return M
