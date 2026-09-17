-- Border colors from the active Omarchy theme, so `omarchy-theme-set` keeps
-- working. Drop this file and inline the colors in looknfeel.lua once Omarchy
-- is gone.

local default_active = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 }
local default_inactive = "rgba(595959aa)"

local function read_border_color(path, variable)
  local file = io.open(path, "r")
  if not file then
    return nil
  end

  local color
  for line in file:lines() do
    color = line:match("^%s*%$" .. variable .. "%s*=%s*(.-)%s*$") or color
  end
  file:close()

  -- Only plain single colors are lifted; a themed gradient falls back.
  if color and color:match("^rgba?%([%x]+%)$") then
    return color
  end
end

local theme = (os.getenv("HOME") or "") .. "/.config/omarchy/current/theme/hyprland.conf"

return {
  active = read_border_color(theme, "activeBorderColor") or default_active,
  inactive = read_border_color(theme, "inactiveBorderColor") or default_inactive,
}
