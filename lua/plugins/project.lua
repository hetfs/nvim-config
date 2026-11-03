-- Stage 12: Project root detection and history.
-- project.nvim detects roots and tracks recent projects.
-- Snacks Picker handles project switching.
-- Working-directory changes remain explicit.

vim.pack.add({
  {
    src = "https://github.com/DrKJeff16/project.nvim",
    name = "project.nvim",
  },
})

local project = require("project")

project.setup({
  -- Detect projects without automatically changing the working directory.
  manual_mode = true,
  enable_autochdir = false,

  -- Explicit project switches use the global working directory.
  scope_chdir = "global",
  silent_chdir = true,

  -- Git-based root detection.
  use_git = true,

  -- LSP-based root detection.
  lsp = {
    enabled = true,
    use_pattern_matching = false,
    no_fallback = false,
  },

  -- Recent project history.
  history = {
    size = 100,
  },

  -- Snacks Picker integration.
  snacks = {
    enabled = true,
    opts = {
      sort = "newest",
      hidden = false,
      title = "Select Project",
      layout = "select",
    },
  },
})
