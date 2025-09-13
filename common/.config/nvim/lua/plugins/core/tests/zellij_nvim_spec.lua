local zellij = require 'core.zellij-nvim'

describe('zellij-nvim', function()
  local mock_jobstart
  local mock_notify

  before_each(function()
    -- Mock vim functions
    mock_jobstart = stub(vim.fn, 'jobstart')
    mock_notify = stub(vim, 'notify')
  end)

  after_each(function()
    mock_jobstart:revert()
    mock_notify:revert()
  end)

  describe('zellij_new_pane', function()
    it('should create a new pane with direction', function()
      zellij.zellij_new_pane('left', '/tmp', false, nil)
      -- Assert that jobstart was called with correct args
      assert.stub(mock_jobstart).was_called_with({
        'zellij', 'action', 'new-pane', '--cwd', '/tmp', '--direction', 'left'
      })
    end)

    it('should handle floating panes', function()
      zellij.zellij_new_pane(nil, '/tmp', true, nil)
      assert.stub(mock_jobstart).was_called_with({
        'zellij', 'action', 'new-pane', '--cwd', '/tmp', '--floating'
      })
    end)

    it('should error on invalid input', function()
      assert.has_error(function()
        zellij.zellij_new_pane(nil, '/tmp', false, nil)
      end, 'No direction or floating specified')
    end)
  end)

  describe('zellij_move_focus', function()
    it('should move focus to the correct direction', function()
      zellij.zellij_move_focus('h')
      assert.stub(mock_jobstart).was_called_with({
        'zellij', 'action', 'move-focus', '--direction', 'left'
      })
    end)
  end)

  describe('zellij_new_terminal', function()
    it('should create a terminal with command', function()
      zellij.zellij_new_terminal({ direction = 'down', cmd = 'ls' })
      assert.stub(mock_jobstart).was_called_with({
        'zellij', 'action', 'new-pane', '--cwd', vim.fn.getcwd(), '--direction', 'down', '--', 'ls'
      })
    end)
  end)

  -- Add more tests for other functions as needed
end)