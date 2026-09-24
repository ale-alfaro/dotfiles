-- Dump the hl API this Hyprland build actually exposes, so the config can stop
-- inferring it from binary strings. Enabled by HYPR_LUA_PROBE=1.
--
-- Everything reached through helpers.dispatch() is a candidate for a native
-- dispatcher once it shows up here.

local out = io.open((os.getenv("HOME") or "/tmp") .. "/.cache/hypr-lua-api.txt", "w")
if not out then
  return
end

local function dump(prefix, table_value, depth)
  local keys = {}
  for key in pairs(table_value) do
    keys[#keys + 1] = tostring(key)
  end
  table.sort(keys)

  for _, key in ipairs(keys) do
    local value = table_value[key]
    out:write(prefix .. key .. "\t" .. type(value) .. "\n")
    if type(value) == "table" and depth > 0 then
      dump(prefix .. key .. ".", value, depth - 1)
    end
  end
end

out:write("hyprland lua api\n\n")
dump("hl.", hl, 3)
out:close()
