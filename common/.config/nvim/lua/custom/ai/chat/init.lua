C = {}

local function change_model_callback(chat)
  local util = require 'codecompanion.utils'

  local function select_opts(prompt, conditional)
    return {
      prompt = prompt,
      kind = 'codecompanion.nvim',
      format_item = function(item)
        if conditional == item then
          return '* ' .. item
        end
        return '  ' .. item
      end,
    }
  end

  if chat.adapter.type == 'http' then
    vim.notify 'Not supported'
    return
    -- Select a command
  elseif chat.adapter.type == 'acp' then
    local commands = chat.adapter.commands
    if not commands or vim.tbl_count(commands) < 2 then
      return
    end

    commands = vim
      .iter(commands)
      :map(function(key, _)
        if type(key) == 'string' then
          return key
        end
      end)
      :filter(function(key)
        return key ~= 'selected'
      end)
      :totable()
    table.sort(commands)

    vim.ui.select(commands, select_opts('Select a Command', commands), function(selected_command)
      if not selected_command then
        return
      end
      local selected = chat.adapter.commands[selected_command]
      chat.adapter.commands.selected = selected
      util.fire('ChatModel', { bufnr = chat.bufnr, model = selected })
      chat:update_metadata()
    end)
  end
end

function C.initialize()
  local opts = {
    adapters = {
      acp = {
        opts = {
          show_defaults = false,
        },
        gemini_cli = function()
          return require('codecompanion.adapters').extend('gemini_cli', {
            commands = {
              default = {
                'gemini',
                '--experimental-acp',
                '-m',
                'gemini-2.5-pro',
              },
            },
            defaults = { auth_method = 'gemini-api-key', mcpServers = {}, timeout = 20000 },
            env = { GEMINI_API_KEY = vim.fn.expand '$GEMINI_API_KEY' },
          })
        end,
      },
      http = {
        opts = {
          show_defaults = false,
        },
        qwen3 = function()
          return require('codecompanion.adapters').extend('ollama', {
            name = 'qwen3-coder', -- Give this adapter a different name to differentiate it from the default ollama adapter
            schema = {
              model = {
                default = 'qwen3-coder:30b',
              },
              num_ctx = {
                default = 20000,
              },
            },
          })
        end,
      },
    }, --adapters
    strategies = {
      cmd = {
        adapter = 'qwen3',
      },
      inline = {
        adapter = 'qwen3',
      },
      chat = {
        adapter = 'qwen3',
        -- model = 'gemini-2.5-pro',
        keymaps = {
          next_chat = { modes = { n = '<C-n>', i = '<C-n>' } },
          clear = { modes = { n = '<C-x>', i = '<C-x>' } },
          yank_code = { modes = { n = '<C-y>', i = '<C-y>' } },
          fold_code = { modes = { n = 'zc' } },
          goto_file_under_cursor = { modes = { n = 'gf' } },
          options = {
            modes = { n = '?' },
            callback = function()
              local keymaps = require 'codecompanion.strategies.chat.keymaps'
              keymaps.options.callback()
              vim.defer_fn(function()
                vim.cmd.stopinsert()
                -- Ensure options window is wide enough for content
                vim.api.nvim_win_set_width(0, math.min(160, vim.o.columns))
              end, 1)
            end,
          },
          pin = { modes = { n = '<Leader>rp' } },
          watch = { modes = { n = '<Leader>rw' } },
          system_prompt = { modes = { n = '<Leader>ts' } },
          close = {
            modes = { n = '<C-q>', i = '<C-q>' },
          },
          send = {
            modes = { n = '<C-s>', i = '<C-s>' },
          },
          change_model = {
            modes = { n = '<C-m>' },
            name = 'Change Model',
            callback = change_model_callback,
            description = 'Change the model for the current chat',
          },
        }, -- keymaps
        slash_commands = require 'custom.ai.chat.slash_commands',
        opts = {
          blank_prompt = 'Look at the chat history and answer the previous prompt', -- The prompt to use when the user doesn't provide a prompt
          completion_provider = 'blink', -- blink|cmp|coc|default
          register = '+', -- The register to use for yanking code
          wait_timeout = 2e6, -- Time to wait for user response before timing out (milliseconds)
          yank_jump_delay_ms = 400, -- Delay before jumping back from the yanked code (milliseconds )

          -- What to do when an ACP permission request times out? (allow_once|reject_once)
          acp_timeout_response = 'reject_once',

          ---This is the default prompt which is sent with every request in the chat
          ---strategy. It is primarily based on the GitHub Copilot Chat's prompt
          ---but with some modifications. You can choose to remove this via
          ---your own config but note that LLM results may not be as good
          ---@param ctx CodeCompanion.SystemPrompt.Context
          ---
          ---language string
          ---adapter CodeCompanion.HTTPAdapter|CodeCompanion.ACPAdapter
          ---date string
          ---nvim_version string
          ---os string the operating system that the user is using
          ---default_system_prompt string
          ---cwd string current working directory
          ---project_root? string The closest parent directory that contains either a `.git`, `.svn`, or `.hg` directory
          ---@return string
          system_prompt = function(ctx)
            local nvim_conf = vim.fn.stdpath 'config'
            local sys_prompt_dir = nvim_conf .. '/lua/custom/ai/prompts/sysprompt'
            local function read(fname)
              local lines
              local path = vim.fs.joinpath(sys_prompt_dir, fname .. '.md')
              local f = io.open(path, 'r')
              local content = ''
              if f then
                content = f:read '*a'
                f:close()
              else
                VimRc.err "Couldn't read sysprompt"
              end
              return content
            end
            return ctx.default_system_prompt
              .. string.format(
                [[Additional context:
All non-code text responses must be written in the %s language.
The current date is %s.
The user's Neovim version is %s.
The user is working on a %s machine. Please respond with system specific commands if applicable.
]],
                ctx.language,
                ctx.date,
                ctx.nvim_version,
                ctx.os
              )
              .. read 'codegen'
          end,
        }, --- opts
      }, --- chat
    }, --strategies
    display = {
      action_palette = { provider = 'fzf_lua' },
      chat = {
        show_settings = false,
        show_header_separator = true,
        auto_scroll = true,
        show_token_count = true,
      },
    },
  }
  return opts
end

return C
