-- Stage 12: Project root detection and navigation.
-- project.nvim manages project roots, working directories, and history.

vim.pack.add({
  {
    src = "https://github.com/DrKJeff16/project.nvim",
    name = "project.nvim",
  },
})

require("project").setup({
  -- Detect project roots automatically.
  manual_mode = false,

  -- Do not enable Neovim's automatic directory-changing option.
  enable_autochdir = false,

  -- Make working-directory scope explicit.
  scope_chdir = "global",

  -- Retain Git and marker-based root detection.
  use_git = true,

  -- Keep root detection compatible with the existing LSP setup.
  lsp = {
    enabled = true,
    use_pattern_matching = false,
    no_fallback = false,
  },

  -- Keep project.nvim's picker integrations independent from
  -- the existing Snacks Picker and fzf-lua configurations.
})
