-- Stage 16: TODO comment highlighting and navigation.
-- Keep plugin installation and setup together.

vim.pack.add({
  {
    src = "https://github.com/nvim-lua/plenary.nvim",
    name = "plenary.nvim",
  },
  {
    src = "https://github.com/folke/todo-comments.nvim",
    name = "todo-comments.nvim",
  },
})

require("todo-comments").setup({})
