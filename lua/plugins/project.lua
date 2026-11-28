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
  -- Detect project roots without automatically switching directories.
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
    ignore = {},
    use_pattern_matching = false,
    no_fallback = false,
  },

  -- Project root markers.
  patterns = {
    ".git",
    ".github",
    "_darcs",
    ".hg",
    ".bzr",
    ".svn",
    "Pipfile",
    "pyproject.toml",
    ".pre-commit-config.yaml",
    ".pre-commit-config.yml",
    "*.sln",
    "*.csproj",
    ".nvim.lua",
    ".neoconf.json",
    "neoconf.json",
  },

  -- Recent project history.
  history = {
    save_dir = vim.fn.stdpath("data"),
    save_file = "project_history.json",
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
      show = "paths",
    },
  },
})

-- Explicit project-management commands.
vim.keymap.set("n", "<leader>pp", "<cmd>Project<cr>", {
  desc = "Project menu",
})

vim.keymap.set("n", "<leader>pr", "<cmd>Project recents<cr>", {
  desc = "Recent projects",
})

vim.keymap.set("n", "<leader>ps", function()
  require("project.extensions.snacks").pick()
end, {
  desc = "Select project",
})

