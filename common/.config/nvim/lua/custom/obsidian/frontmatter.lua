-- YAML frontmatter parsing + safe in-place mutations.

NOTE_TYPES = { fleeting = true, literature = true, permanent = true, reference = true }
REQUIRED_KEYS = { 'note_type', 'categories', 'created', 'last', 'tags' }

local function readlines(p)
  return vim.fn.filereadable(p) == 1 and vim.fn.readfile(p) or nil
end
local function writelines(p, l)
  vim.fn.writefile(l, p)
end

---@param abs_path string
---@return string?  Date as YYYY-MM-DD from file mtime.
local function datetime()
  local secs, _ = vim.uv.gettimeofday()
  local t = os.date('%Y-%m-%d', secs)
  return type(t) == 'string' and t or nil
end

---@class obsidian.health.fm
---@field has boolean
---@field fm_end integer  1-based line of closing `---`, or 0
---@field keys table<string, { line:integer, raw:string, value:string }>
---@field list_items table<string, { line:integer, value:string }[]>

---@param lines string[]
---@return obsidian.health.fm
local function parse(lines)
  local out = { has = false, fm_end = 0, keys = {}, list_items = {} }
  if not lines[1] or lines[1] ~= '---' then
    return out
  end
  out.has = true
  local cur_list
  for i = 2, #lines do
    local line = lines[i]
    if line == '---' then
      out.fm_end = i
      return out
    end
    local k, v = line:match '^([%w_]+):%s*(.*)$'
    if k then
      out.keys[k] = { line = i, raw = line, value = v }
      if v == nil or v == '' then
        cur_list = k
        out.list_items[cur_list] = {}
      else
        cur_list = nil
      end
    elseif cur_list then
      local item = line:match '^%s+%- (.*)$'
      if item then
        table.insert(out.list_items[cur_list], { line = i, value = item })
      else
        cur_list = nil
      end
    end
  end
  return out
end
return {

  ---@param abs_path string
  ---@param folder string
  set_note_type = function(abs_path, folder)
    local lines = readlines(abs_path)
    if not lines then
      return
    end
    local fm = parse(lines)
    if fm.keys.note_type then
      lines[fm.keys.note_type.line] = 'note_type: ' .. folder
    elseif fm.has then
      table.insert(lines, fm.fm_end, 'note_type: ' .. folder)
    end
    writelines(abs_path, lines)
  end,

  ---@param abs_path string
  ---@param folder string
  autofill = function(abs_path, folder)
    local lines = readlines(abs_path)
    if not lines then
      return
    end
    local mt = datetime()
    local defaults = {
      note_type = 'note_type: ' .. folder,
      categories = 'categories: []',
      tags = 'tags: []',
      created = 'created: ' .. mt,
      last = 'last: ' .. mt,
    }

    if not lines[1] or lines[1] ~= '---' then
      local block = { '---' }
      for _, k in ipairs(REQUIRED_KEYS) do
        table.insert(block, defaults[k])
      end
      table.insert(block, '---')
      for i = #block, 1, -1 do
        table.insert(lines, 1, block[i])
      end
      writelines(abs_path, lines)
      return
    end

    local fm = parse(lines)
    local insert_idx = fm.fm_end
    local missing = {}
    for _, k in ipairs(REQUIRED_KEYS) do
      if not fm.keys[k] then
        table.insert(missing, defaults[k])
      end
    end
    for i = #missing, 1, -1 do
      table.insert(lines, insert_idx, missing[i])
    end
    writelines(abs_path, lines)
  end,

  ---@param abs_path string
  ---@param tag string
  add_tag = function(abs_path, tag)
    local lines = readlines(abs_path)
    if not lines then
      return
    end
    local fm = parse(lines)
    for _, it in ipairs(fm.list_items.tags or {}) do
      if it.value == tag then
        return
      end
    end
    if not fm.keys.tags then
      if fm.has then
        table.insert(lines, fm.fm_end, '  - ' .. tag)
        table.insert(lines, fm.fm_end, 'tags:')
      end
    else
      local tl = fm.keys.tags.line
      if lines[tl]:match '^tags:%s*%[%]' then
        lines[tl] = 'tags:'
        table.insert(lines, tl + 1, '  - ' .. tag)
      else
        local tail = tl
        for i = tl + 1, fm.fm_end - 1 do
          if lines[i]:match '^%s+%- ' then
            tail = i
          else
            break
          end
        end
        table.insert(lines, tail + 1, '  - ' .. tag)
      end
    end
    writelines(abs_path, lines)
  end,
  ---@param abs_path string
  ---@param tag string
  remove_tag = function(abs_path, tag)
    local lines = readlines(abs_path)
    if not lines then
      return
    end
    local fm = parse(lines)
    local items = fm.list_items.tags or {}
    for i = #items, 1, -1 do
      if items[i].value == tag then
        table.remove(lines, items[i].line)
      end
    end
    writelines(abs_path, lines)
  end,

  ---@param abs_path string
  ---@param old string
  ---@param new string
  rename_tag = function(abs_path, old, new)
    local lines = readlines(abs_path)
    if not lines then
      return
    end
    local fm = parse(lines)
    for _, it in ipairs(fm.list_items.tags or {}) do
      if it.value == old then
        lines[it.line] = lines[it.line]:gsub(vim.pesc('- ' .. old) .. '$', '- ' .. new)
      end
    end
    for i = (fm.fm_end or 0) + 1, #lines do
      lines[i] = lines[i]:gsub('#' .. vim.pesc(old) .. '%f[%W]', '#' .. new)
    end
    writelines(abs_path, lines)
  end,

  ---@param abs_path string
  ---@param cat string
  remove_category = function(abs_path, cat)
    local lines = readlines(abs_path)
    if not lines then
      return
    end
    local fm = parse(lines)
    local items = fm.list_items.categories or {}
    for i = #items, 1, -1 do
      local name = items[i].value:match '^"?%[%[(.+)%]%]"?$' or items[i].value
      if name == cat then
        table.remove(lines, items[i].line)
      end
    end
    writelines(abs_path, lines)
  end,
}
