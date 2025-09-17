local available_models = {
  'google/gemini-2.5-flash',
  'google/gemini-2.5-pro',
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

return {

  -- {
  --   'Davidyz/VectorCode',
  --   version = '*',
  --   event = 'LspAttach',
  --   lazy = false,
  --   build = 'uv tool upgrade vectorcode', -- This helps keeping the CLI up-to-date
  --   dependencies = { 'nvim-lua/plenary.nvim' },
  --   opts = function()
  --     local opts = {
  --       async_backend = 'lsp',
  --       notify = true,
  --       on_setup = { lsp = true },
  --       n_query = 10,
  --       async_opts = {
  --         timeout_ms = 5000,
  --         -- events = { "BufWritePost", "InsertEnter", "BufReadPost" },
  --         events = { 'BufWritePost' },
  --         single_job = true,
  --         query_cb = require('vectorcode.utils').make_surrounding_lines_cb(-1),
  --         debounce = -1,
  --         n_query = 30,
  --       },
  --     }
  --     vim.api.nvim_create_autocmd('LspAttach', {
  --       callback = function()
  --         local bufnr = vim.api.nvim_get_current_buf()
  --         if package.loaded['vectorcode'] == nil then
  --           local cacher = require('vectorcode.config').get_cacher_backend()
  --           cacher.async_check('config', function()
  --             cacher.register_buffer(bufnr, {
  --               n_query = 10,
  --             })
  --           end, nil)
  --         end
  --       end,
  --       desc = 'Register buffer for VectorCode',
  --     })
  --     return opts
  --   end,
  -- },
  {

    'olimorris/codecompanion.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'ravitemer/codecompanion-history.nvim',
      'Davidyz/VectorCode',
    },
    keys = {
      { '<leader>ar', mode = { 'n', 'v' }, '<cmd>CodeCompanionChat RefreshCache<cr>', desc = 'CodeCompanion RefreshCache' },
      { '<leader>aa', mode = { 'n', 'v' }, '<cmd>CodeCompanionActions<cr>', desc = 'CodeCompanion Actions' },
      { '<leader>at', mode = { 'n', 'v' }, '<cmd>CodeCompanionChat Toggle<cr>', desc = 'CodeCompanionChat Toggle' },
      { '<leader>ai', mode = { 'n', 'v' }, '<cmd>CodeCompanionChat Add<cr>', desc = 'CodeCompanionChat Add' },
      { '<leader>ah', mode = { 'n', 'v' }, '<cmd>CodeCompanionHistory<cr>', desc = 'CodeCompanionHistory' },
      { '<leader>as', mode = { 'n', 'v' }, '<cmd>CodeCompanionSummaries<cr>', desc = 'Browse CodeCompanionSummaries' },
      { '<leader>am', mode = { 'n', 'v' }, select_model, desc = 'Select Gemini Model' },
    },
    opts = {
      adapters = {
        acp = {

          gemini_cli = function()
            return require('codecompanion.adapters').extend('gemini_cli', {
              commands = {
                default = {
                  'gemini',
                  '--experimental-acp',
                },
              },
              defaults = {
                auth_method = 'gemini-api-key',
                mcpServers = {},
                timeout = 20000, -- 20 seconds
                model = current_model,
              },
              env = {
                GEMINI_API_KEY = vim.fn.expand '$GEMINI_API_KEY',
                PATH = vim.fn.trim(vim.fn.system 'uv tool dir') .. '/vectorcode/bin:' .. vim.fn.expand '$PATH',
              },
            })
          end,
        },
      }, -- adapters
      strategies = {
        chat = {
          adapter = 'gemini_cli',
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
        }, -- chat
        inline = {
          adapter = 'gemini_cli', -- Default to Gemini
        }, -- model = 'gemini-2.5-flash',
      },

      opts = {
        log_level = 'DEBUG',
      },
      prompt_library = {
        ['Code Expert'] = {
          strategy = 'chat',
          description = 'Get some special advice from an LLM',
          opts = {
            mapping = '<LocalLeader>ce',
            modes = { 'v' },
            short_name = 'expert',
            auto_submit = true,
            stop_context_insertion = true,
            user_prompt = true,
          },
          prompts = {
            {
              role = 'system',
              content = function(context)
                return 'I want you to act as a senior '
                  .. context.filetype
                  .. ' developer. I will ask you specific questions and I want you to return concise explanations and codeblock examples.'
              end,
            },
            {
              role = 'user',
              content = function(context)
                local text = require('codecompanion.helpers.actions').get_code(context.start_line, context.end_line)

                return 'I have the following code:\n\n```' .. context.filetype .. '\n' .. text .. '\n```\n\n'
              end,
              opts = {
                contains_code = true,
              },
            },
          },
        },
      }, -- prompt_library
      extensions = {
        vectorcode = {
          enabled = true,
          opts = {
            tool_group = {
              -- this will register a tool group called `@vectorcode_toolbox` that contains all 3 tools
              enabled = true,
              -- a list of extra tools that you want to include in `@vectorcode_toolbox`.
              -- if you use @vectorcode_vectorise, it'll be very handy to include
              -- `file_search` here.
              extras = {
                'file_search',
                'grep_search',
              },
              collapse = false, -- whether the individual tools should be shown in the chat
            },
          },
        }, -- vectorcode

        history = {
          enabled = true,
          opts = {
            -- Keymap to open history from chat buffer (default: gh)
            keymap = 'gh',
            -- Keymap to save the current chat manually (when auto_save is disabled)
            save_chat_keymap = 'gsc',
            -- Save all chats by default (disable to save only manually using 'sc')
            auto_save = true,
            -- Number of days after which chats are automatically deleted (0 to disable)
            expiration_days = 0,
            -- Picker interface (auto resolved to a valid picker)
            picker = 'snacks', --- ("telescope", "snacks", "fzf-lua", or "default")
            ---Optional filter function to control which chats are shown when browsing
            chat_filter = nil, -- function(chat_data) return boolean end
            -- Customize picker keymaps (optional)
            picker_keymaps = {
              rename = { n = 'r', i = '<M-r>' },
              delete = { n = 'd', i = '<M-d>' },
              duplicate = { n = '<C-y>', i = '<C-y>' },
            },
            ---Automatically generate titles for new chats
            auto_generate_title = false,
            title_generation_opts = {
              ---Adapter for generating titles (defaults to current chat adapter)
              adapter = 'gemini_cli', -- "copilot"
              ---Model for generating titles (defaults to current chat model)
              model = 'gemini-2.5-flash', -- "gpt-4o"
              ---Number of user prompts after which to refresh the title (0 to disable)
              refresh_every_n_prompts = 0, -- e.g., 3 to refresh after every 3rd user prompt
              ---Maximum number of times to refresh the title (default: 3)
              max_refreshes = 3,
              format_title = function(original_title)
                -- this can be a custom function that applies some custom
                -- formatting to the title.
                return original_title
              end,
            },
            ---On exiting and entering neovim, loads the last chat on opening chat
            continue_last_chat = false,
            ---When chat is cleared with `gx` delete the chat from history
            delete_on_clearing_chat = false,
            ---Directory path to save the chats
            dir_to_save = vim.fn.stdpath 'data' .. '/codecompanion-history',
            ---Enable detailed logging for history extension
            enable_logging = false,

            -- Summary system
            summary = {
              -- Keymap to generate summary for current chat (default: "gcs")
              create_summary_keymap = 'gcs',
              -- Keymap to browse summaries (default: "gbs")
              browse_summaries_keymap = 'gbs',

              generation_opts = {
                adapter = nil, -- defaults to current chat adapter
                model = nil, -- defaults to current chat model
                context_size = 90000, -- max tokens that the model supports
                include_references = true, -- include slash command content
                include_tool_outputs = true, -- include tool execution results
                system_prompt = nil, -- custom system prompt (string or function)
                format_summary = nil, -- custom function to format generated summary e.g to remove <think/> tags from summary
              },
            },

            -- Memory system (requires VectorCode CLI)
            memory = {
              -- Automatically index summaries when they are generated
              auto_create_memories_on_summary_generation = true,
              -- Path to the VectorCode executable
              vectorcode_exe = 'vectorcode',
              -- Tool configuration
              tool_opts = {
                -- Default number of memories to retrieve
                default_num = 10,
              },
              -- Enable notifications for indexing progress
              notify = true,
              -- Index all existing memories on startup
              -- (requires VectorCode 0.6.12+ for efficient incremental indexing)
              index_on_startup = false,
            },
          }, -- history.opts
        }, --history
      }, -- extensions
    },
  },
  {
    'nvim-lualine/lualine.nvim',
    opts = function(_, opts)
      local vec = require 'vectorcode.integrations'
      table.insert(opts.sections.lualine_y, vec.lualine(opts))
    end,
  },
}
