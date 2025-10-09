---@type string
local xdg_config = vim.env.XDG_CONFIG_HOME or vim.env.HOME .. '/.config'

---@param path string
local function have(path)
  return vim.uv.fs_stat(xdg_config .. '/' .. path) ~= nil
end

return {
  {

    'neovim/nvim-lspconfig',
    opts = function(_, opts)
      -- opts.servers = python_lsp_config
      opts.servers = {
        ---@type vim.lsp.Config
        hyprls = {
          build = 'go install github.com/hyprland-community/hyprls/cmd/hyprls@latest',
          cmd = { 'hyprls', '--stdio' },
          filetypes = { 'hyprlang' },

          root_dir = function(bufnr, on_dir)
            -- return vim.fs.dirname(vim.fs.find('.git', { path = fname, upward = true })[1])
            if not vim.fn.bufname(bufnr):match '%.conf$' then
              on_dir(vim.fn.getcwd())
            end
          end,
          single_file_support = true,

          docs = {
            description = [[
      https://github.com/hyprland-community/hyprls

      `hyprls` can be installed via `go`:
      ```sh
      go install github.com/ewen-lbh/hyprls/cmd/hyprls@latest
      ```

      ]],
          },
          on_attach = function(client, bufnr)
            vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter' }, {
              pattern = { '*.hl', 'hypr*.conf' },
              callback = function(event)
                print(string.format('starting hyprls for %s', vim.inspect(event)))
                --   vim.lsp.start {
                --     name = 'hyprlang',
                --     cmd = { 'hyprls' },
                --     root_dir = vim.fn.getcwd(),
                --   }
              end,
            })
          end,
        },
      }
    end,
    vim.lsp.enable 'hyprls',
  },
  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        bashls = {
          filetypes = { 'sh', 'zsh', 'bash' },
        },
      },
    },
    setup = {},
  },
  {
    'mason-org/mason.nvim',
    opts = { ensure_installed = { 'shellcheck' } },
  },
  -- add some stuff to treesitter
  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      local function add(lang)
        if type(opts.ensure_installed) == 'table' then
          table.insert(opts.ensure_installed, lang)
        end
      end

      vim.filetype.add {
        extension = { rasi = 'rasi', rofi = 'rasi', wofi = 'rasi' },
        filename = {
          ['vifmrc'] = 'vim',
        },
        pattern = {
          ['.*/waybar/config'] = 'jsonc',
          ['.*/mako/config'] = 'dosini',
          ['.*/kitty/.+%.conf'] = 'kitty',
          ['.*/hypr/.+%.conf'] = 'hyprlang',
          ['%.env%.[%w_.-]+'] = 'sh',
        },
      }
      vim.treesitter.language.register('bash', 'kitty')

      add 'git_config'

      if have 'hypr' then
        add 'hyprlang'
      end

      if have 'fish' then
        add 'fish'
      end

      if have 'rofi' or have 'wofi' then
        add 'rasi'
      end
    end,
  },
}
