-- Stage 10: Completion engine.
-- Use Blink's stable 1.x release line with Neovim's native vim.pack.
-- Neovim's native LSP client remains responsible for language servers.

vim.pack.add({
  {
    src = "https://github.com/Saghen/blink.cmp",
    name = "blink.cmp",
    version = vim.version.range("1.0"),
  },
}, { load = true })

require("blink.cmp").setup({
  keymap = {
    preset = "default",
  },

  completion = {
    documentation = {
      auto_show = false,
    },
  },

  sources = {
    default = {
      "lsp",
      "path",
      "snippets",
      "buffer",
    },
  },

  fuzzy = {
    implementation = "lua",
  },
})
