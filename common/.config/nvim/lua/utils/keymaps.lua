---@class KeymapSpec
---@field mode? string|string[] The mode(s) for the mapping. Defaults to "n".
---@field lhs string The left-hand side of the mapping.
---@field rhs string|fun()|false The right-hand side. `false` or `nil` will unmap.
---@field opts? vim.keymap.set.Opts Standard options for vim.keymap.set (e.g., { desc = "..." }).
---@field cond? boolean|fun():boolean An optional condition. If false, the keymap is not set.
---@field ft? string|string[] An optional filetype or list of filetypes.

local M = {}
-- Tracks defined keymaps to prevent duplicates.
-- Key is a unique string like "n:<leader>ff".
M.registry = {}

---@param lhs string
---@param mode string
function M.encode(lhs, mode)
  return mode .. ":" .. lhs
end

---@param lhs string
---@param mode? string
function M:have(lhs, mode)
  local check_mode = mode or "n"
  return M.registry[M.encode(lhs, check_mode)] ~= nil
end

--- This extends a deeply nested list with a key in a table
--- that is a dot-separated string.
--- The nested list will be created if it does not exist.
---@generic T
---@param t T[]
---@param key string
---@param values T[]
---@return T[]?
function M.extend(t, key, values)
  local keys = vim.split(key, ".", { plain = true })
  for i = 1, #keys do
    local k = keys[i]
    t[k] = t[k] or {}
    if type(t) ~= "table" then
      return
    end
    t = t[k]
  end
  return vim.list_extend(t, values)
end

---@generic T
---@param list T[]
---@return T[]
function M.dedup(list)
  local ret = {}
  local seen = {}
  for _, v in ipairs(list) do
    if not seen[v] then
      table.insert(ret, v)
      seen[v] = true
    end
  end
  return ret
end

-- Wrapper around vim.keymap.set that will
-- not create a keymap if a keymap already exists.
-- It will also set `silent` to true by default.
function M.safe_keymap_set(mode, lhs, rhs, opts)



  vim.validate("lhs",lhs,  { "string" , "table"}, "Keymap: " .. vim.inspect(lhs) .. " has invalid lhs")
  vim.validate("rhs",rhs, {"function", "string"}, "Keymap: " .. vim.inspect(lhs) .. " has invalid rhs")
  local keys = lhs.lhs or lhs
  opts = opts or {}
  opts.silent = opts.silent ~= false
  if type(mode) == "string" then
    if not M:have(lhs, mode) then
      M.registry[M.encode(lhs, mode)] = true
        vim.keymap.set(mode, lhs, rhs, opts)
    else
      vim.notify("Keymap already defined and was skipped: " .. M.encode(lhs, m), vim.log.levels.WARN)
      return
    end
  elseif type(mode) == "table" and vim.islist(mode) then
    for _, m in ipairs(mode) do
      if not M:have(lhs, m) then
        M.registry[M.encode(lhs, m)] = true
        vim.keymap.set(m, lhs, rhs, opts)
      else
        vim.notify("Keymap already defined and was skipped: " .. M.encode(lhs, m), vim.log.levels.WARN)
        return
      end
    end
  else
    _G.Utils.notify.error("Mode for keymap is incorrect" .. mode .. " lhs: " .. lhs .. " rhs: " .. rhs)
    return
  end
end

function M.add_ft_keymaps(keys)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = keys.ft,
    callback = function(event)
      if keys.rhs then
        local opts = vim.deepcopy(keys.opts or {})
        opts.buffer = event.buf
        M.safe_keymap_set(keys.mode, keys.lhs, keys.rhs, opts)
      end
    end,
  })
end

--- Defines a list of keymaps, preventing duplicates and handling conditions.
---@param keymaps KeymapSpec[]
function M.define(keymaps)
  for _, spec in ipairs(keymaps) do
    -- Skip if the condition is not met
    if spec.cond == false or (type(spec.cond) == "function" and not spec.cond()) then
      goto continue
    end

    if spec.ft then
      M.add_ft_keymaps(spec)
      goto continue
    end

    local modes = spec.mode or "n"
    if type(modes) == "string" then
      modes = { modes }
    end

    for _, mode in ipairs(modes) do
      local id = M.encode(spec.lhs, mode)
      if M.registry[id] then
        vim.notify("Keymap already defined and was skipped: " .. id, vim.log.levels.WARN)
        goto continue_inner
      end

      if spec.rhs == false or spec.rhs == nil then
        -- Unmap the key
        pcall(vim.keymap.del, mode, spec.lhs)
      else
        -- Set the keymap
        vim.keymap.set(mode, spec.lhs, spec.rhs, spec.opts or {})
      end

      -- Mark this keymap as handled
      M.registry[id] = true
      ::continue_inner::
    end
    ::continue::
  end
end

return M
