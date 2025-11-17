---@module 'vectorcode'

return {
  setup = function()
    require('vectorcode')
      .setup
      ---@type VectorCode.Opts
 {
        notify = true,
        async_backend = 'default', -- or "lsp"
        -- n_query = 10,
        -- cli_cmds = { vectorcode = vim.fs.normalize '~/.local/bin/vectorcode' },
        timeout_ms = -1,
        ---@type VectorCode.RegisterOpts
        async_opts = {
          events = { 'BufWritePost' },
          single_job = true,
          query_cb = require('vectorcode.utils').make_surrounding_lines_cb(40),
          debounce = -1,
          n_query = 30,
        },
      }
  end,
}
