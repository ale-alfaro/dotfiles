VimRc.now(function()
  ---
  --- WARNING: This is an experimental feature intended to replace the builtin message + cmdline
  --- presentation layer.
  ---
  --- To enable this feature (default opts shown):
  --- ```lua
  --- require('vim._core.ui2').enable({
  ---   enable = true, -- Whether to enable or disable the UI.
  ---   msg = { -- Options related to the message module.
  ---     ---@type 'cmd'|'msg' Default message target, either in the
  ---     ---cmdline or in a separate ephemeral message window.
  ---     ---@type string|table<string, 'cmd'|'msg'|'pager'> Default message target
  ---     ---or table mapping |ui-messages| kinds and triggers to a target.
  ---     targets = 'cmd',
  ---     cmd = { -- Options related to messages in the cmdline window.
  ---       height = 0.5 -- Maximum height while expanded for messages beyond 'cmdheight'.
  ---     },
  ---     dialog = { -- Options related to dialog window.
  ---       height = 0.5, -- Maximum height.
  ---     },
  ---     msg = { -- Options related to msg window.
  ---       height = 0.5, -- Maximum height.
  ---       timeout = 4000, -- Time a message is visible in the message window.
  ---     },
  ---     pager = { -- Options related to message window.
  ---       height = 1, -- Maximum height.
  ---     },
  ---   },
  --- })
  --- ```
  ---
  --- There are four special windows/buffers for presenting messages and cmdline:
  --- - "cmd": Cmdline. Also used for 'showcmd', 'showmode', 'ruler', and messages by default.
  --- - "msg": Message window, shows ephemeral messages useful for 'cmdheight' == 0.
  --- - "pager": Pager window, shows |:messages| and certain messages that are never "collapsed".
  --- - "dialog": Dialog window, shows modal prompts that expect user input.
  ---
  --- The buffer 'filetype' is set to the above-listed id ("cmd", "msg", …).
  --- Handle the |FileType| event to configure any local options for these
  --- windows and their respective buffers.
  ---
  --- Unlike the legacy |hit-enter| prompt, messages exceeding 'cmdheight' are
  --- instead "collapsed", followed by a `[+x]` "spill" indicator, where `x`
  --- indicates the spilled lines. To see the full messages, do either:
  --- - ENTER immediately after interactive |:| cmdline shows a message and returns to |Normal-mode|.
  --- - |g<| at any time.
  require('vim._core.ui2').enable {
    enable = true,
    msg = { -- Options related to the message module.
      targets = 'cmd', ---@type 'cmd'|'msg' Default message target if not present in targets.
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

VimRc.icons = require 'custom.icons'
VimRc.now(function()
  -- vim.cmd 'colorscheme kanagawa'
  vim.cmd 'colorscheme gruvbox'
end)
VimRc.now(function()
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
VimRc.now(function()
  require('mini.starter').setup()
  -- starter.setup {
  --   items = {
  --     { action = 'FzfLua global', name = 'Browser', section = 'Fzf' },
  --     { action = 'FzfLua history', name = 'Command history', section = 'Fzf' },
  --     { action = 'FzfLua files', name = 'Files', section = 'Fzf' },
  --     { action = 'FzfLua helptags', name = 'Help tags', section = 'Fzf' },
  --     { action = 'FzfLua live_grep', name = 'Live grep', section = 'Fzf' },
  --     { action = 'FzfLua oldfiles', name = 'Old files', section = 'Fzf' },
  --   },
  --   content_hooks = {
  --     starter.gen_hook.adding_bullet(),
  --     starter.gen_hook.aligning('center', 'center'),
  --   },
  -- }
end)

VimRc.now(function()
  require('mini.statusline').setup()
end)
---

VimRc.now(function()
  require 'custom.notify'
end)
