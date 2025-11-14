return {
  qwen3 = function()
    return require("codecompanion.adapters").extend("ollama", {
      name = "qwen3", -- Give this adapter a different name to differentiate it from the default ollama adapter
      opts = {
        vision = true,
        stream = true,
      },
      schema = {
        model = {
          default = "qwen3:latest",
        },
        num_ctx = {
          default = 16384,
        },
        think = {
          default = false,
        },
        keep_alive = {
          default = "5m",
        },
      },
    })
  end,
}
