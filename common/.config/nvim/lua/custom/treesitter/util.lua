---@class ts.mod.Util
local M = {}

---@param language string
---@param name 'highlights'|'indents'|'locals'
---@return boolean
function M.has_query(language, name)
  return #vim.treesitter.query.get_files(language, name) > 0
end

---Elements in left that are not in right
---@param left string[]
---@param right string[]
---@return string[]
function M.difference(left, right)
  local result = {} ---@type string[]
  for _, value in ipairs(left) do
    if not vim.tbl_contains(right, value) then
      result[#result + 1] = value
    end
  end
  return result
end

return M
