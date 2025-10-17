return {  -- Fuzzy Finder (files, lsp, etc)
  'nvim-telescope/telescope.nvim',
  config = function()
    -- Telescope is a fuzzy finder that comes with a lot of different things that
    -- it can fuzzy find! It's more than just a "file finder", it can search
    -- many different aspects of Neovim, your workspace, LSP, and more!
    --
    -- The easiest way to use Telescope, is to start by doing something like:
    --  :Telescope help_tags
    --
    -- After running this command, a window will open up and you're able to
    -- type in the prompt window. You'll see a list of `help_tags` options and
    -- a corresponding preview of the help.
    --
    -- Two important keymaps to use while in Telescope are:
    --  - Insert mode: <c-/>
    --  - Normal mode: ?
    --
    -- This opens a window that shows you all of the keymaps for the current
    -- Telescope picker. This is really useful to discover what Telescope can
    -- do as well as how to actually do it!

    -- [[ Configure Telescope ]]
    -- See `:help telescope` and `:help telescope.setup()`
    --
    local z_utils = require 'telescope._extensions.zoxide.utils'


    require('telescope').setup {
      defaults = {
        preview = { treesitter = false },
        color_devicons = true,
        sorting_strategy = 'ascending',
        borderchars = {
          '─', -- top
          '│', -- right
          '─', -- bottom
          '│', -- left
          '┌', -- top-left
          '┐', -- top-right
          '┘', -- bottom-right
          '└', -- bottom-left
        },
        path_displays = { 'smart' },
        layout_config = {
          height = 100,
          width = 400,
          prompt_position = 'top',
          preview_cutoff = 40,
        },
      },
      --  All the info you're looking for is in `:help telescope.setup()`
      --
      -- defaults = {
      --   mappings = {
      --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
      --   },
      -- },
      -- pickers = {}
      extensions = {
        ['ui-select'] = {
          require('telescope.themes').get_dropdown(),
        },
        ['zoxide'] = {

          prompt_title = '[ Walking on the shoulders of TJ ]',
          mappings = {
            default = {
              after_action = function(selection)
                print('Update to (' .. selection.z_score .. ') ' .. selection.path)
              end,
            },
            ['<C-s>'] = {
              before_action = function(selection)
                print 'before C-s'
              end,
              action = function(selection)
                vim.cmd.edit(selection.path)
              end,
            },
            -- Opens the selected entry in a new split
            ['<C-q>'] = { action = z_utils.create_basic_command 'split' },
          },
        },
      },
    }

    -- Enable Telescope extensions if they are installed
    pcall(require('telescope').load_extension, 'fzf')
    pcall(require('telescope').load_extension, 'ui-select')
    pcall(require('telescope').load_extension, 'zoxide')
    pcall(require('telescope').load_extension, 'env')

    require('actions-preview').setup {
      backend = { 'telescope' },
      telescope = vim.tbl_extend('force', require('telescope.themes').get_dropdown(), {}),
    }
    -- See `:help telescope.builtin`
    local builtin = require 'telescope.builtin'

    _G.Utils.keymaps.define({
      -- Telescope
      { lhs = "<leader>ff",      rhs = require("telescope.builtin").find_files,     opts = { desc = "Telescope find files" } },
      { lhs = "<leader>sg",      rhs = require("telescope.builtin").live_grep,      opts = { desc = "Telescope live grep" } },
      { lhs = "<leader>fb",      rhs = require("telescope.builtin").buffers,        opts = { desc = "Telescope buffers" } },
      { lhs = "<leader>si",      rhs = require("telescope.builtin").grep_string,    opts = { desc = "Telescope live string" } },
      { lhs = "<leader>so",      rhs = require("telescope.builtin").oldfiles,       opts = { desc = "Telescope old files" } },
      { lhs = "<leader>sh",      rhs = require("telescope.builtin").help_tags,      opts = { desc = "Telescope help tags" } },
      { lhs = "<leader>sm",      rhs = require("telescope.builtin").man_pages,      opts = { desc = "Telescope man pages" } },
      { lhs = "<leader>sr",      rhs = require("telescope.builtin").lsp_references, opts = { desc = "Telescope LSP references" } },
      { lhs = "<leader>st",      rhs = require("telescope.builtin").builtin,        opts = { desc = "Telescope built-in pickers" } },
      { lhs = "<leader>sd",      rhs = require("telescope.builtin").registers,      opts = { desc = "Telescope registers" } },
      { lhs = "<leader>sc",      rhs = require("telescope.builtin").git_bcommits,   opts = { desc = "Telescope git bcommits" } },
      { lhs = "<leader>se",      rhs = "<cmd>Telescope env<cr>",                    opts = { desc = "Telescope env variables" } },
      { lhs = "<leader>sa",      rhs = require("actions-preview").code_actions,     opts = { desc = "Telescope code actions" } },
      { lhs = '<leader>ss',      rhs = builtin.builtin,                             opts = { desc = '[S]earch [S]elect Telescope' } },
      { lhs = '<leader>sw',      rhs = builtin.grep_string,                         opts = { desc = '[S]earch current [W]ord' } },
      { lhs = '<leader>sg',      rhs = builtin.live_grep,                           opts = { desc = '[S]earch by [G]rep' } },
      { lhs = '<leader>sG',      rhs = builtin.live_grep,                           opts = { desc = 'Grep in cwd' } },
      { lhs = '<leader>sd',      rhs = builtin.diagnostics,                         opts = { desc = '[S]earch [D]iagnostics' } },
      { lhs = '<leader>sr',      rhs = builtin.resume,                              opts = { desc = '[S]earch [R]esume' } },
      { lhs = '<leader>s.',      rhs = builtin.oldfiles,                            opts = { desc = '[S]earch Recent Files ("." for repeat)' } },
      { lhs = '<leader><leader>', rhs = builtin.buffers,                            opts = { desc = '[ ] Find existing buffers' } },
      { lhs = '<leader>sG',      rhs = '<leader>zd', require('telescope').extensions.zoxide.list,   opts = { desc = "Zoxide" } },
      { lhs = '<leader>sd',      rhs = '<leader>sh',builtin.help_tags,              opts = { desc = '[S]earch [H]elp' } },
      { lhs = '<leader>sr',      rhs = '<leader>sk',builtin.keymaps,                opts = { desc = '[S]earch [K]eymaps' } },
      {
        lhs = '<leader>sr',
        rhs = '<leader>sf',
        function()
          builtin.find_files { hidden = true, no_ignore = true, no_ignore_parent = true, cwd = vim.fn.expand '%:p:h' }
        end,
        opts = { desc = '[S]earch [f]iles in open buffer directory' }
      },
      {
        lhs = '<leader>sB',
        rhs = function()
          builtin.live_grep { grep_open_files = true, prompt_title = 'Grep Open Buffers' }
        end,
        opts = { desc = 'Grep Open Buffers' }
      },
      {
        lhs = '<leader>/',
        rhs = function()
          builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
            winblend = 10,
            previewer = false,
          })
        end,
        opts ={ desc = '[/] Fuzzily search in current buffer' }
      },
      { lhs = '<leader>sn', rhs = function() builtin.find_files { cwd = vim.fn.stdpath 'config' } end,      opts = { desc = '[S]earch [N]eovim files' } },

      {
        lhs = '<leader>s/',
        rhs = function()
          builtin.live_grep {
            grep_open_files = true,
            prompt_title = 'Live Grep in Open Files',
          }
        end,
        opts = { desc = '[S]earch [/] in Open Files' }
      },
      { lhs = '<leader>sB', rhs = function() builtin.live_grep { grep_open_files = true, prompt_title = 'Grep Open Buffers' } end, opts = { desc = 'Grep Open Buffers' } },
      { lhs = '<leader>sm', rhs = builtin.marks,                                                                                   opts = { desc = 'Marks' } },
      { lhs = '<leader>sM', rhs = builtin.man_pages,                                                                               opts = { desc = 'Man ' } },
      { lhs = '<leader>sb', rhs = builtin.current_buffer_fuzzy_find,                                                               opts = { desc = 'Buffer Lines' } },
    })
  end,
}


