-- resurrect.wezterm configuration and settings
--
-- This module:
-- * Configures the resurrect.wezterm plugin
-- * Configures event listener configuration (via an additional required file)
-- * Returns wezterm keybinding configuration for resurrect-related actions.
--
-- The main wezterm configuration is then responsible for merging the
-- keybindings with other keybindings, or setting up its own.

local wezterm = require("wezterm")
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

require("plugins.resurrect.events")

---Apply plugin to Wezterm config.
---@param config_builder table
---@param plugin_config table|nil
---@return table config_builder the updated config
local function apply_to_config(config_builder, plugin_config)
	plugin_config = plugin_config or {}

	-- resurrect.wezterm encryption
	-- If you do, ensure you have the age tool installed, you have created an
	-- encryption key at ~/.config/age/wezterm-resurrect.txt, and that you supply
	-- the associated public_key below
	-- resurrect.set_encryption({
	-- 	enable = true,
	-- 	method = "age",
	-- 	private_key = wezterm.home_dir .. "/.config/age/wezterm-resurrect.txt",
	-- 	public_key = "THE-PUBLIC-KEY-VALUE-GOES-HERE",
	-- })
	if plugin_config.encryption then
		resurrect.set_encryption(plugin_config.encryption)
	end

	-- resurrect.wezterm periodic save every 15 minutes
	resurrect.state_manager.periodic_save(plugin_config.periodic_save or {
		interval_seconds = 900,
		save_tabs = true,
		save_windows = true,
		save_workspaces = true,
	})

	-- Save only 5000 lines per pane
	resurrect.state_manager.set_max_nlines(plugin_config.max_nlines or 5000)

	local keys = {
		{
			key = "s",
			mods = "LEADER",
			action = wezterm.action_callback(function(win, pane)
				resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
				resurrect.window_state.save_window_action()
			end),
		},
		{
			key = "l",
			mods = "LEADER",
			action = wezterm.action_callback(function(win, pane)
				resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, label)
					local type = string.match(id, "^([^/]+)") -- match before '/'
					id = string.match(id, "([^/]+)$") -- match after '/'
					id = string.match(id, "(.+)%..+$") -- remove file extention
					local opts = {
						relative = true,
						restore_text = true,
						on_pane_restore = resurrect.tab_state.default_on_pane_restore,
					}
					if type == "workspace" then
						local state = resurrect.state_manager.load_state(id, "workspace")
						resurrect.workspace_state.restore_workspace(state, opts)
					elseif type == "window" then
						local state = resurrect.state_manager.load_state(id, "window")
						resurrect.window_state.restore_window(pane:window(), state, opts)
					elseif type == "tab" then
						local state = resurrect.state_manager.load_state(id, "tab")
						resurrect.tab_state.restore_tab(pane:tab(), state, opts)
					end
				end)
			end),
		},
	}

	if config_builder.keys == nil then
		config_builder.keys = keys
	else
		for _, keymap in ipairs(keys) do
			table.insert(config_builder.keys, keymap)
		end
	end
	return config_builder
end

return {
	apply_to_config = apply_to_config,
}