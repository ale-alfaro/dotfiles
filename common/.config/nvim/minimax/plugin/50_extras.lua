-- ┌─────────────────────────┐
-- │ Plugins outside of MINI │
-- └─────────────────────────┘
--
-- This file contains installation and configuration of plugins outside of MINI.
-- They significantly improve user experience in a way not yet possible with MINI.
--
-- Use this file to install and configure other such plugins.

---@type PluginSpec[]
local plugins = {
  {
    'folke/trouble.nvim',
    opts = {
      use_diagnostic_signs = true,
      modes = {
        uv_qflist = {
          mode = 'qflist',
          win = { position = 'bottom', size = 10 },
          groups = {
            { 'filename', format = '{file_icon} {basename:Title} {count}' },
          },
        },
        uv_wspace_diags = {
          mode = 'diagnostics', -- inherit from diagnostics mode
          filter = {
            any = {
              buf = 0, -- current buffer
              {
                severity = vim.diagnostic.severity.ERROR, -- errors only
                -- limit to files in the current project
                function(item)
                  return item.filename:find((vim.loop or vim.uv).cwd(), 1, true)
                end,
              },
            },
          },
        },
      },
    },
    keys = {
      { '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', 'Diagnostics (Trouble)' },
      { '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', 'Buffer Diagnostics (Trouble)' },
      { '<leader>cs', '<cmd>Trouble symbols toggle<cr>', 'Symbols (Trouble)' },
      { '<leader>cS', '<cmd>Trouble lsp toggle<cr>', 'LSP references/definitions/... (Trouble)' },
      { '<leader>xL', '<cmd>Trouble loclist toggle<cr>', 'Location List (Trouble)' },
      { '<leader>xQ', '<cmd>Trouble qflist toggle<cr>', 'Quickfix List (Trouble)' },
      {
        '[q',
        function()
          if require('trouble').is_open() then
            require('trouble').prev { skip_groups = true, jump = true }
          else
            local ok, err = pcall(vim.cmd.cprev)
            if not ok then
              vim.notify(err, vim.log.levels.ERROR)
            end
          end
        end,
        'Previous Trouble/Quickfix Item',
      },
      {
        ']q',
        function()
          if require('trouble').is_open() then
            require('trouble').next { skip_groups = true, jump = true }
          else
            local ok, err = pcall(vim.cmd.cnext)
            if not ok then
              vim.notify(err, vim.log.levels.ERROR)
            end
          end
        end,
        'Next Trouble/Quickfix Item',
      },
    },
  },
  {
    'ravitemer/codecompanion-history.nvim',
    opts = {}
  },
  {
    'lalitmee/codecompanion-spinners.nvim',
    opts = {}
  },
  {
    'olimorris/codecompanion.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'lalitmee/codecompanion-spinners.nvim',
      'folke/snacks.nvim',
      'ravitemer/codecompanion-history.nvim',
    },
    opts = {
      display = {
        action_palette = { provider = 'snacks' },
        chat = {
          show_settings = true,
          show_header_separator = true,
          auto_scroll = true,
          show_token_count = true,
        },
      },
      adapters = {
        acp = {
          gemini_cli = function()
            return require('codecompanion.adapters').extend('gemini_cli', {
              commands = {
                ['Gemini 2.5 Pro'] = {
                  'gemini',
                  '--experimental-acp',
                  '-m',
                  'gemini-2.5-pro',
                },
                ['default'] = {
                  'gemini',
                  '--experimental-acp',
                  '-m',
                  'gemini-2.5-flash',
                },
              },
              defaults = {
                auth_method = 'gemini-api-key',
                mcpServers = {},
                timeout = 20000, -- 20 seconds
              },
              env = {
                GEMINI_API_KEY = vim.fn.expand '$GEMINI_API_KEY',
              },
            })
          end,
        },
      },
      strategies = {
        chat = {
          adapter = 'gemini_cli',
          roles = {
            llm = function(adapter)
              if adapter.model then
                return string.format('%s (%s)', adapter.formatted_name, adapter.model.name)
              else
                return adapter.formatted_name
              end
            end,
          },
          opts = {
            system_prompt = require 'custom.ai.prompts.sysprompt',
          }, -- opts
          keymaps = {
            close = {
              modes = { n = '<C-q>', i = '<C-q>' },
            },
            send = {
              modes = { n = '<C-s>', i = '<C-s>' },
            },
            change_model = {
              modes = { n = 'gm' },
              name = 'Change Model',
              callback = require('custom.ai.adapters').change_model_callback,
              description = 'Change the model for the current chat',
            },
          }, -- keymaps
        },
        inline = {
          adapter = 'gemini_cli',
        },
      },

      -- vim.cmd [[cab cc CodeCompanion]]
      extensions = {
        history = {
          enabled = true,
          opts = {
            keymap = 'gh',
            save_chat_keymap = 'sc',
            auto_save = true,
            expiration_days = 7,
            picker = 'snacks',
            picker_keymaps = {
              rename = { n = '<C-r>', i = '<C-r>' },
              delete = { n = '<C-x>', i = '<C-x>' },
              duplicate = { n = '<C-y>', i = '<C-y>' },
            },
            auto_generate_title = false,
            continue_last_chat = false,
            delete_on_clearing_chat = false,
            title_generation_opts = {
              format_title = function(s)
                return vim.trim(string.gsub(s, '<think>.*</think>', ''))
              end,
            },
            summary = {
              create_summary_keymap = '<C-r>c',
              browse_summaries_keymap = '<C-r>b',
              preview_summary_keymap = '<C-r>p',
              generation_opts = {
                context_size = 90000,
                include_references = true,
                include_tool_outputs = true,
                format_summary = function(s)
                  return vim.trim(string.gsub(s, '<think>.*</think>', ''))
                end,
              },
            },
            memory = { index_on_startup = true },
          },
        },
        spinner = {
          enabled = true,
          opts = {
            style = 'native',
            content = {
              thinking = { icon = '🤖', message = 'AI is thinking...', spacing = '  ' },
              receiving = { icon = '📨', message = 'Receiving response...', spacing = '  ' },
              tools_started = { icon = '🔧', message = 'Running tools...', spacing = '  ' },
              diff_attached = { icon = '📋', message = 'Review changes', spacing = '  ' },
            },
          },
        }, -- spinner
      }    -- extensions
    },     -- opts
    keys = {
      { '<leader>ar', mode = { 'n', 'v' }, '<cmd>CodeCompanionChat RefreshCache<cr>', desc = 'CodeCompanion RefreshCache' },
      { '<leader>aa', mode = { 'n', 'v' }, '<cmd>CodeCompanionActions<cr>',           desc = 'CodeCompanion Actions' },
      { '<leader>at', mode = { 'n', 'v' }, '<cmd>CodeCompanionChat Toggle<cr>',       desc = 'CodeCompanionChat Toggle' },
      { '<leader>ai', mode = { 'n', 'v' }, '<cmd>CodeCompanionChat Add<cr>',          desc = 'CodeCompanionChat Add' },
      { '<leader>ah', mode = { 'n', 'v' }, '<cmd>CodeCompanionHistory<cr>',           desc = 'CodeCompanionHistory' },
      { '<leader>as', mode = { 'n', 'v' }, '<cmd>CodeCompanionSummaries<cr>',         desc = 'Browse CodeCompanionSummaries' },
    },
  },
  {
    'folke/lazydev.nvim',
    dependencies = {
      'Bilal2453/luvit-meta',
      'justinsgithub/wezterm-types',
      'folke/snacks.nvim',
    },
    opts = {
      library = {
        { path = 'luvit-meta/library', words = { 'vim%.uv' } },
        { path = 'wezterm-types', mods = { 'wezterm' } },
        { path = 'folke/snacks.nvim', words = { 'Snacks' } },
        { path = 'mini.nvim', words = { 'MiniDeps' } },

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
    },
  },
  {
    'obsidian-nvim/obsidian.nvim',
    keys = {
      { '<leader>oo', '<cmd>ObsidianOpen<cr>' },
      { '<leader>on', '<cmd>ObsidianNew<cr>' },
      { '<leader>oT', '<cmd>ObsidianTemplate<cr>' },
      { '<leader>ot', '<cmd>ObsidianToday<cr>' },
      { '<leader>oy', '<cmd>ObsidianYesterday<cr>' },
      { '<leader>ol', '<cmd>ObsidianLink<cr>' },
      { '<leader>oL', '<cmd>ObsidianLinkNew<cr>' },
      { '<leader>ob', '<cmd>ObsidianBacklinks<cr>' },
      { '<leader>os', '<cmd>ObsidianSearch<cr>' },
      { '<leader>oq', '<cmd>ObsidianQuickSwitch<cr>' },
    },
    opts = {
      completion = {
        blink = true,
      },
      disable_frontmatter = true,
      workspaces = {
        {
          name = 'Personal-Geek',
          path = vim.fn.expand '$OBSIDIAN_HOME' .. '/Personal-Geek',
        },
        {
          name = 'Sibel-Work',
          path = vim.fn.expand '$OBSIDIAN_HOME' .. '/Sibel-Work',
        },
      },
    },
  }
}

-- _G.Utils.plugin.plugins_setup_all(plugins)
