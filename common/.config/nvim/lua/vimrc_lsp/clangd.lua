-- Pick and symlink the active compile_commands.json at the west topdir, the way
-- clangd expects (see the docstring in after/lsp/clangd.lua). One active build
-- at a time; re-point with `:ClangdDb`. clangd reads the file natively, so no
-- settings translation is needed -- unlike the dts LSP (see vimrc_lsp.dts).
local M = {}

M.db = 'compile_commands.json'

--- Nudge running clangd clients to reload the compilation database. clangd
--- reloads compile_commands.json on a watched-file change notification.
M.reload = function()
  if not M._topdir then
    return
  end
  local uri = vim.uri_from_fname(
    vim.fs.joinpath(
      M._topdir,
      M.db
    )
  )
  for _, c in ipairs(
    vim.lsp.get_clients { name = 'clangd' }
  ) do
    c:notify(
      'workspace/didChangeWatchedFiles',
      { changes = { { uri = uri, type = 2 } } }
    ) -- 2 = Changed
  end
end

--- Pick a compile_commands.json and symlink it to the topdir.
M.use = function()
  if not M._topdir then
    VimRc.warn '[clangd] no west workspace'
    return
  end
  local found = vim.fn.systemlist { 'fd', '--no-ignore', '--hidden', '--type', 'f', '--glob', M.db, M._topdir }
  found = vim
    .iter(found)
    :filter(function(p)
      return not p:find(
        '/twister%-out/'
      ) -- test-runner scratch, never edited
    end)
    :totable()
  if #found == 0 then
    VimRc.warn '[clangd] no compile_commands.json found (build an app first)'
    return
  end
  vim.ui.select(
    found,
    {
      prompt = 'Active compile_commands.json:',
      format_item = function(p)
        return vim.fn.fnamemodify(
          p,
          ':~:.'
        )
      end,
    },
    function(choice)
      if not choice then
        return
      end
      local link = vim.fs.joinpath(
        M._topdir,
        M.db
      )
      -- Only ever manage our own symlink; never clobber a real file at the root.
      local st = vim.uv.fs_lstat(
        link
      )
      if st and st.type ~= 'link' then
        VimRc.warn(
          '[clangd] ' .. link .. ' exists and is not a symlink; leaving it'
        )
        return
      end
      pcall(
        vim.uv.fs_unlink,
        link
      )
      local ok, err = vim.uv.fs_symlink(
        choice,
        link
      )
      if not ok then
        VimRc.warn(
          '[clangd] could not create ' .. link .. ': ' .. (err or '')
        )
        return
      end
      M.reload()
      VimRc.info(
        '[clangd] active db: '
          .. vim.fn.fnamemodify(
            choice,
            ':~:.'
          )
      )
    end
  )
end

--- Walk callHierarchy/incomingCalls `depth` levels up and show them in Trouble.
--- Trouble sorts by file, so each entry is tagged with its level (L1 = direct caller).
local function incoming_calls(depth)
  local client = vim.lsp.get_clients({ bufnr = 0, method = 'callHierarchy/incomingCalls' })[1]
  if not client then
    VimRc.warn '[clangd] no client with call hierarchy on this buffer'
    return
  end
  local items = {}

  local function walk(item, level)
    if level > depth then return end
    local res = client:request_sync(
      'callHierarchy/incomingCalls',
      { item = item },
      2000,
      0
    )
    for _, call in ipairs(
      res and res.result or {}
    ) do
      local from = call.from
      table.insert(items, {
        filename = vim.uri_to_fname(
          from.uri
        ),
        lnum = from.selectionRange.start.line + 1,
        col = from.selectionRange.start.character + 1,
        text = ('L%d %s'):format(
          level,
          from.name
        ),
      })
      walk(
        from,
        level + 1
      )
    end
  end

  local params = vim.lsp.util.make_position_params(
    0,
    client.offset_encoding
  )
  local prep = client:request_sync(
    'textDocument/prepareCallHierarchy',
    params,
    2000,
    0
  )
  for _, item in ipairs(
    prep and prep.result or {}
  ) do
    walk(
      item,
      1
    )
  end

  vim.fn.setqflist(
    {},
    ' ',
    { title = 'Incoming calls', items = items }
  )
  vim.cmd(
    'Trouble qflist open'
  )
end

---@param topdir string         west workspace top directory
M.setup = function(topdir)
  M._topdir = topdir
  vim.api.nvim_create_user_command(
    'ClangdDb',
    M.use,
    { desc = 'Select the active compile_commands.json for clangd' }
  )
  vim.api.nvim_create_user_command('ClangdDbReload', M.reload, {
    desc = 'Tell clangd to reload the compilation database',
  })
  vim.keymap.set(
    'n', 'grI',
    function()
      incoming_calls(
        3
      )
    end,
    { desc = 'Incoming calls, 3 levels' }
  )
end

return M
