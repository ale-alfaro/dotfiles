---@type Wezterm
local wezterm = require("wezterm")

---@type Config
local config = wezterm.config_builder and wezterm.config_builder() or {}
local colors = require("utils.colors")
colors.init()

require("config.appearance").apply(config)
require("config.launch").apply(config)
local alt_modifier
-- aarch64-apple-darwin - macOS (Apple Silicon)
if wezterm.target_triple == "aarch64-apple-darwin" then
	config.macos_window_background_blur = 30
	alt_modifier = "CMD"
-- x86_64-unknown-linux-gnu - Linux
elseif wezterm.target_triple == "x86_64-unknown-linux-gnu" then
	config.enable_wayland = false
	alt_modifier = "ALT"
else
	error("Unsupported target triple: " .. wezterm.target_triple)
end
require("config.events").setup()

require("config.keybindings").apply(config, alt_modifier)

-- Plugins:
-- Smart-splits for beter navigation in Wezterm and Neovim
local smart_splits = require("plugins.smart-splits")
smart_splits.apply_to_config(config, {
	direction_keys = { "h", "j", "k", "l" },
	-- modifier keys to combine with direction_keys
	modifiers = {
		move = "CTRL", -- modifier to use for pane movement, e.g. CTRL+h to move left
		resize = alt_modifier, -- modifier to use for pane resize, e.g. META+h to resize to the left
	},
	-- log level to use: info, warn, error
	log_level = "info",
})
local resurrect = require("plugins.resurrect.config")
config.keys = require("utils.functions").merge_all(config.keys, resurrect.keys)

return config
