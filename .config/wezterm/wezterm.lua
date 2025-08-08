-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

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
-- macos_window_background_blur = 40,
config.macos_window_background_blur = 30
config.window_background_opacity = 1.0
config.window_decorations = "RESIZE"

-- Finally, return the configuration to wezterm:
return config
