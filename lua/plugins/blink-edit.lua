-- AI-powered next-edit predictions.
-- Requires an independently running local inference server.

local M = {}

function M.setup()
  require("blink-edit").setup({
    llm = {
      provider = "sweep",
      backend = "openai",

      url = "http://localhost:8000",
      model = "sweep",

      max_tokens = 256,
      temperature = 0,
      timeout_ms = 10000,
    },

    context = {
      enabled = true,

      selection = {
        enabled = true,
        max_lines = 10,
      },

      lsp = {
        enabled = true,
        max_definitions = 2,
        max_references = 2,
        timeout_ms = 100,
      },

      history = {
        enabled = false,
      },
    },

    prefetch = {
      enabled = false,
    },

    normal_mode = {
      enabled = false,
    },

    debounce_ms = 100,

    ui = {
      progress = true,
      suppress_lsp_floats = false,
    },
  })
end

return M
