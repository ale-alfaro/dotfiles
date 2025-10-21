local M = {}
function M.get_code_actions()
  -- vim.validate('options', opts, 'table', true)
  -- opts = opts or {}
  -- Detect old API call code_action(context) which should now be
  -- code_action({ context = context} )
  --- @diagnostic disable-next-line:undefined-field
  -- if opts.diagnostics or opts.only then
  --   opts = { options = opts }
  -- end
  -- local context = opts.context and vim.deepcopy(opts.context) or {}
  -- if not context.triggerKind then
  --   context.triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Invoked
  -- end
  -- local mode = vim.api.nvim_get_mode().mode
  local bufnr = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  vim.lsp.buf_request_all(bufnr, 'textDocument/codeAction', function(client)
    ---@type lsp.CodeActionParams
    local params = vim.lsp.util.make_range_params(win, client.offset_encoding)

    params.context = {
      triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Invoked,
      diagnostics = vim.lsp.diagnostic.get_line_diagnostics(),
    }
    -- if opts.range then
    --   assert(type(opts.range) == 'table', 'code_action range must be a table')
    --   local start = assert(opts.range.start, 'range must have a `start` property')
    --   local end_ = assert(opts.range['end'], 'range must have a `end` property')
    --   params = util.make_given_range_params(start, end_, bufnr, client.offset_encoding)
    -- elseif mode == 'v' or mode == 'V' then
    --   local range = range_from_selection(bufnr, mode)
    --   params =
    --     util.make_given_range_params(range.start, range['end'], bufnr, client.offset_encoding)
    -- else
    --   params = util.make_range_params(win, client.offset_encoding)
    -- end
    --
    -- --- @cast params lsp.CodeActionParams
    --
    -- if context.diagnostics then
    --   params.context = context
    -- else
    --   local ns_push = lsp.diagnostic.get_namespace(client.id, false)
    --   local ns_pull = lsp.diagnostic.get_namespace(client.id, true)
    --   local diagnostics = {}
    --   local lnum = api.nvim_win_get_cursor(0)[1] - 1
    --   vim.list_extend(diagnostics, vim.diagnostic.get(bufnr, { namespace = ns_pull, lnum = lnum }))
    --   vim.list_extend(diagnostics, vim.diagnostic.get(bufnr, { namespace = ns_push, lnum = lnum }))
    --   params.context = vim.tbl_extend('force', context, {
    --     ---@diagnostic disable-next-line: no-unknown
    --     diagnostics = vim.tbl_map(function(d)
    --       return d.user_data.lsp
    --     end, diagnostics),
    --   })
    -- end

    return params
  end, function(results)
    on_code_action_results(results, opts)
  end)
end

-- function M.get_clients_supporting_code_actions()
--
--   local bufnr = vim.api.nvim_get_current_buf()
--   local clients = vim.lsp.get_clients { bufnr = bufnr, method = 'textDocument/codeAction' }
--   local supporting = vim.iter(clients):filter(function()
--
--   end)
--   for lsp in clients do
--     support
--   end
--
-- end

return M
