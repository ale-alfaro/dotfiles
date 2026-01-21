-- Slash command helpers
local function get_loclists_or_qf_entries()
  local diagnostics = {}
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    local loclist = vim.fn.getloclist(winid)
    if #loclist > 0 then
      vim.list_extend(diagnostics, loclist)
    end
  end
  if #diagnostics == 0 then
    diagnostics = vim.fn.getqflist()
  end

  local seen, entries, context = {}, {}, {}
  for _, item in ipairs(diagnostics) do
    local filename = vim.fs.basename(vim.api.nvim_buf_get_name(item.bufnr))
    local lnum = item.lnum or 0
    local col = item.col or 0
    local text = item.text or ''
    local key = table.concat({ filename, lnum, col, text }, '\0')
    if not seen[key] then
      seen[key] = true
      table.insert(entries, string.format('%s:%d:%d: %s', filename, lnum, col, text))
      if filename ~= '' and not vim.tbl_contains(context, filename) then
        table.insert(context, filename)
      end
    end
  end
  return table.concat(entries, '\n'), context
end
local function get_git_root()
  local result = vim.system({ 'git', 'rev-parse', '--show-toplevel' }, { text = true }):wait()
  local output = vim.split(vim.trim(result.stdout or ''), '\n', { plain = true })
  if result.code ~= 0 or not output[1] or output[1] == '' then
    return nil, 'Not inside a Git repository. Could not determine the project root.'
  end
  return output[1]
end

local function to_absolute_paths(files, root)
  return vim
    .iter(files)
    :map(function(f)
      if f == '' then
        return nil
      end
      local abs_path = vim.fs.normalize(vim.fs.joinpath(root, f))
      local stat = vim.uv.fs_stat(abs_path)
      if stat and stat.type == 'file' then
        return abs_path
      end
      return nil
    end)
    :filter(function(f)
      return f ~= nil
    end)
    :totable()
end

local function resolve_git_diff_and_filelist_cmds(opts)
  local diff_cmd = { 'git', 'diff', '--no-ext-diff' }
  local file_list_cmd = { 'git', 'diff', '--name-only' }

  if opts and opts.base_branch then
    local base = opts.base_branch
    local result = vim.system({ 'git', 'rev-parse', '--verify', base }, { text = true }):wait()
    if result.code ~= 0 then
      return nil, nil, 'Base branch not found: ' .. base
    end
    table.insert(diff_cmd, base .. '...HEAD')
    table.insert(file_list_cmd, base .. '...HEAD')
  elseif opts and opts.commit_sha then
    local sha = opts.commit_sha
    table.insert(diff_cmd, sha .. '^!')
    table.insert(file_list_cmd, sha .. '^!')
  else
    table.insert(diff_cmd, '--staged')
    table.insert(file_list_cmd, '--cached')
  end

  return diff_cmd, file_list_cmd
end

local function get_git_files(git_root, file_list_cmd)
  local file_list_result = vim.system(file_list_cmd, { text = true }):wait()
  local files = vim.split(vim.trim(file_list_result.stdout or ''), '\n', { plain = true })
  if #files == 0 or (#files == 1 and files[1] == '') then
    return {}, 'No relevant files found'
  end
  return to_absolute_paths(files, git_root)
end

