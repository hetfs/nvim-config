-- Stage 06: Install mini.nvim and activate the approved mini.icons module.
-- The shared mini.nvim repository is installed only once.

vim.pack.add({
  {
    src = "https://github.com/nvim-mini/mini.nvim",
    name = "mini.nvim",
  },
})

-- Installing mini.nvim does not activate its other modules.
require("mini.icons").setup()
