
-- Stage 20: GitHub integration.
-- Manage GitHub issues, pull requests, reviews, and discussions.

vim.pack.add({
  {
    src = "https://github.com/pwntester/octo.nvim",
    name = "octo.nvim",
  },
})

require("octo").setup({
  picker = "snacks",
  enable_builtin = true,

  default_remote = {
    "upstream",
    "origin",
  },

  default_merge_method = "squash",
  default_delete_branch = false,

  file_panel = {
    icons = false,
  },
})

