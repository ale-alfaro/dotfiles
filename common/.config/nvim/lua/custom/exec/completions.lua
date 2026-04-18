local M = {}
--- arglist    file names in argument list
--- augroup    autocmd groups
--- buffer    buffer names
--- breakpoint  |:breakadd| and |:breakdel| suboptions
--- cmdline    |cmdline-completion| result
--- color    color schemes
--- command    Ex command
--- compiler  compilers
--- custom,{func}  custom completion, defined via {func}
--- customlist,{func} custom completion, defined via {func}
--- diff_buffer  |:diffget| and |:diffput| completion
--- dir    directory names
--- dir_in_path  directory names in 'cdpath'
--- environment  environment variable names
--- event    autocommand events
--- expression  Vim expression
--- file    file and directory names
--- file_in_path  file and directory names in 'path'
--- filetype  filetype names 'filetype'
--- filetypecmd  |:filetype| suboptions
--- function  function name
--- help    help subjects
--- highlight  highlight groups
--- history    |:history| suboptions
--- keymap    keyboard mappings
--- locale    locale names (as output of locale -a)
--- mapclear  buffer argument
--- mapping    mapping name
--- menu    menus
--- messages  |:messages| suboptions
--- option    options
--- packadd    optional package |pack-add| names
--- retab    |:retab| suboptions
--- runtime    |:runtime| completion
--- scriptnames  sourced script names |:scriptnames|
--- shellcmd  Shell command
--- shellcmdline  Shell command line with filename arguments
--- sign    |:sign| suboptions
--- syntax    syntax file names 'syntax'
--- syntime    |:syntime| suboptions
--- tag    tags
--- tag_listfiles  tags, file names
--- user    user names
--- var    user variables
---

---@alias CompletionFunc fun(ArgLead?:string,CmdLine?:string,CursorPos?:integer):(string[],string?)
---
---
---
---
---
---
---
---
---
---
---
---
---
local get_complete_base = function(line)
  local from, _, res = line:find '(%S*)$'
  while from ~= nil do
    local cur_from, _, cur_res = line:sub(1, from - 1):find '(%S*\\ )$'
    if cur_res ~= nil then
      res = cur_res .. res
    end
    from = cur_from
  end
  return (res:gsub([[\ ]], ' '))
end

---- Get path completions when running user cmds
---@param cwd string
---@param base string
---@return string[],string?
M.command_complete_path = function(cwd, base)
  -- Treat base only as path relative to the command's cwd
  cwd = cwd:gsub('/+$', '') .. '/'
  local cwd_len = cwd:len()

  -- List elements from (absolute) target directory
  local target_dir = vim.fn.fnamemodify(base, ':h')
  target_dir = (cwd .. target_dir:gsub('^%.$', '')):gsub('/+$', '') .. '/'
  local ok, fs_entries = pcall(vim.fn.readdir, target_dir)
  if not ok then
    return {}
  end

  -- List directories and files separately
  local dirs, files = {}, {}
  for _, entry in ipairs(fs_entries) do
    local entry_abs = target_dir .. entry
    local arr = vim.fn.isdirectory(entry_abs) == 1 and dirs or files
    table.insert(arr, entry_abs)
  end
  dirs = vim.tbl_map(function(x)
    return x .. '/'
  end, dirs)

  -- List ordered directories first followed by ordered files
  local order_ignore_case = function(a, b)
    return a:lower() < b:lower()
  end
  table.sort(dirs, order_ignore_case)
  table.sort(files, order_ignore_case)

  -- Return candidates relative to command's cwd
  local all = dirs
  vim.list_extend(all, files)
  local res = vim.tbl_map(function(x)
    return x:sub(cwd_len + 1)
  end, all)
  return res, 'path'
end
---@type CompletionFunc
M.command_complete = function(_, line, col)
  -- Compute completion base manually to be "at cursor" and respect `\ `
  local base = get_complete_base(line:sub(1, col))
  local candidates, compl_type = M.command_get_complete_candidates(line, col, base)
  -- Allow several "//" at the end for path completion for easier "chaining"
  if compl_type == 'path' then
    base = base:gsub('/+$', '/')
  end
  return vim.tbl_filter(function(x)
    return vim.startswith(x, base)
  end, candidates)
end


-- Cover at least all subcommands listed in `git help`

