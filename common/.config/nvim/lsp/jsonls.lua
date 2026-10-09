---@diagnostic disable: missing-fields
---
---@type vim.lsp.Config
return {
  settings = {
    json = {
      validate = { enable = true },
    },
  },
  before_init = function (_, client_conf)
    local json_schemas = require('schemastore').json.schemas()
    client_conf.settings.json.schemas = json_schemas
  end
}
