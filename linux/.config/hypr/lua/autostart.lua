local h = require("lua.helpers")
local home = os.getenv("HOME")

h.uwsm_on_start("hyprsunset")
h.uwsm_on_start("mako")
h.uwsm_on_start("fcitx5 --disable notificationitem")
h.uwsm_on_start("swaybg -i " .. home .. "/.config/omarchy/current/background -m fill")
h.uwsm_on_start("swayosd-server")

-- Skipped when the waybar-off toggle is set.
h.on_start("! omarchy-toggle-enabled waybar-off && uwsm-app -- waybar")

h.on_start("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

-- Slow app launch fix -- set systemd vars
h.on_start("systemctl --user import-environment $(env | cut -d'=' -f 1)")
h.on_start("dbus-update-activation-environment --systemd --all")
