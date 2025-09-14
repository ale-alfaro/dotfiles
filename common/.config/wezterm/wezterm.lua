-- Pull in the wezterm API
local wezterm = require("wezterm")

local smart_splits = wezterm.plugin.require("https://github.com/mrjones2014/smart-splits.nvim")
local config = wezterm.config_builder and wezterm.config_builder() or {}
local colors = require("utils.colors")
colors.init()

require("config.appearance").apply(config)
require("config.launch").apply(config)

-- aarch64-apple-darwin - macOS (Apple Silicon)
if wezterm.target_triple == "aarch64-apple-darwin" then
	config.macos_window_background_blur = 30
	-- 	-- Increase this value to make scrolling faster
	config.alternate_buffer_wheel_scroll_speed = 5
	require("config.keybindings").apply(config)

-- x86_64-unknown-linux-gnu - Linux
elseif wezterm.target_triple == "x86_64-unknown-linux-gnu" then
else
	error("Unsupported target triple: " .. wezterm.target_triple)
end
require("config.events").setup()

smart_splits.apply_to_config(config, {
	direction_keys = { "h", "j", "k", "l" },
	-- modifier keys to combine with direction_keys
	modifiers = {
		move = "CTRL", -- modifier to use for pane movement, e.g. CTRL+h to move left
		resize = "CMD", -- modifier to use for pane resize, e.g. META+h to resize to the left
	},
	-- log level to use: info, warn, error
	log_level = "info",
})

return config
