-- Minimal stand-in for Omarchy's `o` helpers. Only what this config uses.

local M = {}

-- Hyprland 0.56 exposes a smaller hl.dsp namespace than newer builds. Anything
-- not confirmed present there goes through hyprctl instead of a native
-- dispatcher. Run `hypr-lua-install.sh --probe` to see what your build exposes.
function M.dispatch(command)
  return hl.dsp.exec_cmd("hyprctl dispatch " .. command)
end

function M.exec(command)
  return hl.dsp.exec_cmd(command)
end

function M.uwsm(command)
  return hl.dsp.exec_cmd("uwsm-app -- " .. command)
end

-- bind("SUPER + C", "Description", action [, opts])
-- action: string (shell command), dispatcher, or Lua function.
function M.bind(keys, description, action, opts)
  opts = opts or {}
  opts.description = description

  if type(action) == "string" then
    action = hl.dsp.exec_cmd(action)
  end

  hl.bind(keys, action, opts)
end

-- window("class-regex" | { class = ..., title = ... }, { float = true, ... })
function M.window(match, rules)
  rules.match = rules.match or {}

  if type(match) == "string" then
    rules.match.class = match
  else
    for key, value in pairs(match) do
      rules.match[key] = value
    end
  end

  hl.window_rule(rules)
end

function M.on_start(command)
  hl.on("hyprland.start", function()
    hl.exec_cmd(command)
  end)
end

function M.uwsm_on_start(command)
  M.on_start("uwsm-app -- " .. command)
end

-- require() a module, tolerating its absence (machine-specific files).
function M.optional(module)
  local ok, err = pcall(require, module)
  if not ok and not tostring(err):match("module '" .. module .. "' not found") then
    error(err)
  end
  return ok
end

return M
