P = {}

setmetatable(P, {
  __index = function(t, k)
    return require('custom.ai.prompts.' .. k)
  end,
})

return P
