return {
  {
    'mrjones2014/smart-splits.nvim',
    dependencies = {
      'folke/snacks.nvim',
    },
    opts = function(_, opts)
      -- Desired behavior when your cursor is at an edge and you
      -- are moving towards that same edge:
      -- 'wrap' => Wrap to opposite side
      -- 'split' => Create a new split in the desired direction
      -- 'stop' => Do nothing
      -- function => You handle the behavior yourself
      -- NOTE: If using a function, the function will be called with
      -- a context object with the following fields:
      -- {
      --    mux = {
      --      type:'tmux'|'wezterm'|'kitty'|'zellij'
      --      current_pane_id():number,
      --      is_in_session(): boolean
      --      current_pane_is_zoomed():boolean,
      --      -- following methods return a boolean to indicate success or failure
      --      current_pane_at_edge(direction:'left'|'right'|'up'|'down'):boolean
      --      next_pane(direction:'left'|'right'|'up'|'down'):boolean
      --      resize_pane(direction:'left'|'right'|'up'|'down'):boolean
      --      split_pane(direction:'left'|'right'|'up'|'down',size:number|nil):boolean
      --    },
      --    direction = 'left'|'right'|'up'|'down',
      --    split(), -- utility function to split current Neovim pane in the current direction
      --    wrap(), -- utility function to wrap to opposite Neovim pane
      -- }
      opts.at_edge = 'wrap'
      opts.log_level = 'debug'
      require('custom.wezterm.wezterm_terminal').setup()
    end,
    keys = {
      { '<leader>wt', '<cmd>WeztermTerm<cr>', desc = 'Spawn Terminal (Wezterm)' },
      { '<leader>ws', '<cmd>WeztermWorkspace<cr>', desc = 'Switch Workspace (Wezterm)' },
    },
  },
}
