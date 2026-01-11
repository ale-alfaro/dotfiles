IH = {}

---@param client vim.lsp.Client
---@param bufnr number
IH.add_inlay_hint_support = function(client, bufnr)
  local inlay_hints_group = vim.api.nvim_create_augroup('mariasolos/toggle_inlay_hints', { clear = false })

  -- Initial inlay hint display.
  -- Idk why but without the delay inlay hints aren't displayed at the very start.
  vim.defer_fn(function()
    local mode = vim.api.nvim_get_mode().mode
    vim.lsp.inlay_hint.enable(mode == 'n' or mode == 'v', { bufnr = bufnr })
  end, 500)

  vim.api.nvim_create_autocmd('InsertEnter', {
    group = inlay_hints_group,
    desc = 'Enable inlay hints',
    buffer = bufnr,
    callback = function()
      if vim.g.inlay_hints then
        vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
      end
    end,
  })

  vim.api.nvim_create_autocmd('InsertLeave', {
    group = inlay_hints_group,
    desc = 'Disable inlay hints',
    buffer = bufnr,
    callback = function()
      if vim.g.inlay_hints then
        vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
      end
    end,
  })
end

return IH
