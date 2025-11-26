---@type Wezterm
local wezterm = require("wezterm")

---@type Config
local config = {}
if wezterm.config_builder then
	config = wezterm.config_builder()
end
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
smart_splits.apply_to_config(config)

-- Sessionizer for project management
local sessionizer = require("plugins.sessionizer.config")
sessionizer.apply_to_config(config)

-- Resurrect for session saving and restoring
local resurrect = require("plugins.resurrect.config")
resurrect.apply_to_config(config)

-- wezterm.log_info("Wezterm keys: " .. config.keys)
return config
