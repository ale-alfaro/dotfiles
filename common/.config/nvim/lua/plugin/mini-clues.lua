local miniclue = require 'mini.clue'
miniclue.enable_all_triggers()
miniclue.setup {
  triggers = {
    -- Builtins.
    { mode = { 'n', 'x' }, keys = 'g' },
    { mode = { 'n', 'x' }, keys = '`' },
    { mode = { 'n', 'x' }, keys = '"' },
    { mode = { 'i', 'c' }, keys = '<C-r>' },
    { mode = 'n', keys = '<C-w>' },
    { mode = 'i', keys = '<C-x>' },
    { mode = 'n', keys = 'z' },
    -- Leader triggers.
    { mode = { 'n', 'x' }, keys = '<leader>' },
    -- Moving between stuff.
    { mode = 'n', keys = '[' },
    { mode = 'n', keys = ']' },
  },
  clues = {
    -- Leader/movement groups.
    { mode = { 'n', 'x' }, keys = '<leader>a', desc = '+ai' },
    { mode = { 'n', 'x' }, keys = '<leader>c', desc = '+code' },
    { mode = { 'n', 'x' }, keys = '<leader>f', desc = '+find' },
    { mode = 'n', keys = '<leader>b', desc = '+buffers' },
    { mode = 'n', keys = '<leader>d', desc = '+debug' },
    { mode = 'n', keys = '<leader>t', desc = '+tabs' },
    { mode = 'n', keys = '<leader>x', desc = '+loclist/quickfix' },
    { mode = 'n', keys = '[', desc = '+prev' },
    { mode = 'n', keys = ']', desc = '+next' },
    -- Builtins.
    miniclue.gen_clues.g(),
    miniclue.gen_clues.marks(),
    miniclue.gen_clues.registers(),
    miniclue.gen_clues.windows(),
    miniclue.gen_clues.z(),
  },
  window = {
    delay = 500,
  },
}
