-- local function create_cmd()
--   local pyrefly_cmd = {
--     'uvx',
--     'pyrefly',
--     'lsp',
--   }
--   local cwd = vim.fn.getcwd()
--   local pyrefly_cfg = vim.fs.find({ 'pyrefly.toml' }, { path = cwd, type = 'file' })
--   if pyrefly_cfg and #pyrefly_cfg == 1 then
--     VimRc.info('Single file mode detected. Using config file at ' .. pyrefly_cfg[1])
--     vim.fn.setenv('PYREFLY_CONFIG', pyrefly_cfg[1])
--   end
--   return pyrefly_cmd
-- end

---@type vim.lsp.Config
return {
  cmd = { 'pyrefly', 'lsp' },
  filetypes = { 'python' },
  root_markers = {
    'pyrefly.toml',
    'pyproject.toml',
    'setup.py',
    'setup.cfg',
    'requirements.txt',
    'Pipfile',
    '.git',
  },
  on_exit = function(code, _, _)
    vim.notify('Closing Pyrefly LSP exited with code: ' .. code, vim.log.levels.INFO)
  end,
}
