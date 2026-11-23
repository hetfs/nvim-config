

-- Stage 19: Git merge conflict resolution.
-- Keep conflict handling separate from Gitsigns and Diffview.

vim.pack.add({
  {
    src = "https://github.com/akinsho/git-conflict.nvim",
    name = "git-conflict.nvim",
  },
})

require("git-conflict").setup({
  -- Use project-specific buffer-local mappings.
  default_mappings = {
    ours = "<leader>gco",
    theirs = "<leader>gct",
    both = "<leader>gcb",
    none = "<leader>gc0",
    next = "]x",
    prev = "[x",
  },

  -- Retain the plugin's conflict-resolution commands.
  default_commands = true,

  -- Keep LSP diagnostics enabled during conflict resolution.
  disable_diagnostics = false,

  -- Populate Neovim's quickfix list when requested.
  list_opener = "copen",

  highlights = {
    incoming = "DiffAdd",
    current = "DiffText",
  },
})
