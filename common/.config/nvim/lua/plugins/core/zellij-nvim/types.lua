---@alias ZellijDirection 'left'|'right'|'up'|'down'

---@alias ZellijAtEdgeBehavior 'split'|'wrap'|'stop'|function
---

---@class ZellijContext
---@field direction ZellijDirection Which direction you're moving (also indicates edge your cursor is currently at)
---@field split fun() Utility function to split the window into the current direction

local M = {
  Direction = {
    ---@type ZellijDirection
    left = 'left',
    ---@type ZellijDirection
    right = 'right',
    ---@type ZellijDirection
    up = 'up',
    ---@type ZellijDirection
    down = 'down',
  },
  AtEdgeBehavior = {
    ---@type ZellijAtEdgeBehavior
    split = 'split',
    ---@type ZellijAtEdgeBehavior
    wrap = 'wrap',
    ---@type ZellijAtEdgeBehavior
    stop = 'stop',
  },
}

return M
