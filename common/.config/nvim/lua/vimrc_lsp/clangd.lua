---@class Clangd.Method : vim.lsp.protocol.Method
---| "textDocument/ast"
---| "textDocument/typeHierarchy"
---| "textDocument/switchSourceHeader"
---| "textDocument/symbolInfo"
---| "$/memoryUsage"
---

local type_hierarchy_augroup = vim.api.nvim_create_augroup('ClangdTypeHierarchy', {})

local function format_tree(node, visited, result, padding, type_to_location)
  vim.validate('node', node, 'table')
  vim.validate('visited', visited, 'table')
  vim.validate('result', result, 'table')
  vim.validate('padding', padding, 'string')
  vim.validate('type_to_location', type_to_location, 'table')

  local symbol_kind = require 'clangd_extensions.symbol_kind'
  visited[node.data] = true
  table.insert(result, padding .. (' • %s: %s'):format(node.name, symbol_kind[node.kind]))

  type_to_location[node.name] = { uri = node.uri, range = node.range }

  if node.parents and #node.parents > 0 then
    table.insert(result, padding .. '   Parents:')
    for _, parent in pairs(node.parents) do
      if not visited[parent.data] then
        format_tree(parent, visited, result, padding .. '   ', type_to_location)
      end
    end
  end

  if node.children and #node.children > 0 then
    table.insert(result, padding .. '   Children:')
    for _, child in pairs(node.children) do
      if not visited[child.data] then
        format_tree(child, visited, result, padding .. '   ', type_to_location)
      end
    end
  end

  return result
end

---@enum Clangd.SymbolKind
local symbol_kind = {
  'File',
  'Module',
  'Namespace',
  'Package',
  'Class',
  'Method',
  'Property',
  'Field',
  'Constructor',
  'Enum',
  'Interface',
  'Function',
  'Variable',
  'Constant',
  'String',
  'Number',
  'Boolean',
  'Array',
  'Object',
  'Key',
  'Null',
  'EnumMember',
  'Struct',
  'Event',
  'Operator',
  'TypeParameter',
}
local offset_encoding = {}
local type_to_location = {}
---@class Clangd.TypeHierarchyItem
---@field name string
---@field detail? string
---@field kind lsp.SymbolKind
---@field deprecated? boolean
---@field uri string
---@field range lsp.Range
---@field selectionRange lsp.Range
---@field parents? Clangd.TypeHierarchyItem[]
---@field children? Clangd.TypeHierarchyItem[]
---@field data? any

---@param err? lsp.ResponseError
---@param result? Clangd.TypeHierarchyItem : table
---@param ctx lsp.HandlerContext
local function type_hierarchy_handler(err, result, ctx)
  vim.validate('err', err, 'table', true)
  vim.validate('result', result, 'table', true)
  vim.validate('ctx', ctx, 'table')

  if err or not result then
    return
  end

  local client_id = ctx.client_id
  -- Save old state
  local source_win = vim.api.nvim_get_current_win()

  -- Init
  local client = vim.lsp.get_clients({ id = client_id })[1]
  assert(client, 'client was nil')
  offset_encoding[client_id] = client.offset_encoding
  vim.cmd.split(('%s: type hierarchy'):format(result.name))
  local bufnr = vim.api.nvim_get_current_buf()
  type_to_location[bufnr] = {}

  -- Set content
  local lines = format_tree(result, {}, {}, '', M.type_to_location[bufnr])
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)

  -- Set options
  vim.bo.modifiable = false
  vim.bo.filetype = 'ClangdTypeHierarchy'
  vim.bo.buftype = 'nofile'
  vim.bo.bufhidden = 'wipe'
  vim.bo.buflisted = true
  vim.api.nvim_set_option_value('number', false, { scope = 'local' })
  vim.api.nvim_set_option_value('relativenumber', false, { scope = 'local' })
  vim.api.nvim_set_option_value('spell', false, { scope = 'local' })
  vim.api.nvim_set_option_value('cursorline', false, { scope = 'local' })
  local winbar = vim.api.nvim_get_option_value('winbar', {})
  local numlines = winbar == '' and #lines or #lines + 1
  local winheight = math.min(numlines, 15)
  vim.api.nvim_win_set_height(0, winheight)

  -- Set highlights
  vim.cmd [[
        syntax clear
        syntax match ClangdTypeName "\( \{2,\}• \)\@<=\w\+\(:\)\@="
        ]]
  vim.api.nvim_set_hl(0, 'ClangdTypeName', { link = 'Underlined' })

  -- Set keymap
  vim.keymap.set('n', 'gd', function()
    local word = vim.fn.expand '<cWORD>'
    word = word:gsub(':$', '')
    local location = M.type_to_location[bufnr][word]
    if location ~= nil then
      vim.api.nvim_set_current_win(source_win)

      vim.lsp.util.show_document(location, M.offset_encoding[client_id], { focus = true })
    end
  end, {
    buffer = bufnr,
    desc = 'go to definition of type under cursor',
  })

  -- Clear `type_to_location` for this buffer when it is wiped out
  vim.api.nvim_create_autocmd('BufWipeout', {
    buffer = bufnr,
    group = type_hierarchy_augroup,
    callback = function()
      M.type_to_location[bufnr] = nil
    end,
  })
