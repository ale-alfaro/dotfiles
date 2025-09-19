---@module "lazy"

---@module "vectorcode"
---@module "codecompanion"

local available_models = {
  'gemini-2.5-flash',
  'gemini-2.5-pro',
}
local current_model = available_models[1]

local function select_model()
  Snacks.picker.select(available_models, {
    prompt = 'Select  Model:',
  }, function(choice)
    if choice then
      current_model = choice
      vim.notify('Selected model: ' .. current_model)
    end
  end)
end

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
      -- 'ibhagwan/fzf-lua',
      {
        'ravitemer/codecompanion-history.nvim',
        -- dir = "~/git/codecompanion-history.nvim/",
      },
      -- {
      --   'Davidyz/codecompanion-dap.nvim',
      --   -- dir = "~/git/codecompanion-dap.nvim/",
      -- },
    },
    cmd = {
      'CodeCompanion',
      'CodeCompanionCmd',
      'CodeCompanionChat',
      'CodeCompanionActions',
    },
    opts = function(plugin, opts)
      opts = opts or {}
      opts.opts = opts.opts or {}
      opts.opts.system_prompt = require 'custom.prompts.sysprompt'
      -- opts.opts = { log_level = "DEBUG" }
      opts.display = {
        action_palette = { provider = 'snacks' },
        chat = {
          show_header_separator = false,
          window = { sticky = true },
        },
      }
      opts.adapters = {
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
                ['Gemini 2.5 Flash'] = {
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
                commands = 'Gemini 2.5 Flash',
              },
              env = {
                GEMINI_API_KEY = vim.fn.expand '$GEMINI_API_KEY',
                PATH = vim.fn.trim(vim.fn.system 'uv tool dir') .. '/vectorcode/bin:' .. vim.fn.expand '$PATH',
              },
              -- defaults = {
              --   auth_method = 'oauth-personal',
              --   mcpServers = require('mcphub').get_hub_instance():get_servers(),
              --   timeout = 20000, -- 20 seconds
              -- },
            })
          end,
        },
        --   http = {
        --     ['Gemini'] = function()
        --       return require('codecompanion.adapters').extend('gemini', {
        --         name = 'Gemini',
        --         schema = { model = { default = 'gemini-2.5-flash' } },
        --       })
        --     end,
        --     ['LlamaCPP'] = function()
        --       return require('codecompanion.adapters').extend('openai_compatible', {
        --         env = {
        --           url = 'http://127.0.0.1:8080',
        --           api_key = 'TERM',
        --           chat_url = '/v1/chat/completions',
        --         },
        --         schema = { cache_prompt = { default = true, mapping = 'parameters' } },
        --       })
        --     end,
        --     ['Ollama'] = function()
        --       return require('codecompanion.adapters').extend('ollama', {
        --         env = {
        --           url = os.getenv 'OLLAMA_HOST',
        --           api_key = 'TERM',
        --         },
        --         name = 'Ollama',
        --         schema = {
        --           num_ctx = { default = 64000 },
        --           -- model = { default = {"qwen3:8b-q4_K_M-dynamic-thinking"} },
        --           -- think = { default = true },
        --         },
        --       })
        --     end,
        --   },
      }
      opts.extensions = {
        -- dap = {
        --   enabled = true,
        --   opts = { tool_opts = {}, interval_ms = 1 },
        -- },
        mcphub = {
          callback = 'mcphub.extensions.codecompanion',
          opts = {
            -- MCP Tools
            make_tools = true, -- Make individual tools (@server__tool) and server groups (@server) from MCP servers
            show_server_tools_in_chat = true, -- Show individual tools in chat completion (when make_tools=true)
            add_mcp_prefix_to_tool_names = false, -- Add mcp__ prefix (e.g `@mcp__github`, `@mcp__neovim__list_issues`)
            show_result_in_chat = true, -- Show tool results directly in chat buffer
            format_tool = nil, -- function(tool_name:string, tool: CodeCompanion.Agent.Tool) : string Function to format tool names to show in the chat buffer
            -- MCP Resources
            make_vars = true, -- Convert MCP resources to #variables for prompts
            -- MCP Prompts
            make_slash_commands = true, -- Add MCP prompts as /slash commands
          },
        },
        history = {
          enabled = true,
          opts = {
            keymap = 'gh',
            save_chat_keymap = 'sc',
            auto_save = true,
            expiration_days = 0,
            picker = 'snacks',
            auto_generate_title = true,
            continue_last_chat = false,
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
              -- ['Kitty Assistant'] = {
              --   project_root = '/usr/share/doc/kitty/',
              --   file_patterns = { '**/*.txt' },
              -- },
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
                summarise = {
                  enabled = false,
                  system_prompt = function(s)
                    return s
                  end,
                  adapter = function()
                    return require('codecompanion.adapters').extend('gemini_cli', {
                      name = 'Summariser',
                      schema = {
                        model = { default = 'gemini-2.0-flash-lite' },
                      },
                      opts = { stream = false },
                    })
                  end,
                  query_augmented = true,
                },
              },
            },
          },
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
          keymaps = {
            close = {
              modes = { n = 'q', i = '<C-q>' },
            },
            send = {
              modes = { n = '<C-s>', i = '<C-s>' },
              callback = function(chat)
                vim.cmd 'stopinsert'
                chat:apply_model(current_model)
                chat:submit()
                chat:add_buf_message { role = 'llm', content = '' }
              end,
            },
          }, -- keymaps
          tools = {
            opts = {
              -- default_tools = { "vectorcode_toolbox", "file_search", "read_file" },
            },
          },
        },
        inline = {
          adapter = 'Gemini 2.5 Flash',
        },
      }

      opts.display = { chat = { show_references = false } }
    end, -- opts

    -- cond = function()
    --   return require("_utils").no_vscode()
    -- end,
    keys = {
      { '<leader>ar', mode = { 'n', 'v' }, '<cmd>CodeCompanionChat RefreshCache<cr>', desc = 'CodeCompanion RefreshCache' },
      { '<leader>aa', mode = { 'n', 'v' }, '<cmd>CodeCompanionActions<cr>', desc = 'CodeCompanion Actions' },
      { '<leader>at', mode = { 'n', 'v' }, '<cmd>CodeCompanionChat Toggle<cr>', desc = 'CodeCompanionChat Toggle' },
      { '<leader>ai', mode = { 'n', 'v' }, '<cmd>CodeCompanionChat Add<cr>', desc = 'CodeCompanionChat Add' },
      { '<leader>ah', mode = { 'n', 'v' }, '<cmd>CodeCompanionHistory<cr>', desc = 'CodeCompanionHistory' },
      { '<leader>as', mode = { 'n', 'v' }, '<cmd>CodeCompanionSummaries<cr>', desc = 'Browse CodeCompanionSummaries' },
      { '<leader>am', mode = { 'n', 'v' }, select_model, desc = 'Select Gemini Model' },
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
  {
    'ravitemer/mcphub.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    build = 'npm install -g mcp-hub@latest', -- Installs `mcp-hub` node binary globally
    config = function()
      require('mcphub').setup()
    end,
  }, -- mcphub
}
