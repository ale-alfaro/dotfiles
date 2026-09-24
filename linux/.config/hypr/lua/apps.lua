-- Ported from omarchy default/hypr/apps/*.conf, keeping only the apps I run.
-- Dropped: davinci-resolve, geforce, jetbrains, moonlight, qemu, retroarch,
-- steam, telegram, typora, hyprshot, webcam-overlay.

local h = require("lua.helpers")
local window = h.window

-- Browsers opt out of the blanket opacity and set their own.
window("((google-)?[cC]hrom(e|ium)|[bB]rave-browser|[mM]icrosoft-edge|Vivaldi-stable|helium)", { tag = "+chromium-based-browser" })
window("([fF]irefox|zen|librewolf)", { tag = "+firefox-based-browser" })
window({ tag = "chromium-based-browser" }, { tag = "-default-opacity" })
window({ tag = "firefox-based-browser" }, { tag = "-default-opacity" })
window("(chrome-youtube.com__-Default|chrome-app.zoom.us__wc_home-Default)", { tag = "-chromium-based-browser" })
window("(chrome-youtube.com__-Default|chrome-app.zoom.us__wc_home-Default)", { tag = "-default-opacity" })
window({ tag = "chromium-based-browser" }, { tile = true })
window({ tag = "chromium-based-browser" }, { opacity = "1.0 0.985" })
window({ tag = "firefox-based-browser" }, { opacity = "1.0 0.985" })

-- Hide the screen-sharing indicator.
window({ title = ".*is sharing.*" }, { workspace = "special silent" })

-- Terminals get their own opacity.
window("(Alacritty|kitty|com.mitchellh.ghostty|foot)", { tag = "+terminal" })
window({ tag = "terminal" }, { tag = "-default-opacity" })
window({ tag = "terminal" }, { opacity = "0.985 0.96" })

-- Password managers stay out of screen shares.
window("^(1[pP]assword)$", { no_screen_share = true })
window("^(1[pP]assword)$", { tag = "+floating-window" })
window("^(Bitwarden)$", { no_screen_share = true })
window("^(Bitwarden)$", { tag = "+floating-window" })

-- Generic floating treatment.
window({ tag = "floating-window" }, { float = true })
window({ tag = "floating-window" }, { center = true })
window({ tag = "floating-window" }, { size = { 875, 600 } })
window("(org.omarchy.btop|org.omarchy.terminal|org.omarchy.bash|org.codeberg.dnkl.foot|org.gnome.NautilusPreviewer|org.gnome.Evince|com.gabm.satty|Omarchy|About|TUI.float|imv|mpv)", { tag = "+floating-window" })
window("xdg-desktop-portal-gtk", { tag = "+floating-window" })
window({
  class = "(sublime_text|DesktopEditors|org.gnome.Nautilus)",
  title = "^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files|.*wants to [open|save].*|[Cc]hoose.*)",
}, { tag = "+floating-window" })

-- No transparency on media windows.
local media = "^(zoom|vlc|mpv|org.kde.kdenlive|com.obsproject.Studio|com.github.PintaProject.Pinta|imv|org.gnome.NautilusPreviewer)$"
window(media, { tag = "-default-opacity" })
window(media, { opacity = "1 1" })

-- Picture-in-picture pinned to the top right.
window({ title = "(Picture.?in.?[Pp]icture)" }, { tag = "+pip" })
window({ tag = "pip" }, { tag = "-default-opacity" })
window({ tag = "pip" }, { float = true })
window({ tag = "pip" }, { pin = true })
window({ tag = "pip" }, { size = { 600, 338 } })
window({ tag = "pip" }, { keep_aspect_ratio = true })
window({ tag = "pip" }, { border_size = 0 })
window({ tag = "pip" }, { opacity = "1 1" })
window({ tag = "pip" }, { move = "(monitor_w-window_w-40) (monitor_h*0.04)" })

window({ tag = "pop" }, { rounding = 8 })
window({ tag = "noidle" }, { idle_inhibit = "always" })

hl.layer_rule({ match = { namespace = "walker" }, no_anim = true })
