-- Laptop multimedia keys for volume and LCD brightness (with OSD)
local h = require("lua.helpers")
local bind = h.bind

local held = { locked = true, repeating = true }
local once = { locked = true }

bind("XF86AudioRaiseVolume", "Volume up", "omarchy-swayosd-client --output-volume raise", held)
bind("XF86AudioLowerVolume", "Volume down", "omarchy-swayosd-client --output-volume lower", held)
bind("XF86AudioMute", "Mute", "omarchy-swayosd-client --output-volume mute-toggle", held)
bind("XF86AudioMicMute", "Mute microphone", "omarchy-audio-input-mute", held)
bind("XF86MonBrightnessUp", "Brightness up", "omarchy-brightness-display +5%", held)
bind("XF86MonBrightnessDown", "Brightness down", "omarchy-brightness-display 5%-", held)
bind("SHIFT + XF86MonBrightnessUp", "Brightness maximum", "omarchy-brightness-display 100%", held)
bind("SHIFT + XF86MonBrightnessDown", "Brightness minimum", "omarchy-brightness-display 1%", held)
bind("XF86KbdBrightnessUp", "Keyboard brightness up", "omarchy-brightness-keyboard up", held)
bind("XF86KbdBrightnessDown", "Keyboard brightness down", "omarchy-brightness-keyboard down", held)
bind("XF86KbdLightOnOff", "Keyboard backlight cycle", "omarchy-brightness-keyboard cycle", once)
bind("XF86TouchpadToggle", "Toggle touchpad", "omarchy-toggle-touchpad", once)
bind("XF86TouchpadOn", "Enable touchpad", "omarchy-toggle-touchpad on", once)
bind("XF86TouchpadOff", "Disable touchpad", "omarchy-toggle-touchpad off", once)

-- Precise 1% adjustments with Alt
bind("ALT + XF86AudioRaiseVolume", "Volume up precise", "omarchy-swayosd-client --output-volume +1", held)
bind("ALT + XF86AudioLowerVolume", "Volume down precise", "omarchy-swayosd-client --output-volume -1", held)
bind("ALT + XF86MonBrightnessUp", "Brightness up precise", "omarchy-brightness-display +1%", held)
bind("ALT + XF86MonBrightnessDown", "Brightness down precise", "omarchy-brightness-display 1%-", held)

-- Requires playerctl
bind("XF86AudioNext", "Next track", "omarchy-swayosd-client --playerctl next", once)
bind("XF86AudioPause", "Pause", "omarchy-swayosd-client --playerctl play-pause", once)
bind("XF86AudioPlay", "Play", "omarchy-swayosd-client --playerctl play-pause", once)
bind("XF86AudioPrev", "Previous track", "omarchy-swayosd-client --playerctl previous", once)

bind("SUPER + XF86AudioMute", "Switch audio output", "omarchy-audio-output-switch", once)
