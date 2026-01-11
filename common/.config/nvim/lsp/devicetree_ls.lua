return {
  cmd = { 'devicetree-language-server', '--stdio' },
  filetypes = { 'dts', 'dtsi' },
  root_markers = { '.west' },
  settings = {
    devicetree = {
      defaultIncludePaths = {
        './zephyr/dts',
        './zephyr/dts/arm',
        './zephyr/dts/arm64/',
        './zephyr/dts/riscv',
        './zephyr/dts/common',
        './zephyr/dts/vendor',
        './zephyr/include',
      },
      cwd = '${workspaceFolder}',
      defaultZephyrBindings = {
        './zephyr/dts/bindings',
      },
      contexts = {},
      defaultBindingType = 'Zephyr',
      autoChangeContext = true,
      allowAdhocContexts = true,
    },
  },
}
