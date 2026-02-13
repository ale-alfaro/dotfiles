---@type vim.lsp.Config
return {
  cmd = { 'devicetree-language-server', '--stdio' },
  filetypes = { 'dts' },
  root_markers = { '.west', '.git' },
  settings = {
    devicetree = {
      defaultIncludePaths = {
        './external/zephyr/dts',
        './external/zephyr/dts/arm',
        './external/zephyr/dts/common',
        './external/zephyr/dts/vendor',
        './external/zephyr/include',
      },
      cwd = '${workspaceFolder}',
      defaultBindingType = 'Zephyr',
      defaultZephyrBindings = {
        './external/zephyr/dts/bindings',
      },
      autoChangeContext = true,
      allowAdhocContexts = true,
    },
  },
  --     defaultBindingType = 'Zephyr',
  --     autoChangeContext = true,
  --     allowAdhocContexts = true,
}
