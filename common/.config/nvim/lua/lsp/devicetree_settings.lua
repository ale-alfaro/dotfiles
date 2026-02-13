local log = require 'overseer.log'
local lsp_settings = require 'lsp.settings'

local M = {}

local function read_file(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return nil
  end
  return table.concat(lines, '\n')
end

local function is_list(value)
  return type(value) == 'table' and vim.tbl_islist(value)
end

local function merge_settings(defaults, overrides)
  if overrides == nil then
    return defaults
  end
  if type(defaults) ~= 'table' or type(overrides) ~= 'table' then
    return overrides
  end
  if is_list(defaults) or is_list(overrides) then
    return overrides
  end

  local out = vim.deepcopy(defaults)
  for key, value in pairs(overrides) do
    out[key] = merge_settings(defaults[key], value)
  end
  return out
end

local function normalize_keys(entry)
  local normalized = {}
  for key, value in pairs(entry) do
    if vim.startswith(key, 'devicetree.') then
      normalized[key:sub(#'devicetree.' + 1)] = value
    else
      normalized[key] = value
    end
  end
  return normalized
end

local function normalize_contexts(contexts)
  if not is_list(contexts) then
    return contexts
  end

  local normalized = {}
  for _, context in ipairs(contexts) do
    if type(context) == 'table' then
      table.insert(normalized, normalize_keys(context))
    else
      table.insert(normalized, context)
    end
  end
  return normalized
end

local function extract_devicetree_settings(data)
  local devicetree = {}
  for key, value in pairs(data) do
    if key == 'devicetree' and type(value) == 'table' then
      devicetree = vim.tbl_deep_extend('force', devicetree, value)
    elseif vim.startswith(key, 'devicetree.') then
      devicetree[key:sub(#'devicetree.' + 1)] = value
    end
  end

  if devicetree.contexts then
    devicetree.contexts = normalize_contexts(devicetree.contexts)
  end

  return devicetree
end

local function build_precalculated_vars(root)
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname == '' then
    bufname = vim.fn.getcwd()
  end

  local file_dir = vim.fs.dirname(bufname)
  local file_root = M.get_workspace_root(file_dir) or root or vim.fn.getcwd()
  local workspace_root = root or file_root or vim.fn.getcwd()
  local relative_file = vim.fn.fnamemodify(bufname, ':.')

  return {
    workspaceFolder = workspace_root,
    workspaceFolderBasename = vim.fs.basename(workspace_root),
    file = bufname,
    fileWorkspaceFolder = file_root,
    relativeFile = relative_file,
    relativeFileDirname = vim.fs.dirname(relative_file),
    fileBasename = vim.fn.fnamemodify(bufname, ':t'),
    fileBasenameNoExtension = vim.fn.fnamemodify(bufname, ':t:r'),
    fileDirname = vim.fn.fnamemodify(bufname, ':h'),
    fileExtname = vim.fn.fnamemodify(bufname, ':e'),
    lineNumber = vim.api.nvim_win_get_cursor(0)[1],
    selectedText = lsp_settings.get_selected_text(),
    cwd = workspace_root,
  }
end

local function get_workspace_root_from_lsp()
  local clients = vim.lsp.get_clients { name = 'devicetree_ls' }
  if not clients or #clients == 0 then
    clients = vim.lsp.get_clients { name = 'devicetree' }
  end
  local client = clients and clients[1]
  local folders = client and client.workspace_folders
  local folder = folders and folders[1]
  if not folder or not folder.uri then
    return nil
  end
  return vim.uri_to_fname(folder.uri)
end

function M.get_workspace_root(start_path)
  local lsp_root = get_workspace_root_from_lsp()
  if lsp_root and lsp_root ~= '' then
    return lsp_root
  end

  local path = start_path
  if not path or path == '' then
    path = vim.api.nvim_buf_get_name(0)
    if path == '' then
      path = vim.fn.getcwd()
    end
  end

  local west_dir = vim.fs.find('.west', { upward = true, type = 'directory', path = path })[1]
  if not west_dir then
    return nil
  end
  return vim.fs.dirname(west_dir)
end

function M.load_vscode_settings(settings_path)
  local content = read_file(settings_path)
  if not content or content == '' then
    return nil
  end

  local ok, decoded = pcall(vim.json.decode, content)
  if not ok or type(decoded) ~= 'table' then
    log.warn('Failed to parse VS Code settings from %s', settings_path)
    return nil
  end

  return decoded
end
---@param workspace_folder lsp.WorkspaceFolder
function M.load_devicetree_settings(workspace_folder)
  local settings_path = vim.fs.joinpath(vim.uri_to_fname(workspace_folder.uri), '.vscode', 'settings.json')
  if not vim.uv.fs_stat(settings_path) then
    VimRc.error 'No .vscode/settings.json found'
    return nil
  end
  local data = M.load_vscode_settings(settings_path)
  if not data then
    VimRc.error "Couldn't load settings.json"
    return nil
  end

  local devicetree = extract_devicetree_settings(data)
  local precalculated = build_precalculated_vars(vim.uri_to_fname(workspace_folder.uri))
  return lsp_settings.replace_vars(devicetree, {}, precalculated)
end

function M.get_settings(defaults, start_path)
  local overrides = M.load_devicetree_settings(start_path)
  if not overrides then
    return defaults
  end
  return merge_settings(defaults, overrides)
end

return M
