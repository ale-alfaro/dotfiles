-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {

  -- the opts function can also be used to change the default opts:
  'nvim-lualine/lualine.nvim',

  dependencies = { 'nvim-tree/nvim-web-devicons' },
  opts = {},
  event = 'VeryLazy',
  -- opts = function(_, opts)
  --   table.insert(opts.sections.lualine_x, {
  --     function()
  --       return '😄'
  --     end,
  --   })
  -- end,
}
