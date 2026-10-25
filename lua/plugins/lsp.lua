-- Stage 09: LSP server definitions.
-- Neovim's native LSP API owns configuration and activation.

vim.pack.add({
  {
    src = "https://github.com/neovim/nvim-lspconfig",
    name = "nvim-lspconfig",
  },
})
