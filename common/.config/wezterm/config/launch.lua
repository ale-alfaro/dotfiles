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

	-- config.unix_domains = {
	-- 	{
	-- 		name = "unix",
	-- 		-- The path to the socket.  If unspecified, a reasonable default
	-- 		-- value will be computed.
	--
	-- 		-- socket_path = "/home/alealfaro/",
	--
	-- 		-- If true, do not attempt to start this server if we try and fail to
	-- 		-- connect to it.
	--
	-- 		no_serve_automatically = false,
	--
	-- 		-- If true, bypass checking for secure ownership of the
	-- 		-- socket_path.  This is not recommended on a multi-user
	-- 		-- system, but is useful for example when running the
	-- 		-- server inside a WSL container but with the socket
	-- 		-- on the host NTFS volume.
	--
	-- 		skip_permissions_check = true,
	-- 	},
	-- }

	-- config.default_gui_startup_args = { "connect", "unix" }
	-- Mouse and hyperlink configuration
	config.mouse_bindings = M.get_mouse_bindings()
	config.hyperlink_rules = M.get_hyperlink_rules()
	config.launch_menu = M.get_launch_menu()
end

function M.get_mouse_bindings()
	local action = wezterm.action
	return {
		{ event = { Down = { streak = 1, button = "Right" } }, mods = "NONE", action = action.PasteFrom("Clipboard") },
		{
			event = { Down = { streak = 1, button = "Left" } },
			mods = "NONE",
			action = action.Multiple({ action.ClearSelection }),
		},
		{ event = { Up = { streak = 1, button = "Left" } }, mods = "NONE", action = action.Nop },
		{
			event = { Up = { streak = 2, button = "Left" } },
			mods = "NONE",
			action = action.Multiple({ action.CopyTo("ClipboardAndPrimarySelection"), action.ClearSelection }),
		},
		{
			event = { Up = { streak = 3, button = "Left" } },
			mods = "NONE",
			action = action.Multiple({ action.CopyTo("ClipboardAndPrimarySelection"), action.ClearSelection }),
		},
		{ event = { Up = { streak = 1, button = "Left" } }, mods = "CMD", action = action.OpenLinkAtMouseCursor },
	}
end

function M.get_hyperlink_rules()
	local rules = wezterm.default_hyperlink_rules()
	table.insert(rules, {
		regex = "\\b[A-Z-a-z0-9-_\\.]+@[\\w-]+(\\.[\\w-]+)+\\b",
		format = "mailto:$0",
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
