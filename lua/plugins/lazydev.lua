-- Stage 09: Lua development support.
-- lazydev improves LuaLS awareness of Neovim and installed Lua libraries.
-- The Lua language server itself is installed and managed externally.

vim.pack.add({
  {
    src = "https://github.com/folke/lazydev.nvim",
    name = "lazydev.nvim",
  },
})

require("lazydev").setup({})
