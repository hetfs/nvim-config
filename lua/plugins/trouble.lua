-- Stage 22: Diagnostics and navigation.
-- Present existing Neovim diagnostics and navigation results.

vim.pack.add({
  {
    src = "https://github.com/folke/trouble.nvim",
    name = "trouble.nvim",
  },
})

require("trouble").setup({})
