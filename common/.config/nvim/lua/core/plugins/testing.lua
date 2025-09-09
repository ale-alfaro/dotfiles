return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/neotest-go',
    'nvim-lua/plenary.nvim',
    'antoinemadec/FixCursorHold.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  config = function()
    require('neotest').setup({
      adapters = {
        require('neotest-go')({
          -- Here you can customize the arguments passed to `go test`
          args = { "-count=1", "-vet=off" }
        })
      },
      -- You can customize the UI here
      status = { virtual_text = true },
      output = { open_on_run = true },
      summary = { open_on_run = true },
    })

    -- Keymaps
    vim.keymap.set('n', '<leader>tr', function() require('neotest').run.run() end, { desc = 'Test: Run Nearest' })
    vim.keymap.set('n', '<leader>tf', function() require('neotest').run.run(vim.fn.expand('%')) end, { desc = 'Test: Run File' })
    vim.keymap.set('n', '<leader>ts', function() require('neotest').summary.toggle() end, { desc = 'Test: Summary' })
    vim.keymap.set('n', '<leader>to', function() require('neotest').output.open({ enter = true }) end, { desc = 'Test: Output' })
    vim.keymap.set('n', '<leader>td', function() require('neotest').run.debug() end, { desc = 'Test: Debug Nearest' })
    vim.keymap.set('n', '<leader>tS', function() require('neotest').run.stop() end, { desc = 'Test: Stop' })
  end,
}