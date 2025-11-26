---@type Wezterm
local wezterm = require("wezterm")

local M = {}

---@param config Config
function M.apply(config)
	-- Basic settings
	config.default_prog = { "/bin/zsh", "-l" }
	config.automatically_reload_config = true
	config.initial_cols = 160
	config.initial_rows = 35
	config.default_workspace = "dotfiles"
	local home_dir = os.getenv("HOME")
	config.set_environment_variables = {
		ZDOTDIR = home_dir .. "/.config/zsh",
		TERMINAL = "wezterm",
	}
	-- Input method and scrolling
	config.use_ime = true
	config.ime_preedit_rendering = "System"
	config.enable_scroll_bar = false
	config.scrollback_lines = 10000
	config.alternate_buffer_wheel_scroll_speed = 5
	config.hyperlink_rules = M.get_hyperlink_rules()

	config.unix_domains = {
		{
			name = "unix",
		},
	}

	config.default_gui_startup_args = { "connect", "unix" }
	-- Mouse and hyperlink configuration
	config.launch_menu = M.get_launch_menu()
end

function M.get_hyperlink_rules()
	local rules = wezterm.default_hyperlink_rules()
	table.insert(rules, {
		regex = "\\b[A-Z-a-z0-9-_\\.]+@[\\w-]+(\\.[\\w-]+)+\\b",
		format = "mailto:$0",
	})
	table.insert(rules, {
		regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
		format = "https://www.github.com/$1/$3",
	})
	return rules
end

function M.get_launch_menu()
	return {
		{ label = "Activity Monitor", args = { "open", "-a", "Activity Monitor" } },
		{ label = "Disk Utility", args = { "open", "-a", "Disk Utility" } },
	}
end

return M
