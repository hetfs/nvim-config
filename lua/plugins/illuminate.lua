-- Stage 28: Symbol reference highlighting.
-- Use LSP, Tree-sitter, and regex providers in priority order.

vim.pack.add({
  {
    src = "https://github.com/RRethy/vim-illuminate",
    name = "vim-illuminate",
  },
})

require("illuminate").configure({
  providers = {
    "lsp",
    "treesitter",
    "regex",
  },

  delay = 150,

  under_cursor = true,

  large_file_cutoff = 10000,
  large_file_overrides = nil,

  min_count_to_highlight = 1,

  -- Register project-owned mappings instead.
  disable_keymaps = true,
})
