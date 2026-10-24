-- Stage 06: Keymap discovery and descriptive keybinding groups.

vim.pack.add({
  {
    src = "https://github.com/folke/which-key.nvim",
    name = "which-key.nvim",
  },
})

require("which-key").setup({
  spec = {
    { "<leader>s", group = "Window Management" },
  },
})