--stylua: ignore
---@type table<string,fun(cwd:string,base:string):(string?,string[])>?
M.command_complete_subcommand_targets = {
  -- clone - no targets
  -- init  - no targets

  -- Worktree
  add     = M.command_complete_path,
  mv      = M.command_complete_path,
  restore = M.command_complete_path,
  rm      = M.command_complete_path,
  --
  -- -- Examine history
  -- -- bisect - no targets
  -- diff = H.command_complete_path,
  -- grep = H.command_complete_path,
  -- log  = H.make_git_cli_complete({ 'rev-parse', '--symbolic', '--branches', '--tags' }, 'ref'),
  -- show = H.make_git_cli_complete({ 'rev-parse', '--symbolic', '--branches', '--tags' }, 'ref'),
  -- -- status - no targets
  --
  -- -- Modify history
  -- branch = H.make_git_cli_complete({ 'rev-parse', '--symbolic', '--branches' },           'branch'),
  -- commit = H.command_complete_path,
  -- merge  = H.make_git_cli_complete({ 'rev-parse', '--symbolic', '--branches' },           'branch'),
  -- rebase = H.make_git_cli_complete({ 'rev-parse', '--symbolic', '--branches' },           'branch'),
  -- reset  = H.make_git_cli_complete({ 'rev-parse', '--symbolic', '--branches', '--tags' }, 'ref'),
  -- switch = H.make_git_cli_complete({ 'rev-parse', '--symbolic', '--branches' },           'branch'),
  -- tag    = H.make_git_cli_complete({ 'rev-parse', '--symbolic', '--tags' },               'tag'),
  --
  -- -- Collaborate
  -- fetch = H.make_git_cli_complete({ 'remote' }, 'remote'),
  -- push = H.command_complete_pullpush,
  -- pull = H.command_complete_pullpush,
  --
  -- -- Miscellaneous
  -- checkout = H.make_git_cli_complete({ 'rev-parse', '--symbolic', '--branches', '--tags', '--remotes' }, 'checkout'),
  -- config = H.make_git_cli_complete({ 'help', '--config-for-completion' }, 'config'),
  -- help = function()
  --   local res = { 'git', 'everyday' }
  --   vim.list_extend(res, H.git_subcommands.supported)
  --   return res, 'help'
  -- end,
}

M.cmds = {
  supported = {
    'append',
    'bookmark',
    'bookmarks',
    'daily',
    'delete',
    'diff',
    'file',
    'files',
    'folder',
    'folders',
    'move',
    'orphans',
    'outline',
    'prepend',
    'properties',
    ['property'] = { 'read', 'remove', 'set' },
    'read',
    'rename',
    'restart',
    'search',
    'task',
    'tasks',
    ['template'] = { 'read', 'insert' },
    ['templater'] = { 'create-from-template' },
    'templates',
    'tag',
    'tags',
    'vault',
    'vaults',
    'web',
  },
}

M.command_get_complete_candidates = function(line, col, base)
  -- Determine current Git subcommand as the earliest present supported one
  local subcmd, subcmd_end = nil, math.huge
  for _, cmd in pairs(M.cmds.supported) do
    local _, ind = line:find(' ' .. cmd .. ' ', 1, true)
    if ind ~= nil and ind < subcmd_end then
      subcmd, subcmd_end = cmd, ind
    end
  end

  subcmd = subcmd or 'git'
  local cwd = vim.fn.getcwd()

  -- Determine command candidates:
  -- - Commannd options if complete base starts with "-".
  -- - Paths if after explicit "--".
  -- - Git commands if there is none fully formed yet or cursor is at the end
  --   of the command (to also suggest subcommands).
  -- - Command targets specific for each command (if present).
  -- if vim.startswith(base, '-') then
  --   return H.command_complete_option(subcmd)
  -- end
  -- if line:sub(1, col):find ' -- ' ~= nil then
  --   return H.command_complete_path(cwd, base)
  -- end
  -- if subcmd_end == math.huge or (subcmd_end - 1) == col then
  --   return H.git_subcommands.complete, 'subcommand'
  -- end
  --
  -- subcmd = H.git_subcommands.alias[subcmd] or subcmd
  local complete_targets = M.command_complete_subcommand_targets[subcmd]
  if complete_targets == nil then
    return {}, nil
  end
  return complete_targets(cwd, base, line)
end

return M
