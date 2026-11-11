-- Stage 13: Markdown rendering.
--
-- md-render.nvim provides terminal-native Markdown previews.
-- Preview activation is explicit; previews never start automatically.
--
-- Optional dependencies are installed separately when their
-- additional functionality is required.

vim.pack.add({
  {
    src = "https://github.com/delphinus/md-render.nvim",
    name = "md-render.nvim",
  },
})

