local U = {}
---@param path string
---@return table|nil
function U.read_json(path)
  local file = io.open(path, 'r')
  if not file then
    return
  end
  local content = file:read '*a'
  file:close()
  local ok, decoded = pcall(vim.json.decode, content)
  if not ok or type(decoded) ~= 'table' then
    return
  end
  return decoded
end

---@param paths (string|fun():string|nil)[]?
---@return string|nil
function U.resolve_first_existing(paths)
  vim.validate('paths', paths, { 'table' }, 'not table')
  for _, candidate in ipairs(paths) do
    vim.validate('paths', candidate, { 'callable', 'string' }, 'not callable nor string')
    local path = candidate
    if vim.is_callable(candidate) then
      local p = candidate()
      path = p or ''
    elseif type(path) == 'string' and path ~= '' and vim.uv.fs_stat(path) then
      return path
    end
  end
  return nil
end

return U
