VimRc.now(function()
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
      targets = 'msg', ---@type 'cmd'|'msg' Default message target if not present in targets.
      cmd = { -- Options related to messages in the cmdline window.
        height = 0, -- Maximum height while expanded for messages beyond 'cmdheight'.
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
  -- vim.cmd 'colorscheme gruvbox'
  vim.cmd 'colorscheme miniwinter'
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
  local starter = require 'mini.starter'
  starter.setup {
    items = {
      { action = 'FzfLua files', name = 'Files', section = 'Fzf' },
      { action = 'FzfLua oldfiles', name = 'Old files', section = 'Fzf' },
      { action = 'FzfLua visits', name = 'Visits', section = 'Fzf' },
      { action = 'FzfLua live_grep', name = 'Live grep', section = 'Fzf' },
    },
    content_hooks = {
      starter.gen_hook.adding_bullet(),
      starter.gen_hook.aligning('center', 'center'),
    },
  }
end)

VimRc.now(function()
  require('extras.image').setup_image_snacks()
end)
VimRc.now(function()
  require('mini.statusline').setup()
end)
---

VimRc.now_if_args(function()
  NOTIFY_WIDTH = 120
  --- to display progress when the server supports percentages
  ---@param notif_arr Notification[]
  local show_notifications = function(notif_arr)
    local ns_id = vim.api.nvim_create_namespace 'MiniNotifyHighlight'

    local buf_id
    for _, id in ipairs(vim.api.nvim_list_bufs()) do
      if vim.bo[id].filetype == 'vimrc-notify' then
        buf_id = id
      end
    end
    -- Ensure clear buffer
    -- vim.api.nvim_buf_clear_namespace(buf_id, ns_id, 0, -1)
    -- vim.api.nvim_buf_set_lines(buf_id, 0, -1, true, {})

    -- Compute lines and highlight regions
    local lines, highlights = {}, {}
    for _, notif in ipairs(notif_arr) do
      local notif_lines = vim.split(notif.msg, '\n')
      for _, l in ipairs(notif_lines) do
        table.insert(lines, l)
      end
      table.insert(highlights, { group = notif.hl_group, from_line = #lines - #notif_lines + 1, to_line = #lines })
    end

    if buf_id ~= nil then
      vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
    else
      buf_id = VimRc.show_in_split(lines, 'vimrc://notify')
    end
    -- Set lines and highlighting
    local extmark_opts = { end_col = 0, hl_eol = true, hl_mode = 'combine' }
    for _, hi_data in ipairs(highlights) do
      extmark_opts.end_row, extmark_opts.hl_group = hi_data.to_line, hi_data.group
      vim.api.nvim_buf_set_extmark(buf_id, ns_id, hi_data.from_line - 1, 0, extmark_opts)
    end
    vim.api.nvim_set_current_buf(buf_id)
  end

  ---@param pred (fun(Notification):boolean)?
  ---@param format (fun(Notification):string)?
  local get_notif_arr = function(pred, format)
    -- Get notifications based on predicate
    local notif_arr = MiniNotify.get_all()
    if pred then
      notif_arr = vim.tbl_filter(function(notif)
        return pred(notif)
      end, notif_arr)
    end
    -- Prepare content
    table.sort(notif_arr, function(a, b)
      return a.ts_update < b.ts_update
    end)
    format = format or MiniNotify.default_format
    for _, notif in ipairs(notif_arr) do
      local res = format(notif)
      if type(res) ~= 'string' then
        VimRc.err 'Output of `content.format` should be string.'
      end
      notif.msg = res
    end
    return notif_arr
  end

  require('mini.notify').setup()
  vim.notify = MiniNotify.make_notify()

  local keymaps = {
    {
      'a',
      function()
        -- Get active notifications
        local notifs = get_notif_arr(function(notif)
          return notif.ts_remove ~= nil
        end)
        show_notifications(notifs)
      end,
      'All',
    },
    {
      'h',
      '<Cmd>lua MiniNotify.show_history()<CR>',
      'History',
    },
    {
      'e',
      function()
        -- Get active notifications
        local err_notifs = get_notif_arr(function(notif)
          return notif.level == 'ERROR'
        end)
        show_notifications(err_notifs)
      end,
      'Errors',
    },
    {
      'd',
      '<Cmd>lua MiniNotify.clear()<CR>',
      'Dismiss',
    },
  }

  for _, k in ipairs(keymaps) do
    vim.keymap.set('n', '<leader>n' .. k[1], k[2], { desc = k[3] })
  end
end)