end

---@class Clangd.SymbolDetails
---@field name string
---@field containerName string
---@field usr string
---@field id string?

---@param err? lsp.ResponseError
---@param result? Clangd.SymbolDetails[]: table
---@param ctx lsp.HandlerContext
local function symbol_info_handler(err, result, ctx)
  vim.validate('err', err, 'table', true)
  vim.validate('result', result, 'table', true)

  if err or not result or not result[1] then
    return
  end

  local name_str = ('name: %s'):format(result[1].name)
  local container_str = ('container: %s'):format(result[1].containerName)

  local buf, win = vim.lsp.util.open_floating_preview({ name_str, container_str }, '', {
    height = 2,
    width = math.max(name_str:len(), container_str:len()),
    focusable = false,
    focus = false,
    border = require('clangd_extensions.config').options.symbol_info.border,
  })

  vim.keymap.set('n', 'q', function()
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
    pcall(vim.api.nvim_win_close, win, true)
  end, { buffer = buf })
end
---@return VimRcLspSetup
return {
  on_attach = function(client, bufnr)
    VimRc.user_cmd('SwitchSourceHeader', function()
      VimRc.lsp_request_method(client, bufnr, 'textDocument/switchSourceHeader', {
        uri = vim.uri_from_bufnr(bufnr),
      }, function(err, uri)
        vim.validate('err', err, 'table', true)
        vim.validate('uri', uri, 'string', true)

        if err or not uri or (uri == '') then
          VimRc.err('Corresponding file cannot be determined', { err = err, uri = uri })
          return
        end

        vim.cmd.edit(vim.uri_to_fname(uri))
      end)
    end, { desc = 'Switch between source and header file' })
    --- Symbol Info
    VimRc.user_buf_cmd(bufnr, 'SymbolInfo', function()
      VimRc.lsp_request_method(client, bufnr, 'textDocument/symbolInfo', {
        textDocument = {
          uri = vim.uri_from_bufnr(bufnr),
        },
        position = {
          line = vim.fn.getcurpos()[2] - 1,
          character = vim.fn.getcurpos()[3] - 1,
        },
      }, symbol_info_handler)
    end, { desc = 'Clangd Symbol Info' })
    --- Type Hierarchy
    VimRc.user_buf_cmd(bufnr, 'TypeHierarchy', function()
      VimRc.lsp_request_method(client, bufnr, 'textDocument/typeHierarchy', {
        textDocument = {
          uri = vim.uri_from_bufnr(bufnr),
        },
        position = {
          line = vim.fn.getcurpos()[2] - 1,
          character = vim.fn.getcurpos()[3] - 1,
        },
        -- TODO: make these configurable (config + command args)
        resolve = 3,
        direction = 2,
      }, type_hierarchy_handler)
    end, { desc = 'Clangd TypeHierarchy' })
  end,
  keymap = {
    { '<leader>ch', '<cmd>SwitchSourceHeader<cr>', { desc = 'SwitchSourceHeader' } },
  },
}
