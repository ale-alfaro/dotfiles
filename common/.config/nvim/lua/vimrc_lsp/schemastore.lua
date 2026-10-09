local M = {}

M.json_ls = function()
  local json_schemas = require('schemastore').json.schemas()
  vim.lsp.config('jsonls', {
    settings = {
      json = {
        schemas = json_schemas,
        validate = { enable = true },
      },
    },
  })
  vim.lsp.enable 'json_ls'
end
M.yaml_ls = function()
  vim.lsp.config('yamlls', {
    settings = {
      yaml = {
        schemas = require('schemastore').json.schemas {
          select = {
            'GitHub Action',
            'GitHub Workflow',

          },
        },
        validate = { enable = true },
        format = { enable = true },
      },
    },
  })
  vim.lsp.enable 'yaml_ls'
end

return M
