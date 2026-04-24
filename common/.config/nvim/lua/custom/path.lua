local function coerce(v)
  if v == vim.NIL then
    return nil
  else
    return v
  end
end

---@param path table
---@param k string
---@param factory fun(path: vimrc.Path): any
---@private
local function cached_get(path, k, factory)
  local cache_key = '__' .. k
  local v = rawget(path, cache_key)
  if v == nil then
    v = factory(path)
    if v == nil then
      v = vim.NIL
    end
    path[cache_key] = v
  end
  return coerce(v)
end
--- A `Path` class that provides a subset of the functionality of the Python `pathlib` library while
--- staying true to its API. It improves on a number of bugs in `plenary.path`.
---
---
---@class vimrc.Path
---
---@field filename string The underlying filename as a string.
---@field name string|? The final path component, if any.
---@field suffix string|? The final extension of the path, if any.
---@field stem string The final path component, without its suffix.
---@operator div(string|vimrc.Path): vimrc.Path
local Path = {}

Path.__tostring = function(self)
  return self.filename
end

Path.__eq = function(a, b)
  return a.filename == b.filename
end
Path.__div = function(self, other)
  return Path.new(vim.fs.joinpath(self.filename, tostring(other)))
end

Path.__index = function(self, k)
  local raw = rawget(Path, k)
  if raw then
    return raw
  end

  local factory
  if k == 'name' then
    factory = function(path)
      return vim.fs.basename(path.filename)
    end
  elseif k == 'suffix' then
    factory = function(path)
      return vim.fs.ext(path.filename)
    end
  elseif k == 'stem' then
    factory = function(path)
      return vim.fs.basename(path.filename):gsub('%.' .. vim.fs.ext(path.filename))
    end
  end

  if factory then
    return cached_get(self, k, factory)
  end
end

--- Check if an object is an `vimrc.Path` object.
---
---@param path any
---
---@return boolean
Path.is_path_obj = function(path)
  if getmetatable(path) == Path then
    return true
  else
    return false
  end
end

-------------------------------------------------------------------------------
--- Constructors.
-------------------------------------------------------------------------------

--- Create a new path from a string.
---
---@param p string|vimrc.Path
---
---@return vimrc.Path
Path.new = function(p)
  local self = {}

  if Path.is_path_obj(p) then
    ---@cast p -string
    return p
  end
  --- Path is expanded to an absolute path
  self.filename = vim.fs.normalize(tostring(p))

  return setmetatable(self, Path)
end

--- Get a temporary path with a unique name.
---
---@param opts { suffix: string|? }|?
---
---@return vimrc.Path
Path.temp = function(opts)
  opts = opts or {}
  local tmpname = vim.fn.tempname()
  if opts.suffix then
    tmpname = tmpname .. opts.suffix
  end
  return Path.new(tmpname)
end

--- Get a path corresponding to a buffer.
---
---@param bufnr integer|? The buffer number or `0` / `nil` for the current buffer.
---
---@return vimrc.Path
Path.buffer = function(bufnr)
  return Path.new(vim.api.nvim_buf_get_name(bufnr or 0))
end

--- Try to resolve a version of the path relative to the other.
--- An error is raised when it's not possible.
---
---@param other vimrc.Path|string
---
---@return vimrc.Path?
Path.relative_to = function(self, other)
  other = (type(other) == 'string') and Path.new(other) or other

  local common_prefix = string.match(other.filename, '^' .. self.filename)
  if common_prefix then
    common_prefix = common_prefix:gsub('%w$', '%1/')
    return Path.new(other.filename:gsub(common_prefix, ''))
  end
  return nil
end
--- The logical parent of the path.
---
---@return vimrc.Path|?
Path.parent = function(self)
  local parent = vim.fs.dirname(self.filename)
  if parent ~= nil then
    return Path.new(parent)
  else
    return nil
  end
end

--- Get a list of the parent directories.
---
---@return vimrc.Path[]
Path.parents = function(self)
  return vim.iter(vim.fs.parents(self.filename)):map(Path.new):totable()
end

--- Check if the path is a parent of other. This is a pure path method, so it only checks by
--- comparing strings. Therefore in practice you probably want to `:resolve()` each path before
--- using this.
---
---@param other vimrc.Path|string
---
---@return boolean
Path.is_parent_of = function(self, other)
  other = Path.new(other)
  for _, parent in ipairs(other:parents()) do
    if parent == self then
      return true
    end
  end
  return false
end

--- Get OS stat results.
---
---@return boolean
Path.exists = function(self)
  local realpath = vim.fs.abspath(self.filename)
  if realpath then
    local stat, _ = vim.uv.fs_stat(realpath)
    return stat ~= nil
  end
  return false
end
return Path
