local h = require("lua.helpers")
local bind = h.bind
local home = os.getenv("HOME")

local webapp = home .. "/dotfiles/linux/bin/dots-launch-webapp"
local floatterm = home .. "/dotfiles/linux/bin/floatterm"

-- Essential apps
bind("SUPER + RETURN", "Terminal", h.uwsm('xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)"'))
bind("SUPER + SHIFT + RETURN", "Term (sesh picker)", h.uwsm('xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)" zsh -c "mise exec -- sesh picker -i"'))
bind("SUPER + F", "File manager (cwd)", h.uwsm('nautilus --new-window "$(omarchy-cmd-terminal-cwd)"'))
bind("SUPER + Z", "Zen-Browser", "omarchy-launch-or-focus zen")
bind("SUPER + A", "Activity", "omarchy-launch-tui btop")
bind("SUPER + O", "Obsidian", 'omarchy-launch-or-focus ^obsidian$ "uwsm-app -- obsidian -disable-gpu --enable-wayland-ime"')
bind("SUPER + SLASH", "Passwords", h.uwsm("bitwarden-desktop"))
bind("SUPER + B", "Browser", "omarchy-launch-browser")
bind("SUPER + E", "Editor", "omarchy-launch-editor")

-- Web apps (parses the firefoxpwa profile list, so somewhat fragile)
bind("SUPER + M", "Meeting Calendar", webapp .. ' "Google Calendar"')
bind("SUPER + Y", "YouTube", webapp .. ' "YouTube"')
bind("SUPER + G", "Github", webapp .. ' "Github"')

-- TUIs
bind("SUPER + C", "Calc (python)", floatterm .. ' "mise exec -- ptpython"')

-- Menus
bind("SUPER + SPACE", "Launch apps", 'walker -p "Start…"')
bind("SUPER + SHIFT + SPACE", "Omarchy menu", "omarchy-menu")
bind("SUPER + ESCAPE", "Power menu", "omarchy-menu system")
bind("SUPER + K", "Show key bindings", "omarchy-menu-keybindings")
bind("SUPER + CTRL + E", "Emoji picker", "omarchy-launch-walker -m symbols")
bind("SUPER + CTRL + C", "Capture menu", "omarchy-menu capture")
bind("SUPER + CTRL + O", "Toggle menu", "omarchy-menu toggle")

-- Media control panels
bind("SUPER + CTRL + A", "Audio controls", "omarchy-launch-audio")
bind("SUPER + CTRL + B", "Bluetooth controls", "omarchy-launch-bluetooth")
bind("SUPER + CTRL + W", "Wifi controls", "omarchy-launch-wifi")

-- Top bar and themes
bind("SUPER + ALT + SPACE", "Toggle top bar", "omarchy-toggle-waybar")
bind("SUPER + CTRL + SPACE", "Theme background menu", "omarchy-menu background")
bind("SUPER + SHIFT + CTRL + SPACE", "Theme menu", "omarchy-menu theme")

-- Window effects
bind("SUPER + BACKSPACE", "Toggle window transparency", "omarchy-hyprland-active-window-transparency-toggle")
bind("SUPER + SHIFT + BACKSPACE", "Toggle window gaps", "omarchy-hyprland-window-gaps-toggle")
bind("SUPER + CTRL + BACKSPACE", "Toggle single-window square aspect", "omarchy-hyprland-window-single-square-aspect-toggle")

-- Notifications
bind("SUPER + COMMA", "Dismiss last notification", "makoctl dismiss")
bind("SUPER + SHIFT + COMMA", "Dismiss all notifications", "makoctl dismiss --all")
bind("SUPER + CTRL + COMMA", "Toggle silencing notifications", "omarchy-toggle-notification-silencing")
bind("SUPER + ALT + COMMA", "Invoke last notification", "makoctl invoke")
bind("SUPER + SHIFT + ALT + COMMA", "Restore last notification", "makoctl restore")

-- Toggles
bind("SUPER + CTRL + I", "Toggle locking on idle", "omarchy-toggle-idle")
bind("SUPER + CTRL + N", "Toggle nightlight", "omarchy-toggle-nightlight")
bind("SUPER + CTRL + Delete", "Toggle laptop display", "omarchy-hyprland-monitor-internal toggle")
bind("SUPER + CTRL + ALT + Delete", "Toggle laptop display mirroring", "omarchy-hyprland-monitor-internal-mirror toggle")

bind("switch:on:Lid Switch", nil, "omarchy-hw-external-monitors && omarchy-hyprland-monitor-internal off", { locked = true })
bind("switch:off:Lid Switch", nil, "omarchy-hyprland-monitor-internal on", { locked = true })

