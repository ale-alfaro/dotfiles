--[[
===============================================================================
    File:       custom/helpers/parsers/gemini.lua
    Author:     Oli Morris (modified)
-------------------------------------------------------------------------------
    Description:
      Parses a GEMINI.md (or similarly formatted) file, extracting any lines
      that are markdown list items as file paths to be included in memory.
===============================================================================
--]]

---@param file CodeCompanion.Chat.Memory.ProcessedFile
---@return CodeCompanion.Chat.Memory.Parser
return function(file)
  if file == nil then
    vim.notify('File parsed by gemini parser is nil', vim.log.levels.WARN)
    return { content = '' }
  end
  local content = file.content or ''
  local included_files = {}

  if content == '' then
    return { content = content }
  end

  -- Parse the markdown content
  local ok, parser = pcall(vim.treesitter.get_string_parser, content, 'markdown')
  if not ok or not parser then
    -- fallback to simple line-by-line parsing if treesitter fails
    for line in content:gmatch '[^\r\n]+' do
      local path = line:match '^%s*-%s*([%w%._/-]+)'
      if path then
        table.insert(included_files, path)
      end
    end
    return { content = content, meta = (#included_files > 0) and { included_files = included_files } or nil }
  end

  local tree = parser:parse()[1]
  if not tree then
    return { content = content }
  end
  local root = tree:root()

  -- Query for list items
  local query = vim.treesitter.query.parse('markdown', '(list_item) @item')
  local get_text = vim.treesitter.get_node_text

  local seen = {}
  for id, node in query:iter_captures(root, content, 0, -1) do
    if query.captures[id] == 'item' then
      local item_text = get_text(node, content)
      -- Extract path from list item, removing the leading '- ' or '* '
      local path = item_text:match '^%s*[-*]%s*(%S+)'
      if path and not seen[path] then
        seen[path] = true
        table.insert(included_files, path)
      end
    end
  end

  return { content = content, meta = (#included_files > 0) and { included_files = included_files } or nil }
end
