---@module "blink.cmp"
---@module "lazy"

local lspkind

---@return LazySpec[]
return {

  {
    'milanglacier/minuet-ai.nvim',
    event = 'VeryLazy',
    opts = {
      auto_trigger_ft = {},
      keymap = {
        -- accept whole completion
        accept = '<A-A>',
        -- accept one line
        accept_line = '<A-a>',
        -- accept n lines (prompts for number)
        -- e.g. "A-z 2 CR" will accept 2 lines
        accept_n_lines = '<A-z>',
        -- Cycle to prev completion item, or manually invoke completion
        prev = '<A-[>',
        -- Cycle to next completion item, or manually invoke completion
        next = '<A-]>',
        dismiss = '<A-e>',
      },
      add_single_line_entry = true,
      n_completions = 1,
      after_cursor_filter_length = 0,
      provider = 'gemini',
      provider_options = {
        gemini = {
          model = 'gemini-2.0-flash',
          chat_input = {
            template = '{{{language}}}\n{{{tab}}}\n{{{repo_context}}}{{{git_diff}}}<|fim_prefix|>{{{context_before_cursor}}}<|fim_suffix|>{{{context_after_cursor}}}<|fim_middle|>',
            repo_context = function()
              local has_vc, vectorcode_config = pcall(require, 'vectorcode.config')
              if has_vc then
                return vectorcode_config.get_cacher_backend().make_prompt_component(0, function(file)
                  return '<|file_separator|>' .. file.path .. '\n' .. file.document
                end).content
              else
                return ''
              end
            end,
          },
          optional = {
            -- generationConfig = { stop_sequences = { '<|file_separator|>' } },
            generationConfig = {
              maxOutputTokens = 256,
              -- When using `gemini-2.5-flash`, it is recommended to entirely
              -- disable thinking for faster completion retrieval.
              thinkingConfig = {
                thinkingBudget = 0,
              },
            },
            safetySettings = {
              {
                -- HARM_CATEGORY_HATE_SPEECH,
                -- HARM_CATEGORY_HARASSMENT
                -- HARM_CATEGORY_SEXUALLY_EXPLICIT
                category = 'HARM_CATEGORY_DANGEROUS_CONTENT',
                -- BLOCK_NONE
                threshold = 'BLOCK_ONLY_HIGH',
              },
            },
          },
        },
      },

      request_timeout = 10,
    },
    -- local num_ctx = 1024 * 32
    -- local job = require('plenary.job'):new {
    --
    -- }
    -- job:start()
    dependencies = { 'ibhagwan/fzf-lua' },
  }, -- minuet-ai
  {
    'saghen/blink.cmp',
    dependencies = {
      'rafamadriz/friendly-snippets',
      'milanglacier/minuet-ai.nvim',
      'folke/lazydev.nvim',
      'xzbdmw/colorful-menu.nvim',
      'moyiz/blink-emoji.nvim',
      {
        'saghen/blink.compat',
        version = '*',
      },
      'MahanRahmati/blink-nerdfont.nvim',
      'marcoSven/blink-cmp-yanky',
      'archie-judd/blink-cmp-words',
    },
    event = { 'InsertEnter', 'CmdlineEnter' },
    version = '*',
    opts = function(_, opts)
      for _, m in ipairs { 's', 'x', 'v', 'o', 'l' } do
        pcall(vim.keymap.del, m, '<tab>', {})
      end
      ---@type blink.cmp.Config
      opts = vim.tbl_deep_extend('force', opts or {}, {
        keymap = {
          ['<C-x>'] = {
            function(cmp)
              if package.loaded['minuet'] then
                cmp.show { providers = { 'minuet' } }
              end
            end,
          },
          ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
          ['<C-e>'] = { 'hide', 'fallback' },

          ['<Tab>'] = {
            function(cmp)
              local col = vim.fn.col '.' - 1
              if cmp.is_menu_visible() then
                return cmp.select_next()
              -- elseif cmp.snippet_active() then
              --   return cmp.accept()
              elseif col == 0 or vim.fn.getline('.'):sub(col, col):match '%s' then
                return nil
              else
                return cmp.show()
              end
            end,
            'fallback',
          },
          ['<S-Tab>'] = { 'select_prev', 'fallback' },
          ['<Left>'] = { 'fallback' },
          ['<Right>'] = { 'fallback' },
          ['<CR>'] = {
            'accept',
            'fallback',
          },

          ['<Up>'] = { 'snippet_backward', 'select_prev', 'fallback' },
          ['<Down>'] = { 'snippet_forward', 'select_next', 'fallback' },
          ['<C-p>'] = { 'select_prev', 'fallback' },
          ['<C-n>'] = { 'select_next', 'fallback' },

          ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
          ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
        }, -- keymap
        cmdline = {
          completion = {
            menu = { auto_show = true },
            list = {
              selection = {
                preselect = false,
                auto_insert = true,
              },
            },
          },
          enabled = true,
          keymap = {
            ['<CR>'] = {
              function(cmp)
                if cmp.is_menu_visible() then
                  return cmp.accept()
                end
              end,
              'fallback',
            },
            ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
            ['<C-e>'] = { 'hide', 'fallback' },

            ['<Tab>'] = {
              function(cmp)
                local col = vim.fn.col '.' - 1
                if cmp.is_menu_visible() then
                  return cmp.select_next { auto_insert = true, preselect = true }
                elseif col == 0 or vim.fn.getline('.'):sub(col, col):match '%s' then
                  return nil
                else
                  return cmp.show()
                end
              end,
              'fallback',
            },
            ['<S-Tab>'] = { 'snippet_backward', 'select_prev', 'fallback' },

            ['<Up>'] = { 'fallback' },
            ['<Down>'] = { 'fallback' },
            ['<Left>'] = { 'fallback' },
            ['<Right>'] = { 'fallback' },
            ['<C-p>'] = { 'select_prev', 'fallback' },
            ['<C-n>'] = { 'select_next', 'fallback' },

            ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
            ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },

            ['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
          },
        }, -- cmdline
        signature = {
          enabled = true,
          trigger = { enabled = true, show_on_insert = true, show_on_keyword = true },
        },
        appearance = {
          use_nvim_cmp_as_default = true,
          nerd_font_variant = 'mono',
          kind_icons = {
            ellipsis = false,
            text = function(ctx)
              if lspkind == nil then
                lspkind = require('lspkind').symbolic
              end
              return lspkind(ctx.kind, {
                mode = 'symbol',
              })
            end,
          },
        },
        sources = {
          default = {
            'lazydev',
            'lsp',
            -- 'emoji',
            'path',
            'snippets',
            'buffer',
            -- 'nerdfont',
            'yank',
            -- 'dictionary',
            -- 'thesaurus',
          },
          providers = {
            lsp = { async = true, score_offset = 1 },
            -- snippets = { score_offset = 1, max_items = 3 },
            -- nerdfont = {
            --   module = 'blink-nerdfont',
            --   name = 'Nerd Fonts',
            --   -- score_offset = 15, -- Tune by preference
            --   opts = { insert = true }, -- Insert nerdfont icon (default) or complete its name
            -- },
            minuet = {
              name = 'minuet',
              module = 'minuet.blink',
              score_offset = 8,
              async = true,
              timeout_ms = 10000,
              enabled = function()
                return true
              end,
            },
            lazydev = {
              name = 'LazyDev',
              module = 'lazydev.integrations.blink',
              score_offset = 100,
            },
            yank = {
              name = 'yank',
              module = 'blink-yanky',
              opts = {
                minLength = 3,
                onlyCurrentFiletype = false,
                -- trigger_characters = { '"' },
                kind_icon = '󰅍',
              },
              max_items = 3,
            },
          },
        },
        completion = {
          accept = { auto_brackets = { enabled = true } },
          documentation = {
            auto_show = true,
            auto_show_delay_ms = 500,
            window = {
              winblend = 0,
            },
          },
          trigger = {
            prefetch_on_insert = true,
            show_on_keyword = true,
            show_on_trigger_character = true,
            show_in_snippet = true,
            show_on_insert_on_trigger_character = true,
            show_on_accept_on_trigger_character = true,
          },
          list = {
            selection = {
              auto_insert = false,
              preselect = function(ctx)
                return ctx.mode ~= 'cmdline' and not require('blink.cmp').snippet_active { direction = 1 }
              end,
            },
          },

          menu = {
            auto_show = true,
            border = 'none',
            draw = {
              columns = {
                { 'kind_icon' },
                { 'label', gap = 1 },
                { 'source_name' },
              },
              components = {
                label = {
                  text = function(ctx)
                    return require('colorful-menu').blink_components_text(ctx)
                  end,
                  highlight = function(ctx)
                    return require('colorful-menu').blink_components_highlight(ctx)
                  end,
                },
              },
            },
          },
          keyword = { range = 'full' },
        },
        fuzzy = {
          implementation = 'prefer_rust_with_warning',
          sorts = { 'exact', 'score', 'sort_text' },
        },
      })
      return opts
    end, -- opts
  }, -- blink.cmp
  -- {
  --   "garymjr/nvim-snippets",
  --   -- custom snippets by filetypes at ~/.config/nvim/snippets/
  --   event = { "InsertEnter" },
  --   opts = {
  --     friendly_snippets = true,
  --     create_autocmd = true,
  --     create_cmp_source = false,
  --   },
  --   dependencies = { "rafamadriz/friendly-snippets" },
  --   cond = require("_utils").no_vscode,
  -- },
  {
    'gbprod/yanky.nvim',
    opts = {
      ring = { history_length = 5 },
      system_clipboard = {
        sync_with_ring = true,
        clipboard_register = nil,
      },
    },
  },
}
