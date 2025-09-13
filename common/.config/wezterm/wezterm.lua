-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()
-- aarch64-apple-darwin - macOS (Apple Silicon)
-- x86_64-unknown-linux-gnu - Linux
if wezterm.target_triple == "aarch64-apple-darwin" then
	config.set_environment_variables = {
		-- prepend the path to your utility and include the rest of the PATH
		PATH = "/opt/homebrew/bin:" .. os.getenv("PATH"),
	}
	config.macos_window_background_blur = 30

	config.keys = {
		-- Turn off the default CMD-m Hide action, allowing CMD-m to
		-- be potentially recognized and handled by the tab
		{
			key = "m",
			mods = "CMD",
			action = wezterm.action.DisableDefaultAssignment,
		},
		{
			key = "n",
			mods = "CMD",
			action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
		},
	}
elseif wezterm.target_triple == "x86_64-unknown-linux-gnu" then
	config.set_environment_variables = {
		-- prepend the path to your utility and include the rest of the PATH
		PATH = "/usr/local/bin:" .. os.getenv("PATH"),
	}
else
	error("Unsupported target triple: " .. wezterm.target_triple)
end
--- Spawn a fish shell in login mode
-- config.default_prog = { "/opt/homebrew/bin/nu" }
config.default_prog = { "zsh", "-l" }
-- For example, changing the initial geometry for new windows:
config.initial_cols = 120
config.initial_rows = 28

-- or, changing the font size and color scheme.
config.font_size = 12
config.adjust_window_size_when_changing_font_size = false
-- color_scheme = 'termnial.sexy',
config.color_scheme = "Catppuccin Mocha"
config.enable_tab_bar = false
config.font = wezterm.font("JetBrains Mono")
config.window_background_opacity = 1.0
config.window_decorations = "RESIZE"

-- Finally, return the configuration to wezterm:
return config
