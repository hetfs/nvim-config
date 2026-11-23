-- Stage 15: Git diff and history.
-- Keep Diffview installation and setup together.

vim.pack.add({
  {
    src = "https://github.com/sindrets/diffview.nvim",
    name = "diffview.nvim",
  },
})

require("diffview").setup({
  use_icons = false,
  hg_cmd = nil,
})
