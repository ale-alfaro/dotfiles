---@module "lazy"

---@module "vectorcode"
---@module "codecompanion"

---@type LazySpec[]
return {
  {
    'olimorris/codecompanion.nvim',
    -- dir = "~/git/codecompanion.nvim/",
    version = '*',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'Davidyz/VectorCode',

      'lalitmee/codecompanion-spinners.nvim', -- Install the spinners extension
      -- 📦 Optional dependencies for certain spinner styles:
      'folke/snacks.nvim',
      'nvim-lualine/lualine.nvim',
      'ravitemer/codecompanion-history.nvim',
      --   'Davidyz/codecompanion-dap.nvim',
    },
    cmd = {
      'CodeCompanion',
      'CodeCompanionCmd',
      'CodeCompanionChat',
      'CodeCompanionActions',
    },
    opts = function(plugin, opts)
      opts = opts or {}
      opts.display = {
        action_palette = { provider = 'snacks' },
        chat = {
          show_settings = true,
          show_header_separator = true,
          auto_scroll = true,
          show_token_count = true,
          -- window = { sticky = true },
        },
      }
      opts.adapters = {
        acp = {
          ---@type CodeCompanion.ACPAdapter
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
                -- mcpServers = require('mcphub').get_hub_instance():get_servers(),
                mcpServers = {},
                timeout = 20000, -- 20 seconds
              },
              env = {
                GEMINI_API_KEY = vim.fn.expand '$GEMINI_API_KEY',
                -- PATH = vim.fn.trim(vim.fn.system 'uv tool dir') .. '/vectorcode/bin:' .. vim.fn.expand '$PATH',
              },
            })
          end,
        },
      }
      opts.strategies = {
        chat = {
          adapter = 'gemini_cli',
          roles = {
            ---@type string|fun(adapter: CodeCompanion.HTTPAdapter|CodeCompanion.ACPAdapter): string
            llm = function(adapter)
              if adapter.model then
                return string.format('%s (%s)', adapter.formatted_name, adapter.model.name)
              else
                return adapter.formatted_name
              end
            end,
          },
          opts = {
            ---@type string|fun(path: string)
            system_prompt = require 'custom.ai.prompts.sysprompt',
          }, -- opts
          keymaps = {
            close = {
              modes = { n = 'q', i = '<C-q>' },
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
      }

      vim.cmd [[cab cc CodeCompanion]]
      opts.extensions = {
        -- dap = {
        --   enabled = true,
        --   opts = { tool_opts = {}, interval_ms = 1 },
        -- },
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
            ---Automatically generate titles for new chats
            auto_generate_title = false,
            continue_last_chat = true,
            delete_on_clearing_chat = false,
            title_generation_opts = {
              format_title = function(s)
                return vim.trim(string.gsub(s, '<think>.*</think>', ''))
              end,
            },
            summary = {
              create_summary_keymap = '<C-s>c',
              browse_summaries_keymap = '<C-s>b',
              preview_summary_keymap = '<C-s>p',

              generation_opts = {
                context_size = 90000,
                -- Include slash command content (default: true)
                include_references = true,
                -- Include tool outputs (default: true)
                include_tool_outputs = true,
                format_summary = function(s)
                  return vim.trim(string.gsub(s, '<think>.*</think>', ''))
                end,
              },
            },
            memory = { index_on_startup = true },
          },
        },
        vectorcode = {
          enabled = vim.fn.executable 'vectorcode' == 1,
          ---@type VectorCode.CodeCompanion.ExtensionOpts
          opts = {
            prompt_library = {
              ['CodeCompanion Assistant'] = {
                project_root = plugin.dir,
                file_patterns = { 'lua/codecompanion/**.lua', 'doc/**/*.md' },
              },
              ['Zephyr Assistant'] = {
                project_root = '/home/alealfaro/ncs/sdk/v3.1.0/zephyr',
                file_patterns = { '**/*.c*', '**/*.yml', '**/*.dts*', '**/*.cmake', '**/*.txt', '**/*.rst', '**/*.py' },
              },
              ['NCS Assistant'] = {
                project_root = '/home/alealfaro/ncs/sdk/v3.1.0/nrf',
                file_patterns = { '**/*.c*', '**/*.yml', '**/*.dts*', '**/*.cmake', '**/*.txt', '**/*.rst', '**/*.py' },
              },
            },
            tool_group = { collapse = true },
            tool_opts = {
              ---@type VectorCode.CodeCompanion.ToolOpts
              ['*'] = { use_lsp = true },
              ls = {},
              vectorise = {},
              ---@type VectorCode.CodeCompanion.QueryToolOpts
              query = {
                default_num = { document = 5, chunk = 10 },
                max_num = { document = 10, chunk = 20 },
                chunk_mode = true,
              },
            },
          },
        }, -- vectorcode
        spinner = {
          enabled = true,
          opts = {
            style = 'native', -- Other options: "cursor-relative", "fidget", "snacks", "lualine", "heirline", "none"
            content = {
              thinking = { icon = '🤖', message = 'AI is thinking...', spacing = '  ' },
              receiving = { icon = '📨', message = 'Receiving response...', spacing = '  ' },
              tools_started = { icon = '🔧', message = 'Running tools...', spacing = '  ' },
              diff_attached = { icon = '📋', message = 'Review changes', spacing = '  ' },
              -- ... many more states
            },
          },
        }, -- spinner
      } -- extensions
    end, -- opts
    keys = {
      { '<leader>ar', mode = { 'n', 'v' }, '<cmd>CodeCompanionChat RefreshCache<cr>', desc = 'CodeCompanion RefreshCache' },
      { '<leader>aa', mode = { 'n', 'v' }, '<cmd>CodeCompanionActions<cr>', desc = 'CodeCompanion Actions' },
      { '<leader>at', mode = { 'n', 'v' }, '<cmd>CodeCompanionChat Toggle<cr>', desc = 'CodeCompanionChat Toggle' },
      { '<leader>ai', mode = { 'n', 'v' }, '<cmd>CodeCompanionChat Add<cr>', desc = 'CodeCompanionChat Add' },
      { '<leader>ah', mode = { 'n', 'v' }, '<cmd>CodeCompanionHistory<cr>', desc = 'CodeCompanionHistory' },
      { '<leader>as', mode = { 'n', 'v' }, '<cmd>CodeCompanionSummaries<cr>', desc = 'Browse CodeCompanionSummaries' },
    },
  },
  {
    'Davidyz/VectorCode',
    -- dir = "~/git/VectorCode/",
    version = '*',
    -- build = "uv tool upgrade vectorcode",
    build = function(plugin)
      if vim.fn.executable 'uv' ~= 1 then
        return vim.notify('Failed to install VectorCode because `uv` is missing.', vim.log.levels.WARN)
      end
      local stdpath = vim.fn.stdpath 'data'
      if string.find(plugin.dir, stdpath) then
        local command
        if vim.fn.executable 'vectorcode' == 1 then
          command = 'uv tool upgrade vectorcode'
        else
          command = 'uv tool install "vectorcode[lsp,mcp]"'
        end
        vim.system(vim.split(command, ' ', { trimempty = true }), {}, nil)
      end
    end,
    opts = function()
      return {
        async_backend = 'lsp',
        notify = true,
        on_setup = { lsp = true },
        n_query = 10,
        timeout_ms = -1,
        async_opts = {
          events = { 'BufWritePost' },
          single_job = true,
          query_cb = require('vectorcode.utils').make_surrounding_lines_cb(40),
          debounce = -1,
          n_query = 30,
        },
      }
    end,
    config = function(_, opts)
      vim.lsp.config('vectorcode_server', {
        cmd_env = {
          HTTP_PROXY = os.getenv 'HTTP_PROXY',
          HTTPS_PROXY = os.getenv 'HTTPS_PROXY',
        },
      })
      require('vectorcode').setup(opts)
      -- vim.api.nvim_create_autocmd("LspAttach", {
      --   callback = function()
      --     require("vectorcode.config").get_cacher_backend().register_buffer(0)
      --   end,
      -- })
    end,
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    cmd = 'VectorCode',
    cond = function()
      return vim.fn.executable 'vectorcode' == 1
    end,
  }, -- vectorcode
}
