---@return string, string
local prefix = function(fs_entry)
  -- Prefer 'mini.icons'
  local filetype = vim.fn.getftype(fs_entry.path)
  if filetype == 'link' then
    return VimRc.icons.os.Interface .. ' ', 'MiniFilesSymLink'
  else
    local category = fs_entry.fs_type == 'directory' and 'directory' or 'file'
    if category == 'directory' then
      return VimRc.icons.os.Folder .. ' ', 'MiniFilesDirectory'
    else
      if MiniIcons ~= nil then
        local icon, hl = MiniIcons.get(category, fs_entry.path)
        return icon .. ' ', hl
      else
        -- Try falling back to 'nvim-web-devicons'
        return ' ', 'MiniFilesFile'
      end
    end
  end
end
return {
  setup = function()
    ---
    ---
    vim.api.nvim_set_hl(0, 'MiniFilesSymLink', { link = 'PmenuExtra' })

    require('mini.files').setup {
      windows = {
        -- Whether to show preview of file/directory under cursor
        preview = true,
        -- Width of focused window
        width_focus = 80,
        -- Width of non-focused window
        width_nofocus = 15,
        --
        -- Width of preview window
        width_preview = 25,
      },
      options = {
        permanent_delete = false,
        use_as_default_explorer = false,
      },
      content = {
        prefix = prefix,
      },
      mappings = {
        close = 'q',
        go_in = '<CR>',
        go_in_plus = '<Right>',
        go_out = '<BS>',
        go_out_plus = '<Left>',
        mark_goto = '<localleader>g',
        mark_set = '<localleader>m',
      },
    }
    ---@param evt string|string[]
    ---@param cb function
    ---@param desc string?
    local minifiles_autocmd = function(evt, cb, desc, other)
      vim.api.nvim_create_autocmd('User', { pattern = 'MiniFiles' .. evt, callback = cb, desc = 'MiniFiles ' .. desc })
    end

    minifiles_autocmd('BufferCreate', function(args)
      vim.b.minisurround_disable = false
      vim.b.minioperators_disable = false
      local b = args.data.buf_id
      vim.keymap.set('n', '<C-g>', function()
        -- works only if cursor is on the valid file system entry
        local cur_entry_path = (MiniFiles.get_fs_entry() or {}).path
        local prefills = { paths = vim.fs.dirname(cur_entry_path) }

        local grug_far = require 'grug-far'

        -- instance check
        if not grug_far.has_instance 'explorer' then
          grug_far.open {
            instanceName = 'explorer',
            prefills = prefills,
            staticTitle = 'Find and Replace from Explorer',
          }
        else
          grug_far.get_instance('explorer'):open()
          -- updating the prefills without crealing the search and other fields
          grug_far.get_instance('explorer'):update_input_values(prefills, false)
        end
      end, { buf = b, desc = 'Search' })
      vim.keymap.set('n', 'q', '<Cmd>lua MiniFiles.close()<CR>', { buf = b, desc = 'close' })
      vim.keymap.set(
        'n',
        'gy',
        '<Cmd>lua vim.fn.setreg(vim.v.register, (MiniFiles.get_fs_entry() or {path = vim.fn.getcwd()}).path)<CR>',
        { buf = b, desc = 'Yank Path' }
      )
      vim.keymap.set('n', 'gx', '<Cmd>lua vim.ui.open(MiniFiles.get_fs_entry().path)<cr>', { buf = b, desc = 'OS open' })
      MiniClue.ensure_buf_triggers(b)
    end, 'Mappings')

    minifiles_autocmd('BufferUpdate', function(ev)
      if ev.buf_id then
        local path = (MiniFiles.get_explorer_state() or {}).anchor or (MiniFiles.get_fs_entry(ev.buf_id) or {}).path
        if path then
          MiniVisits.add_path('mini_files', path)
          MiniVisits.add_label('mini_files', path)
        end
      end
    end, '')
    minifiles_autocmd('ExplorerOpen', function()
      ---@type string[]
      local visits = MiniVisits.list_paths(nil, {
        sort = MiniVisits.gen_sort.default { recency_weight = 1.0 },
      })
      local n = math.min(5, #visits)
      for i = 1, n do
        if not type(visits[i]) == 'string' then
          VimRc.warn('Not a string ', { visits = visits[i] })
        elseif vim.uv.fs_stat(visits[i]) == nil then
          VimRc.warn('Not a valid path', { visits = visits[i] })
        else
          MiniFiles.set_bookmark(string.format('%d', i), vim.fs.dirname(visits[i]), { desc = string.format('%d: %s', i, vim.fs.dirname(visits[i])) }) -- callable
        end
      end
    end, 'Bookmarks')
    minifiles_autocmd('ActionRename', function(event)
      local from = event.data.from
      local to = event.data.to
      local changes = {
        files = {
          {
            oldUri = vim.uri_from_fname(from),
            newUri = vim.uri_from_fname(to),
          },
        },
      }

      local clients = vim.lsp.get_clients()
      for _, client in ipairs(clients) do
        if client:supports_method 'workspace/willRenameFiles' then
          local resp = client:request_sync('workspace/willRenameFiles', changes, 1000, 0)
          if resp and resp.result ~= nil then
            vim.lsp.util.apply_workspace_edit(resp.result, client.offset_encoding)
          end
        end
      end
      for _, client in ipairs(clients) do
        if client:supports_method 'workspace/didRenameFiles' then
          client:notify('workspace/didRenameFiles', changes)
        end
      end
    end, 'Rename Files')
  end,
}
