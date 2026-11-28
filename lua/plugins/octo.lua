-- GitHub integration.
-- Manage GitHub issues, pull requests, reviews, and discussions.
--
-- External dependency:
--   GitHub CLI (gh)
--
-- Authenticate separately in the terminal:
--   gh auth login
--   gh auth status

vim.pack.add({
  {
    src = "https://github.com/pwntester/octo.nvim",
    name = "octo.nvim",
  },
})

require("octo").setup({
  -- Use Snacks for issue and pull request selection.
  picker = "snacks",
  enable_builtin = true,

  -- Prefer upstream when available, then origin.
  default_remote = {
    "upstream",
    "origin",
  },

  -- Pull request defaults.
  default_merge_method = "squash",
  default_delete_branch = false,

  -- File panel appearance.
  file_panel = {
    icons = false,
  },
})

