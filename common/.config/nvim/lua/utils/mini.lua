---@class MiniUtils
local M = {}

-- -- Renames the provided file, or the current buffer's file.
-- -- Prompt for the new filename if `to` is not provided.
-- -- do the rename, and trigger LSP handlers
-- ---@param opts? {from?: string, to?:string, on_rename?: fun(to:string, from:string, ok:boolean)}
-- function M.rename_file(opts)
--   opts = opts or {}
--   local from = vim.fn.fnamemodify(opts.from or opts.file or vim.api.nvim_buf_get_name(0), ":p")
--   local to = opts.to and vim.fn.fnamemodify(opts.to, ":p") or nil
--
--   local function rename()
--     assert(to, "to is required")
--     M.on_rename_file(from, to, function()
--       local ok = M._rename(from, to)
--       if opts.on_rename then
--         opts.on_rename(to, from, ok)
--       end
--     end)
--   end
--
--   if to then
--     return rename()
--   end
--
--   local root = vim.fn.getcwd()
--
--   if from:find(root, 1, true) ~= 1 then
--     root = vim.fn.fnamemodify(from, ":p:h")
--   end
--
--   local extra = from:sub(#root + 2)
--
--   vim.ui.input({
--     prompt = "New File Name: ",
--     default = extra,
--     completion = "file",
--   }, function(value)
--     if not value or value == "" or value == extra then
--       return
--     end
--     to = vim.fs.normalize(root .. "/" .. value)
--     rename()
--   end)
-- end
--
-- --- Rename a file and update buffers
-- ---@param from string
-- ---@param to string
-- ---@return boolean ok
-- function M._rename(from, to)
--   from = vim.fn.fnamemodify(from, ":p")
--   to = vim.fn.fnamemodify(to, ":p")
--   -- rename the file
--   local ret = vim.fn.rename(from, to)
--   if ret ~= 0 then
--     _G.error("Failed to rename file: `" .. from .. "`")
--     return false
--   end
--
--   -- replace buffer in all windows
--   local from_buf = vim.fn.bufnr(from)
--   if from_buf >= 0 then
--     local to_buf = vim.fn.bufadd(to)
--     vim.bo[to_buf].buflisted = true
--     for _, win in ipairs(vim.fn.win_findbuf(from_buf)) do
--       vim.api.nvim_win_call(win, function()
--         vim.cmd("buffer " .. to_buf)
--       end)
--     end
--     vim.api.nvim_buf_delete(from_buf, { force = true })
--   end
--   return true
-- end

--- Lets LSP clients know that a file has been renamed
---@param from string
---@param to string
---@param rename? fun()
function M.files_on_rename(from, to, rename)
  local changes = { files = { {
    oldUri = vim.uri_from_fname(from),
    newUri = vim.uri_from_fname(to),
  } } }

  local clients = vim.lsp.get_clients()
  for _, client in ipairs(clients) do
    if client:supports_method 'workspace/willRenameFiles' then
      local resp = client:request_sync('workspace/willRenameFiles', changes, 1000, 0)
      if resp and resp.result ~= nil then
        vim.lsp.util.apply_workspace_edit(resp.result, client.offset_encoding)
      end
    end
  end

  if rename then
    rename()
  end

  for _, client in ipairs(clients) do
    if client:supports_method 'workspace/didRenameFiles' then
      client:notify('workspace/didRenameFiles', changes)
    end
  end
end
-- taken from MiniExtra.gen_ai_spec.buffer
function M.mini_ai_buffer(ai_type)
  local start_line, end_line = 1, vim.fn.line '$'
  if ai_type == 'i' then
    -- Skip first and last blank lines for `i` textobject
    local first_nonblank, last_nonblank = vim.fn.nextnonblank(start_line), vim.fn.prevnonblank(end_line)
    -- Do nothing for buffer with all blanks
    if first_nonblank == 0 or last_nonblank == 0 then
      return { from = { line = start_line, col = 1 } }
    end
    start_line, end_line = first_nonblank, last_nonblank
  end

  local to_col = math.max(vim.fn.getline(end_line):len(), 1)
  return { from = { line = start_line, col = 1 }, to = { line = end_line, col = to_col } }
end

-- register all text objects with which-key
---@param opts table
function M.mini_ai_whichkey(opts)
  local objects = {
    { ' ', desc = 'whitespace' },
    { '"', desc = '" string' },
    { "'", desc = "' string" },
    { '(', desc = '() block' },
    { ')', desc = '() block with ws' },
    { '<', desc = '<> block' },
    { '>', desc = '<> block with ws' },
    { '?', desc = 'user prompt' },
    { 'U', desc = 'use/call without dot' },
    { '[', desc = '[] block' },
    { ']', desc = '[] block with ws' },
    { '_', desc = 'underscore' },
    { '`', desc = '` string' },
    { 'a', desc = 'argument' },
    { 'b', desc = ')]} block' },
    { 'c', desc = 'class' },
    { 'd', desc = 'digit(s)' },
    { 'e', desc = 'CamelCase / snake_case' },
    { 'f', desc = 'function' },
    { 'g', desc = 'entire file' },
    { 'i', desc = 'indent' },
    { 'o', desc = 'block, conditional, loop' },
    { 'q', desc = 'quote `"\'' },
    { 't', desc = 'tag' },
    { 'u', desc = 'use/call' },
    { '{', desc = '{} block' },
    { '}', desc = '{} with ws' },
  }

  ---@type wk.Spec[]
  local ret = { mode = { 'o', 'x' } }
  ---@type table<string, string>
  local mappings = vim.tbl_extend('force', {}, {
    around = 'a',
    inside = 'i',
    around_next = 'an',
    inside_next = 'in',
    around_last = 'al',
    inside_last = 'il',
  }, opts.mappings or {})
  mappings.goto_left = nil
  mappings.goto_right = nil

  for name, prefix in pairs(mappings) do
    name = name:gsub('^around_', ''):gsub('^inside_', '')
    ret[#ret + 1] = { prefix, group = name }
    for _, obj in ipairs(objects) do
      local desc = obj.desc
      if prefix:sub(1, 1) == 'i' then
        desc = desc:gsub(' with ws', '')
      end
      ret[#ret + 1] = { prefix .. obj[1], desc = obj.desc }
    end
  end
  require('which-key').add(ret, { notify = false })
end

---@param opts {skip_next: string, skip_ts: string[], skip_unbalanced: boolean, markdown: boolean}
function M.mini_pairs(opts)
  local pairs = require 'mini.pairs'
  pairs.setup(opts)
  local open = pairs.open
  pairs.open = function(pair, neigh_pattern)
    if vim.fn.getcmdline() ~= '' then
      return open(pair, neigh_pattern)
    end
    local o, c = pair:sub(1, 1), pair:sub(2, 2)
    local line = vim.api.nvim_get_current_line()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local next = line:sub(cursor[2] + 1, cursor[2] + 1)
    local before = line:sub(1, cursor[2])
    if opts.markdown and o == '`' and vim.bo.filetype == 'markdown' and before:match '^%s*``' then
      return '`\n```' .. vim.api.nvim_replace_termcodes('<up>', true, true, true)
    end
    if opts.skip_next and next ~= '' and next:match(opts.skip_next) then
      return o
    end
    if opts.skip_ts and #opts.skip_ts > 0 then
      local ok, captures = pcall(vim.treesitter.get_captures_at_pos, 0, cursor[1] - 1, math.max(cursor[2] - 1, 0))
      for _, capture in ipairs(ok and captures or {}) do
        if vim.tbl_contains(opts.skip_ts, capture.capture) then
          return o
        end
      end
    end
    if opts.skip_unbalanced and next == c and c ~= o then
      local _, count_open = line:gsub(vim.pesc(pair:sub(1, 1)), '')
      local _, count_close = line:gsub(vim.pesc(pair:sub(2, 2)), '')
      if count_close > count_open then
        return o
      end
    end
    return open(pair, neigh_pattern)
  end
end

return M
