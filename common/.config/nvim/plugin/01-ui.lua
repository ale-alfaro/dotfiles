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
-- Mock 'nvim-tree/nvim-web-devicons' for plugins without 'mini.icons' support.
-- Not needed for 'mini.nvim' or MiniMax, but might be useful for others.

now(function()
  require('mini.statusline').setup()
end)

VimRc.later(function()
  vim.o.messagesopt = 'hit-enter,history:1000,progress:c'
  require('vim._core.ui2').enable {
    enable = true, -- Whether to enable or disable the UI.
    msg = { -- Options related to the message module.
      ---@type 'cmd'|'msg' Default message target, either in the
      ---cmdline or in a separate ephemeral message window.
      ---@type string|table<string, 'cmd'|'msg'|'pager'> Default message target
      ---or table mapping |ui-messages| kinds and triggers to a target.
      targets = 'cmd',
      cmd = { -- Options related to messages in the cmdline window.
        height = 0.5, -- Maximum height while expanded for messages beyond 'cmdheight'.
      },
      dialog = { -- Options related to dialog window.
        height = 0.5, -- Maximum height.
      },
      msg = { -- Options related to msg window.
        height = 0.5, -- Maximum height.
        timeout = 4000, -- Time a message is visible in the message window.
      },
      pager = { -- Options related to message window.
        height = 1, -- Maximum height.
      },
    },
  }
end)
-- Add LSP kind icons. Useful for 'mini.completion
now(function()
  require('custom.notify').setup()
end)
