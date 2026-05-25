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
  local yaml_schemas = require('schemastore').yaml.schemas()
  vim.lsp.config('yamlls', {
    settings = {
      yaml = {
        schemas = yaml_schemas,
        validate = { enable = true },
        format = { enable = true },
      },
    },
  })
  vim.lsp.enable 'yaml_ls'
end
M.toml_ls = function()
  local catalogs = require('schemastore').json.load()
  vim.lsp.config('taplo', {
    settings = {
      -- Use the defaults that the VSCode extension uses: https://github.com/tamasfe/taplo/blob/2e01e8cca235aae3d3f6d4415c06fd52e1523934/editors/vscode/package.json
      taplo = {
        configFile = { enabled = true },
        schema = {
          enabled = true,
          catalogs = catalogs,
          cache = {
            memoryExpiration = 60,
            diskExpiration = 600,
          },
        },
      },
    },
  })
  vim.lsp.enable 'taplo'
end

return M
