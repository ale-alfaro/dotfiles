local now = VimRc.now

now(function()
  if VimRc.THEME == 'kanagawa' then
    vim.pack.add(_G.plug_spec {
      'rebelot/kanagawa.nvim',
    })
    vim.cmd 'colorscheme kanagawa'
  elseif VimRc.THEME == 'matte-black' then
    vim.pack.add(_G.plug_spec {
      'tahayvr/matteblack.nvim',
    })
    require('matteblack').colorscheme()
  else
    vim.pack.add(_G.plug_spec {
      'catppuccin/nvim',
    })
    require('catppuccin').setup {
      flavour = 'macchiato', -- latte, frappe, macchiato, mocha
      background = { -- :h background
        light = 'latte',
        dark = 'mocha',
      },
    }
  end
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
-- Mock 'nvim-tree/nvim-web-devicons' for plugins without 'mini.icons' support.
-- Not needed for 'mini.nvim' or MiniMax, but might be useful for others.

now(function()
  require('mini.statusline').setup()
end)
-- Example for showing notifications in bottom right corner: >lua

--- # Notification specification ~
---
--- Notification is a table with the following keys:
---
--- - <msg> `(string)` - single string with notification message.
---   Use `\n` to delimit several lines.
--- - <level> `(string)` - notification level as key of |vim.log.levels|.
---   Like "ERROR", "WARN", "INFO", etc.
--- - <hl_group> `(string)` - highlight group with which notification is shown.
--- - <data> `(table)` - extra data to store in notification (like `source`, etc.).
--- - <ts_add> `(number)` - timestamp of when notification is added.
--- - <ts_update> `(number)` - timestamp of the latest notification update.
--- - <ts_remove> `(number|nil)` - timestamp of when notification is removed.
---   It is `nil` if notification was never removed and thus considered "active".
---

-- Add LSP kind icons. Useful for 'mini.completion
now(function()
  require('custom.notify').setup()
end)
