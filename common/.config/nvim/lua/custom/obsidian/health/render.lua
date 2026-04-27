-- Render an issue struct to buffer lines, plus cursor → context.
local M = {}

---@param issues table
---@return string[]
function M.lines(issues)
  local res = {}
  local function add(s)
    table.insert(res, s)
  end
  local function section(title, body)
    add('# ' .. title)
    body()
    add('')
  end

  section('Orphans', function()
    for _, p in ipairs(issues.orphans) do
      add('## ' .. p)
    end
  end)
  section('Deadends', function()
    for _, p in ipairs(issues.deadends) do
      add('## ' .. p)
    end
  end)
  section('Missing properties', function()
    for _, e in ipairs(issues.missing_props) do
      add('## ' .. e.path)
      add('- missing: ' .. table.concat(e.missing, ', '))
    end
  end)
  section('Mismatched note_type', function()
    for _, e in ipairs(issues.mismatched_type) do
      add('## ' .. e.path)
      add(string.format('- note_type=`%s`, folder=`%s`', e.note_type, e.folder))
    end
  end)
  section('Unknown tags', function()
    for _, e in ipairs(issues.unknown_tags) do
      add('## ' .. e.path)
      for _, t in ipairs(e.tags) do
        add('- ' .. t)
      end
    end
  end)
  section('Unknown categories', function()
    for _, e in ipairs(issues.unknown_cats) do
      add('## ' .. e.path)
      for _, c in ipairs(e.cats) do
        add('- ' .. c)
      end
    end
  end)
  return res
end

---@class obsidian.health.ctx
---@field group string?  Section heading the cursor is under
---@field file string?   Note path the cursor is under (rel to vault)
---@field entity string? `- foo` item under the file (only for tag/category sections)
---@field from integer?  1-based start line of the file's block
---@field to integer?    1-based end line of the file's block

---@param bufnr integer
---@param lnum integer  1-based
---@return obsidian.health.ctx
function M.ctx_at(bufnr, lnum)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local group, file, from
  for i = lnum, 1, -1 do
    if not group then
      group = lines[i]:match('^# (.+)$')
    end
    if group then
      break
    end
    if not file then
      local f = lines[i]:match('^## (.+)$')
      if f then
        file = f
        from = i
      end
    end
  end
  local entity
  local cur = lines[lnum] or ''
  local item = cur:match('^%- (.+)$')
  if item and not item:match('^missing:') and not item:match('^note_type=') then
    entity = item
  end
  local to
  if file then
    for i = (from or lnum) + 1, #lines do
      if lines[i]:match('^# ') or lines[i]:match('^## ') then
        to = i - 2
        break
      end
    end
    to = to or #lines
  end
  return { group = group, file = file, entity = entity, from = from, to = to }
end

return M
