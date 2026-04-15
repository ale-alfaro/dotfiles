local now = VimRc.now

VimRc.icons = require 'custom.icons'
now(function()
  vim.pack.add {
    'https://github.com/rebelot/kanagawa.nvim',
  }
  vim.cmd 'colorscheme kanagawa'
end)
now(function()
  -- Set up to not prefer extension-based icon for some extensions
  local ext3_blocklist = { scm = true, txt = true, yml = true }
  local ext4_blocklist = { json = true, yaml = true }
  local mini_icons = require 'mini.icons'
  mini_icons.setup {
    use_file_extension = function(ext, _)
      return not (ext3_blocklist[ext:sub(-3)] or ext4_blocklist[ext:sub(-4)])
    end,
  }
  mini_icons.mock_nvim_web_devicons()
end)
now(function()
  local starter = require 'mini.starter'
  starter.setup {
    items = {
      { action = 'FzfLua global', name = 'Browser', section = 'Fzf' },
      { action = 'FzfLua history', name = 'Command history', section = 'Fzf' },
      { action = 'FzfLua files', name = 'Files', section = 'Fzf' },
      { action = 'FzfLua helptags', name = 'Help tags', section = 'Fzf' },
      { action = 'FzfLua live_grep', name = 'Live grep', section = 'Fzf' },
      { action = 'FzfLua oldfiles', name = 'Old files', section = 'Fzf' },
    },
    content_hooks = {
      starter.gen_hook.adding_bullet(),
      starter.gen_hook.aligning('center', 'center'),
    },
  }
end)

now(function()
  require('mini.statusline').setup()
end)
---

now(function()
  require('custom.notify').setup()
end)
