-- Stage 05: Native plugin management and colorscheme.
-- Catppuccin is the first explicitly approved plugin.

vim.pack.add({
  {
    src = "https://github.com/catppuccin/nvim",
    name = "catppuccin",
  },
})

-- Configure Catppuccin.
require("catppuccin").setup({
  flavour = "mocha",
})

-- Activate the colorscheme.
vim.cmd.colorscheme("catppuccin-nvim")
