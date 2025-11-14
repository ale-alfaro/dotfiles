---@module "nvim-dap-ui"
---@module "nvim-dap"

---@param lhs string
---@param dap_cmd string|function
---@param desc string
---@return KeymapSpec
local function dap_map(lhs, dap_cmd, desc)
  local rhs
  if type(dap_cmd) == "string" then
    rhs = function()
      require('dap')[dap_cmd]()
    end
  else
    rhs = dap_cmd
  end
  return { lhs = lhs, rhs = rhs, opts = { desc = desc } }
end


---@param enable boolean
local function dap_keymap_toggle(enable)
  ---@type KeymapSpec[]
  local dap_keymaps = {
    dap_map("<C-c>", "continue", "DAP: Continue/Start"),
    dap_map("<C-b>", "toggle_breakpoint", "DAP: Toggle breakpoint"),
    dap_map("<C-Right>", "step_over", "DAP: Step over"),
    dap_map("<C-Down>", "step_into", "DAP: Step into"),
    dap_map("<C-Up>", "step_out", "DAP: Step out"),
    dap_map("<C-r>", function() require('dap').repl.open() end, "DAP: REPL open"),
    -- dap_map('<Leader>bl', function() require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end,
    --   "DAP: Log Point"),
  }
  if enable ~= vim.g.dap_keymaps_enabled then
    vim.g.dap_keymaps_enabled = enable
    _G.keymaps_toggle(dap_keymaps, enable)
  end
end

---@type VimPackPlugin
return {
  name = 'nvim-dap',
  plugin = _G.plug_spec { "mfussenegger/nvim-dap" },
  dependencies = _G.plug_spec {
    "nvim-neotest/nvim-nio",
    "rcarriga/nvim-dap-ui",
    "mfussenegger/nvim-dap-python",
    "theHamsta/nvim-dap-virtual-text",
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")
    -- Taken from https://git.ramboe.io/YouTube/neovim-c-the-sane-debugging-setup-nvim-dap-ui
    ---@diagnostic disable-next-line
    dapui.setup({


      render = {
        max_type_length = 100, -- Can be integer or nil.
        max_value_lines = 400, -- Can be integer or nil.
        indent = 1,
      },
      layouts = {
        {
          -- You can change the order of elements in the sidebar
          elements = {
            -- Provide IDs as strings or tables with "id" and "size" keys
            {
              id = "scopes",
              size = 0.5, -- Can be float or integer > 1
            },
            { id = "stacks", size = 0.5 },
          },
          size = 40,
          position = "left", -- Can be "left" or "right"
        },
        {
          elements = {
            "repl",
            "console"
          },
          size = 30,           -- height in lines (adjust to taste)
          position = "bottom", -- "left", "right", "top", "bottom"
        },
      }
    })
    -- dapui.setup({
    --   icons = { expanded = "", collapsed = "", current_frame = "" },
    --   mappings = {
    --     -- Use a table to apply multiple mappings
    --     expand = { "<CR>", "<2-LeftMouse>" },
    --     open = "o",
    --     remove = "d",
    --     edit = "e",
    --     repl = "r",
    --     toggle = "t",
    --   },
    --   force_buffers = true,
    --   expand_lines = true,
    --   ---@diagnostic disable-next-line: missing-fields
    --   controls = { enabled = false }, -- no extra play/step buttons
    --   floating = { border = "rounded" },
    --   -- Set dapui window
    --   render = {
    --     max_type_length = nil,
    --     max_value_lines = nil,
    --     indent = 1
    --   },
    --   -- Only one layout: just the "scopes" (variables) list at the bottom
    --   --
    --   },
    -- })
    require("nvim-dap-virtual-text").setup({
      commented = true, -- Show virtual text alongside comment
    })

    require("dap-python").setup("uv")
    vim.fn.sign_define("DapBreakpoint", {
      text = "",
      texthl = "DiagnosticSignError",
      linehl = "",
      numhl = "",
    })

    vim.fn.sign_define("DapBreakpointRejected", {
      text = "", -- or "❌"
      texthl = "DiagnosticSignError",
      linehl = "",
      numhl = "",
    })

    vim.fn.sign_define("DapStopped", {
      text = "", -- or "→"
      texthl = "DiagnosticSignWarn",
      linehl = "Visual",
      numhl = "DiagnosticSignWarn",
    })

    vim.g.dap_keymaps_enabled = false
    -- stylua: ignore
    -- Automatically open/close DAP UI
    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open()
      dap_keymap_toggle(true)
    end
    dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close()
      dap_keymap_toggle(false)
    end
  end,

  keys = {
    { lhs = "<leader>db", rhs = function() require('dap').toggle_breakpoint() end, opts = { desc = "DAP: Toggle Breakpoint" } },
    { lhs = "<leader>dl", rhs = function() require('dap').run_last() end,          opts = { desc = "DAP: Run Last" } },
    { lhs = "<leader>dc", rhs = function() require('dap').continue() end,          opts = { desc = "DAP: Continue / Start" } },
    { lhs = "<leader>dq", rhs = function() require("dap").terminate() end,         opts = { desc = "DAP: Terminate" } },
    { lhs = "<leader>du", rhs = function() require('dapui').toggle() end,          opts = { desc = "DAP: Toggle UI" } },
  },
  wkey_group = { prefix = '<leader>d', group = 'Debug' },

}
