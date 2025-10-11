local wezterm = require("wezterm")

local sessionizer = wezterm.plugin.require("https://github.com/mikkasendke/sessionizer.wezterm")
local history = wezterm.plugin.require("https://github.com/mikkasendke/sessionizer-history")
--[[
--  Define a Schema
   
A schema is a Lua table that defines what appears in your sessionizer menu and how it behaves. It tells the plugin what to display and what to do when an entry was selected.

A schema can contain the following elements:

1. **`options` (Table, Optional):** Controls the appearance and behavior of the menu. These are its fields:

    | Name           | Type      | Default                        | Description                                                                                                                    |
    | -------------- | --------- | ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------ |
    | `title`        | `string`  | `"Sessionizer"`                | The **window** title when the sessionizer is open.                                                                             |
    | `prompt`       | `string`  | `"Select entry: "`             | The prompt text shown in the input area.                                                                                       |
    | `always_fuzzy` | `boolean` | `true`                         | Whether to enable fuzzy finding always or only after typing /.                                                                 |
    | `callback`     | `function`| `sessionizer.DefaultCallback`  | Function called when an entry is selected. Signature: `function(window, pane, id, label)` |

2. **Entries (Array Elements):** Define the items that appear in the menu. These can be a mix of:
    * **String:** Shorthand for `{ label = value, id = value }`.
        ```lua
        "My Workspace"
        ```
    * **Table (Entry):** A table with `label` and `id` fields.
        ```lua
        { label = "WezTerm Config", id = "~/.config/wezterm" }
        ```
    * **Table (Schema):** Another schema table can be nested inside and its entries will be included (its `options` will be ignored though).
    * **Function (Generator):** A function that returns a Schema. For example:
        ```lua
        function exampleGenerator()
            local schema = {}
            for i=1,10 do
                table.insert(schema, { label = "Workspace " .. i, id = "this is workspace " .. i })
            end
            return schema
        end
        -- or this:
        -- sessionizer.AllActiveWorkspaces is a function that returns a generator,
        -- it's useful to provide some options.
        sessionizer.AllActiveWorkspaces { filter_default = true } 

3. **`processing` (Table | Function, Optional):** Function(s) to modify entries before they are used/displayed.
    * Can be a function or table of functions.
    * Each function modifies the `entries` array in-place.
    * Useful for styling, filtering, or formatting entries.

--]]

---Apply plugin to Wezterm config.
---@param config_builder table
---@param plugin_config table|nil
---@return table config_builder the updated config
local function apply_to_config(config_builder, plugin_config)
	plugin_config = plugin_config or {}

	local schema = plugin_config.schema or {
		options = {
			prompt = "Workspace to switch: ",
			callback = history.Wrapper(sessionizer.DefaultCallback),
		},
		sessionizer.DefaultWorkspace({}),
		history.MostRecentWorkspace({}),

		wezterm.home_dir .. "/dotfiles",
		wezterm.home_dir .. "/Documents/Obsidian",

		sessionizer.FdSearch({
			wezterm.home_dir .. "/sibel/eng",
			max_depth = 2,
			include_submodules = true,
		}),
		sessionizer.FdSearch({
			wezterm.home_dir .. "/GeekieStuff",
			max_depth = 2,
			include_submodules = true,
		}),
		processing = sessionizer.for_each_entry(function(entry)
			entry.label = entry.label:gsub(wezterm.home_dir, "~")
		end),
	}

	local smart_workspace_switcher_replica = plugin_config.smart_workspace_switcher_replica or {
		options = {
			prompt = "Workspace to switch: ",
			callback = history.Wrapper(sessionizer.DefaultCallback),
		},
		{
			sessionizer.AllActiveWorkspaces({ filter_current = false, filter_default = false }),
			processing = sessionizer.for_each_entry(function(entry)
				entry.label = wezterm.format({
					{ Text = "󱂬 : " .. entry.label },
				})
			end),
		},
		wezterm.plugin.require("https://github.com/mikkasendke/sessionizer-zoxide.git").Zoxide({}),
		processing = sessionizer.for_each_entry(function(entry)
			entry.label = entry.label:gsub(wezterm.home_dir, "~")
		end),
	}

	local keys = plugin_config.keys or {
		{
			key = "p",
			mods = "LEADER",
			action = sessionizer.show(schema),
		},
		{
			key = "e",
			mods = "LEADER",
			action = sessionizer.show(smart_workspace_switcher_replica),
		},
		{
			key = "m",
			mods = "LEADER",
			action = history.switch_to_most_recent_workspace,
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