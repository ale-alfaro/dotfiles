-- Run obsidian CLI + validate notes against canonical sources, returning
-- a struct of issue groups.
local fm_mod = require('custom.obsidian.health.frontmatter')
local sources = require('custom.obsidian.health.sources')

local M = {}

local function readlines(p)
  return vim.fn.filereadable(p) == 1 and vim.fn.readfile(p) or nil
end

local function obs(vault, args)
  local cmd = 'cd ' .. vim.fn.shellescape(vault) .. ' && obsidian ' .. args .. ' 2>/dev/null'
  return vim.fn.systemlist({ 'sh', '-c', cmd })
end

---@param vault string
function M.run(vault)
  local tags, cats = sources.tags(vault), sources.categories(vault)
  local function only_notes(list)
    return vim.tbl_filter(fm_mod.is_note_path, list)
  end

  local out = {
    orphans = only_notes(obs(vault, 'orphans')),
    deadends = only_notes(obs(vault, 'deadends')),
    missing_props = {},
    mismatched_type = {},
    unknown_tags = {},
    unknown_cats = {},
  }

  for _, rel in ipairs(only_notes(obs(vault, 'files'))) do
    local lines = readlines(vault .. '/' .. rel) or {}
    local fm = fm_mod.parse(lines)
    local folder = rel:match('^([^/]+)/')

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
        local name = it.value:match('^"?%[%[(.+)%]%]"?$') or it.value
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
end

return M
