local ctx_files_dir = vim.fn.stdpath 'config' .. '/lua/custom/ai/memory/ctx'

local default_adapters = {
  http = {
    deepseek = 'deepseek',
    ollama = 'ollama',
    openai = 'openai',
    -- opts = {
    --   allow_insecure = false, -- Allow insecure connections?
    --   cache_models_for = 1800, -- Cache adapter models for this long (seconds)
    --   proxy = nil, -- [protocol://]host[:port] e.g. socks5://127.0.0.1:9999
    --   show_presets = true, -- Show preset adapters
    --   show_model_choices = true, -- Show model choices when changing adapter
    -- },
  },
  acp = {
    codex = 'codex',
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
  opts = {
    cmd_timeout = 10e3, -- Timeout for commands that resolve env variables (milliseconds)
  },
}
return {
  adapters = {
    http = {
      ['llama.cpp'] = function()
        return require('codecompanion.adapters').extend('openai_compatible', {
          env = {
            url = 'http://127.0.0.1:8080', -- replace with your llama.cpp instance
            api_key = 'TERM',
            chat_url = '/v1/chat/completions',
          },
          handlers = {
            parse_message_meta = function(self, data)
              local extra = data.extra
              if extra and extra.reasoning_content then
                data.output.reasoning = { content = extra.reasoning_content }
                if data.output.content == '' then
                  data.output.content = nil
                end
              end
              return data
            end,
          },
        })
      end,
      ['qwen3'] = function()
        return require('codecompanion.adapters').extend('ollama', {
          name = 'qwen3-coder', -- Give this adapter a different name to differentiate it from the default ollama adapter
          schema = {
            model = {
              default = 'qwen3-coder:latest',
            },
            num_ctx = {
              default = 20000,
            },
          },
        })
      end,
    },
  },
  interactions = {
    chat = {
      adapter = 'qwen3',
    },
    inline = {
      adapter = 'llama.cpp',
    },
    background = {
      adapter = 'llama.cpp',
    },
    cmd = {
      adapter = 'llama.cpp',
    },
  },
  --PROMPT LIBRARIES ---------------------------------------------------------
  -- prompt_library = {
  --   -- Users can define prompt library items in markdown
  --   markdown = {
  --     dirs = {},
  --   },
  -- },
  -- RULES -------------------------------------------------------------------
  rules = {
    default = {
      description = 'Collection of common files for all projects',
      files = {
        'AGENT.md',
        'AGENTS.md',
        { path = 'CLAUDE.md', parser = 'claude' },
        { path = 'CLAUDE.local.md', parser = 'claude' },
        { path = '~/.claude/CLAUDE.md', parser = 'claude' },
      },
      is_preset = true,
    },
    Python = {
      description = 'Python memory files',
      parser = 'claude',
      ---@return boolean
      enabled = function()
        -- Don't show this to users who aren't working on CodeCompanion itself
        return MiniMisc.find_root(0, { 'uv.lock', 'pyproject.toml' }) ~= nil
      end,
      files = {
        vim.fs.joinpath(ctx_files_dir, 'python', 'anyio.md'),
        vim.fs.joinpath(ctx_files_dir, 'python', 'RULES.md'),
      },
    },
    Just = {
      description = 'Justfile memory files',
      parser = 'claude',
      files = {
        vim.fs.joinpath(ctx_files_dir, 'justfile.md'),
      },
    },
    Cpp = {
      description = 'Justfile memory files',
      parser = 'claude',
      enabled = function()
        -- Don't show this to users who aren't working on CodeCompanion itself
        return vim.fn.getcwd():find('codecompanion', 1, true) ~= nil
      end,
      files = {
        vim.fs.joinpath(ctx_files_dir, 'cpp', 'best-practices.md'),
      },
    },
  },
  -- DISPLAY OPTIONS ----------------------------------------------------------
  display = {
    action_palette = {
      width = 95,
      height = 10,
      prompt = 'Prompt ', -- Prompt used for interactive LLM calls
      provider = 'fzf_lua', -- telescope|mini_pick|snacks|default
      opts = {
        show_preset_actions = true, -- Show the preset actions in the action palette?
        show_preset_prompts = true, -- Show the preset prompts in the action palette?
        show_preset_rules = true, -- Show the preset rules in the action palette?
        title = 'CodeCompanion actions', -- The title of the action palette
      },
    },
    chat = {

      -- Chat buffer options --------------------------------------------------
      auto_scroll = false, -- Automatically scroll down and place the cursor at the end?
      intro_message = 'Press ? for options',

      ---The function to display the token count
      ---@param tokens number
      ---@param adapter CodeCompanion.HTTPAdapter|CodeCompanion.ACPAdapter
      token_count = function(tokens, adapter) -- The function to display the token count
        return ' (' .. tokens .. ' tokens)'
      end,
    },
    diff = {
      enabled = true,
      provider = 'mini_diff', -- mini_diff|split|inline

      provider_opts = {
        -- Options for inline diff provider
        inline = {
          layout = 'buffer', -- float|buffer - Where to display the diff

          opts = {
            context_lines = 3, -- Number of context lines in hunks
            show_dim = true, -- Enable dimming background for floating windows (applies to both diff and super_diff)
            dim = 25, -- Background dim level for floating diff (0-100, [100 full transparent], only applies when layout = "float")
            full_width_removed = true, -- Make removed lines span full width
            show_keymap_hints = true, -- Show "gda: accept | gdr: reject" hints above diff
            show_removed = true, -- Show removed lines as virtual text
          },
        },

        -- Options for the split provider
        split = {
          close_chat_at = 240, -- Close an open chat buffer if the total columns of your display are less than...
          layout = 'vertical', -- vertical|horizontal split
          opts = {
            'internal',
            'filler',
            'closeoff',
            'algorithm:histogram', -- https://adamj.eu/tech/2024/01/18/git-improve-diff-histogram/
            'indent-heuristic', -- https://blog.k-nut.eu/better-git-diffs
            'followwrap',
            'linematch:120',
          },
        },
      },
    },
  },
  -- EXTENSIONS ------------------------------------------------------
  extensions = {
    history = {
      enabled = true, -- defaults to true
      opts = {
        dir_to_save = vim.fn.stdpath 'data' .. '/codecompanion_chats.json',
      },
    },
  },
  spinner = {
    enabled = true,
    opts = { style = 'native' },
  },
  -- GENERAL OPTIONS ----------------------------------------------------------
  opts = {
    log_level = 'INFO', -- TRACE|DEBUG|ERROR|INFO
    job_start_delay = 1500, -- Delay in milliseconds between cmd tools
    submit_delay = 2000, -- Delay in milliseconds before auto-submitting the chat buffer
  },
}