local function get_majority_filetype(files)
  local counts = {}
  local max_ft, max_count = nil, 0
  for _, file in ipairs(files) do
    local ft = vim.filetype.match { filename = file }
    if ft and ft ~= '' then
      counts[ft] = (counts[ft] or 0) + 1
      if counts[ft] > max_count then
        max_count = counts[ft]
        max_ft = ft
      end
    end
  end
  -- Only return a filetype if it appears in more than half of the files
  if max_count > (#files / 2) then
    return max_ft
  end
  return nil
end

local function send_project_tree(chat, root)
  local result = vim.system({ 'eza', '-a', '-L', '2', root }, { text = true }):wait()
  local tree = result.stdout or ''
  chat:add_message {
    role = 'user',
    content = string.format('The project structure is given by:\n%s', tree),
  }
end

---@type CodeCompanion.SlashCommands[]
return {
  -- Custom
  ['file_path'] = {
    description = 'Insert a filepath',
    keymaps = { modes = { n = '<C-f>', i = '<C-f>' } },
    callback = function()
      vim.ui.input({ prompt = 'File path: ', completion = 'file' }, function(file)
        local stat = file and vim.uv.fs_stat(file)
        if not (stat and stat.type == 'file') then
          vim.notify(string.format('File not found: %s', file), vim.log.levels.ERROR)
          return
        end
        VimRc.CodeCompanionConfig.add_context { file }
      end)
    end,
  },
  ['directory_contents'] = {
    description = 'Insert all files in a directory',
    callback = function(chat)
      vim.ui.input({ prompt = 'Context dir: ', completion = 'dir' }, function(dir)
        dir = vim.fs.normalize(vim.trim(dir)):gsub('/$', '')
        vim.cmd.redraw { bang = true }
        local stat = vim.uv.fs_stat(dir)
        if not (stat and stat.type == 'directory') then
          VimRc.err('Directory not found: ' .. dir, vim.log.levels.ERROR)
          return
        end

        local files = {}
        for name, type in vim.fs.dir(dir) do
          if type == 'file' then
            table.insert(files, vim.fs.joinpath(dir, name))
          end
        end

        send_project_tree(chat, dir)
        VimRc.CodeCompanionConfig.add_context(files)
      end)
    end,
  },
  ['git_files'] = {
    description = 'List git files',
    ---@param chat CodeCompanion.Chat
    callback = function(chat)
      local handle = io.popen 'git ls-files'
      if handle ~= nil then
        local result = handle:read '*a'
        handle:close()
        chat:add_context({ role = 'user', content = result }, 'git', '<git_files>')
      else
        return vim.notify('No git files available', vim.log.levels.INFO, { title = 'CodeCompanion' })
      end
    end,
    opts = {
      contains_code = false,
    },
  },
  ['git_ls_files'] = {
    description = 'Insert all files in git repo',
    callback = function(chat)
      local git_root, err = get_git_root()
      if not git_root then
        vim.notify(err, vim.log.levels.ERROR)
        return
      end
      local result = vim.system({ 'git', 'ls-files', '--full-name', git_root }, { text = true }):wait()
      local git_files = vim.split(vim.trim(result.stdout or ''), '\n', { plain = true })

      local ignore_exts = { ['.png'] = true }
      local function has_ignored_ext(filename)
        local ext = filename:match '(%.[^%.]+)$' or ''
        return ignore_exts[ext] or false
      end
      local files = vim
        .iter(git_files)
        :filter(function(f)
          return not has_ignored_ext(f)
        end)
        :map(function(f)
          return vim.fs.joinpath(git_root, f)
        end)
        :totable()

      send_project_tree(chat, git_root)
      VimRc.CodeCompanionConfig.add_context(files)
    end,
  },
  -- ['py_files'] = {
  --   description = 'Insert all project python files',
  --   callback = function(chat)
  --     send_project_tree(chat, _G.PyVenv.active_venv.project_root)
  --     VimRc.CodeCompanionConfig.add_context(_G.PyVenv.active_venv.project_files)
  --   end,
  -- },

  ['explain_qfix'] = {
    description = 'Explain quickfix/loclist code diagnostics',
    callback = function(chat)
      local entries, context = get_loclists_or_qf_entries()
      if entries == '' then
        vim.notify('No diagnostics found in quickfix or location lists.', vim.log.levels.ERROR)
        return
      end
      VimRc.CodeCompanionConfig.add_context(context)
      chat:add_buf_message {
        role = 'user',
        content = string.format(VimRc.PROMPT_LIBRARY['quickfix'], entries),
      }
      chat:submit()
    end,
  },
  ['conventional_commit'] = {
    description = 'Generate a conventional git commit message',
    callback = function(chat, opts)
      local git_root, err = get_git_root()
      if not git_root then
        vim.notify(err, vim.log.levels.ERROR)
        return
      end

      local diff_cmd, file_list_cmd, error = resolve_git_diff_and_filelist_cmds(opts)
      if not diff_cmd then
        vim.notify(error, vim.log.levels.ERROR)
        return
      end

      local abs_files, file_err = get_git_files(git_root, file_list_cmd)
      if file_err then
        vim.notify(file_err, vim.log.levels.WARN)
        return
      end
      VimRc.CodeCompanionConfig.add_context(abs_files)

      local commit_history_result = vim.system({ 'git', 'log', '-n', '50', '--pretty=format:%s' }, { text = true }):wait()
      local commit_history = vim.trim(commit_history_result.stdout or '')

      local diff_result = vim.system(diff_cmd, { text = true }):wait()
      local diff_output = diff_result.stdout or ''

      chat:add_buf_message {
        role = 'user',
        content = string.format(VimRc.PROMPT_LIBRARY['conventional_commits'], commit_history, diff_output),
      }
      chat:submit()
    end,
  },
  ['code_review'] = {
    description = 'Perform a code review',
    callback = function(_, opts)
      local git_root, err = get_git_root()
      if not git_root then
        vim.notify(err, vim.log.levels.ERROR)
        return
      end

      local diff_cmd, file_list_cmd, error = resolve_git_diff_and_filelist_cmds(opts)
      if not diff_cmd then
        vim.notify(error, vim.log.levels.ERROR)
        return
      end

      local abs_files, file_err = get_git_files(git_root, file_list_cmd)
      if file_err then
        vim.notify(file_err, vim.log.levels.WARN)
        return
      end

      -- Determine majority filetype and call the prompt for that filetype
      local ft = get_majority_filetype(abs_files)
      local prompt_short_name = VimRc.ft_prompt_map[ft] or 'assistant_role'
      VimRc.codecompanion.prompt(prompt_short_name)
      local chat = VimRc.codecompanion.last_chat() or VimRc.codecompanion.chat()
      if not chat then
        VimRc.warn 'Could not get cc chat '
        return
      end

      VimRc.CodeCompanionConfig.add_context(abs_files)

      local diff_result = vim.system(diff_cmd, { text = true }):wait()
      local diff_output = diff_result.stdout or ''

      chat:add_buf_message {
        role = 'user',
        content = string.format(VimRc.PROMPT_LIBRARY['code_reviewer'], diff_output),
      }
      chat:submit()
    end,
  },
}
