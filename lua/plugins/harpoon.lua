-- Stage 23: Project file navigation.
-- Harpoon 2 uses Plenary for path and data handling.

vim.pack.add({
  {
    src = "https://github.com/nvim-lua/plenary.nvim",
    name = "plenary.nvim",
  },
  {
    src = "https://github.com/ThePrimeagen/harpoon",
    name = "harpoon",
    version = "harpoon2",
  },
})

-- Activate the optional package before requiring Harpoon.
vim.cmd.packadd("plenary.nvim")

require("harpoon"):setup({
  settings = {
    save_on_toggle = true,
    save_on_change = true,
  },
})
