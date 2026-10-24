-- Install with: mise use -g npm:yaml-language-server

---@type vim.lsp.Config
-- return {
--
--     settings = {
--       yaml = {
--             schemaStore = { enable = false, url = '' },
--     },
--     -- before_init = function (_, cfg)
--     --   cfg.settings.yaml.schemas = require('schemastore').yaml.schemas()
--     -- end,
--   }
-- }
return {
    settings = {
        yaml = {
            schemaStore = {
                -- You must disable built-in schemaStore support if you want to use
        -- this plugin and its advanced options like `ignore`.
                enable = false,
                -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
                url = "",
            },
            schemas = require('schemastore').yaml.schemas(),
        },
    },
}
