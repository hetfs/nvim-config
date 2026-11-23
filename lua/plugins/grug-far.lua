
-- Stage 14: Project-wide search and replace.
-- Keep plugin installation and setup together.

vim.pack.add({
  {
    src = "https://github.com/MagicDuck/grug-far.nvim",
    name = "grug-far.nvim",
  },
})

require("grug-far").setup({})
