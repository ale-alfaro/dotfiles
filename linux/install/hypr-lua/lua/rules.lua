-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- Order matters: tag everything, let apps.lua opt out, then apply opacity.

local h = require("lua.helpers")
local window = h.window

window(".*", { suppress_event = "maximize" })
window(".*", { tag = "+default-opacity" })

-- Fix some dragging issues with XWayland.
window({
  class = "^$",
  title = "^$",
  xwayland = true,
  float = true,
  fullscreen = false,
  pin = false,
}, { no_focus = true })

require("lua.apps")

window({ tag = "default-opacity" }, { opacity = "0.97 0.9" })

-- Bitwarden vault login
window({ class = "(chrome-)(.*)", initial_title = "(_crx_)(.*)" }, { center = true, float = true, size = { 500, 600 } })

-- File dialogs
window("xdg-desktop-portal-gtk", { center = true, float = true, size = { 900, 600 } })
window({ class = "zen", title = "(Open|Save) Files" }, { center = true, float = true, size = { 900, 550 } })

-- New mail window
window({ class = "(.*)Thunderbird", title = "^Write(.*)" }, { float = true, size = { 800, 600 } })

-- PWAs
window({ class = "(zen)(.*)", initial_title = "Element" }, { center = true, float = true, size = { 1100, 780 } })

-- Floating terminal from bin/floatterm
window("org.dots.floatterm", { tag = "+floatterm" })
window({ tag = "floatterm" }, { float = true, center = true, size = { 1075, 800 } })

-- LocalSend
window("(Share|localsend)", { float = true, center = true })
