require('uv.init').setup {
  keymaps = {
    prefix = '<leader>x',  -- Main prefix for uv commands
    commands = true,       -- Show uv commands menu (<leader>x)
    run_file = false,      -- Run current file (<leader>xr)
    run_selection = false, -- Run selected code (<leader>xs)
    run_function = false,  -- Run function (<leader>xf)
    venv = true,           -- Environment management (<leader>xe)
    init = true,           -- Initialize uv project (<leader>xi)
    add = true,            -- Add a package (<leader>xa)
    remove = true,         -- Remove a package (<leader>xd)
    sync = false,          -- Sync packages (<leader>xc)
    sync_all = false,      -- Sync all packages, extras and groups (<leader>xC)
  },
}
require('custom.python.uv').setup()
