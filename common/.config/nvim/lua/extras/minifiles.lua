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
---@param id string
---@param path string
---@param desc string
---@param opts? {save?:boolean}
local set_mark = function(id, path, desc, opts)
  opts = opts or {}
  MiniFiles.set_bookmark(id, path, { desc = desc })
  if opts.save then
    MiniVisits.add_label(id, path)
  end
  ---   local map_branch = function(keys, action, desc)
  ---     local rhs = function()
  ---       local branch = vim.fn.system('git rev-parse --abbrev-ref HEAD')
  ---       if vim.v.shell_error ~= 0 then return nil end
  ---       branch = vim.trim(branch)
  ---       require('mini.visits')[action](branch)
  ---     end
  ---     vim.keymap.set('n', '<Leader>' .. keys, rhs, { desc = desc })
  ---   end
end
local files_grug_far_replace = function()
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
        width_focus = 50,
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
      ---@param lhs string
      ---@param rhs string
      ---@param desc string
      local buf_map = function(lhs, rhs, desc)
        vim.api.nvim_buf_set_keymap(b, 'n', '<localleader>' .. lhs, rhs, { desc = desc })
      end
      buf_map('q', '<cmd>lua MiniFiles.close()<cr>', 'close')
      vim.api.nvim_buf_create_user_command(b, 'Search', files_grug_far_replace, { desc = 'Search' })
      buf_map('s', '<cmd>Search<cr>', 'Search in directory')
      local localleader_buf_map = function(lhs, rhs, desc)
        buf_map('<localleader>' .. lhs, rhs, desc)
      end
      vim.api.nvim_buf_create_user_command(b, 'Yank', function()
        local path = (MiniFiles.get_fs_entry() or {}).path
        if path == nil then
          return vim.notify 'Cursor is not on valid entry'
        end
        vim.fn.setreg(vim.v.register, path)
      end, { desc = 'Yank Path' })
      vim.api.nvim_buf_create_user_command(b, 'Cwd', function()
        local path = (MiniFiles.get_fs_entry() or {}).path
        if path == nil then
          return vim.notify 'Cursor is not on valid entry'
        end
        vim.fn.chdir(vim.fs.dirname(path))
      end, { desc = 'Change Cwd' })
      localleader_buf_map('~', '<cmd>Cwd<cr>', 'Set cwd')
      localleader_buf_map('y', '<cmd>Yank<cr>', 'Yank path')
      localleader_buf_map('X', '<cmd>lua vim.ui.open(MiniFiles.get_fs_entry().path)<cr>', 'OS open')
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
      local paths = vim
        .iter(MiniVisits.list_paths(nil, {
          filter = function()
            return function(path_data)
              return path_data.labels['mini.files'] ~= nil
            end
          end,
          sort = MiniVisits.gen_sort.default { recency_weight = 1.0 },
        }))
        :map(function(p)
          return vim.fs.dirname(p)
        end)
        :unique()
        :totable()
      local n = math.min(5, #paths) + 1
      for i = 1, n do
        set_mark(tostring(i), paths[i], 'Prev path ' .. paths[i]) -- callable
      end

      set_mark('w', vim.fn.getcwd(), 'Working directory') -- callable
    end, 'Bookmarks')
    minifiles_autocmd('ActionRename', function(event)
      local from = event.data.from
      local to = event.data.to
      local changes = {
        files = { {
          oldUri = vim.uri_from_fname(from),
          newUri = vim.uri_from_fname(to),
        } },
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
