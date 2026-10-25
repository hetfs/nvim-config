-- Stage 10: Snippet collection.
-- Blink provides the snippet completion source; Neovim handles expansion.

vim.pack.add({
  {
    src = "https://github.com/rafamadriz/friendly-snippets",
    name = "friendly-snippets",
  },
}, { load = true })
