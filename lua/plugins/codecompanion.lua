-- CodeCompanion.nvim
-- AI chat and inline editing through a local Ollama server.

local M = {}

local function install()
  -- Required dependency.
  vim.pack.add({
    "https://github.com/nvim-lua/plenary.nvim",
  })

  -- CodeCompanion.
  vim.pack.add({
    {
      src = "https://github.com/olimorris/codecompanion.nvim",
      version = vim.version.range("^19.0.0"),
    },
  })
end

function M.setup()
  -- Ensure the plugin and dependency are installed and available.
  install()

  require("codecompanion").setup({
    interactions = {
      -- Interactive AI chat.
      chat = {
        adapter = {
          name = "ollama",
          model = "qwen2.5-coder:7b",
        },
      },

      -- Inline AI editing.
      inline = {
        adapter = {
          name = "ollama",
          model = "qwen2.5-coder:7b",
        },
      },
    },
  })
end

return M