-- Screenshots and screen recording
bind("SUPER + R", "Screenrecording", "omarchy-menu screenrecord")
bind("SUPER + SHIFT + S", "Screenshot to clipboard", "omarchy-capture-screenshot")
bind("SUPER + PRINT", "Color picker", "pkill hyprpicker || hyprpicker -a")
bind("SUPER + ALT + O", "Extract text (OCR) from screenshot", "omarchy-capture-text-extraction")
bind("SUPER + SHIFT + O", "OCR Screenshot", home .. "/dotfiles/linux/bin/better-screenshot region ocr")

-- File sharing
bind("SUPER + SHIFT + L", "Share", "omarchy-menu share")

-- Waybar-less information
bind("SUPER + CTRL + ALT + T", "Show time", 'notify-send "    $(date +\\"%A %H:%M  —  %d %B W%V %Y\\")"')
bind("SUPER + CTRL + ALT + B", "Show battery remaining", 'notify-send "󰁹    Battery is at $(omarchy-battery-remaining)%"')

-- Dictation
bind("SUPER + D", "Start dictation", "voxtype record toggle")

-- Zoom
bind("SUPER + CTRL + Z", "Zoom in", "hyprctl keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '.float + 1')")
bind("SUPER + CTRL + ALT + Z", "Reset zoom", "hyprctl keyword cursor:zoom_factor 1")

-- Universal clipboard. Same dispatcher hyprlang used, so semantics are identical.
bind("SUPER + C", "Universal copy", h.dispatch("sendshortcut CTRL,Insert,"))
bind("SUPER + V", "Universal paste", h.dispatch("sendshortcut SHIFT,Insert,"))
bind("SUPER + X", "Universal cut", h.dispatch("sendshortcut CTRL,X,"))
bind("SUPER + SHIFT + V", "View Clipboard History", "omarchy-launch-walker -m clipboard")

-- Tiling
bind("SUPER + LEFT", "Move window focus left", hl.dsp.focus({ direction = "l" }))
bind("SUPER + RIGHT", "Move window focus right", hl.dsp.focus({ direction = "r" }))
bind("SUPER + UP", "Move window focus up", hl.dsp.focus({ direction = "u" }))
bind("SUPER + DOWN", "Move window focus down", hl.dsp.focus({ direction = "d" }))

bind("SUPER + W", "Close active window", hl.dsp.window.close())
bind("CTRL + ALT + DELETE", "Close all Windows", "omarchy-cmd-close-all-windows")

bind("SUPER + TAB", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
bind("SUPER + SHIFT + TAB", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
bind("ALT + TAB", "Cycle to next window", h.dispatch("cyclenext"))
bind("ALT + TAB", "Reveal active window on top", h.dispatch("bringactivetotop"))
bind("ALT + SHIFT + TAB", "Cycle to prev window", h.dispatch("cyclenext prev"))
bind("ALT + SHIFT + TAB", "Reveal active window on top", h.dispatch("bringactivetotop"))

-- Resize
bind("SUPER + minus", "Expand window left", hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
bind("SUPER + equal", "Shrink window left", hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
bind("SUPER + SHIFT + minus", "Shrink window up", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
bind("SUPER + SHIFT + equal", "Expand window down", hl.dsp.window.resize({ x = 0, y = 100, relative = true }))

-- Mouse tiling
bind("SUPER + mouse_down", "Scroll active workspace forward", hl.dsp.focus({ workspace = "e+1" }))
bind("SUPER + mouse_up", "Scroll active workspace backward", hl.dsp.focus({ workspace = "e-1" }))
bind("SUPER + mouse:272", "Move window", hl.dsp.window.drag(), { mouse = true })
bind("SUPER + mouse:273", "Resize window", hl.dsp.window.resize(), { mouse = true })

bind("SUPER + ALT + V", "Toggle floating", hl.dsp.window.float({ action = "toggle" }))

bind("SUPER + SHIFT + LEFT", "Swap window to the left", h.dispatch("swapwindow l"))
bind("SUPER + SHIFT + RIGHT", "Swap window to the right", h.dispatch("swapwindow r"))
bind("SUPER + SHIFT + UP", "Swap window up", h.dispatch("swapwindow u"))
bind("SUPER + SHIFT + DOWN", "Swap window down", h.dispatch("swapwindow d"))

-- Workspaces 1-5 live on the left monitor, 6-8 on the right.
-- code:10 is the "1" key, so workspace N is code:(N+9).
local workspace_monitor = { "l", "l", "l", "l", "l", "r", "r", "r" }

for workspace, monitor in ipairs(workspace_monitor) do
  local key = "code:" .. tostring(workspace + 9)

  bind("SUPER + " .. key, "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
  bind("SUPER + " .. key, "Focus monitor of workspace " .. workspace, h.dispatch("focusmonitor " .. monitor))

  bind("SUPER + SHIFT + " .. key, "Move window to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace) }))
  bind("SUPER + SHIFT + " .. key, "Move window to monitor of workspace " .. workspace, h.dispatch("movewindow " .. monitor))
end
