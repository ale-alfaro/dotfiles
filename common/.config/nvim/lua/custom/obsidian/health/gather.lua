-- Run obsidian CLI + validate notes against canonical sources, returning
-- a struct of issue groups.

---@param rel string  Path relative to the vault.
local function is_note_path(rel)
  local top = rel:match '^([^/]+)/'
  return top and fm_mod.NOTE_TYPES[top] and rel:match '%.md$' ~= nil
end
local function only_notes(list)
  return vim.tbl_filter(is_note_path, list)
end
---@param vault string
---@return table<string, true>?
local function tags(vault)
  return vim.iter(vim.split((vim.system({ 'obsidian', 'tags' }):wait() or {}).stdout or '', '\n', { trimempty = true })):fold({}, function(acc, t)
    acc[t:sub(2)] = true
    return acc
  end)
end

---@param vault string
---@return table<string, true>
local function categories(vault)
  local set = {}
  for _, f in ipairs(vim.fn.glob(vault .. '/_categories/*.md', false, true)) do
    set[vim.fn.fnamemodify(f, ':t:r')] = true
  end
  return set
end

local function readlines(p)
  return vim.fn.filereadable(p) == 1 and vim.fn.readfile(p) or nil
end
--- Obsidian cmd
---@param subcmd string
---@param kwargs? table<string,string>
---@return string[]
local function obs(subcmd, kwargs)
  kwargs = kwargs or {}
  local cmd = { 'obsidian', subcmd }
  for k, v in vim.spairs(kwargs) do
    cmd[#cmd + 1] = k .. '=' .. v
  end
  cmd[#cmd + 1] = '2>/dev/null'
  return vim.fn.systemlist(cmd)
end

return {
  ---@param vault string
  run = function(vault)
    local tags, cats = tags(vault), categories(vault)

    local out = {
      orphans = only_notes(obs 'orphans'),
      deadends = only_notes(obs 'deadends'),
      missing_props = {},
      mismatched_type = {},
      unknown_tags = {},
      unknown_cats = {},
    }

    for _, rel in ipairs(only_notes(obs 'files')) do
      local lines = readlines(vault .. '/' .. rel) or {}
      local fm = fm_mod.parse(lines)
      local folder = rel:match '^([^/]+)/'

      if not fm.has then
        table.insert(out.missing_props, { path = rel, missing = fm_mod.REQUIRED_KEYS })
      else
        local missing = {}
        for _, k in ipairs(fm_mod.REQUIRED_KEYS) do
          if not fm.keys[k] then
            table.insert(missing, k)
          end
        end
        if #missing > 0 then
          table.insert(out.missing_props, { path = rel, missing = missing })
        end

        local nt = fm.keys.note_type and fm.keys.note_type.value or ''
        if nt ~= '' and nt ~= folder then
          table.insert(out.mismatched_type, { path = rel, note_type = nt, folder = folder })
        end

        local bad_t = {}
        for _, it in ipairs(fm.list_items.tags or {}) do
          if not tags[it.value] then
            table.insert(bad_t, it.value)
          end
        end
        if #bad_t > 0 then
          table.insert(out.unknown_tags, { path = rel, tags = bad_t })
        end

        local bad_c = {}
        for _, it in ipairs(fm.list_items.categories or {}) do
          local name = it.value:match '^"?%[%[(.+)%]%]"?$' or it.value
          if name ~= '' and not cats[name] then
            table.insert(bad_c, name)
          end
        end
        if #bad_c > 0 then
          table.insert(out.unknown_cats, { path = rel, cats = bad_c })
        end
      end
    end
    return out
  end,
}
