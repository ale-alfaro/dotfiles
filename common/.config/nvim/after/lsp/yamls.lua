return {
  cmd = { 'yaml-language-server', '--stdio' },
  filetypes = { 'yaml' },
  settings = {
    yaml = {
      -- Using the schemastore plugin for schemas.
      schemastore = { enable = false, url = '' },
      schemas = require('schemastore').yaml.schemas(),
    },
  },
  -- Have to add this for yamlls to understand that we support line folding
  -- lazy-load schemastore when needed
  -- before_init = function(_, new_config)
  --   new_config.settings.yaml.schemas = vim.tbl_deep_extend('force', new_config.settings.yaml.schemas or {}, require('schemastore').yaml.schemas())
  -- end,
  -- settings = {
  --   redhat = { telemetry = { enabled = false } },
  --   yaml = {
  --     keyOrdering = false,
  --     format = {
  --       enable = true,
  --     },
  --     validate = true,
  --     schemaStore = {
  --       -- Must disable built-in schemaStore support to use
  --       -- schemas from SchemaStore.nvim plugin
  --       enable = false,
  --       -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
  --       url = '',
  --     },
  --   },
  -- },
}
