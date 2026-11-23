-- Stage 21: Automatic tag closing and renaming.
-- Use existing Tree-sitter parsers for supported markup languages.

vim.pack.add({
  {
    src = "https://github.com/windwp/nvim-ts-autotag",
    name = "nvim-ts-autotag",
  },
})

require("nvim-ts-autotag").setup({
  opts = {
    enable_close = true,
    enable_rename = true,
    enable_close_on_slash = false,
  },
})
