return {
  {
    {
      'obsidian-nvim/obsidian.nvim',
      version = '*', -- recommended, use latest release instead of latest commit
      event = {
        -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
        -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
        -- refer to `:h file-pattern` for more examples
        'BufReadPre '
          .. vim.fn.expand '$OBSIDIAN_HOME'
          .. '/*.md',
        'BufNewFile ' .. vim.fn.expand '$OBSIDIAN_HOME' .. '/*.md',
      },
      keys = {
        { '<leader>oo', '<cmd>ObsidianOpen<cr>' },
        { '<leader>on', '<cmd>ObsidianNew<cr>' },
        { '<leader>oT', '<cmd>ObsidianTemplate<cr>' },
        { '<leader>ot', '<cmd>ObsidianToday<cr>' },
        { '<leader>oy', '<cmd>ObsidianYesterday<cr>' },
        { '<leader>ol', '<cmd>ObsidianLink<cr>' },
        { '<leader>oL', '<cmd>ObsidianLinkNew<cr>' },
        { '<leader>ob', '<cmd>ObsidianBacklinks<cr>' },
        { '<leader>os', '<cmd>ObsidianSearch<cr>' },
        { '<leader>oq', '<cmd>ObsidianQuickSwitch<cr>' },
      },
      opts = {
        completion = {
          blink = true, -- with this set to true, it automatically configures completion on its own
        },
        disable_frontmatter = true,
        workspaces = {
          {
            name = 'Personal-Geek',
            path = vim.fn.expand '$OBSIDIAN_HOME' .. '/Personal-Geek',
          },
          {
            name = 'Sibel-Work',
            path = vim.fn.expand '$OBSIDIAN_HOME' .. '/Sibel-Work',
          },
        },
      },
      post_setup = function()
        -- if cursor is on a link in an obsidian file, gf will follow the reference, otherwise it will behave normally
        vim.keymap.set('n', 'gf', function()
          if require('obsidian').util.cursor_on_markdown_link() then
            return '<cmd>ObsidianFollowLink<CR>'
          else
            return 'gf'
          end
        end, { noremap = false, expr = true })
      end,
    },
  },
}
