---@module "blink.cmp"
---@module "lazy"

return {
  {
    'saghen/blink.cmp',
    init = function()
      -- set to `true` to follow the main branch
      -- you need to have a working rust toolchain to build the plugin
      -- in this case.
      vim.g.lazyvim_blink_main = true
    end,
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
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

      appearance = {
        -- sets the fallback highlight groups to nvim-cmp's highlight groups
        -- useful for when your theme doesn't support blink.cmp
        -- will be removed in a future release, assuming themes add support
        use_nvim_cmp_as_default = true,
        -- set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- adjusts spacing to ensure icons are aligned
        nerd_font_variant = 'mono',
      },

      completion = {
        accept = {
          -- experimental auto-brackets support
          auto_brackets = {
            enabled = true,
          },
        },
        menu = {
          draw = {
            treesitter = { 'lsp' },
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
        },
        ghost_text = {
          enabled = true,
        },
      },

      -- experimental signature help support
      signature = { enabled = true },

      sources = {
        -- adding any nvim-cmp sources here will enable them
        -- with blink.compat
        compat = {},
        default = { 'lsp', 'path', 'snippets', 'buffer' },
        per_filetype = {
          lua = { inherit_defaults = true, 'lazydev' },
        },
        providers = {
          lazydev = {
            name = 'LazyDev',
            module = 'lazydev.integrations.blink',
            score_offset = 100, -- show at a higher priority than lsp
          },

          lsp = { async = true, score_offset = 70 },
          snippets = { score_offset = 1, max_items = 3 },
          -- yank = {
          --   name = 'yank',
          --   module = 'blink-yanky',
          --   opts = {
          --     minLength = 3,
          --     onlyCurrentFiletype = true,
          --     -- trigger_characters = { '"' },
          --     kind_icon = '󰅍',
          --   },
          --   max_items = 3,
          -- },
          --           },
        },
      },
      cmdline = {
        enabled = true,
        keymap = { preset = 'cmdline' },
        completion = {
          list = { selection = { preselect = false } },
          menu = {
            auto_show = function(ctx)
              return vim.fn.getcmdtype() == ':'
            end,
          },
          ghost_text = { enabled = true },
        },
      },

      keymap = {
        preset = 'enter',
        ['<C-y>'] = { 'select_and_accept' },
      },
    },
  },

  -- {
  --   'gbprod/yanky.nvim',
  --   opts = {
  --     ring = { history_length = 5 },
  --     system_clipboard = {
  --       sync_with_ring = true,
  --       clipboard_register = nil,
  --     },
  --   },
  -- },
}
