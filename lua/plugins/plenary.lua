-- CodeCompanion dependencies.
-- plenary.nvim provides shared Lua utilities.
-- CodeCompanion provides AI-assisted development.

vim.pack.add({
  {
    src = "https://github.com/nvim-lua/plenary.nvim",
    name = "plenary.nvim",
  },
  {
    src = "https://github.com/olimorris/codecompanion.nvim",
    name = "codecompanion.nvim",
    version = vim.version.range("^20.0.0"),
  },
})

