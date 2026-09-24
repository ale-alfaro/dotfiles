-- Hyprland Lua config. Hyprland prefers this file over hyprland.conf when it
-- exists, so renaming it to hyprland.lua.off falls straight back to hyprlang.
-- https://wiki.hypr.land/Configuring/Start/

local home = os.getenv("HOME")

-- Modules live in ~/.config/hypr/lua/, required as "lua.<name>".
package.path = home .. "/.config/hypr/?.lua;" .. package.path

local h = require("lua.helpers")

require("lua.env")
require("lua.input")
require("lua.looknfeel")
require("lua.rules")
require("lua.bindings")
require("lua.media")
require("lua.autostart")

-- Machine-specific: present on the laptop, absent on the desktop.
h.optional("lua.hw")

-- Dump the hl API this build actually exposes, so the config can stop guessing.
if os.getenv("HYPR_LUA_PROBE") then
  require("lua.probe")
end
