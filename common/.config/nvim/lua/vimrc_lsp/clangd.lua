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
---@brief
---
--- https://clangd.llvm.org/installation.html
---
--- - **NOTE:** Clang >= 11 is recommended! See [#23](https://github.com/neovim/nvim-lspconfig/issues/23).
--- - If `compile_commands.json` lives in a build directory, you should
---   symlink it to the root of your source tree.
---   ```
---   ln -s /path/to/myproject/build/compile_commands.json /path/to/myproject/
---   ```
--- - clangd relies on a [JSON compilation database](https://clang.llvm.org/docs/JSONCompilationDatabase.html)
---   specified as compile_commands.json, see https://clangd.llvm.org/installation#compile_commandsjson

-- https://clangd.llvm.org/extensions.html#switch-between-sourceheader
local function switch_source_header(bufnr, client)
  local method_name = 'textDocument/switchSourceHeader'
  ---@diagnostic disable-next-line:param-type-mismatch
  if not client or not client:supports_method(method_name) then
    return vim.notify(('method %s is not supported by any servers active on the current buffer'):format(method_name))
  end
  local params = vim.lsp.util.make_text_document_params(bufnr)
  ---@diagnostic disable-next-line:param-type-mismatch
  client:request(method_name, params, function(err, result)
    if err then
      error(tostring(err))
    end
    if not result then
      vim.notify 'corresponding file cannot be determined'
      return
    end
    vim.cmd.edit(vim.uri_to_fname(result))
  end, bufnr)
end

local function symbol_info(bufnr, client)
  local method_name = 'textDocument/symbolInfo'
  ---@diagnostic disable-next-line:param-type-mismatch
  if not client or not client:supports_method(method_name) then
    return vim.notify('Clangd client not found', vim.log.levels.ERROR)
  end
  local win = vim.api.nvim_get_current_win()
  local params = vim.lsp.util.make_position_params(win, client.offset_encoding)
  ---@diagnostic disable-next-line:param-type-mismatch
  client:request(method_name, params, function(err, res)
    if err or #res == 0 then
      -- Clangd always returns an error, there is no reason to parse it
      return
    end
    local container = string.format('container: %s', res[1].containerName) ---@type string
    local name = string.format('name: %s', res[1].name) ---@type string
    vim.lsp.util.open_floating_preview({ name, container }, '', {
      height = 2,
      width = math.max(string.len(name), string.len(container)),
      focusable = false,
      focus = false,
      title = 'Symbol Info',
    })
  end, bufnr)
end

---@class ClangdInitializeResult: lsp.InitializeResult
---@field offsetEncoding? string

---@return vim.lsp.Config
M.create_config = function()
  return {
    cmd = { 'clangd' },
    filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
    root_markers = {
      '.clangd',
      '.clang-tidy',
      '.clang-format',
      'compile_commands.json',
      'compile_flags.txt',
      'configure.ac', -- AutoTools
      '.git',
    },
    get_language_id = function(_, ftype)
      local t = { objc = 'objective-c', objcpp = 'objective-cpp', cuda = 'cuda-cpp' }
      return t[ftype] or ftype
    end,
    capabilities = {
      textDocument = {
        completion = {
          editsNearCursor = true,
        },
      },
      offsetEncoding = { 'utf-8', 'utf-16' },
    },
    ---@param init_result ClangdInitializeResult
    on_init = function(client, init_result)
      if init_result.offsetEncoding then
        client.offset_encoding = init_result.offsetEncoding
      end
    end,
    on_attach = function(client, bufnr)
      vim.api.nvim_buf_create_user_command(bufnr, 'LspClangdSwitchSourceHeader', function()
        switch_source_header(bufnr, client)
      end, { desc = 'Switch between source/header' })

      vim.api.nvim_buf_create_user_command(bufnr, 'LspClangdShowSymbolInfo', function()
        symbol_info(bufnr, client)
      end, { desc = 'Show symbol info' })
      VimRc.user_buf_cmd(bufnr, 'TypeHierarchy', function()
        local method = 'textDocument/typeHierarchy'
        ---@diagnostic disable-next-line:param-type-mismatch
        VimRc.lsp_request_method(client, bufnr, method, {
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
  }
end
