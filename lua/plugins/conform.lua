-- Stage 11: External formatter integration.
-- Formatter executables are managed separately from Neovim plugins.

vim.pack.add({
  {
    src = "https://github.com/stevearc/conform.nvim",
    name = "conform.nvim",
  },
})
