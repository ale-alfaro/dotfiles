return {
  {
    'folke/snacks.nvim',
    opts = {
      dashboard = { enabled = false },
      terminal = { enabled = false },
    },
    -- stylua: ignore
    keys = {
      {"<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers" },
      { "<leader>/", LazyVim.pick("grep", { hidden = true }), desc = "Grep (Root Dir)" },
      { "<leader>:",  false },--function() Snacks.picker.command_history() end, desc = "Command History" },
      { "<leader><space>", false},--LazyVim.pick("files"), desc = "Find Files (Root Dir)" },
      -- { "<leader>n", function() Snacks.picker.notifications() end, desc = "Notification History" },
      -- -- find
      -- { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
      -- { "<leader>fB", function() Snacks.picker.buffers({ hidden = true, nofile = true }) end, desc = "Buffers (all)" },
      -- { "<leader>fc", LazyVim.pick.config_files(), desc = "Find Config File" },
      { "<leader>ff", LazyVim.pick("files", {hidden = true}), desc = "Find Files (Root Dir)" },
      { "<leader>fF", LazyVim.pick("files", { hidden = true, root = false }), desc = "Find Files (cwd)" },
      --Floating terminal
      {"<leader>fT", false},
      {"<leader>ft", false},
      -- { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Find Files (git-files)" },
      -- { "<leader>fr", LazyVim.pick("oldfiles"), desc = "Recent" },
      -- { "<leader>fR", function() Snacks.picker.recent({ filter = { cwd = true }}) end, desc = "Recent (cwd)" },
      -- { "<leader>fp", function() Snacks.picker.projects() end, desc = "Projects" },
      -- -- git
      -- { "<leader>gd", function() Snacks.picker.git_diff() end, desc = "Git Diff (hunks)" },
      -- { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Git Status" },
      -- { "<leader>gS", function() Snacks.picker.git_stash() end, desc = "Git Stash" },
      -- -- Grep
      { "<leader>sb" , false}, --  function() Snacks.picker.lines() end, desc = "Buffer Lines" },
      -- { "<leader>sB", function() Snacks.picker.grep_buffers() end, desc = "Grep Open Buffers" },
      -- { "<leader>sg", LazyVim.pick("live_grep"), desc = "Grep (Root Dir)" },
      -- { "<leader>sG", LazyVim.pick("live_grep", { root = false }), desc = "Grep (cwd)" },
      -- { "<leader>sp", function() Snacks.picker.lazy() end, desc = "Search for Plugin Spec" },
      -- { "<leader>sw", LazyVim.pick("grep_word"), desc = "Visual selection or word (Root Dir)", mode = { "n", "x" } },
      -- { "<leader>sW", LazyVim.pick("grep_word", { root = false }), desc = "Visual selection or word (cwd)", mode = { "n", "x" } },
      -- -- search
      -- { '<leader>s"', function() Snacks.picker.registers() end, desc = "Registers" },
      -- { '<leader>s/', function() Snacks.picker.search_history() end, desc = "Search History" },
      -- { "<leader>sa", function() Snacks.picker.autocmds() end, desc = "Autocmds" },
      -- { "<leader>sc", function() Snacks.picker.command_history() end, desc = "Command History" },
      -- { "<leader>sC", function() Snacks.picker.commands() end, desc = "Commands" },
      -- { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
      -- { "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer Diagnostics" },
      -- { "<leader>sh", function() Snacks.picker.help() end, desc = "Help Pages" },
      -- { "<leader>sH", function() Snacks.picker.highlights() end, desc = "Highlights" },
      -- { "<leader>si", function() Snacks.picker.icons() end, desc = "Icons" },
      -- { "<leader>sj", function() Snacks.picker.jumps() end, desc = "Jumps" },
      -- { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
      -- { "<leader>sl", function() Snacks.picker.loclist() end, desc = "Location List" },
      -- { "<leader>sM", function() Snacks.picker.man() end, desc = "Man Pages" },
      -- { "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks" },
      -- { "<leader>sR", function() Snacks.picker.resume() end, desc = "Resume" },
      -- { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix List" },
      -- { "<leader>su", function() Snacks.picker.undo() end, desc = "Undotree" },
      -- -- ui
      -- { "<leader>uC", function() Snacks.picker.colorschemes() end, desc = "Colorschemes" },
    },
  },
  {
    'folke/flash.nvim',
    -- enabled = false,
    vscode = false,
    keys = {
      { 's', mode = { 'n', 'x', 'o' }, false },
      -- { 'S', mode = { 'n', 'o', 'x' }, false },
      { 'r', mode = 'o', false },

      {
        'S',
        mode = { 'n', 'o', 'x' },
        function()
          require('flash').treesitter()
        end,
        desc = 'Flash Treesitter',
      },
      {
        'R',
        mode = { 'o', 'x' },
        function()
          require('flash').treesitter_search()
        end,
        desc = 'Treesitter Search',
      },
      { '<c-s>', mode = { 'c' }, false },
      -- Simulate nvim-treesitter incremental selection
      {
        '<c-space>',
        mode = { 'n', 'o', 'x' },
        function()
          require('flash').treesitter {
            actions = {
              ['<c-space>'] = 'next',
              ['<BS>'] = 'prev',
            },
          }
        end,
        desc = 'Treesitter Incremental Selection',
      },
    },
  },
  {
    'folke/ts-comments.nvim',
    enabled = false,
  },
  {
    'folke/persistence.nvim',
    -- stylua: ignore
    -- keys = {
    --   { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session" },
    --   { "<leader>qS", function() require("persistence").select() end,desc = "Select Session" },
    --   { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
    --   { "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
    -- },
  },
  {
    'akinsho/bufferline.nvim',
    enabled = false,
    keys = {
      { '<leader>bp', false },
      { '<leader>bP', false },
      { '<leader>br', false },
      { '<leader>bl', false },
      { '<S-h>', false },
      { '<S-l>', false },
      { '[b', false },
      { ']b', false },
      { '[B', false },
      { ']B', false },
    },
  },
  {
    'folke/trouble.nvim',
    opts = { use_diagnostic_signs = true },
  },
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = function(_, opts)
      opts = vim.tbl_deep_extend('force', opts or {}, {
        library = {
          { path = 'luvit-meta/library', words = { 'vim%.uv' } },
          { path = 'wezterm-types', mods = { 'wezterm' } },
          { path = 'folke/snacks.nvim', words = { 'Snacks' } },
          {
            path = 'nvim-lua/plenary.nvim',
            words = {
              'describe',
              'it',
              'pending',
              'before_each',
              'after_each',
              'clear',
              'assert.*',
            },
          },
        },
      })
      return opts
    end,
    config = function(_, opts)
      require('lazydev').setup(opts)
    end,
    dependencies = {
      { 'Bilal2453/luvit-meta' },
      { 'justinsgithub/wezterm-types' },
      { 'folke/snacks.nvim' },
    },
  },
}
