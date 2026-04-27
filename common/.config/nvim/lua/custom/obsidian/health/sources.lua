-- Canonical sources of truth: TAGS list (in scripts/makeNote.js) and
-- categories (basenames of _categories/*.md).
local M = {}

local function readlines(p)
  return vim.fn.filereadable(p) == 1 and vim.fn.readfile(p) or nil
end

---@param vault string
---@return table<string, true>
function M.tags(vault)
  local lines = readlines(vault .. '/scripts/makeNote.js') or {}
  local set, in_arr = {}, false
  for _, l in ipairs(lines) do
    if l:match('^const TAGS = %[') then
      in_arr = true
    elseif in_arr and l:match('^%];') then
      break
    elseif in_arr then
      for t in l:gmatch('"([%w%-]+)"') do
        set[t] = true
      end
    end
  end
  return set
end

---@param vault string
---@return table<string, true>
function M.categories(vault)
  local set = {}
  for _, f in ipairs(vim.fn.glob(vault .. '/_categories/*.md', false, true)) do
    set[vim.fn.fnamemodify(f, ':t:r')] = true
  end
  return set
end

---@param vault string
---@param tag string
function M.add_tag_to_canonical(vault, tag)
  local p = vault .. '/scripts/makeNote.js'
  local lines = readlines(p)
  if not lines then
    return
  end
  local in_arr, close_idx = false, nil
  for i, l in ipairs(lines) do
    if l:match('^const TAGS = %[') then
      in_arr = true
    elseif in_arr and l:match('^%];') then
      close_idx = i
      break
    end
  end
  if not close_idx then
    return
  end
  table.insert(lines, close_idx, '  "' .. tag .. '",')
  vim.fn.writefile(lines, p)
end

---@param vault string
---@param name string
function M.create_category(vault, name)
  local p = vault .. '/_categories/' .. name .. '.md'
  if vim.fn.filereadable(p) == 1 then
    return
  end
  local today = os.date('%Y-%m-%d')
  vim.fn.writefile({
    '---',
    'note_type: _categories',
    'categories: []',
    'created: ' .. today,
    'last: ' .. today,
    'tags: []',
    '---',
    '',
    '## ' .. name,
    '',
  }, p)
end

return M
